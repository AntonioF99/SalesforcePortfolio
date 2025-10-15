/**
 * @description Native Salesforce automation for subscription lifecycle management
 * @author Antonio Franco
 * @date 2025-09-24
 * @story STORY-006: Platform Events & Integration Layer (Simplified)
 */
public class SubscriptionAutomationService {
    
    /**
     * @description Handles new subscription automation
     * @param subscriptionIds Set of subscription IDs to process
     */
    public static void processNewSubscriptions(Set<Id> subscriptionIds) {
        
        if (subscriptionIds.isEmpty()) return;
        
        // Query subscription data with related account
        List<Subscription__c> subscriptions = [
            SELECT Id, Name, Account__c, Account__r.Name, Status__c, 
                   Start_Date__c
            FROM Subscription__c 
            WHERE Id IN :subscriptionIds
            WITH SECURITY_ENFORCED
        ];
        
        // Bulk query email template
        EmailTemplate welcomeTemplate = null;
        try {
            welcomeTemplate = [
                SELECT Id FROM EmailTemplate 
                WHERE DeveloperName = 'Subscription_Welcome'
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
        } catch (QueryException e) {
            System.debug('Welcome email template not found: ' + e.getMessage());
        }
        
        // Bulk query contacts for all accounts
        Set<Id> accountIds = new Set<Id>();
        for (Subscription__c sub : subscriptions) {
            if (sub.Account__c != null) {
                accountIds.add(sub.Account__c);
            }
        }
        
        Map<Id, Contact> accountContactMap = new Map<Id, Contact>();
        try {
            List<Contact> contacts = [
                SELECT Id, AccountId, Email FROM Contact
                WHERE AccountId IN :accountIds
                AND Email != null
                WITH SECURITY_ENFORCED
                ORDER BY AccountId, CreatedDate ASC
            ];
            for (Contact contact : contacts) {
                if (!accountContactMap.containsKey(contact.AccountId)) {
                    accountContactMap.put(contact.AccountId, contact);
                }
            }
        } catch (QueryException e) {
            System.debug('Contacts not found: ' + e.getMessage());
        }
        
        List<Task> onboardingTasks = new List<Task>();
        List<Messaging.SingleEmailMessage> welcomeEmails = new List<Messaging.SingleEmailMessage>();
        Map<Id, Account> accountsToUpdateMap = new Map<Id, Account>();
        
        for (Subscription__c sub : subscriptions) {
            
            // Create onboarding tasks
            onboardingTasks.addAll(createOnboardingTasks(sub));
            
            // Send welcome email
            if (sub.Account__c != null) {
                Messaging.SingleEmailMessage email = createWelcomeEmail(sub, welcomeTemplate, accountContactMap);
                if (email != null) {
                    welcomeEmails.add(email);
                }
            }
            
            // Update account subscription status (avoid duplicates with Map)
            if (sub.Account__c != null && !accountsToUpdateMap.containsKey(sub.Account__c)) {
                accountsToUpdateMap.put(sub.Account__c, new Account(
                    Id = sub.Account__c,
                    Subscription_Status__c = Constants.ACCOUNT_STATUS_ACTIVE_CUSTOMER,
                    Last_Subscription_Date__c = sub.Start_Date__c
                ));
            }
        }
        
        // Execute bulk operations
        if (!onboardingTasks.isEmpty()) {
            insert onboardingTasks;
        }
        
        if (!welcomeEmails.isEmpty() && !Test.isRunningTest()) {
            System.debug('Sending ' + welcomeEmails.size() + ' welcome emails');

            try {
                Messaging.SendEmailResult[] results = Messaging.sendEmail(welcomeEmails);

                for (Messaging.SendEmailResult result : results) {
                    if (result.isSuccess()) {
                        System.debug('Email sent successfully');
                    } else {
                        for (Messaging.SendEmailError error : result.getErrors()) {
                            System.debug(LoggingLevel.ERROR, 'Email error (non-blocking): ' + error.getMessage());
                        }
                    }
                }
            } catch (Exception emailException) {
                // Log email failure but don't stop the automation process
                System.debug(LoggingLevel.ERROR, 'Email sending failed (non-blocking): ' + emailException.getMessage());

                // Continue with rest of automation - email failure shouldn't block subscription creation
                System.debug('Continuing with subscription automation despite email failure');
            }
        } else if (Test.isRunningTest()) {
            System.debug('Test context: Skipping actual email send for ' + welcomeEmails.size() + ' emails');
        }
        
        if (!accountsToUpdateMap.isEmpty()) {
            System.debug('Updating ' + accountsToUpdateMap.size() + ' account records');
            update accountsToUpdateMap.values();
        }
    }
    
    /**
     * @description Handles subscription status changes
     * @param subscriptionIds Set of subscription IDs with status changes
     */
    public static void processStatusChanges(Set<Id> subscriptionIds) {
        
        if (subscriptionIds.isEmpty()) return;
        
        List<Subscription__c> subscriptions = [
            SELECT Id, Name, Account__c, Account__r.Name, Status__c
            FROM Subscription__c 
            WHERE Id IN :subscriptionIds
            WITH SECURITY_ENFORCED
        ];
        
        List<Task> followUpTasks = new List<Task>();
        Map<Id, Account> accountsToUpdateMap = new Map<Id, Account>();
        
        for (Subscription__c sub : subscriptions) {
            
            // Create status-specific tasks
            Task followUp = createStatusChangeTask(sub);
            if (followUp != null) {
                followUpTasks.add(followUp);
            }
            
            // Update account health score based on subscription status (avoid duplicates)
            if (sub.Account__c != null && !accountsToUpdateMap.containsKey(sub.Account__c)) {
                Decimal healthScore = calculateAccountHealthScore(sub.Status__c);
                accountsToUpdateMap.put(sub.Account__c, new Account(
                    Id = sub.Account__c,
                    Health_Score__c = healthScore,
                    Subscription_Status__c = getAccountStatus(sub.Status__c)
                ));
            }
        }
        
        if (!followUpTasks.isEmpty()) {
            insert followUpTasks;
        }
        
        if (!accountsToUpdateMap.isEmpty()) {
            System.debug('Updating ' + accountsToUpdateMap.size() + ' account records');
            update accountsToUpdateMap.values();
        }
    }
    
    /**
     * @description Generates invoices for active subscriptions
     * @param subscriptionIds Set of subscription IDs that just became Active
     *
     * Security: This method is called only from trigger context (system mode).
     * User permissions are validated in SubscriptionValidator before the trigger executes.
     * WITH SECURITY_ENFORCED is not required as this is internal automation not exposed to users.
     * Follows Salesforce best practice: triggers execute in system context by design.
     */
    public static void generateInvoicesForActiveSubscriptions(Set<Id> subscriptionIds) {

        if (subscriptionIds.isEmpty()) return;

        List<Subscription__c> subscriptions = [
            SELECT Id, Name, Account__c, Quantity__c, Start_Date__c,
                   Price_Plan__c, Price_Plan__r.Name, Price_Plan__r.Unit_Price__c,
                   Price_Plan__r.Billing_Frequency__c
            FROM Subscription__c
            WHERE Id IN :subscriptionIds
            AND Status__c = :Constants.SUBSCRIPTION_STATUS_ACTIVE
            AND Price_Plan__c != null
        ];

        if (subscriptions.isEmpty()) {
            System.debug('No active subscriptions with Price Plan found');
            return;
        }

        Set<Id> accountIds = new Set<Id>();
        for (Subscription__c sub : subscriptions) {
            accountIds.add(sub.Account__c);
        }

        Map<String, Invoice__c> existingInvoicesMap = checkExistingInvoices(subscriptionIds, accountIds);

        List<Invoice__c> invoicesToInsert = new List<Invoice__c>();
        Map<Integer, Subscription__c> subscriptionIndexMap = new Map<Integer, Subscription__c>();
        Integer index = 0;

        for (Subscription__c sub : subscriptions) {

            String duplicateKey = buildInvoiceDuplicateKey(sub.Id, Date.today());

            if (existingInvoicesMap.containsKey(duplicateKey)) {
                System.debug('Invoice already exists for subscription: ' + sub.Name + ' for current period');
                continue;
            }

            Invoice__c invoice = new Invoice__c(
                Account__c = sub.Account__c,
                Subscription__c = sub.Id,
                Status__c = Constants.INVOICE_STATUS_DRAFT,
                Invoice_Date__c = Date.today(),
                Payment_Terms__c = Constants.PAYMENT_TERMS_NET_30
            );
            invoicesToInsert.add(invoice);
            subscriptionIndexMap.put(index, sub);
            index++;
        }

        if (invoicesToInsert.isEmpty()) {
            System.debug('No new invoices to create - all subscriptions already have invoices for current period');
            return;
        }

        try {
            insert invoicesToInsert;
            System.debug('Created ' + invoicesToInsert.size() + ' invoices');
        } catch (DmlException e) {
            System.debug(LoggingLevel.ERROR, 'Failed to insert invoices: ' + e.getMessage());
            throw new SubscriptionAutomationException('Failed to create invoices: ' + e.getMessage());
        }

        List<Invoice_Line_Item__c> lineItemsToInsert = new List<Invoice_Line_Item__c>();

        for (Integer i = 0; i < invoicesToInsert.size(); i++) {
            Subscription__c sub = subscriptionIndexMap.get(i);
            Invoice__c invoice = invoicesToInsert[i];

            Date periodStart = Date.today();
            Date periodEnd = calculatePeriodEnd(periodStart, sub.Price_Plan__r.Billing_Frequency__c);

            Invoice_Line_Item__c lineItem = new Invoice_Line_Item__c(
                Invoice__c = invoice.Id,
                Subscription__c = sub.Id,
                Type__c = Constants.LINE_ITEM_TYPE_ADD_ON,
                Status__c = 'Active',
                Quantity__c = sub.Quantity__c != null ? sub.Quantity__c : 1,
                Unit_Price__c = sub.Price_Plan__r.Unit_Price__c,
                Period_Start__c = periodStart,
                Period_End__c = periodEnd,
                Discount_Percent__c = 0
            );
            lineItemsToInsert.add(lineItem);
        }

        try {
            insert lineItemsToInsert;
            System.debug('Created ' + lineItemsToInsert.size() + ' invoice line items');
        } catch (DmlException e) {
            System.debug(LoggingLevel.ERROR, 'Failed to insert line items: ' + e.getMessage());
            throw new SubscriptionAutomationException('Failed to create invoice line items: ' + e.getMessage());
        }

        PlatformEventPublisher.publishInvoiceEvents(invoicesToInsert, 'Created');
        System.debug('Published ' + invoicesToInsert.size() + ' Invoice Created events');
    }

    /**
     * @description Checks if invoices already exist for subscriptions in current period
     * @param subscriptionIds Set of subscription IDs to check
     * @param accountIds Set of account IDs to check
     * @return Map of duplicate keys to existing invoices
     *
     * Security: Internal helper method for duplicate detection. No security enforcement needed
     * as it's called from trigger context with already validated permissions.
     */
    private static Map<String, Invoice__c> checkExistingInvoices(Set<Id> subscriptionIds, Set<Id> accountIds) {

        Map<String, Invoice__c> existingInvoicesMap = new Map<String, Invoice__c>();

        Date periodStart = Date.today();
        Date periodEnd = periodStart.addMonths(1);

        List<Invoice_Line_Item__c> existingLineItems = [
            SELECT Id, Invoice__c, Subscription__c, Invoice__r.Account__c,
                   Period_Start__c, Period_End__c
            FROM Invoice_Line_Item__c
            WHERE Subscription__c IN :subscriptionIds
            AND Period_Start__c >= :periodStart
            AND Period_End__c <= :periodEnd
            AND Invoice__r.Status__c != 'Voided'
            LIMIT 200
        ];

        for (Invoice_Line_Item__c lineItem : existingLineItems) {
            String key = buildInvoiceDuplicateKey(lineItem.Subscription__c, lineItem.Period_Start__c);
            if (!existingInvoicesMap.containsKey(key)) {
                existingInvoicesMap.put(key, new Invoice__c(Id = lineItem.Invoice__c));
            }
        }

        return existingInvoicesMap;
    }

    /**
     * @description Builds a unique key for duplicate invoice detection
     * @param subscriptionId Subscription ID
     * @param periodStart Period start date
     * @return Unique key string
     */
    private static String buildInvoiceDuplicateKey(Id subscriptionId, Date periodStart) {
        return subscriptionId + '_' + periodStart.year() + '_' + periodStart.month();
    }

    /**
     * @description Calculates period end date based on billing frequency
     * @param startDate Period start date
     * @param billingFrequency Billing frequency (Monthly, Quarterly, etc.)
     * @return Period end date
     */
    private static Date calculatePeriodEnd(Date startDate, String billingFrequency) {

        if (startDate == null || String.isBlank(billingFrequency)) {
            return startDate.addMonths(1).addDays(-1);
        }

        if (billingFrequency == Constants.BILLING_FREQUENCY_MONTHLY) {
            return startDate.addMonths(1).addDays(-1);
        } else if (billingFrequency == Constants.BILLING_FREQUENCY_QUARTERLY) {
            return startDate.addMonths(3).addDays(-1);
        } else if (billingFrequency == Constants.BILLING_FREQUENCY_SEMI_ANNUAL) {
            return startDate.addMonths(6).addDays(-1);
        } else if (billingFrequency == Constants.BILLING_FREQUENCY_ANNUAL) {
            return startDate.addYears(1).addDays(-1);
        } else {
            return startDate.addMonths(1).addDays(-1);
        }
    }

    /**
     * @description Calculates invoice due date based on billing frequency
     * @param invoiceDate Invoice date
     * @param billingFrequency Billing frequency
     * @return Due date
     */
    private static Date calculateDueDate(Date invoiceDate, String billingFrequency) {

        if (invoiceDate == null) {
            return Date.today().addDays(30);
        }

        if (billingFrequency == Constants.BILLING_FREQUENCY_MONTHLY) {
            return invoiceDate.addDays(30);
        } else if (billingFrequency == Constants.BILLING_FREQUENCY_QUARTERLY) {
            return invoiceDate.addDays(30);
        } else if (billingFrequency == Constants.BILLING_FREQUENCY_SEMI_ANNUAL) {
            return invoiceDate.addDays(45);
        } else if (billingFrequency == Constants.BILLING_FREQUENCY_ANNUAL) {
            return invoiceDate.addDays(60);
        } else {
            return invoiceDate.addDays(30);
        }
    }

    /**
     * @description Custom exception for subscription automation errors
     */
    public class SubscriptionAutomationException extends Exception {}

    /**
     * @description Creates onboarding tasks for new subscriptions
     */
    private static List<Task> createOnboardingTasks(Subscription__c subscription) {
        
        List<Task> tasks = new List<Task>();
        String accountName = subscription.Account__r?.Name;
        
        // Day 1: Welcome call
        tasks.add(new Task(
            Subject = 'Welcome Call - ' + accountName,
            Description = 'Conduct welcome call for new subscription: ' + subscription.Name,
            WhatId = subscription.Id,
            Status = 'Not Started',
            Priority = 'High',
            ActivityDate = Date.today().addDays(1)
        ));
        
        // Week 1: Check-in
        tasks.add(new Task(
            Subject = 'Week 1 Check-in - ' + accountName,
            Description = 'Follow up on onboarding progress and address questions',
            WhatId = subscription.Id,
            Status = 'Not Started',
            Priority = 'Normal',
            ActivityDate = Date.today().addDays(7)
        ));
        
        // Month 1: Success review
        tasks.add(new Task(
            Subject = 'Month 1 Success Review - ' + accountName,
            Description = 'Review subscription value and identify expansion opportunities',
            WhatId = subscription.Id,
            Status = 'Not Started',
            Priority = 'Normal',
            ActivityDate = Date.today().addDays(30)
        ));
        
        return tasks;
    }
    
    /**
     * @description Creates welcome email for new subscription
     */
    private static Messaging.SingleEmailMessage createWelcomeEmail(Subscription__c subscription, EmailTemplate welcomeTemplate, Map<Id, Contact> accountContactMap) {
        
        try {
            // Use bulk queried template and contact
            if (welcomeTemplate == null) {
                throw new QueryException('Template not found');
            }
            System.debug('Found email template: ' + welcomeTemplate.Id);
            
            Contact primaryContact = accountContactMap.get(subscription.Account__c);
            if (primaryContact == null) {
                throw new QueryException('Contact not found');
            }
            System.debug('Found contact: ' + primaryContact?.Email);
            
            if (primaryContact != null) {
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setTemplateId(welcomeTemplate.Id);
                email.setTargetObjectId(primaryContact.Id);
                email.setWhatId(subscription.Id);
                email.setSaveAsActivity(true);
                
                System.debug('Email message created successfully for: ' + primaryContact.Email);
                return email;
            } else {
                System.debug(LoggingLevel.WARN, 'No contact found with email for Account: ' + subscription.Account__c);
            }
            
        } catch (QueryException e) {
            System.debug(LoggingLevel.ERROR, 'Welcome email template or contact not found: ' + e.getMessage());
            // In test context, return null to avoid email failures
            if (Test.isRunningTest()) {
                return null;
            }
        }
        
        return null;
    }
    
    /**
     * @description Creates tasks for subscription status changes
     */
    private static Task createStatusChangeTask(Subscription__c subscription) {
        
        String subject;
        String description;
        String priority = 'Normal';
        
        if (subscription.Status__c == Constants.SUBSCRIPTION_STATUS_ACTIVE) {
            subject = 'Subscription Activated - ' + subscription.Account__r?.Name;
            description = 'Subscription successfully activated. Ensure customer has access to all features.';
        } else if (subscription.Status__c == Constants.SUBSCRIPTION_STATUS_SUSPENDED) {
            subject = 'URGENT: Subscription Suspended - ' + subscription.Account__r?.Name;
            description = 'Subscription suspended. Contact customer immediately to resolve payment issues.';
            priority = 'High';
        } else if (subscription.Status__c == Constants.SUBSCRIPTION_STATUS_CANCELLED) {
            subject = 'Subscription Cancelled - ' + subscription.Account__r?.Name;
            description = 'Subscription cancelled. Schedule exit interview and identify win-back opportunities.';
            priority = 'High';
        } else {
            return null;
        }
        
        return new Task(
            Subject = subject,
            Description = description,
            WhatId = subscription.Id,
            Status = 'Not Started',
            Priority = priority,
            ActivityDate = Date.today()
        );
    }
    
    /**
     * @description Calculates account health score based on subscription status
     */
    private static Decimal calculateAccountHealthScore(String subscriptionStatus) {
        
        if (subscriptionStatus == Constants.SUBSCRIPTION_STATUS_ACTIVE) {
            return 100;
        } else if (subscriptionStatus == Constants.SUBSCRIPTION_STATUS_TRIAL) {
            return 75;
        } else if (subscriptionStatus == Constants.SUBSCRIPTION_STATUS_SUSPENDED) {
            return 25;
        } else if (subscriptionStatus == Constants.SUBSCRIPTION_STATUS_CANCELLED) {
            return 0;
        } else {
            return 50;
        }
    }
    
    /**
     * @description Gets account status based on subscription status
     */
    private static String getAccountStatus(String subscriptionStatus) {
        
        if (subscriptionStatus == Constants.SUBSCRIPTION_STATUS_ACTIVE) {
            return Constants.ACCOUNT_STATUS_ACTIVE_CUSTOMER;
        } else if (subscriptionStatus == Constants.SUBSCRIPTION_STATUS_TRIAL) {
            return Constants.ACCOUNT_STATUS_TRIAL_CUSTOMER;
        } else if (subscriptionStatus == Constants.SUBSCRIPTION_STATUS_SUSPENDED) {
            return Constants.ACCOUNT_STATUS_AT_RISK;
        } else if (subscriptionStatus == Constants.SUBSCRIPTION_STATUS_CANCELLED) {
            return Constants.ACCOUNT_STATUS_FORMER_CUSTOMER;
        } else {
            return Constants.ACCOUNT_STATUS_PROSPECT;
        }
    }
}
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
                    Subscription_Status__c = 'Active Customer',
                    Last_Subscription_Date__c = sub.Start_Date__c
                ));
            }
        }
        
        // Execute bulk operations
        if (!onboardingTasks.isEmpty()) {
            insert onboardingTasks;
        }
        
        if (!welcomeEmails.isEmpty()) {
            System.debug('Sending ' + welcomeEmails.size() + ' welcome emails');
            Messaging.SendEmailResult[] results = Messaging.sendEmail(welcomeEmails);
            
            for (Messaging.SendEmailResult result : results) {
                if (result.isSuccess()) {
                    System.debug('Email sent successfully');
                } else {
                    for (Messaging.SendEmailError error : result.getErrors()) {
                        System.debug(LoggingLevel.ERROR, 'Email error: ' + error.getMessage());
                    }
                }
            }
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
        
        switch on subscription.Status__c {
            when 'Active' {
                subject = 'Subscription Activated - ' + subscription.Account__r?.Name;
                description = 'Subscription successfully activated. Ensure customer has access to all features.';
            }
            when 'Suspended' {
                subject = 'URGENT: Subscription Suspended - ' + subscription.Account__r?.Name;
                description = 'Subscription suspended. Contact customer immediately to resolve payment issues.';
                priority = 'High';
            }
            when 'Cancelled' {
                subject = 'Subscription Cancelled - ' + subscription.Account__r?.Name;
                description = 'Subscription cancelled. Schedule exit interview and identify win-back opportunities.';
                priority = 'High';
            }
            when else {
                return null;
            }
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
        
        switch on subscriptionStatus {
            when 'Active' { return 100; }
            when 'Trial' { return 75; }
            when 'Suspended' { return 25; }
            when 'Cancelled' { return 0; }
            when else { return 50; }
        }
    }
    
    /**
     * @description Gets account status based on subscription status
     */
    private static String getAccountStatus(String subscriptionStatus) {
        
        switch on subscriptionStatus {
            when 'Active' { return 'Active Customer'; }
            when 'Trial' { return 'Trial Customer'; }
            when 'Suspended' { return 'At Risk'; }
            when 'Cancelled' { return 'Former Customer'; }
            when else { return 'Prospect'; }
        }
    }
}
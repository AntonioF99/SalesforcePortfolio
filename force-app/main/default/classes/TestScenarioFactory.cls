/**
 * @description Business-focused test scenarios with clear domain intent
 * @author Antonio Franco  
 * @date 2025-09-12
 * @story STORY-005: Test Data Refactoring
 */
@isTest
public class TestScenarioFactory {
    
    /**
     * @description Ensures a Contact exists for the Account (for email Flow testing)
     * @param accountId Account to check for Contact
     */
    private static void ensureContactExists(Id accountId) {
        List<Contact> existingContacts = [SELECT Id FROM Contact WHERE AccountId = :accountId LIMIT 1];
        if (existingContacts.isEmpty()) {
            Contact contact = TestDataFactory.createContact(accountId);
            insert contact;
        }
    }

    public static Invoice__c createDraftInvoice(Id accountId) {
        ensureContactExists(accountId);
        Invoice__c invoice = TestDataFactory.createInvoice(accountId);
        insert invoice;
        return invoice;
    }
    
    public static Invoice__c createInvoiceWithLineItems(Id accountId) {
        ensureContactExists(accountId);
        Invoice__c invoice = TestDataFactory.createInvoice(accountId);
        insert invoice;

        Invoice_Line_Item__c lineItem = TestDataFactory.createInvoiceLineItem(invoice.Id);
        insert lineItem;

        return invoice;
    }
    
    /*
     * @description Creates sent invoice (realistic workflow: Draft → line items → Sent)
     * @param accountId Account to associate with
     * @return Inserted Invoice__c in Sent status with line items
     */
    public static Invoice__c createSentInvoice(Id accountId) {
        Invoice__c invoice = createInvoiceWithLineItems(accountId);
        
        invoice.Status__c = 'Sent';
        update invoice;
        
        return invoice;
    }
    
    public static Invoice__c createPaidInvoice(Id accountId) {
        Invoice__c invoice = createSentInvoice(accountId);
        
        invoice.Status__c = 'Paid';
        invoice.Balance_Due__c = 0.0;
        update invoice;
        
        return invoice;
    }
    
    public static Invoice__c createVoidedInvoice(Id accountId) {
        Invoice__c invoice = TestDataFactory.createInvoice(accountId);
        insert invoice;
        
        invoice.Status__c = 'Voided';
        update invoice;
        
        return invoice;
    }
    
    public static Invoice__c createOverdueInvoice(Id accountId) {
        Invoice__c invoice = createSentInvoice(accountId);
        
        invoice.Due_Date__c = Date.today().addDays(-5);
        invoice.Status__c = 'Overdue';
        update invoice;
        
        return invoice;
    }
    
    /*
     * @description Creates invoices for multiple countries (tax testing)
     * @param countries List of country names for billing addresses
     * @return Map<Country, Invoice__c> - inserted invoices by country
     */
    public static Map<String, Invoice__c> createMultiCountryInvoices(List<String> countries) {
        Map<String, Invoice__c> invoicesByCountry = new Map<String, Invoice__c>();
        
        List<Account> accounts = new List<Account>();
        for (String country : countries) {
            accounts.add(TestDataFactory.createAccountForCountry(country));
        }
        insert accounts;
        
        List<Invoice__c> invoices = new List<Invoice__c>();
        for (Integer i = 0; i < accounts.size(); i++) {
            Invoice__c invoice = TestDataFactory.createInvoice(accounts[i].Id);
            invoices.add(invoice);
            invoicesByCountry.put(countries[i], invoice);
        }
        insert invoices;
        
        return invoicesByCountry;
    }
    
    /*
     * @description Creates complete subscription setup (all dependencies)
     * @return Map with 'account', 'product', 'pricePlan', 'subscription'
     */
    public static Map<String, SObject> createCompleteSubscriptionSetup() {
        Account acc = TestDataFactory.createAccount();
        insert acc;

        Contact contact = TestDataFactory.createContact(acc.Id);
        insert contact;

        Price_Plan__c pricePlan = TestDataFactory.createPricePlan();
        insert pricePlan;

        Subscription__c subscription = TestDataFactory.createSubscription(acc.Id, pricePlan.Id);
        insert subscription;

        return new Map<String, SObject>{
            'account' => acc,
            'contact' => contact,
            'pricePlan' => pricePlan,
            'subscription' => subscription
        };
    }
    
    public static Map<String, SObject> createTrialSubscriptionScenario() {
        Map<String, SObject> data = createCompleteSubscriptionSetup();
        
        Subscription__c subscription = (Subscription__c) data.get('subscription');
        subscription.Status__c = 'Trial';
        subscription.Trial_End_Date__c = Date.today().addDays(14);
        update subscription;
        
        return data;
    }
    
    public static Map<String, SObject> createActiveSubscriptionScenario() {
        Map<String, SObject> data = createCompleteSubscriptionSetup();
        
        Subscription__c subscription = (Subscription__c) data.get('subscription');
        subscription.Status__c = 'Active';
        update subscription;
        
        return data;
    }
    
    public static Map<String, SObject> createCancelledSubscriptionScenario() {
        Map<String, SObject> data = createCompleteSubscriptionSetup();
        
        Subscription__c subscription = (Subscription__c) data.get('subscription');
        subscription.Status__c = 'Cancelled';
        subscription.Cancellation_Reason__c = 'Other';
        update subscription;
        
        return data;
    }
    
    /*
     * @description Creates bulk invoices for performance testing
     * @param accountId Account to associate with
     * @param count Number of invoices to create
     * @return List of inserted Draft invoices
     */
    public static List<Invoice__c> createBulkDraftInvoices(Id accountId, Integer count) {
        List<Invoice__c> invoices = new List<Invoice__c>();
        
        for (Integer i = 0; i < count; i++) {
            invoices.add(TestDataFactory.createInvoice(accountId));
        }
        
        insert invoices;
        return invoices;
    }
    
    /*
     * @description Creates bulk subscriptions for performance testing
     * @param accountId Account to associate with
     * @param pricePlanId Price Plan to associate with
     * @param count Number of subscriptions to create
     * @return List of inserted Draft subscriptions
     */
    public static List<Subscription__c> createBulkDraftSubscriptions(Id accountId, Id pricePlanId, Integer count) {
        List<Subscription__c> subscriptions = new List<Subscription__c>();
        
        for (Integer i = 0; i < count; i++) {
            subscriptions.add(TestDataFactory.createSubscription(accountId, pricePlanId));
        }
        
        insert subscriptions;
        return subscriptions;
    }
    
    public static Invoice__c createOrphanInvoice() {
        Invoice__c invoice = new Invoice__c(
            Status__c = 'Draft',
            Invoice_Date__c = Date.today(),
            Due_Date__c = Date.today().addDays(30)
        );
        insert invoice;
        return invoice;
    }
    
    /*
     * @description Creates mixed status bulk invoices for complex testing
     * @param accountId Account to associate with
     * @return Map<Status, List<Invoice__c>> with 50 of each status
     */
    public static Map<String, List<Invoice__c>> createMixedStatusBulkInvoices(Id accountId) {
        Map<String, List<Invoice__c>> invoicesByStatus = new Map<String, List<Invoice__c>>();
        List<String> statuses = new List<String>{'Draft', 'Sent', 'Paid', 'Overdue'};
        
        for (String status : statuses) {
            List<Invoice__c> statusInvoices = new List<Invoice__c>();
            for (Integer i = 0; i < 50; i++) {
                Invoice__c inv = TestDataFactory.createInvoice(accountId);
                if (status != 'Draft') {
                    inv.Status__c = status;
                    if (status == 'Paid') {
                        inv.Balance_Due__c = 0.0;
                    } else if (status == 'Overdue') {
                        inv.Due_Date__c = Date.today().addDays(-5);
                    }
                }
                statusInvoices.add(inv);
            }
            insert statusInvoices;
            invoicesByStatus.put(status, statusInvoices);
        }
        return invoicesByStatus;
    }
    
    /*
     * @description Creates invoices for recalculation testing
     * @param accountId Account to associate with  
     * @return Map with 'sent', 'paid', 'draft' invoices
     */
    public static Map<String, Invoice__c> createInvoicesForRecalculationTesting(Id accountId) {
        List<Invoice__c> invoices = new List<Invoice__c>{
            TestDataFactory.createInvoice(accountId),
            TestDataFactory.createInvoice(accountId), 
            TestDataFactory.createInvoice(accountId)
        };
        insert invoices;
        
        List<Invoice_Line_Item__c> lineItems = new List<Invoice_Line_Item__c>{
            TestDataFactory.createInvoiceLineItem(invoices[0].Id),
            TestDataFactory.createInvoiceLineItem(invoices[1].Id)
        };
        insert lineItems;
        
        // Step 1: Move to Sent status first
        invoices[0].Status__c = 'Sent';
        invoices[1].Status__c = 'Sent';
        update new List<Invoice__c>{invoices[0], invoices[1]};
        
        // Step 2: Move to Paid (only allowed from Sent)
        invoices[1].Status__c = 'Paid';
        invoices[1].Balance_Due__c = 0.0;
        update invoices[1];
        
        return new Map<String, Invoice__c>{
            'sent' => invoices[0],
            'paid' => invoices[1],
            'draft' => invoices[2]
        };
    }
    
    /*
     * @description Creates subscription state transition data for testing
     * @return Map with subscriptions in different states
     */
    public static Map<String, SObject> createSubscriptionStateTransitionData() {
        Map<String, SObject> baseData = createCompleteSubscriptionSetup();
        Account acc = (Account) baseData.get('account');
        Price_Plan__c pricePlan = (Price_Plan__c) baseData.get('pricePlan');
        
        List<Subscription__c> subscriptions = new List<Subscription__c>();
        
        subscriptions.add(TestDataFactory.createSubscription(acc.Id, pricePlan.Id));
        
        Subscription__c trialSub = TestDataFactory.createSubscription(acc.Id, pricePlan.Id);
        trialSub.Status__c = 'Trial';
        trialSub.Trial_End_Date__c = Date.today().addDays(14);
        subscriptions.add(trialSub);
        
        Subscription__c activeSub = TestDataFactory.createSubscription(acc.Id, pricePlan.Id);
        activeSub.Status__c = 'Active';
        subscriptions.add(activeSub);
        
        Subscription__c cancelledSub = TestDataFactory.createSubscription(acc.Id, pricePlan.Id);
        cancelledSub.Status__c = 'Cancelled';
        cancelledSub.Cancellation_Reason__c = 'Budget Constraints';
        subscriptions.add(cancelledSub);
        
        insert subscriptions;
        
        baseData.put('draftSubscription', subscriptions[0]);
        baseData.put('trialSubscription', subscriptions[1]);
        baseData.put('activeSubscription', subscriptions[2]);
        baseData.put('cancelledSubscription', subscriptions[3]);
        
        return baseData;
    }

    /*
     * @description Creates subscription state transition data with B2B account for testing
     * @return Map with subscriptions in different states using B2B record type
     */
    public static Map<String, SObject> createB2BSubscriptionStateTransitionData() {
        Map<String, SObject> baseData = createCompleteSubscriptionSetup();
        Account acc = (Account) baseData.get('account');

        // Ensure this is a B2B account to match B2B Cancellation_Reason__c values
        acc.Type = 'Customer - Direct';
        acc.NumberOfEmployees = 50;
        update acc;

        Price_Plan__c pricePlan = (Price_Plan__c) baseData.get('pricePlan');

        List<Subscription__c> subscriptions = new List<Subscription__c>();

        subscriptions.add(TestDataFactory.createSubscription(acc.Id, pricePlan.Id));

        Subscription__c trialSub = TestDataFactory.createSubscription(acc.Id, pricePlan.Id);
        trialSub.Status__c = 'Trial';
        trialSub.Trial_End_Date__c = Date.today().addDays(14);
        subscriptions.add(trialSub);

        Subscription__c activeSub = TestDataFactory.createSubscription(acc.Id, pricePlan.Id);
        activeSub.Status__c = 'Active';
        subscriptions.add(activeSub);

        Subscription__c cancelledSub = TestDataFactory.createSubscription(acc.Id, pricePlan.Id);
        subscriptions.add(cancelledSub);

        insert subscriptions;

        // Update cancelled subscription separately to avoid permission validation during insert
        subscriptions[3].Status__c = 'Cancelled';
        subscriptions[3].Cancellation_Reason__c = 'Budget Constraints';  // B2B value
        update subscriptions[3];

        baseData.put('draftSubscription', subscriptions[0]);
        baseData.put('trialSubscription', subscriptions[1]);
        baseData.put('activeSubscription', subscriptions[2]);
        baseData.put('cancelledSubscription', subscriptions[3]);

        return baseData;
    }

    /*
     * @description Creates invoices for permission testing scenarios
     * @param accountId Account to associate with
     * @return Map with 'paid', 'voided', 'draft' invoices for permission tests
     */
    public static Map<String, Invoice__c> createInvoicesForPermissionTesting(Id accountId) {
        return new Map<String, Invoice__c>{
            'paid' => createPaidInvoice(accountId),
            'voided' => createVoidedInvoice(accountId), 
            'draft' => createDraftInvoice(accountId)
        };
    }
}
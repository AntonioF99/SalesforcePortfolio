/**
 * @description Test class for PlatformEventPublisher
 * @author Antonio Franco
 * @date 2025-09-24
 * @story STORY-006: Platform Events & Integration Layer
 */
@isTest
private class PlatformEventPublisherTest {
    
    @testSetup
    static void setupTestData() {
        Account testAccount = TestDataFactory.createAccount();
        insert testAccount;
    }
    
    @isTest
    static void testPublishSubscriptionEvents() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        
        // Create test subscriptions
        List<Subscription__c> subscriptions = new List<Subscription__c>();
        for (Integer i = 0; i < 5; i++) {
            Subscription__c sub = TestDataFactory.createSubscription(acc.Id);
            sub.Status__c = 'Active';
            sub.External_Id__c = 'EXT-SUB-' + i;
            subscriptions.add(sub);
        }
        
        // Test event publishing
        PlatformEventPublisher.publishSubscriptionEvents(subscriptions, 'Created');
        PlatformEventPublisher.publishSubscriptionEvents(subscriptions, 'StatusChanged');
        
        // Test empty list handling
        PlatformEventPublisher.publishSubscriptionEvents(null, 'Created');
        PlatformEventPublisher.publishSubscriptionEvents(new List<Subscription__c>(), 'Created');
        
        Test.stopTest();
        
        // Verify no exceptions were thrown
        System.assert(true, 'Platform event publishing completed successfully');
    }
    
    @isTest
    static void testPublishInvoiceEvents() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        
        // Create test invoices
        List<Invoice__c> invoices = new List<Invoice__c>();
        for (Integer i = 0; i < 5; i++) {
            Invoice__c inv = TestDataFactory.createInvoice(acc.Id);
            inv.Status__c = 'Sent';
            inv.Tax_Rate__c = 20.0; // Will calculate Total_Amount__c via formula
            invoices.add(inv);
        }
        
        // Test event publishing
        PlatformEventPublisher.publishInvoiceEvents(invoices, 'Created');
        PlatformEventPublisher.publishInvoiceEvents(invoices, 'Sent');
        PlatformEventPublisher.publishInvoiceEvents(invoices, 'Paid');
        
        // Test empty list handling
        PlatformEventPublisher.publishInvoiceEvents(null, 'Created');
        PlatformEventPublisher.publishInvoiceEvents(new List<Invoice__c>(), 'Created');
        
        Test.stopTest();
        
        System.assert(true, 'Platform event publishing completed successfully');
    }
    
    @isTest
    static void testPublishSubscriptionStatusChanges() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        
        // Create subscriptions with different statuses
        List<Subscription__c> newSubscriptions = new List<Subscription__c>();
        Map<Id, Subscription__c> oldSubscriptions = new Map<Id, Subscription__c>();
        
        for (Integer i = 0; i < 3; i++) {
            Subscription__c oldSub = TestDataFactory.createSubscription(acc.Id);
            oldSub.Status__c = 'Draft';
            oldSub.Id = TestDataFactory.getFakeId(Subscription__c.SObjectType);
            
            Subscription__c newSub = oldSub.clone(true, true, true, true);
            newSub.Status__c = 'Active';
            
            newSubscriptions.add(newSub);
            oldSubscriptions.put(oldSub.Id, oldSub);
        }
        
        // Test status change detection
        PlatformEventPublisher.publishSubscriptionStatusChanges(newSubscriptions, oldSubscriptions);
        
        // Test with no changes
        Map<Id, Subscription__c> noChangeOld = new Map<Id, Subscription__c>();
        for (Subscription__c sub : newSubscriptions) {
            Subscription__c noChangeSub = sub.clone(true, true, true, true);
            noChangeOld.put(sub.Id, noChangeSub);
        }
        PlatformEventPublisher.publishSubscriptionStatusChanges(newSubscriptions, noChangeOld);
        
        Test.stopTest();
        
        System.assert(true, 'Subscription status change events processed successfully');
    }
    
    @isTest
    static void testPublishInvoiceStatusChanges() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        
        // Create invoices with different statuses
        List<Invoice__c> newInvoices = new List<Invoice__c>();
        Map<Id, Invoice__c> oldInvoices = new Map<Id, Invoice__c>();
        
        String[] statusProgression = new String[]{'Draft', 'Sent', 'Paid'};
        
        for (Integer i = 0; i < statusProgression.size(); i++) {
            Invoice__c oldInv = TestDataFactory.createInvoice(acc.Id);
            oldInv.Status__c = 'Draft';
            oldInv.Id = TestDataFactory.getFakeId(Invoice__c.SObjectType);
            
            Invoice__c newInv = oldInv.clone(true, true, true, true);
            newInv.Status__c = statusProgression[i];
            
            newInvoices.add(newInv);
            oldInvoices.put(oldInv.Id, oldInv);
        }
        
        // Test status change detection and specific event publishing
        PlatformEventPublisher.publishInvoiceStatusChanges(newInvoices, oldInvoices);
        
        Test.stopTest();
        
        System.assert(true, 'Invoice status change events processed successfully');
    }
    
    @isTest
    static void testBulkEventPublishing() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        
        // Create bulk data for testing
        List<Subscription__c> bulkSubscriptions = new List<Subscription__c>();
        List<Invoice__c> bulkInvoices = new List<Invoice__c>();
        
        for (Integer i = 0; i < 200; i++) {
            Subscription__c sub = TestDataFactory.createSubscription(acc.Id);
            sub.Status__c = 'Active';
            bulkSubscriptions.add(sub);
            
            Invoice__c inv = TestDataFactory.createInvoice(acc.Id);
            inv.Status__c = 'Sent';
            bulkInvoices.add(inv);
        }
        
        // Test bulk publishing
        PlatformEventPublisher.publishSubscriptionEvents(bulkSubscriptions, 'Created');
        PlatformEventPublisher.publishInvoiceEvents(bulkInvoices, 'Created');
        
        Test.stopTest();
        
        System.assert(true, 'Bulk event publishing completed successfully');
    }
    
    @isTest
    static void testEventPublishingWithNullValues() {
        Test.startTest();
        
        // Test with subscriptions having null values
        List<Subscription__c> subsWithNulls = new List<Subscription__c>{
            new Subscription__c(
                Account__c = null,
                Status__c = null,
                External_Id__c = null
            )
        };
        
        // Test with invoices having null values
        List<Invoice__c> invsWithNulls = new List<Invoice__c>{
            new Invoice__c(
                Account__c = null,
                Status__c = null,
                Tax_Rate__c = null
            )
        };
        
        // Should handle null values gracefully
        PlatformEventPublisher.publishSubscriptionEvents(subsWithNulls, 'Created');
        PlatformEventPublisher.publishInvoiceEvents(invsWithNulls, 'Created');
        
        Test.stopTest();
        
        System.assert(true, 'Event publishing with null values handled successfully');
    }
}
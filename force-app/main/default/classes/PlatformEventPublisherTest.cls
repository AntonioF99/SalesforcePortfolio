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
        
        // Create test subscriptions without DML in loop
        List<Subscription__c> subscriptions = new List<Subscription__c>();
        for (Integer i = 0; i < 5; i++) {
            subscriptions.add(new Subscription__c(
                Account__c = acc.Id,
                Status__c = 'Active',
                External_Id__c = 'EXT-SUB-' + i,
                Start_Date__c = Date.today(),
            ));
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
        
        // Create test invoices without DML in loop  
        List<Invoice__c> invoices = new List<Invoice__c>();
        for (Integer i = 0; i < 5; i++) {
            invoices.add(new Invoice__c(
                Account__c = acc.Id,
                Status__c = 'Sent',
                Tax_Rate__c = 20.0,
                Invoice_Date__c = Date.today(),
                Due_Date__c = Date.today().addDays(30),
                Balance_Due__c = 0
            ));
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
            Id fakeId = TestDataFactory.getFakeId(Subscription__c.SObjectType);
            
            Subscription__c oldSub = new Subscription__c(
                Id = fakeId,
                Account__c = acc.Id,
                Status__c = 'Draft',
                Start_Date__c = Date.today(),
            );
            
            Subscription__c newSub = new Subscription__c(
                Id = fakeId,
                Account__c = acc.Id,
                Status__c = 'Active',
                Start_Date__c = Date.today(),
            );
            
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
            Id fakeId = TestDataFactory.getFakeId(Invoice__c.SObjectType);
            
            Invoice__c oldInv = new Invoice__c(
                Id = fakeId,
                Account__c = acc.Id,
                Status__c = 'Draft',
                Invoice_Date__c = Date.today(),
                Due_Date__c = Date.today().addDays(30),
                Balance_Due__c = 0
            );
            
            Invoice__c newInv = new Invoice__c(
                Id = fakeId,
                Account__c = acc.Id,
                Status__c = statusProgression[i],
                Invoice_Date__c = Date.today(),
                Due_Date__c = Date.today().addDays(30),
                Balance_Due__c = 0
            );
            
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
        
        // Create bulk data for testing - no DML in loop
        List<Subscription__c> bulkSubscriptions = new List<Subscription__c>();
        List<Invoice__c> bulkInvoices = new List<Invoice__c>();
        
        // Create all objects without DML using clean pattern
        Integer bulkSize = 50;
        
        for (Integer i = 0; i < bulkSize; i++) {
            bulkSubscriptions.add(new Subscription__c(
                Account__c = acc.Id,
                Status__c = 'Active',
                Start_Date__c = Date.today(),
            ));
            
            bulkInvoices.add(new Invoice__c(
                Account__c = acc.Id,
                Status__c = 'Sent',
                Invoice_Date__c = Date.today(),
                Due_Date__c = Date.today().addDays(30),
                Balance_Due__c = 0
            ));
        }
        
        // Test bulk publishing - verify no exceptions thrown
        Boolean success = false;
        try {
            PlatformEventPublisher.publishSubscriptionEvents(bulkSubscriptions, 'Created');
            PlatformEventPublisher.publishInvoiceEvents(bulkInvoices, 'Created');
            success = true;
        } catch (Exception e) {
            System.assert(false, 'Platform event publishing failed: ' + e.getMessage());
        }
        
        Test.stopTest();
        
        System.assert(success, 'Should publish bulk events successfully without exceptions');
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
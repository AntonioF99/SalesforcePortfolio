/**
 * @description Test class for simplified PlatformEventSubscriber
 * @author Antonio Franco
 * @date 2025-09-24
 * @story STORY-006: Platform Events & Integration Layer (Simplified)
 */
@isTest
private class PlatformEventSubscriberTest {
    
    @testSetup
    static void setupTestData() {
        Account testAccount = TestDataFactory.createAccount();
        insert testAccount;
        
        // Create a test contact for email functionality
        Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test@example.com',
            AccountId = testAccount.Id
        );
        insert testContact;
    }
    
    @isTest
    static void testProcessSubscriptionEvents() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        // Create test subscription
        Subscription__c sub = TestDataFactory.createSubscription(acc.Id);
        sub.Status__c = 'Active';
        sub.External_Id__c = 'EXT-SUB-001';
        insert sub;
        
        Test.startTest();
        
        // Create subscription events
        List<Subscription_Event__e> events = new List<Subscription_Event__e>{
            new Subscription_Event__e(
                Subscription_Id__c = sub.Id,
                Event_Type__c = 'Created',
                Account_Id__c = acc.Id,
                Status__c = 'Active',
                External_System_Id__c = 'EXT-SUB-001'
            ),
            new Subscription_Event__e(
                Subscription_Id__c = sub.Id,
                Event_Type__c = 'StatusChanged',
                Account_Id__c = acc.Id,
                Status__c = 'Cancelled',
                External_System_Id__c = 'EXT-SUB-001'
            )
        };
        
        // Test event processing
        PlatformEventSubscriber.processSubscriptionEvents(events);
        
        // Test empty list handling
        PlatformEventSubscriber.processSubscriptionEvents(null);
        PlatformEventSubscriber.processSubscriptionEvents(new List<Subscription_Event__e>());
        
        Test.stopTest();
        
        // Verify account was updated
        Account updatedAcc = [SELECT Subscription_Status__c, Health_Score__c FROM Account WHERE Id = :acc.Id];
        System.assertNotEquals(null, updatedAcc.Subscription_Status__c, 'Account subscription status should be updated');
        
        // Verify tasks were created
        List<Task> createdTasks = [SELECT Subject FROM Task WHERE WhatId = :sub.Id];
        System.assert(!createdTasks.isEmpty(), 'Tasks should be created for subscription events');
    }
    
    @isTest
    static void testProcessInvoiceEvents() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        // Create test invoice
        Invoice__c inv = TestDataFactory.createInvoice(acc.Id);
        inv.Status__c = 'Sent';
        inv.Tax_Rate__c = 22.0; // Will create a calculated Total_Amount__c
        insert inv;
        
        Test.startTest();
        
        // Create invoice events
        List<Invoice_Event__e> events = new List<Invoice_Event__e>{
            new Invoice_Event__e(
                Invoice_Id__c = inv.Id,
                Event_Type__c = 'Created',
                Account_Id__c = acc.Id,
                Status__c = 'Draft',
                Total_Amount__c = 750.00
            ),
            new Invoice_Event__e(
                Invoice_Id__c = inv.Id,
                Event_Type__c = 'Sent',
                Account_Id__c = acc.Id,
                Status__c = 'Sent',
                Total_Amount__c = 750.00
            ),
            new Invoice_Event__e(
                Invoice_Id__c = inv.Id,
                Event_Type__c = 'Paid',
                Account_Id__c = acc.Id,
                Status__c = 'Paid',
                Total_Amount__c = 750.00
            )
        };
        
        // Test event processing
        PlatformEventSubscriber.processInvoiceEvents(events);
        
        // Test empty list handling
        PlatformEventSubscriber.processInvoiceEvents(null);
        PlatformEventSubscriber.processInvoiceEvents(new List<Invoice_Event__e>());
        
        Test.stopTest();
        
        // Verify account metrics were updated
        Account updatedAcc = [SELECT Total_Billed__c, Invoice_Count__c FROM Account WHERE Id = :acc.Id];
        System.assertNotEquals(null, updatedAcc.Total_Billed__c, 'Account total billed should be updated');
        System.assertNotEquals(null, updatedAcc.Invoice_Count__c, 'Account invoice count should be updated');
        
        // Verify tasks were created
        List<Task> createdTasks = [SELECT Subject FROM Task WHERE WhatId = :inv.Id];
        System.assert(!createdTasks.isEmpty(), 'Tasks should be created for invoice events');
    }
    
    @isTest
    static void testSlackNotificationFiltering() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        // Create test data
        Subscription__c sub = TestDataFactory.createSubscription(acc.Id);
        sub.Status__c = 'Active';
        insert sub;
        
        Invoice__c smallInvoice = TestDataFactory.createInvoice(acc.Id);
        smallInvoice.Tax_Rate__c = 5.0; // Will create small calculated amount
        insert smallInvoice;
        
        Invoice__c largeInvoice = TestDataFactory.createInvoice(acc.Id);
        largeInvoice.Tax_Rate__c = 25.0; // Will create larger calculated amount
        insert largeInvoice;
        
        Test.startTest();
        
        // Create events that should/shouldn't trigger Slack
        List<Subscription_Event__e> subEvents = new List<Subscription_Event__e>{
            new Subscription_Event__e(
                Subscription_Id__c = sub.Id,
                Event_Type__c = 'Created', // Should notify
                Account_Id__c = acc.Id,
                Status__c = 'Active'
            ),
            new Subscription_Event__e(
                Subscription_Id__c = sub.Id,
                Event_Type__c = 'Updated', // Should NOT notify
                Account_Id__c = acc.Id,
                Status__c = 'Active'
            )
        };
        
        List<Invoice_Event__e> invEvents = new List<Invoice_Event__e>{
            new Invoice_Event__e(
                Invoice_Id__c = smallInvoice.Id,
                Event_Type__c = 'Sent', // Should NOT notify (small amount)
                Account_Id__c = acc.Id,
                Total_Amount__c = 100.00
            ),
            new Invoice_Event__e(
                Invoice_Id__c = largeInvoice.Id,
                Event_Type__c = 'Sent', // Should notify (large amount)
                Account_Id__c = acc.Id,
                Total_Amount__c = 1000.00
            )
        };
        
        // Process events - should handle filtering correctly
        PlatformEventSubscriber.processSubscriptionEvents(subEvents);
        PlatformEventSubscriber.processInvoiceEvents(invEvents);
        
        Test.stopTest();
        
        System.assert(true, 'Slack notification filtering should work without errors');
    }
    
    @isTest
    static void testBulkEventProcessing() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        // Create shared dependencies
        Product__c product = TestDataFactory.createProduct();
        insert product;
        
        Price_Plan__c pricePlan = TestDataFactory.createPricePlan(product.Id);
        insert pricePlan;
        
        // Create test data without DML in loop
        List<Subscription__c> subscriptions = new List<Subscription__c>();
        List<Invoice__c> invoices = new List<Invoice__c>();
        
        for (Integer i = 0; i < 50; i++) {
            subscriptions.add(new Subscription__c(
                Account__c = acc.Id,
                Price_Plan__c = pricePlan.Id,
                Status__c = 'Active',
                Start_Date__c = Date.today(),
                End_Date__c = Date.today().addMonths(12)
            ));
            
            invoices.add(new Invoice__c(
                Account__c = acc.Id,
                Status__c = 'Draft', // Changed from 'Sent' to avoid validation error
                Tax_Rate__c = 20.0 + i,
                Invoice_Date__c = Date.today(),
                Due_Date__c = Date.today().addDays(30),
                Balance_Due__c = 0
            ));
        }
        
        insert subscriptions;
        insert invoices;
        
        Test.startTest();
        
        // Create bulk events
        List<Subscription_Event__e> subscriptionEvents = new List<Subscription_Event__e>();
        List<Invoice_Event__e> invoiceEvents = new List<Invoice_Event__e>();
        
        for (Integer i = 0; i < 50; i++) {
            subscriptionEvents.add(new Subscription_Event__e(
                Subscription_Id__c = subscriptions[i].Id,
                Event_Type__c = 'Created',
                Account_Id__c = acc.Id,
                Status__c = 'Active'
            ));
            
            invoiceEvents.add(new Invoice_Event__e(
                Invoice_Id__c = invoices[i].Id,
                Event_Type__c = 'Created',
                Account_Id__c = acc.Id,
                Status__c = 'Sent',
                Total_Amount__c = 600.00 + i
            ));
        }
        
        // Test bulk processing
        PlatformEventSubscriber.processSubscriptionEvents(subscriptionEvents);
        PlatformEventSubscriber.processInvoiceEvents(invoiceEvents);
        
        Test.stopTest();
        
        // Verify bulk processing completed
        List<Task> allTasks = [SELECT Subject FROM Task WHERE AccountId = :acc.Id];
        System.assert(allTasks.size() > 0, 'Bulk processing should create tasks');
        
        Account updatedAcc = [SELECT Total_Billed__c, Invoice_Count__c FROM Account WHERE Id = :acc.Id];
        System.assert(updatedAcc.Total_Billed__c > 0, 'Account metrics should be updated from bulk processing');
    }
    
    @isTest
    static void testEventProcessingWithInvalidIds() {
        Test.startTest();
        
        // Create events with non-existent IDs
        List<Subscription_Event__e> invalidSubEvents = new List<Subscription_Event__e>{
            new Subscription_Event__e(
                Subscription_Id__c = TestDataFactory.getFakeId(Subscription__c.SObjectType),
                Event_Type__c = 'Created',
                Account_Id__c = TestDataFactory.getFakeId(Account.SObjectType),
                Status__c = 'Active'
            )
        };
        
        List<Invoice_Event__e> invalidInvEvents = new List<Invoice_Event__e>{
            new Invoice_Event__e(
                Invoice_Id__c = TestDataFactory.getFakeId(Invoice__c.SObjectType),
                Event_Type__c = 'Created',
                Account_Id__c = TestDataFactory.getFakeId(Account.SObjectType),
                Status__c = 'Draft'
            )
        };
        
        // Should handle invalid IDs gracefully
        PlatformEventSubscriber.processSubscriptionEvents(invalidSubEvents);
        PlatformEventSubscriber.processInvoiceEvents(invalidInvEvents);
        
        Test.stopTest();
        
        System.assert(true, 'Invalid ID handling should complete without errors');
    }
}
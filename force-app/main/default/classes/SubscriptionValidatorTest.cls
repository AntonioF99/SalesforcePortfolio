/**
 * @description Test class for SubscriptionValidator
 * @author Antonio Franco
 * @date 2025-09-10
 * @story STORY-005: Test Classes
 */
@isTest
private class SubscriptionValidatorTest {
    
    @testSetup
    static void setupTestData() {
        // Don't reset counter to avoid duplicate Product_Code__c issues
        // TestDataFactory.resetCounter();
        
        // Create base test data
        Account testAccount = TestDataFactory.createAccount();
        insert testAccount;
        
        Product__c testProduct = TestDataFactory.createProduct();
        insert testProduct;
        
        Price_Plan__c testPricePlan = TestDataFactory.createPricePlan(testProduct.Id);
        insert testPricePlan;
    }
    
    // ========== STATE MACHINE VALIDATION TESTS ==========
    
    @isTest
    static void testValidStateTransitions() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Price_Plan__c pricePlan = [SELECT Id FROM Price_Plan__c LIMIT 1];

        // Create Draft subscription
        Subscription__c draftSub = TestDataFactory.createSubscriptionWithOverrides(acc.Id, pricePlan.Id,
            new Map<String, Object>{'Status__c' => 'Draft'});
        insert draftSub;
        
        Test.startTest();
        
        // Valid transition: Draft -> Trial
        draftSub.Status__c = 'Trial';
        draftSub.Trial_End_Date__c = Date.today().addDays(14);
        
        try {
            update draftSub;
            System.assertEquals('Trial', draftSub.Status__c, 'Draft to Trial transition should be valid');
        } catch (Exception e) {
            System.assert(false, 'Valid Draft to Trial transition should not throw exception: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
        
   @isTest
    static void testInvalidStateTransitions() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Price_Plan__c pricePlan = [SELECT Id FROM Price_Plan__c LIMIT 1];

        // Create Active subscription
        Subscription__c activeSub = TestDataFactory.createSubscriptionWithOverrides(acc.Id, pricePlan.Id,
            new Map<String, Object>{'Status__c' => 'Active'});
        insert activeSub;
        
        Test.startTest();
        
        // Invalid transition: Active -> Draft
        activeSub.Status__c = 'Draft';
        
        try {
            update activeSub;
            System.assert(false, 'Invalid Active to Draft transition should throw exception');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Invalid status transition'), 
                        'Exception should mention invalid transition: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testCancelledStatusIsTerminal() {
        // Setup
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Price_Plan__c pricePlan = [SELECT Id FROM Price_Plan__c LIMIT 1];

        // Use DRAFT instead of Active to avoid permission issues
        Subscription__c subscription = TestDataFactory.createSubscriptionWithOverrides(acc.Id, pricePlan.Id,
            new Map<String, Object>{'Status__c' => 'Draft'});
        insert subscription;
        
        // Draft can be cancelled without special permissions
        subscription.Status__c = 'Cancelled';
        subscription.Cancellation_Reason__c = 'Other';
        update subscription; // This now works
        
        Test.startTest();
        
        // Now test that Cancelled is terminal
        subscription.Status__c = 'Active';
        
        try {
            update subscription;
            System.assert(false, 'Cancelled subscription should not be reactivatable');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Invalid status transition'), 
                         'Should not allow transition from Cancelled status');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testCancellationReasonRequired() {
        // Setup
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Price_Plan__c pricePlan = [SELECT Id FROM Price_Plan__c LIMIT 1];

        Subscription__c subscription = TestDataFactory.createSubscriptionWithOverrides(acc.Id, pricePlan.Id,
        new Map<String, Object>{'Status__c' => 'Active'});
        insert subscription;
        
        
        Test.startTest();
        
        // Try to cancel without reason
        subscription.Status__c = 'Cancelled';
        // Deliberately not setting Cancellation_Reason__c
        
        try {
            update subscription;
            System.assert(false, 'Cancellation without reason should fail');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Cancellation reason is required'), 
                         'Should require cancellation reason: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
    // ========== PERMISSION VALIDATION TESTS ==========
    
    @isTest   static void testCancelPermissionValidation() {
        // Setup - use existing test data
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Price_Plan__c pricePlan = [SELECT Id FROM Price_Plan__c LIMIT 1];
        
        Subscription__c subscription = TestDataFactory.createSubscriptionWithOverrides(acc.Id, pricePlan.Id,
            new Map<String, Object>{'Status__c' => 'Active'});
        insert subscription;
        
        Test.startTest();
        
        // Test cancellation of active subscription without permission
        subscription.Status__c = 'Cancelled';
        subscription.Cancellation_Reason__c = 'Other';
        
        try {
            update subscription;
            System.assert(false, 'Should not allow cancellation without permission');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('permission'), 
                         'Should mention permission in error: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testDraftCancellationAllowed() {
        // Setup
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Price_Plan__c pricePlan = [SELECT Id FROM Price_Plan__c LIMIT 1];
        
        Subscription__c draftSub = TestDataFactory.createSubscriptionWithOverrides(acc.Id, pricePlan.Id,
            new Map<String, Object>{'Status__c' => 'Draft'});
        insert draftSub;
        
        Test.startTest();
        
        // Draft subscriptions can be cancelled without special permission
        draftSub.Status__c = 'Cancelled';
        draftSub.Cancellation_Reason__c = 'Other';
        
        try {
            update draftSub;
            System.assertEquals('Cancelled', draftSub.Status__c, 'Draft subscription should be cancellable');
        } catch (Exception e) {
            System.assert(false, 'Draft cancellation should not require special permission: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testDeleteActiveSubscriptionBlocked() {
        // Setup - use existing test data
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Price_Plan__c pricePlan = [SELECT Id FROM Price_Plan__c LIMIT 1];
        
        Subscription__c subscription = TestDataFactory.createSubscriptionWithOverrides(acc.Id, pricePlan.Id,
            new Map<String, Object>{'Status__c' => 'Active'});
        insert subscription;
        
        Test.startTest();
        
        try {
            delete subscription;
            System.assert(false, 'Should not allow deletion of active subscription');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Cancel first'), 
                         'Should mention cancelling first: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
    // ========== BUSINESS RULES VALIDATION TESTS ==========
    
    @isTest
    static void testDateValidation() {
        // Setup
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Price_Plan__c pricePlan = [SELECT Id FROM Price_Plan__c LIMIT 1];
        
        Test.startTest();
        
        // Test invalid date range
        Subscription__c subscription = TestDataFactory.createSubscriptionWithOverrides(acc.Id, pricePlan.Id,
            new Map<String, Object>{
                'Start_Date__c' => Date.today(),
                'End_Date__c' => Date.today().addDays(-1) // End before start
            });
        
        try {
            insert subscription;
            System.assert(false, 'Should not allow end date before start date');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('End date must be after start date'), 
                         'Should validate date logic: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testTrialDefaultBehavior() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Price_Plan__c pricePlan = [SELECT Id FROM Price_Plan__c LIMIT 1];
        
        Test.startTest();
        
        // Test: subscription without date gets default
        Subscription__c trialSub = TestDataFactory.createSubscriptionWithOverrides(acc.Id, pricePlan.Id,
            new Map<String, Object>{
                'Status__c' => 'Trial',
                'Trial_End_Date__c' => null
            });
        
        insert trialSub;
        
        // Verify that the default was applied
        trialSub = [SELECT Trial_End_Date__c FROM Subscription__c WHERE Id = :trialSub.Id];
        System.assertEquals(Date.today().addDays(14), trialSub.Trial_End_Date__c, 
                        'Should default to 14 days when not specified');
        
        Test.stopTest();
    }
        
    @isTest
    static void testTrialEndDateInFuture() {
        // Setup
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Price_Plan__c pricePlan = [SELECT Id FROM Price_Plan__c LIMIT 1];
        
        Test.startTest();
        
        // Test trial with past end date
        Subscription__c trialSub = TestDataFactory.createSubscriptionWithOverrides(acc.Id, pricePlan.Id,
            new Map<String, Object>{
                'Status__c' => 'Trial',
                'Trial_End_Date__c' => Date.today().addDays(-1) // Past date
            });
        
        try {
            insert trialSub;
            System.assert(false, 'Trial end date should be in future');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Trial end date must be in the future'), 
                         'Should require future trial end date: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testActiveSubscriptionRequirements() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Price_Plan__c pricePlan = [SELECT Id FROM Price_Plan__c LIMIT 1];
        
        Test.startTest();
        
        // Test active subscription without start date
        Subscription__c activeSub = TestDataFactory.createSubscriptionWithOverrides(acc.Id, pricePlan.Id,
            new Map<String, Object>{
                'Status__c' => 'Active',
                'Start_Date__c' => null
            });
        
        try {
            insert activeSub;
            System.assert(false, 'Active subscription should require start date');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Start date is required'), 
                        'Should require start date for active subscription: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
    // ========== DEFAULT VALUE TESTS ==========
    
    @isTest
    static void testDefaultValues() {
        // Setup
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Price_Plan__c pricePlan = [SELECT Id FROM Price_Plan__c LIMIT 1];
        
        Test.startTest();
        
        // Create subscription without explicit values
        Subscription__c subscription = new Subscription__c(
            Account__c = acc.Id,
            Price_Plan__c = pricePlan.Id
        );
        
        insert subscription;
        
        // Reload to get default values
        subscription = [SELECT Status__c, Start_Date__c FROM Subscription__c WHERE Id = :subscription.Id];
        
        System.assertEquals('Draft', subscription.Status__c, 'Default status should be Draft');
        System.assertEquals(Date.today(), subscription.Start_Date__c, 'Default start date should be today');
        
        Test.stopTest();
    }
    
    // ========== BULK OPERATION TESTS ==========
    
    @isTest
    static void testBulkStateTransitions() {
        // Setup
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Price_Plan__c pricePlan = [SELECT Id FROM Price_Plan__c LIMIT 1];
        
        List<Subscription__c> subscriptions = new List<Subscription__c>();
        
        // Create 200 draft subscriptions
        for (Integer i = 0; i < 200; i++) {
            subscriptions.add(TestDataFactory.createSubscriptionWithOverrides(acc.Id, pricePlan.Id,
                new Map<String, Object>{'Status__c' => 'Draft'}));
        }
        insert subscriptions;
        
        Test.startTest();
        
        // Bulk transition to Trial
        for (Subscription__c sub : subscriptions) {
            sub.Status__c = 'Trial';
            sub.Trial_End_Date__c = Date.today().addDays(14);
        }
        
        try {
            update subscriptions;
            
            // Verify all transitions succeeded
            List<Subscription__c> updatedSubs = [SELECT Status__c FROM Subscription__c WHERE Id IN :subscriptions];
            for (Subscription__c sub : updatedSubs) {
                System.assertEquals('Trial', sub.Status__c, 'Bulk transition should succeed');
            }
            
        } catch (Exception e) {
            System.assert(false, 'Bulk valid transitions should not fail: ' + e.getMessage());
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testBulkInvalidTransitions() {
        // Setup
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Price_Plan__c pricePlan = [SELECT Id FROM Price_Plan__c LIMIT 1];
        
        List<Subscription__c> subscriptions = new List<Subscription__c>();
        
        // Create active subscriptions
        for (Integer i = 0; i < 50; i++) {
            subscriptions.add(TestDataFactory.createSubscriptionWithOverrides(acc.Id, pricePlan.Id,
                new Map<String, Object>{'Status__c' => 'Active'}));
        }
        insert subscriptions;
        
        Test.startTest();
        
        // Try bulk invalid transition Active -> Draft
        for (Subscription__c sub : subscriptions) {
            sub.Status__c = 'Draft';
        }
        
        try {
            update subscriptions;
            System.assert(false, 'Bulk invalid transitions should fail');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Invalid status transition'), 
                         'Should reject bulk invalid transitions');
        }
        
        Test.stopTest();
    }
    
    // ========== INVOICE GENERATION DETECTION TESTS ==========
    
    @isTest
    static void testInvoiceGenerationDetection() {
        // Setup
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Price_Plan__c pricePlan = [SELECT Id FROM Price_Plan__c LIMIT 1];

        Subscription__c trialSub = TestDataFactory.createSubscriptionWithOverrides(acc.Id, pricePlan.Id,
        new Map<String, Object>{
            'Status__c' => 'Trial',
            'Trial_End_Date__c' => Date.today().addDays(14)
        });
        insert trialSub;
        
        Test.startTest();
        
        // Simulate transition from Trial to Active
        Map<Id, Subscription__c> oldMap = new Map<Id, Subscription__c>{
            trialSub.Id => trialSub.clone(true)
        };
        
        trialSub.Status__c = 'Active';
        Map<Id, Subscription__c> newMap = new Map<Id, Subscription__c>{
            trialSub.Id => trialSub
        };
        
        Set<Id> needingInvoice = SubscriptionValidator.getSubscriptionsNeedingInvoice(oldMap, newMap);
        
        System.assertEquals(1, needingInvoice.size(), 'Should detect subscription needing invoice');
        System.assert(needingInvoice.contains(trialSub.Id), 'Should include the transitioning subscription');
        
        Test.stopTest();
    }
    
    @isTest
    static void testNoInvoiceGenerationForOtherTransitions() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Price_Plan__c pricePlan = [SELECT Id FROM Price_Plan__c LIMIT 1];

        // Create Draft subscription
        Subscription__c draftSub = TestDataFactory.createSubscriptionWithOverrides(acc.Id, pricePlan.Id,
            new Map<String, Object>{'Status__c' => 'Draft'});
        insert draftSub;
        
        Test.startTest();
        
        // Simulate transition from Draft to Trial
        Map<Id, Subscription__c> oldMap = new Map<Id, Subscription__c>{
            draftSub.Id => draftSub.clone(true)
        };
        
        draftSub.Status__c = 'Trial';
        draftSub.Trial_End_Date__c = Date.today().addDays(14);
        Map<Id, Subscription__c> newMap = new Map<Id, Subscription__c>{
            draftSub.Id => draftSub
        };
        
        Set<Id> needingInvoice = SubscriptionValidator.getSubscriptionsNeedingInvoice(oldMap, newMap);
        
        System.assertEquals(0, needingInvoice.size(), 'Draft to Trial should not need invoice generation');
        
        Test.stopTest();
    }
    
}
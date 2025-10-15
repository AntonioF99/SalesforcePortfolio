/**
 * @description Test class for SubscriptionValidator - REFACTORED with TestScenarioFactory
 * @author Antonio Franco
 * @date 2025-09-12
 * @story STORY-005: Test Classes Refactoring
 * @pattern Clean test architecture using TestDataFactory + TestScenarioFactory
 */
@isTest
private class SubscriptionValidatorTest {
    
    // Note: Removed @testSetup to avoid conflicts when tests create their own data
    
    // ========== STATE MACHINE VALIDATION ==========
    
    @isTest
    static void testValidateStateTransitions() {

        // Get user with admin profile who should have permission to cancel subscriptions
        User adminUser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' AND IsActive = true LIMIT 1];

        Map<String, SObject> data;
        System.runAs(adminUser) {
            data = TestScenarioFactory.createB2BSubscriptionStateTransitionData();
        }

        Test.startTest();

        // Test valid transitions
        Subscription__c draftSub = (Subscription__c) data.get('draftSubscription');
        draftSub.Status__c = 'Trial';
        update draftSub; // Should succeed

        Subscription__c trialSub = (Subscription__c) data.get('trialSubscription');
        trialSub.Status__c = 'Active';
        update trialSub; // Should succeed
        
        // Test Draft to Cancelled (no special permission needed)
        Subscription__c draftSub2 = TestDataFactory.createSubscription(((Account) data.get('account')).Id, ((Price_Plan__c) data.get('pricePlan')).Id);
        insert draftSub2; // Insert as Draft first

        draftSub2.Status__c = 'Cancelled';
        draftSub2.Cancellation_Reason__c = 'Budget Constraints';
        update draftSub2; // Should succeed without special permission
        
        // Test invalid transitions
        Subscription__c cancelledSub = (Subscription__c) data.get('cancelledSubscription');
        cancelledSub.Status__c = 'Draft'; // Invalid transition
        
        try {
            update cancelledSub;
            System.assert(false, 'Should reject invalid state transition');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Invalid status transition'));
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testTerminalStatusValidation() {
        Map<String, SObject> data = TestScenarioFactory.createCancelledSubscriptionScenario();
        Subscription__c cancelledSub = (Subscription__c) data.get('subscription');
        
        Test.startTest();
        
        // Try to reactivate cancelled subscription
        cancelledSub.Status__c = 'Active';
        
        try {
            update cancelledSub;
            System.assert(false, 'Cancelled status should be terminal');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Invalid status transition'));
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testCancellationReasonRequired() {
        Map<String, SObject> data = TestScenarioFactory.createActiveSubscriptionScenario();
        Subscription__c activeSub = (Subscription__c) data.get('subscription');
        
        Test.startTest();
        
        // Try to cancel without reason
        activeSub.Status__c = 'Cancelled';
        // Deliberately not setting Cancellation_Reason__c
        
        try {
            update activeSub;
            System.assert(false, 'Should require cancellation reason');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Cancellation reason is required'));
        }
        
        // Test with reason - should succeed
        activeSub.Cancellation_Reason__c = 'Other';
        try {
            update activeSub; // This will still fail due to permission, but reason validation passes
        } catch (DmlException e) {
            // Permission error is expected, reason validation passed
            System.assert(e.getMessage().contains('permission'));
        }
        
        Test.stopTest();
    }
    
    // ========== PERMISSION VALIDATION ==========
    
    @isTest
    static void testValidateCancellationPermissions() {
        // Use Sales User without Cancel_Any_Subscription permission (should fail)
        User regularUser = [SELECT Id FROM User WHERE Profile.Name = 'Sales User' AND IsActive = true LIMIT 1];

        Map<String, SObject> baseData;
        System.runAs(regularUser) {
            baseData = TestScenarioFactory.createCompleteSubscriptionSetup();
        }

        Account acc = (Account) baseData.get('account');
        Price_Plan__c pricePlan = (Price_Plan__c) baseData.get('pricePlan');

        Test.startTest();

        System.runAs(regularUser) {
            // Test cancellation of Active subscription without permission
            Subscription__c activeSub = TestDataFactory.createSubscription(acc.Id, pricePlan.Id);
            activeSub.Status__c = 'Active';
            insert activeSub;

            activeSub.Status__c = 'Cancelled';
            activeSub.Cancellation_Reason__c = 'Other';

            try {
                update activeSub;
                System.assert(false, 'Should block active subscription cancellation without permission');
            } catch (DmlException e) {
                System.assert(e.getMessage().contains('permission'));
            }
        }
        
        // Test Draft and Trial can be cancelled without permission
        Subscription__c draftSub = TestDataFactory.createSubscription(acc.Id, pricePlan.Id);
        insert draftSub;
        
        draftSub.Status__c = 'Cancelled';
        draftSub.Cancellation_Reason__c = 'Other';
        update draftSub; // Should succeed
        
        Subscription__c trialSub = TestDataFactory.createSubscription(acc.Id, pricePlan.Id);
        trialSub.Status__c = 'Trial';
        insert trialSub;
        
        trialSub.Status__c = 'Cancelled';
        trialSub.Cancellation_Reason__c = 'Other';
        update trialSub; // Should succeed
        
        Test.stopTest();
    }
    
    @isTest
    static void testValidateDeletionPermissions() {
        Map<String, SObject> data = TestScenarioFactory.createActiveSubscriptionScenario();
        Subscription__c activeSub = (Subscription__c) data.get('subscription');
        
        Test.startTest();
        
        // Active subscriptions cannot be deleted
        try {
            delete activeSub;
            System.assert(false, 'Should block deletion of active subscription');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Cancel first'));
        }
        
        // Draft subscriptions can be deleted
        Map<String, SObject> baseData = TestScenarioFactory.createCompleteSubscriptionSetup();
        Subscription__c draftSub = (Subscription__c) baseData.get('subscription');
        delete draftSub; // Should succeed
        
        Test.stopTest();
    }
    
    // ========== BUSINESS RULES VALIDATION - DATE & TRIAL ==========
    
    @isTest
    static void testValidateBusinessRules() {
        Map<String, SObject> baseData = TestScenarioFactory.createCompleteSubscriptionSetup();
        Account acc = (Account) baseData.get('account');
        Price_Plan__c pricePlan = (Price_Plan__c) baseData.get('pricePlan');
        
        Test.startTest();
        
        // Test invalid date range
        try {
            Subscription__c invalidDates = TestDataFactory.createSubscription(acc.Id, pricePlan.Id);
            invalidDates.Start_Date__c = Date.today();
            insert invalidDates;
            System.assert(false, 'Should reject invalid date range');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('End date must be after start date'));
        }
        
        // Test trial end date validation
        try {
            Subscription__c invalidTrial = TestDataFactory.createSubscription(acc.Id, pricePlan.Id);
            invalidTrial.Status__c = 'Trial';
            insert invalidTrial;
            System.assert(false, 'Should reject past trial end date');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Trial end date must be in the future'));
        }
        
        // Test trial period limit (14 days max)
        try {
            Subscription__c longTrial = TestDataFactory.createSubscription(acc.Id, pricePlan.Id);
            longTrial.Status__c = 'Trial';
            insert longTrial;
            System.assert(false, 'Should reject trial period over 14 days');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Trial period cannot exceed 14 days'));
        }
        
        // Positive case - valid subscription
        Subscription__c validSub = TestDataFactory.createSubscription(acc.Id, pricePlan.Id);
        insert validSub; // Should succeed
        
        Test.stopTest();
    }
    

    @isTest
    static void testActiveSubscriptionRequirements() {
        Map<String, SObject> baseData = TestScenarioFactory.createCompleteSubscriptionSetup();
        Account acc = (Account) baseData.get('account');
        
        Test.startTest();
        
        // Focus solo su Price Plan requirement
        try {
            Subscription__c activeWithoutPricePlan = new Subscription__c(
                Account__c = acc.Id,
                Price_Plan__c = null,
                Status__c = 'Active'
            );
            insert activeWithoutPricePlan;
            System.assert(false, 'Should require price plan for active subscription');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Price plan is required'));
        }
        
        Test.stopTest();
    }

    // ========== DEFAULT VALUES ==========
    
    @isTest
    static void testSetDefaults() {
        Map<String, SObject> baseData = TestScenarioFactory.createCompleteSubscriptionSetup();
        Account acc = (Account) baseData.get('account');
        Price_Plan__c pricePlan = (Price_Plan__c) baseData.get('pricePlan');
        
        Test.startTest();
        
        // Test Draft defaults (esistente)
        Subscription__c subscription = new Subscription__c(
            Account__c = acc.Id,
            Price_Plan__c = pricePlan.Id
        );
        insert subscription;
        
        subscription = [SELECT Status__c, Start_Date__c FROM Subscription__c WHERE Id = :subscription.Id];
        System.assertEquals('Draft', subscription.Status__c, 'Should default to Draft status');
        System.assertEquals(Date.today(), subscription.Start_Date__c, 'Should default to today for start date');
        
        // Test Trial defaults (esistente)
        Subscription__c trialSub = new Subscription__c(
            Account__c = acc.Id,
            Price_Plan__c = pricePlan.Id,
            Status__c = 'Trial'
        );
        insert trialSub;
        
        
        // NUOVO: Test Active defaults
        Subscription__c activeSub = new Subscription__c(
            Account__c = acc.Id,
            Price_Plan__c = pricePlan.Id,
            Status__c = 'Active',
            Start_Date__c = null  // Deliberatamente null
        );
        insert activeSub;
        
        activeSub = [SELECT Start_Date__c FROM Subscription__c WHERE Id = :activeSub.Id];
        System.assertEquals(Date.today(), activeSub.Start_Date__c, 
                        'setDefaults should populate Start_Date for Active subscriptions');
        
        Test.stopTest();
    }
    
    // ========== INVOICE GENERATION DETECTION ==========
    
    @isTest
    static void testGetSubscriptionsNeedingInvoice() {
        Map<String, SObject> data = TestScenarioFactory.createTrialSubscriptionScenario();
        Subscription__c trialSub = (Subscription__c) data.get('subscription');
        
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
        
        System.assertEquals(1, needingInvoice.size(), 'Should detect subscription becoming active');
        System.assert(needingInvoice.contains(trialSub.Id), 'Should include the activated subscription');
        
        // Test no invoice generation for other transitions
        Map<String, SObject> draftData = TestScenarioFactory.createCompleteSubscriptionSetup();
        Subscription__c draftSub = (Subscription__c) draftData.get('subscription');
        
        Map<Id, Subscription__c> draftOldMap = new Map<Id, Subscription__c>{
            draftSub.Id => draftSub.clone(true)
        };
        
        draftSub.Status__c = 'Trial';
        Map<Id, Subscription__c> draftNewMap = new Map<Id, Subscription__c>{
            draftSub.Id => draftSub
        };
        
        Set<Id> noInvoiceNeeded = SubscriptionValidator.getSubscriptionsNeedingInvoice(draftOldMap, draftNewMap);
        System.assertEquals(0, noInvoiceNeeded.size(), 'Draft to Trial should not need invoice');
        
        Test.stopTest();
    }
    
    // ========== BULK OPERATIONS ==========
    
    @isTest
    static void testBulkOperations() {
        Map<String, SObject> baseData = TestScenarioFactory.createCompleteSubscriptionSetup();
        Account acc = (Account) baseData.get('account');
        Price_Plan__c pricePlan = (Price_Plan__c) baseData.get('pricePlan');
        
        Test.startTest();
        
        // Create bulk subscriptions using scenario factory
        List<Subscription__c> subscriptions = TestScenarioFactory.createBulkDraftSubscriptions(acc.Id, pricePlan.Id, 200);
        
        // Verify defaults applied
        for (Subscription__c sub : subscriptions) {
            System.assertEquals('Draft', sub.Status__c, 'Bulk subscriptions should have default status');
        }
        
        // Test bulk valid transitions
        for (Subscription__c sub : subscriptions) {
            sub.Status__c = 'Trial';
        }
        update subscriptions; // Should succeed
        
        // Test bulk invalid transitions
        for (Subscription__c sub : subscriptions) {
            sub.Status__c = 'Draft'; // Invalid: Trial -> Draft
        }
        
        try {
            update subscriptions;
            System.assert(false, 'Bulk invalid transitions should fail');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Invalid status transition'));
        }
        
        Test.stopTest();
    }
}
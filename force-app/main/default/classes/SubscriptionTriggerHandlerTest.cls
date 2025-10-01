/**
 * @description Test class for SubscriptionTriggerHandler - Complete lifecycle coverage
 * @author Antonio Franco
 * @date 2025-09-12
 * @story STORY-005: Test Classes - Final Implementation
 */
@isTest
private class SubscriptionTriggerHandlerTest {
    
    // Note: Removed @testSetup to avoid conflicts when tests create their own data
    
    @isTest
    static void testBeforeTriggerOrchestration() {
        Map<String, SObject> testData = TestScenarioFactory.createCompleteSubscriptionSetup();
        Account acc = (Account) testData.get('account');
        Price_Plan__c pricePlan = (Price_Plan__c) testData.get('pricePlan');
        
        Test.startTest();

        // Use existing subscription from setup instead of creating new one
        Subscription__c sub = (Subscription__c) testData.get('subscription');
        
        sub = [SELECT Status__c FROM Subscription__c WHERE Id = :sub.Id];
        System.assertEquals('Draft', sub.Status__c, 'Handler should orchestrate defaults');
        
        sub.Status__c = 'Trial';
        sub.Trial_End_Date__c = Date.today().addDays(14);
        update sub;
        
        sub.Status__c = 'Cancelled';
        sub.Cancellation_Reason__c = 'Other';
        update sub;
        delete sub;
        
        System.assertEquals(0, [SELECT COUNT() FROM Subscription__c WHERE Id = :sub.Id],
                          'Handler should orchestrate full lifecycle');
        
        Test.stopTest();
    }
    
    @isTest
    static void testAfterTriggerOrchestration() {
        Map<String, SObject> data = TestScenarioFactory.createTrialSubscriptionScenario();
        Subscription__c sub = (Subscription__c) data.get('subscription');
        
        Test.startTest();
        
        // Test afterUpdate with status transition (Trial->Active)
        sub.Status__c = 'Active';
        update sub;
        
        sub = [SELECT Status__c FROM Subscription__c WHERE Id = :sub.Id];
        System.assertEquals('Active', sub.Status__c, 'Status transition should be processed');
        
        // Test afterUpdate - cancellation should FAIL for Active without permission (negative test)
        sub.Status__c = 'Cancelled';
        sub.Cancellation_Reason__c = 'Other';
        try {
            update sub;
            System.assert(false, 'Should block active subscription cancellation without permission');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('permission'), 
                         'Should block active subscription cancellation');
        }
        
        // Test afterDelete + afterUndelete with Draft subscription (positive test)
        Map<String, SObject> draftData = TestScenarioFactory.createCompleteSubscriptionSetup();
        Subscription__c draftSub = (Subscription__c) draftData.get('subscription');
        Id draftId = draftSub.Id;
        
        delete draftSub; // Should succeed for Draft
        undelete draftSub; // Should succeed
        
        System.assertEquals(1, [SELECT COUNT() FROM Subscription__c WHERE Id = :draftId],
                          'Handler should orchestrate draft subscription lifecycle');
        
        Test.stopTest();
    }
    
    @isTest
    static void testErrorPropagation() {
        Map<String, SObject> testData = TestScenarioFactory.createCompleteSubscriptionSetup();
        Account acc = (Account) testData.get('account');
        Price_Plan__c pricePlan = (Price_Plan__c) testData.get('pricePlan');
        
        Test.startTest();
        
        Subscription__c sub = TestDataFactory.createSubscription(acc.Id, pricePlan.Id);
        sub.Start_Date__c = Date.today();
        sub.End_Date__c = Date.today().addDays(-1);
        
        try {
            insert sub;
            System.assert(false, 'Handler should propagate validation errors');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('End date must be after start date'),
                        'Handler should propagate validator messages');
        }
        
        Subscription__c activeSub = TestDataFactory.createSubscription(acc.Id, pricePlan.Id);
        activeSub.Status__c = 'Active';
        insert activeSub;
        
        activeSub.Status__c = 'Cancelled';
        activeSub.Cancellation_Reason__c = 'Other';
        try {
            update activeSub;
            System.assert(false, 'Handler should propagate permission errors');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('permission'),
                        'Handler should propagate permission errors');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testBulkProcessing() {
        Map<String, SObject> testData = TestScenarioFactory.createCompleteSubscriptionSetup();
        Account acc = (Account) testData.get('account');
        Price_Plan__c pricePlan = (Price_Plan__c) testData.get('pricePlan');
        
        Test.startTest();
        
        List<Subscription__c> bulkSubs = TestScenarioFactory.createBulkDraftSubscriptions(acc.Id, pricePlan.Id, 200);
        
        for (Subscription__c sub : bulkSubs) {
            System.assertEquals('Draft', sub.Status__c, 'Bulk handler should set defaults');
        }
        
        for (Subscription__c sub : bulkSubs) {
            sub.Status__c = 'Trial';
            sub.Trial_End_Date__c = Date.today().addDays(14);
        }
        update bulkSubs;
        
        for (Subscription__c sub : bulkSubs) {
            sub.Status__c = 'Cancelled';
            sub.Cancellation_Reason__c = 'Other';
        }
        update bulkSubs;
        delete bulkSubs;
        
        System.assertEquals(0, [SELECT COUNT() FROM Subscription__c WHERE Id IN :bulkSubs],
                          'Handler should process bulk operations');
        
        Test.stopTest();
    }
}
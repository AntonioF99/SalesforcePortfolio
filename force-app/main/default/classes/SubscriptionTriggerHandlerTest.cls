/**
 * @description Test class for SubscriptionTriggerHandler - ULTRA LEAN with TestScenarioFactory  
 * @author Antonio Franco
 * @date 2025-09-12
 * @story STORY-005: Test Classes - Final Refactoring
 * @note Business logic tested in SubscriptionValidatorTest (100% coverage)
 */
@isTest
private class SubscriptionTriggerHandlerTest {
    
    @testSetup
    static void setupTestData() {
        // Use scenario factory for setup
        TestScenarioFactory.createCompleteSubscriptionSetup();
    }
    
    @isTest
    static void testHandlerOrchestration() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Price_Plan__c pricePlan = [SELECT Id FROM Price_Plan__c LIMIT 1];
        
        Test.startTest();
        
        // Test complete lifecycle orchestration
        Subscription__c sub = new Subscription__c(
            Account__c = acc.Id,
            Price_Plan__c = pricePlan.Id
        );
        insert sub; // Should call setDefaults + validateBusinessRules
        
        // Verify orchestration worked
        sub = [SELECT Status__c FROM Subscription__c WHERE Id = :sub.Id];
        System.assertEquals('Draft', sub.Status__c, 'Handler should orchestrate defaults');
        
        // UPDATE orchestration - valid state transition
        sub.Status__c = 'Trial';
        sub.Trial_End_Date__c = Date.today().addDays(14);
        update sub; // Should call state validation + business rules
        
        // DELETE orchestration
        sub.Status__c = 'Cancelled';
        sub.Cancellation_Reason__c = 'Other';
        update sub;
        delete sub; // Should call deletion validation
        
        System.assertEquals(0, [SELECT COUNT() FROM Subscription__c WHERE Id = :sub.Id],
                          'Handler should orchestrate full lifecycle');
        
        Test.stopTest();
    }
    
    @isTest  
    static void testErrorPropagation() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Price_Plan__c pricePlan = [SELECT Id FROM Price_Plan__c LIMIT 1];
        
        Test.startTest();
        
        // Test validation error propagation with invalid dates
        Subscription__c sub = TestDataFactory.createSubscription(acc.Id, pricePlan.Id);
        sub.Start_Date__c = Date.today();
        sub.End_Date__c = Date.today().addDays(-1); // Invalid
        
        try {
            insert sub;
            System.assert(false, 'Handler should propagate validation errors');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('End date must be after start date'),
                        'Handler should propagate validator messages');
        }
        
        Test.stopTest();
    }
}
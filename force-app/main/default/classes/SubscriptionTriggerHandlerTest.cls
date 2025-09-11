/**
 * @description Test class for SubscriptionTriggerHandler
 * @author Antonio Franco
 * @date 2025-09-11
 * @story STORY-005: Test Classes
 * @note Focused testing for thin handler - business logic is tested in SubscriptionValidatorTest
 */
@isTest
private class SubscriptionTriggerHandlerTest {
    
    @testSetup
    static void setupTestData() {
        // Create minimal test data
        Account testAccount = TestDataFactory.createAccount();
        insert testAccount;
        
        Product__c testProduct = TestDataFactory.createProduct();
        insert testProduct;
        
        Price_Plan__c testPricePlan = TestDataFactory.createPricePlan(testProduct.Id);
        insert testPricePlan;
    }
    
    // ========== HANDLER ORCHESTRATION TESTS ==========
    
    @isTest
    static void testHandlerOrchestration() {
        // This test verifies the handler correctly orchestrates validator calls
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Price_Plan__c pricePlan = [SELECT Id FROM Price_Plan__c LIMIT 1];
        
        Test.startTest();
        
        // Test INSERT - should call setDefaults and validateBusinessRules
        Subscription__c sub = new Subscription__c(
            Account__c = acc.Id,
            Price_Plan__c = pricePlan.Id
            // Not setting Status/Start_Date to test defaults
        );
        insert sub;
        
        // Verify defaults were applied (proves setDefaults was called)
        sub = [SELECT Status__c, Start_Date__c FROM Subscription__c WHERE Id = :sub.Id];
        System.assertEquals('Draft', sub.Status__c, 'Handler should orchestrate default setting');
        System.assertNotEquals(null, sub.Start_Date__c, 'Handler should orchestrate date default');
        
        // Test UPDATE - should call state validation
        sub.Status__c = 'Trial';
        sub.Trial_End_Date__c = Date.today().addDays(14);
        update sub;
        
        // Test DELETE - should call deletion validation
        sub.Status__c = 'Cancelled';
        sub.Cancellation_Reason__c = 'Other';
        update sub;
        delete sub;
        
        System.assertEquals(0, [SELECT COUNT() FROM Subscription__c WHERE Id = :sub.Id],
                          'Handler should orchestrate through full lifecycle');
        
        Test.stopTest();
    }
    
    @isTest
    static void testInvoiceGenerationDetection() {
        // Specific test for the after update invoice generation logic
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Price_Plan__c pricePlan = [SELECT Id FROM Price_Plan__c LIMIT 1];
        
        // Create trial subscription
        Subscription__c sub = TestDataFactory.createSubscriptionWithOverrides(acc.Id, pricePlan.Id,
            new Map<String, Object>{
                'Status__c' => 'Trial',
                'Trial_End_Date__c' => Date.today().addDays(14)
            });
        insert sub;
        
        Test.startTest();
        
        // Transition to Active - should detect need for invoice
        sub.Status__c = 'Active';
        update sub;
        
        // Verify the transition completed
        // The actual invoice generation detection is internal to handler
        // We just verify the update succeeded
        sub = [SELECT Status__c FROM Subscription__c WHERE Id = :sub.Id];
        System.assertEquals('Active', sub.Status__c, 
                          'Handler should process activation for invoice generation');
        
        Test.stopTest();
    }
    
    @isTest
    static void testValidationErrorPropagation() {
        // Verify that validation errors from Validator are properly propagated
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Price_Plan__c pricePlan = [SELECT Id FROM Price_Plan__c LIMIT 1];
        
        Test.startTest();
        
        // Create subscription with invalid dates
        Subscription__c sub = new Subscription__c(
            Account__c = acc.Id,
            Price_Plan__c = pricePlan.Id,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addDays(-1) // Invalid: end before start
        );
        
        try {
            insert sub;
            System.assert(false, 'Handler should propagate validation errors');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('End date must be after start date'),
                        'Handler should propagate validator error messages');
        }
        
        Test.stopTest();
    }
    
    // ========== BULK OPERATIONS TEST ==========
    
    @isTest
    static void testBulkOperations() {
        // Verify handler can process bulk operations within governor limits
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Price_Plan__c pricePlan = [SELECT Id FROM Price_Plan__c LIMIT 1];
        
        List<Subscription__c> subscriptions = new List<Subscription__c>();
        
        // Create 200 subscriptions
        for (Integer i = 0; i < 200; i++) {
            subscriptions.add(new Subscription__c(
                Account__c = acc.Id,
                Price_Plan__c = pricePlan.Id
            ));
        }
        
        Test.startTest();
        
        // Bulk insert
        insert subscriptions;
        
        // Bulk update
        for (Subscription__c sub : subscriptions) {
            sub.End_Date__c = Date.today().addMonths(12);
        }
        update subscriptions;
        
        // Verify bulk processing succeeded
        System.assertEquals(200, [SELECT COUNT() FROM Subscription__c 
                                WHERE Account__c = :acc.Id AND End_Date__c != null],
                          'Handler should process bulk operations efficiently');
        
        // Bulk delete (Draft can be deleted)
        delete subscriptions;
        
        System.assertEquals(0, [SELECT COUNT() FROM Subscription__c WHERE Account__c = :acc.Id],
                          'Handler should handle bulk deletes');
        
        Test.stopTest();
    }
    
    // ========== UNDELETE TEST ==========
    
    @isTest
    static void testUndeleteHandling() {
        // Verify after undelete is properly handled
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Price_Plan__c pricePlan = [SELECT Id FROM Price_Plan__c LIMIT 1];
        
        Subscription__c sub = TestDataFactory.createSubscription(acc.Id, pricePlan.Id);
        insert sub;
        delete sub;
        
        Test.startTest();
        
        undelete sub;
        
        // Verify undelete succeeded
        sub = [SELECT Id, IsDeleted FROM Subscription__c WHERE Id = :sub.Id ALL ROWS];
        System.assertEquals(false, sub.IsDeleted, 'Handler should process undelete');
        
        Test.stopTest();
    }
}
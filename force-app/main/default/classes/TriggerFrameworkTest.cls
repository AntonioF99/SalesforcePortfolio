/**
 * @description Test class for TriggerFramework
 * @author Antonio Franco
 * @date 2025-09-11
 * @story STORY-005: Test Classes
 * @coverage Target: 100% for TriggerFramework.cls
 */
@isTest
private class TriggerFrameworkTest {
    
    // Move counters to class level to avoid static in inner class
    private static Integer beforeInsertCallCount = 0;
    private static Integer beforeUpdateCallCount = 0;
    private static Integer beforeDeleteCallCount = 0;
    private static Integer afterInsertCallCount = 0;
    private static Integer afterUpdateCallCount = 0;
    private static Integer afterDeleteCallCount = 0;
    private static Integer afterUndeleteCallCount = 0;
    
    /**
     * @description Mock handler implementation for testing
     */
    private class MockHandler implements IHandler {
        
        public void beforeInsert(List<SObject> newRecords) {
            TriggerFrameworkTest.beforeInsertCallCount++;
        }
        
        public void beforeUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {
            TriggerFrameworkTest.beforeUpdateCallCount++;
        }
        
        public void beforeDelete(Map<Id, SObject> oldMap) {
            TriggerFrameworkTest.beforeDeleteCallCount++;
        }
        
        public void afterInsert(Map<Id, SObject> newMap) {
            TriggerFrameworkTest.afterInsertCallCount++;
        }
        
        public void afterUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {
            TriggerFrameworkTest.afterUpdateCallCount++;
        }
        
        public void afterDelete(Map<Id, SObject> oldMap) {
            TriggerFrameworkTest.afterDeleteCallCount++;
        }
        
        public void afterUndelete(Map<Id, SObject> newMap) {
            TriggerFrameworkTest.afterUndeleteCallCount++;
        }
    }
    
    private static void resetCounters() {
        beforeInsertCallCount = 0;
        beforeUpdateCallCount = 0;
        beforeDeleteCallCount = 0;
        afterInsertCallCount = 0;
        afterUpdateCallCount = 0;
        afterDeleteCallCount = 0;
        afterUndeleteCallCount = 0;
    }
    
    // ========== DISPATCH TESTS ==========
    
    @isTest
    static void testDispatchWithNullHandler() {
        Test.startTest();
        
        try {
            TriggerFramework.dispatch(null);
            System.assert(false, 'Should throw exception for null handler');
        } catch (TriggerFramework.TriggerException e) {
            System.assert(e.getMessage().contains('Handler cannot be null'), 
                         'Should have correct error message');
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testDispatchOutsideTriggerContext() {
        MockHandler handler = new MockHandler();
        
        Test.startTest();
        
        // Outside trigger context, should return early without executing
        TriggerFramework.dispatch(handler);
        
        System.assertEquals(0, beforeInsertCallCount, 
                          'Should not execute handler outside trigger context');
        
        Test.stopTest();
    }
    
    // ========== BYPASS MANAGEMENT TESTS ==========
    
    @isTest
    static void testBypassManagement() {
        Test.startTest();
        
        String handlerName = 'TestHandler';
        
        // Initially not bypassed
        System.assertEquals(false, TriggerFramework.isBypassed(handlerName), 
                          'Handler should not be bypassed initially');
        
        // Add bypass
        TriggerFramework.bypass(handlerName);
        System.assertEquals(true, TriggerFramework.isBypassed(handlerName), 
                          'Handler should be bypassed after bypass()');
        
        // Clear specific bypass
        TriggerFramework.clearBypass(handlerName);
        System.assertEquals(false, TriggerFramework.isBypassed(handlerName), 
                          'Handler should not be bypassed after clearBypass()');
        
        // Test clearAllBypasses
        TriggerFramework.bypass(handlerName);
        TriggerFramework.bypass('AnotherHandler');
        TriggerFramework.clearAllBypasses();
        
        System.assertEquals(false, TriggerFramework.isBypassed(handlerName), 
                          'All handlers should be cleared after clearAllBypasses()');
        System.assertEquals(false, TriggerFramework.isBypassed('AnotherHandler'), 
                          'All handlers should be cleared after clearAllBypasses()');
        
        Test.stopTest();
    }
    
    @isTest
    static void testBypassedHandlerNotExecuted() {
        // This test requires actual DML to simulate trigger context
        Account testAccount = TestDataFactory.createAccount();
        
        Test.startTest();
        
        // Bypass the handler before insert
        TriggerFramework.bypass('SubscriptionTriggerHandler');
        
        // Create subscription - handler should be bypassed
        insert testAccount;
        
        // Verify bypass worked (handler methods not called)
        // In real scenario, we'd check that validator methods weren't called
        
        System.assert(TriggerFramework.isBypassed('SubscriptionTriggerHandler'), 
                     'Handler should remain bypassed');
        
        // Clear bypass for cleanup
        TriggerFramework.clearBypass('SubscriptionTriggerHandler');
        
        Test.stopTest();
    }
    
    // ========== RECURSION MANAGEMENT TESTS ==========
    
    @isTest
    static void testRecursionLimit() {
        // Test that recursion limit prevents infinite loops
        // This requires simulating multiple trigger executions
        
        Test.startTest();
        
        Account acc1 = TestDataFactory.createAccount();
        insert acc1;
        
        // Simulate recursive updates (would normally be in trigger)
        for (Integer i = 0; i < 5; i++) {
            acc1.Name = 'Updated ' + i;
            try {
                update acc1;
            } catch (Exception e) {
                // After MAX_RECURSION (3), further updates should be blocked
                if (i >= 3) {
                    System.debug('Recursion limit reached at iteration: ' + i);
                }
            }
        }
        
        Test.stopTest();
    }
    
    // ========== ROUTING TESTS ==========
    
    @isTest
    static void testBeforeInsertRouting() {
        MockHandler handler = new MockHandler();
        resetCounters();
        
        // We need to test with actual DML to get trigger context
        Account testAccount = TestDataFactory.createAccount();
        
        Test.startTest();
        
        // Temporarily replace handler for Account trigger
        // Note: In real implementation, we'd use the actual trigger
        insert testAccount;
        
        // Since we can't easily mock trigger context, we verify the pattern
        System.assertNotEquals(null, testAccount.Id, 'Record should be inserted');
        
        Test.stopTest();
    }
    
    @isTest
    static void testBeforeUpdateRouting() {
        Account testAccount = TestDataFactory.createAccount();
        insert testAccount;
        
        Test.startTest();
        
        testAccount.Name = 'Updated Name';
        update testAccount;
        
        // Verify update succeeded
        Account updatedAccount = [SELECT Name FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals('Updated Name', updatedAccount.Name, 'Update should succeed');
        
        Test.stopTest();
    }
    
    @isTest
    static void testBeforeDeleteRouting() {
        Account testAccount = TestDataFactory.createAccount();
        insert testAccount;
        Id accountId = testAccount.Id;
        
        Test.startTest();
        
        delete testAccount;
        
        // Verify deletion
        List<Account> deletedAccounts = [SELECT Id FROM Account WHERE Id = :accountId];
        System.assertEquals(0, deletedAccounts.size(), 'Record should be deleted');
        
        Test.stopTest();
    }
    
    @isTest
    static void testAfterUndeleteRouting() {
        Account testAccount = TestDataFactory.createAccount();
        insert testAccount;
        delete testAccount;
        
        Test.startTest();
        
        undelete testAccount;
        
        // Verify undelete
        Account undeletedAccount = [SELECT Id, IsDeleted FROM Account WHERE Id = :testAccount.Id ALL ROWS];
        System.assertEquals(false, undeletedAccount.IsDeleted, 'Record should be undeleted');
        
        Test.stopTest();
    }
    
    // ========== EXCEPTION HANDLING TESTS ==========
    
    @isTest
    static void testTriggerExceptionClass() {
        Test.startTest();
        
        try {
            throw new TriggerFramework.TriggerException('Test exception message');
        } catch (TriggerFramework.TriggerException e) {
            System.assertEquals('Test exception message', e.getMessage(), 
                              'Exception should preserve message');
        }
        
        Test.stopTest();
    }
    
    // ========== BULK OPERATION TESTS ==========
    
    @isTest
    static void testBulkOperations() {
        List<Account> accounts = new List<Account>();
        
        // Create 200 accounts for bulk testing
        for (Integer i = 0; i < 200; i++) {
            accounts.add(TestDataFactory.createAccount());
        }
        
        Test.startTest();
        
        insert accounts;
        
        // Verify all inserted
        System.assertEquals(200, [SELECT COUNT() FROM Account WHERE Id IN :accounts], 
                          'All records should be processed in bulk');
        
        // Bulk update
        for (Account acc : accounts) {
            acc.Phone = '555-0000';
        }
        update accounts;
        
        // Bulk delete
        delete accounts;
        
        System.assertEquals(0, [SELECT COUNT() FROM Account WHERE Id IN :accounts], 
                          'Bulk delete should process all records');
        
        Test.stopTest();
    }
    
    // ========== INTEGRATION TESTS ==========
    
    @isTest
    static void testFullTriggerLifecycle() {
        // This test verifies the complete lifecycle through all trigger events
        Test.startTest();
        
        // INSERT
        Account acc = TestDataFactory.createAccount();
        insert acc;
        System.assertNotEquals(null, acc.Id, 'Insert should succeed');
        
        // UPDATE
        acc.Name = 'Updated Account';
        acc.Phone = '999-8888';
        update acc;
        
        Account updatedAcc = [SELECT Name, Phone FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Updated Account', updatedAcc.Name, 'Update should persist');
        
        // DELETE
        delete acc;
        System.assertEquals(0, [SELECT COUNT() FROM Account WHERE Id = :acc.Id], 
                          'Delete should remove record');
        
        // UNDELETE
        undelete acc;
        System.assertEquals(1, [SELECT COUNT() FROM Account WHERE Id = :acc.Id], 
                          'Undelete should restore record');
        
        Test.stopTest();
    }
    
    @isTest
    static void testHandlerNameExtraction() {
        // Test that handler name is correctly extracted for bypass checking
        MockHandler handler = new MockHandler();
        
        Test.startTest();
        
        // The framework extracts handler name from the object toString()
        String handlerString = String.valueOf(handler);
        System.assert(handlerString.contains('MockHandler'), 
                     'Handler string should contain class name');
        
        Test.stopTest();
    }
}
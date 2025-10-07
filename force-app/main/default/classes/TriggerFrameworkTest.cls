/**
 * @description Test class for TriggerFramework - Simplified without counter nonsense
 * @author Antonio Franco
 * @date 2025-09-11
 * @story STORY-005: Test Classes - Final Consolidation
 */
@isTest
private class TriggerFrameworkTest {
    
    @isTest
    static void testDispatchValidation() {
        Test.startTest();
        
        try {
            TriggerFramework.dispatch(null);
            System.assert(false, 'Should throw exception for null handler');
        } catch (TriggerFramework.TriggerException e) {
            System.assert(e.getMessage().contains('Handler cannot be null'));
        }
        
        Test.stopTest();
    }
    
    @isTest
    static void testBypassMechanisms() {
        Test.startTest();
        
        String handlerName = 'TestHandler';
        
        System.assertEquals(false, TriggerFramework.isBypassed(handlerName));
        
        TriggerFramework.bypass(handlerName);
        System.assertEquals(true, TriggerFramework.isBypassed(handlerName));
        
        TriggerFramework.clearBypass(handlerName);
        System.assertEquals(false, TriggerFramework.isBypassed(handlerName));
        
        TriggerFramework.bypass(handlerName);
        TriggerFramework.bypass('AnotherHandler');
        TriggerFramework.clearAllBypasses();
        
        System.assertEquals(false, TriggerFramework.isBypassed(handlerName));
        System.assertEquals(false, TriggerFramework.isBypassed('AnotherHandler'));
        
        Test.stopTest();
    }
    
    @isTest
    static void testTriggerEventRouting() {
        Test.startTest();
        
        Account testAccount = TestDataFactory.createAccount();
        
        insert testAccount;
        System.assertNotEquals(null, testAccount.Id, 'INSERT should work');
        
        testAccount.Name = 'Updated Name';
        update testAccount;
        Account updatedAccount = [SELECT Name FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals('Updated Name', updatedAccount.Name, 'UPDATE should work');
        
        delete testAccount;
        List<Account> deletedAccounts = [SELECT Id FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(0, deletedAccounts.size(), 'DELETE should work');
        
        undelete testAccount;
        Account undeletedAccount = [SELECT Id, IsDeleted FROM Account WHERE Id = :testAccount.Id ALL ROWS];
        System.assertEquals(false, undeletedAccount.IsDeleted, 'UNDELETE should work');
        
        Test.stopTest();
    }
    
    @isTest
    static void testBulkOperations() {
        Test.startTest();
        
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(TestDataFactory.createAccount());
        }
        
        insert accounts;
        System.assertEquals(200, [SELECT COUNT() FROM Account WHERE Id IN :accounts]);
        
        for (Account acc : accounts) {
            acc.Phone = '555-0000';
        }
        update accounts;
        
        delete accounts;
        System.assertEquals(0, [SELECT COUNT() FROM Account WHERE Id IN :accounts]);
        
        Test.stopTest();
    }
    
    @isTest
    static void testExceptionClass() {
        Test.startTest();
        
        try {
            throw new TriggerFramework.TriggerException('Test message');
        } catch (TriggerFramework.TriggerException e) {
            System.assertEquals('Test message', e.getMessage());
        }
        
        Test.stopTest();
    }
}
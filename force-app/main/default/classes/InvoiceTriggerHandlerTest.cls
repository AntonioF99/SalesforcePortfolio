/**
 * @description Test class for InvoiceTriggerHandler - ULTRA LEAN with TestScenarioFactory
 * @author Antonio Franco
 * @date 2025-09-12
 * @story STORY-005: Test Classes - Final Refactoring
 * @note Business logic tested in InvoiceValidatorTest (100% coverage)
 */
@isTest
private class InvoiceTriggerHandlerTest {
    
    @testSetup
    static void setupTestData() {
        Account testAccount = TestDataFactory.createAccount();
        insert testAccount;
    }
    
    @isTest
    static void testHandlerOrchestration() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        
        // Test complete lifecycle orchestration
        Invoice__c inv = new Invoice__c(Account__c = acc.Id);
        insert inv; // Should call setDefaults + calculateTax + validateBusinessRules
        
        // Verify orchestration worked
        inv = [SELECT Status__c, Tax_Rate__c FROM Invoice__c WHERE Id = :inv.Id];
        System.assertEquals('Draft', inv.Status__c, 'Handler should orchestrate defaults');
        System.assertEquals(22.0, inv.Tax_Rate__c, 'Handler should orchestrate tax calculation');
        
        // UPDATE orchestration
        inv.Payment_Terms__c = 'Net 45';
        update inv; // Should call permission validation + business rules
        
        // DELETE orchestration
        delete inv; // Should call permission validation
        
        System.assertEquals(0, [SELECT COUNT() FROM Invoice__c WHERE Id = :inv.Id],
                          'Handler should orchestrate full lifecycle');
        
        Test.stopTest();
    }
    
    @isTest
    static void testErrorPropagation() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        
        // Use scenario factory for permission testing
        Invoice__c paidInv = TestScenarioFactory.createPaidInvoice(acc.Id);
        
        paidInv.Tax_Rate__c = 25.0;
        try {
            update paidInv;
            System.assert(false, 'Handler should propagate permission errors');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('permission'),
                        'Handler should propagate validator errors');
        }
        
        Test.stopTest();
    }
}

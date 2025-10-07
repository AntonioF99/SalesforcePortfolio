/**
 * @description Test class for InvoiceTriggerHandler - Complete lifecycle coverage
 * @author Antonio Franco
 * @date 2025-09-12
 * @story STORY-005: Test Classes - Final Implementation
 */
@isTest
private class InvoiceTriggerHandlerTest {
    
    @testSetup
    static void setupTestData() {
        Account testAccount = TestDataFactory.createAccount();
        insert testAccount;
    }
    
    @isTest
    static void testBeforeTriggerOrchestration() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        
        Invoice__c inv = new Invoice__c(
            Account__c = acc.Id,
            Due_Date__c = Date.today().addDays(30)
        );
        insert inv;
        
        inv = [SELECT Status__c, Tax_Rate__c, Invoice_Date__c, Due_Date__c FROM Invoice__c WHERE Id = :inv.Id];
        System.assertEquals('Draft', inv.Status__c, 'Handler should orchestrate defaults');
        System.assertEquals(22.0, inv.Tax_Rate__c, 'Handler should orchestrate tax calculation');
        
        inv.Payment_Terms__c = 'Net 45';
        inv.Due_Date__c = inv.Invoice_Date__c.addDays(45); // Consistent with Net 45 terms
        update inv;
        
        delete inv;
        
        System.assertEquals(0, [SELECT COUNT() FROM Invoice__c WHERE Id = :inv.Id],
                          'Handler should orchestrate deletion validation');
        
        Test.stopTest();
    }
    
    @isTest
    static void testAfterTriggerOrchestration() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        
        // Test afterInsert
        Invoice__c inv = TestDataFactory.createInvoice(acc.Id);
        insert inv;
        
        // Test afterUpdate with status change to Paid
        inv = TestScenarioFactory.createSentInvoice(acc.Id);
        inv.Status__c = 'Paid';
        inv.Balance_Due__c = 0.0;
        update inv;
        
        inv = [SELECT Status__c FROM Invoice__c WHERE Id = :inv.Id];
        System.assertEquals('Paid', inv.Status__c, 'Status change should be processed');
        
        // Test afterDelete - should FAIL for Paid invoice (negative test)
        try {
            delete inv;
            System.assert(false, 'Should block deletion of paid invoice');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Cannot delete invoices with status'), 
                         'Should block paid invoice deletion');
        }
        
        // Test afterDelete + afterUndelete with Draft invoice (positive test)
        Invoice__c draftInv = TestDataFactory.createInvoice(acc.Id);
        insert draftInv;
        Id draftId = draftInv.Id;
        
        delete draftInv; // Should succeed
        undelete draftInv; // Should succeed
        
        System.assertEquals(1, [SELECT COUNT() FROM Invoice__c WHERE Id = :draftId],
                          'Handler should orchestrate draft invoice lifecycle');
        
        Test.stopTest();
    }
    
    @isTest
    static void testErrorPropagation() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        
        Invoice__c orphanInv = new Invoice__c(
            Account__c = null,
            Status__c = 'Draft'
        );
        
        try {
            insert orphanInv;
            System.assert(false, 'Handler should propagate validation errors');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Account is required'),
                        'Handler should propagate validator messages');
        }
        
        // Test that updates succeed (no security validation in triggers)
        Invoice__c paidInv = TestScenarioFactory.createPaidInvoice(acc.Id);
        
        paidInv.Tax_Rate__c = 25.0;
        update paidInv; // Should succeed - security validation moved to SecurityUtils
        
        Invoice__c updatedInv = [SELECT Tax_Rate__c FROM Invoice__c WHERE Id = :paidInv.Id];
        System.assertEquals(25.0, updatedInv.Tax_Rate__c, 'Update should succeed');
        
        Test.stopTest();
    }
    
    @isTest
    static void testBulkProcessing() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        
        List<Invoice__c> bulkInvoices = TestScenarioFactory.createBulkDraftInvoices(acc.Id, 200);
        
        for (Invoice__c inv : bulkInvoices) {
            System.assertEquals('Draft', inv.Status__c, 'Bulk handler should set defaults');
        }
        
        for (Invoice__c inv : bulkInvoices) {
            inv.Status__c = 'Sent';
        }
        
        List<Invoice_Line_Item__c> lineItems = new List<Invoice_Line_Item__c>();
        for (Invoice__c inv : bulkInvoices) {
            lineItems.add(TestDataFactory.createInvoiceLineItem(inv.Id));
        }
        insert lineItems;
        
        update bulkInvoices;
        
        delete bulkInvoices;
        
        System.assertEquals(0, [SELECT COUNT() FROM Invoice__c WHERE Id IN :bulkInvoices],
                          'Handler should process bulk operations');
        
        Test.stopTest();
    }
}
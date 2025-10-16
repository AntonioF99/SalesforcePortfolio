/**
 * @description Test class for InvoiceLineItemTrigger and InvoiceLineItemTriggerHandler
 * @author Antonio Franco
 * @date 2025-01-16
 */
@isTest
private class InvoiceLineItemTriggerTest {
    
    @testSetup
    static void setupTestData() {
        Account testAccount = TestDataFactory.createAccount();
        insert testAccount;
    }
    
    // ========== LINE ITEM DELETION VALIDATION ==========
    
    @isTest
    static void testDeleteLineItemFromDraftInvoice() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        // Create DRAFT invoice
        Invoice__c invoice = new Invoice__c(
            Account__c = acc.Id,
            Status__c = Constants.INVOICE_STATUS_DRAFT
        );
        insert invoice;
        
        // Add line item
        Invoice_Line_Item__c lineItem = TestDataFactory.createInvoiceLineItem(invoice.Id);
        insert lineItem;
        
        Test.startTest();
        delete lineItem; // Should succeed for DRAFT
        Test.stopTest();
        
        List<Invoice_Line_Item__c> items = [SELECT Id FROM Invoice_Line_Item__c];
        System.assertEquals(0, items.size(), 'Line item should be deleted from draft');
    }
    
    @isTest
    static void testCannotDeleteLineItemFromSentInvoice() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        // Create DRAFT invoice with line item
        Invoice__c invoice = new Invoice__c(
            Account__c = acc.Id,
            Status__c = Constants.INVOICE_STATUS_DRAFT
        );
        insert invoice;
        
        Invoice_Line_Item__c lineItem = TestDataFactory.createInvoiceLineItem(invoice.Id);
        insert lineItem;
        
        // Update to SENT (locks invoice)
        invoice.Status__c = Constants.INVOICE_STATUS_SENT;
        update invoice;
        
        Test.startTest();
        try {
            delete lineItem; // Should fail
            System.assert(false, 'Should not delete from locked invoice');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Cannot delete line items'), 
                         'Error should mention deletion prevention');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testCannotDeleteLineItemFromPaidInvoice() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        // Create PAID invoice scenario
        Invoice__c invoice = new Invoice__c(
            Account__c = acc.Id,
            Status__c = Constants.INVOICE_STATUS_PAID,
            Balance_Due__c = 0
        );
        insert invoice;
        
        Invoice_Line_Item__c lineItem = TestDataFactory.createInvoiceLineItem(invoice.Id);
        insert lineItem;
        
        Test.startTest();
        try {
            delete lineItem;
            System.assert(false, 'Should not delete from paid invoice');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('delete line items'));
        }
        Test.stopTest();
    }
    
    @isTest
    static void testBulkDeleteLineItemsValidation() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        // Create 2 DRAFT invoices
        Invoice__c draftInv = new Invoice__c(
            Account__c = acc.Id,
            Status__c = Constants.INVOICE_STATUS_DRAFT
        );
        Invoice__c draftInv2 = new Invoice__c(
            Account__c = acc.Id,
            Status__c = Constants.INVOICE_STATUS_DRAFT
        );
        insert new List<Invoice__c>{draftInv, draftInv2};
        
        // Add line items to both
        List<Invoice_Line_Item__c> items = new List<Invoice_Line_Item__c>{
            TestDataFactory.createInvoiceLineItem(draftInv.Id),
            TestDataFactory.createInvoiceLineItem(draftInv2.Id)
        };
        insert items;
        
        // Update one to SENT (locks it)
        draftInv2.Status__c = Constants.INVOICE_STATUS_SENT;
        update draftInv2;
        
        Test.startTest();
        try {
            delete items; // Bulk delete should fail (one is locked)
            System.assert(false, 'Bulk delete should fail for locked item');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('delete line items'));
        }
        Test.stopTest();
    }
}

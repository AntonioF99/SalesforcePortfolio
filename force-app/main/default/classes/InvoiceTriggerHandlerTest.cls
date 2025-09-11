/**
 * @description Test class for InvoiceTriggerHandler
 * @author Antonio Franco
 * @date 2025-09-11
 * @story STORY-005: Test Classes
 * @note Focused testing for thin handler - business logic is tested in InvoiceValidatorTest
 */
@isTest
private class InvoiceTriggerHandlerTest {
    
    @testSetup
    static void setupTestData() {
        // Create minimal test data with Italian billing for consistent tax testing
        Account testAccount = TestDataFactory.createAccountWithOverrides(new Map<String, Object>{
            'BillingCountry' => 'Italy',
            'BillingCity' => 'Milan'
        });
        insert testAccount;
    }
    
    // ========== HANDLER ORCHESTRATION TESTS ==========
    
    @isTest
    static void testHandlerOrchestration() {
        // This test verifies the handler correctly orchestrates validator calls
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        
        // Test INSERT - should call setDefaults, generateInvoiceNumbers, calculateTaxAmounts
        Invoice__c inv = new Invoice__c(
            Account__c = acc.Id
            // Not setting fields to test defaults
        );
        insert inv;
        
        // Verify defaults and tax calculation were applied
        inv = [SELECT Status__c, Invoice_Date__c, Due_Date__c, Tax_Rate__c 
               FROM Invoice__c WHERE Id = :inv.Id];
        System.assertEquals('Draft', inv.Status__c, 'Handler should orchestrate default status');
        System.assertEquals(Date.today(), inv.Invoice_Date__c, 'Handler should orchestrate date default');
        System.assertEquals(Date.today().addDays(30), inv.Due_Date__c, 'Handler should orchestrate due date');
        System.assertEquals(22.0, inv.Tax_Rate__c, 'Handler should orchestrate tax calculation for Italy');
        
        // Test UPDATE - just test a simple field update
        inv.Payment_Terms__c = 'Net 45';
        update inv;

        
        // Test DELETE validation
        inv.Status__c = 'Draft'; // Reset to deletable status
        update inv;
        delete inv;
        
        System.assertEquals(0, [SELECT COUNT() FROM Invoice__c WHERE Id = :inv.Id],
                          'Handler should orchestrate through full lifecycle');
        
        Test.stopTest();
    }
    
    @isTest
    static void testPermissionValidation() {
        // Verify handler enforces permission checks for paid invoices
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Invoice__c inv = TestDataFactory.createInvoiceWithOverrides(acc.Id,
            new Map<String, Object>{'Status__c' => 'Paid'});
        insert inv;
        
        Test.startTest();
        
        // Try to modify paid invoice without permission
        inv.Tax_Rate__c = 25.0;
        
        try {
            update inv;
            System.assert(false, 'Handler should enforce permission validation');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('permission'),
                        'Handler should propagate permission errors');
        }
        
        Test.stopTest();
    }
    
        @isTest
    static void testRecalculationDetection() {
        // Test that handler identifies invoices needing line item recalculation
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Invoice__c inv = TestDataFactory.createInvoice(acc.Id);
        insert inv;
        
        // Create line item so invoice has subtotal (required for Sent status)
        Invoice_Line_Item__c lineItem = TestDataFactory.createInvoiceLineItem(inv.Id);
        insert lineItem;
        
        Test.startTest();
        
        // Change to Sent status - should trigger recalculation detection
        inv.Status__c = 'Sent';
        update inv;
        
        // Verify status change succeeded (recalculation detection is internal)
        inv = [SELECT Status__c FROM Invoice__c WHERE Id = :inv.Id];
        System.assertEquals('Sent', inv.Status__c, 
                        'Handler should process status changes for recalculation');
        
        Test.stopTest();
    }
    
    @isTest
    static void testValidationErrorPropagation() {
        // Verify that validation errors from Validator are properly propagated
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        
        // Create invoice with invalid dates
        Invoice__c inv = new Invoice__c(
            Account__c = acc.Id,
            Invoice_Date__c = Date.today(),
            Due_Date__c = Date.today().addDays(-1) // Invalid: due before invoice
        );
        
        try {
            insert inv;
            System.assert(false, 'Handler should propagate validation errors');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Due date cannot be before invoice date'),
                        'Handler should propagate validator error messages');
        }
        
        Test.stopTest();
    }
    
    // ========== BULK OPERATIONS TEST ==========
    
    @isTest
    static void testBulkOperations() {
        // Verify handler can process bulk operations within governor limits
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        List<Invoice__c> invoices = new List<Invoice__c>();
        
        // Create 200 invoices
        for (Integer i = 0; i < 200; i++) {
            invoices.add(new Invoice__c(Account__c = acc.Id));
        }
        
        Test.startTest();
        
        // Bulk insert
        insert invoices;
        
        // Verify tax was calculated for all
        List<Invoice__c> insertedInvoices = [SELECT Tax_Rate__c FROM Invoice__c 
                                            WHERE Account__c = :acc.Id];
        System.assertEquals(200, insertedInvoices.size(), 'All invoices should be created');
        for (Invoice__c inv : insertedInvoices) {
            System.assertEquals(22.0, inv.Tax_Rate__c, 'Tax should be calculated in bulk');
        }
        
        // Bulk update
        for (Invoice__c inv : invoices) {
         inv.Payment_Terms__c = 'Net 45'; // Valid picklist value
        }
        update invoices;
        
        // Bulk delete (all are Draft, so deletable)
        delete invoices;
        
        System.assertEquals(0, [SELECT COUNT() FROM Invoice__c WHERE Account__c = :acc.Id],
                          'Handler should handle bulk deletes');
        
        Test.stopTest();
    }
    
    // ========== TAX CALCULATION TEST ==========
    
        @isTest
    static void testTaxCalculationUpdate() {
        // Test that tax calculation happens based on account billing country
        
        // Create German account
        Account germanAccount = TestDataFactory.createAccountWithOverrides(new Map<String, Object>{
            'BillingCountry' => 'Germany',
            'BillingCity' => 'Berlin'
        });
        insert germanAccount;
        
        Account italianAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        
        // Create invoice with Italian account
        Invoice__c italianInv = new Invoice__c(Account__c = italianAccount.Id);
        insert italianInv;
        
        // Verify Italian tax rate
        italianInv = [SELECT Tax_Rate__c FROM Invoice__c WHERE Id = :italianInv.Id];
        System.assertEquals(22.0, italianInv.Tax_Rate__c, 'Should have Italian tax rate');
        
        // Create separate invoice with German account
        Invoice__c germanInv = new Invoice__c(Account__c = germanAccount.Id);
        insert germanInv;
        
        // Verify German tax rate
        germanInv = [SELECT Tax_Rate__c FROM Invoice__c WHERE Id = :germanInv.Id];
        System.assertEquals(19.0, germanInv.Tax_Rate__c, 'Should have German tax rate');
        
        Test.stopTest();
    }
    
    // ========== UNDELETE TEST ==========
    
    @isTest
    static void testUndeleteHandling() {
        // Verify after undelete is properly handled
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Invoice__c inv = TestDataFactory.createInvoice(acc.Id);
        insert inv;
        delete inv;
        
        Test.startTest();
        
        undelete inv;
        
        // Verify undelete succeeded
        inv = [SELECT Id, IsDeleted FROM Invoice__c WHERE Id = :inv.Id ALL ROWS];
        System.assertEquals(false, inv.IsDeleted, 'Handler should process undelete');
        
        Test.stopTest();
    }
}
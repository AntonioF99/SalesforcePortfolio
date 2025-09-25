/**
 * @description Test class for InvoiceValidator - REFACTORED with TestScenarioFactory
 * @author Antonio Franco
 * @date 2025-09-12
 * @story STORY-005: Test Classes Refactoring
 * @pattern Clean test architecture using TestDataFactory + TestScenarioFactory
 */
@isTest
private class InvoiceValidatorTest {
    
    @testSetup
    static void setupTestData() {
        Account testAccount = TestDataFactory.createAccount();
        insert testAccount;
    }
    
    // ========== PERMISSION VALIDATION ==========
    
    @isTest
    static void testValidateUserPermissions() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        
        // Create invoices for permission testing using scenario factory
        Map<String, Invoice__c> invoices = TestScenarioFactory.createInvoicesForPermissionTesting(acc.Id);
        
        // Test UPDATE operations - Paid invoice blocking
        Invoice__c paidInv = invoices.get('paid');
        paidInv.Tax_Rate__c = 15.0;
        try {
            update paidInv;
            System.assert(false, 'Should block paid invoice modification');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('permission'),
                'Should mention permission requirement');
        }
        
        // Test UPDATE operations - Voided invoice blocking
        Invoice__c voidedInv = invoices.get('voided');
        voidedInv.Due_Date__c = Date.today().addDays(45);
        try {
            update voidedInv;
            System.assert(false, 'Should block voided invoice modification');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('permission'));
        }
        
        // Test DELETE operations - Locked status blocking
        try {
            delete paidInv;
            System.assert(false, 'Should block paid invoice deletion');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Cannot delete invoices with status'));
        }
        
        // Test Draft allowing (positive cases)
        Invoice__c draftInv = invoices.get('draft');
        draftInv.Tax_Rate__c = 25.0;
        update draftInv; // Should succeed
        delete draftInv; // Should succeed
        
        Test.stopTest();
    }
    
    // ========== BUSINESS RULES VALIDATION ==========
    
    @isTest
    static void testValidateBusinessRules() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        
        // Test date validation - invalid range
        try {
            Invoice__c invalidDates = TestDataFactory.createInvoiceWithInvalidDates(acc.Id);
            insert invalidDates;
            System.assert(false, 'Should reject invalid date range');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Due date cannot be before invoice date'));
        }
        
        // Test negative amounts validation - Balance Due
        try {
            Invoice__c negativeBalance = TestDataFactory.createInvoiceWithNegativeBalance(acc.Id);
            insert negativeBalance;
            System.assert(false, 'Should reject negative balance');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Balance due cannot be negative'));
        }
        
        // Note: Subtotal__c and Tax_Amount__c are read-only formula/rollup fields
        // These validations are tested via the validator methods directly
        List<Invoice__c> testInvoices = new List<Invoice__c>{
            new Invoice__c(Account__c = acc.Id, Tax_Rate__c = -10.0)  // This will trigger negative validation
        };
        
        // Test that validator catches negative calculated amounts
        InvoiceValidator.validateBusinessRules(testInvoices, false);
        System.assert(testInvoices[0].hasErrors(), 'Should have validation errors for negative amounts');
        
        // Test status-specific validations - Sent without subtotal
        try {
            Invoice__c sentWithoutSubtotal = TestDataFactory.createInvoice(acc.Id);
            sentWithoutSubtotal.Status__c = 'Sent';
            insert sentWithoutSubtotal;
            System.assert(false, 'Should reject Sent without subtotal');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Cannot send invoice with zero'));
        }
        
        // Test status-specific validations - Paid with balance
        try {
            Invoice__c paidWithBalance = TestDataFactory.createInvoice(acc.Id);
            paidWithBalance.Status__c = 'Paid';
            paidWithBalance.Balance_Due__c = 50.00;
            insert paidWithBalance;
            System.assert(false, 'Should reject Paid with positive balance');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Cannot mark as paid while balance due is positive'));
        }
        
        // Test status-specific validations - Overdue with future date
        try {
            Invoice__c overdueWithFutureDate = TestDataFactory.createInvoice(acc.Id);
            overdueWithFutureDate.Status__c = 'Overdue';
            overdueWithFutureDate.Due_Date__c = Date.today().addDays(5);
            insert overdueWithFutureDate;
            System.assert(false, 'Should reject Overdue with future date');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Cannot mark as overdue if due date is not past'));
        }
        
        // Positive case - valid invoice
        Invoice__c validInvoice = TestDataFactory.createInvoice(acc.Id);
        insert validInvoice; // Should succeed
        System.assertEquals(Date.today().addDays(30), validInvoice.Due_Date__c);
        
        Test.stopTest();
    }
    
    // ========== DEFAULT VALUES ==========
    
    @isTest
    static void testSetDefaults() {
        Test.startTest();
        
        // Create account without billing country to avoid tax calculation
        Account testAcc = TestDataFactory.createAccountForCountry(null);
        insert testAcc;
        
        // Test complete default scenario - all null/blank values
        Invoice__c invoiceAllDefaults = new Invoice__c(
            Account__c = testAcc.Id,
            Status__c = '',
            Invoice_Date__c = null,
            Tax_Rate__c = null
        );
        insert invoiceAllDefaults;
        
        // Reload to get default values
        invoiceAllDefaults = [SELECT Status__c, Invoice_Date__c, Due_Date__c, Tax_Rate__c, Balance_Due__c 
                             FROM Invoice__c WHERE Id = :invoiceAllDefaults.Id];
        
        System.assertEquals('Draft', invoiceAllDefaults.Status__c, 'Default status should be Draft');
        System.assertEquals(Date.today(), invoiceAllDefaults.Invoice_Date__c, 'Default invoice date should be today');
        System.assertEquals(Date.today().addDays(30), invoiceAllDefaults.Due_Date__c, 'Default due date should be 30 days out');
        System.assertEquals(0, invoiceAllDefaults.Tax_Rate__c, 'Default tax rate should be 0');
        System.assertEquals(0, invoiceAllDefaults.Balance_Due__c, 'Default balance due should be 0');
        
        // Test partial defaults - some values pre-filled
        Invoice__c invoicePartialDefaults = new Invoice__c(
            Account__c = testAcc.Id,
            Status__c = 'Sent',
            Invoice_Date__c = Date.today().addDays(-10),
            Tax_Rate__c = 22.0
        );
        insert invoicePartialDefaults;
        
        invoicePartialDefaults = [SELECT Status__c, Invoice_Date__c, Tax_Rate__c 
                                 FROM Invoice__c WHERE Id = :invoicePartialDefaults.Id];
        
        System.assertEquals('Sent', invoicePartialDefaults.Status__c, 'Should preserve existing status');
        System.assertEquals(Date.today().addDays(-10), invoicePartialDefaults.Invoice_Date__c, 'Should preserve existing date');
        System.assertEquals(22.0, invoicePartialDefaults.Tax_Rate__c, 'Should preserve existing tax rate');
        
        Test.stopTest();
    }
    
    // ========== TAX CALCULATION ==========
    
    @isTest
    static void testCalculateTaxAmounts() {
        Test.startTest();
        
        // Create multi-country invoices using scenario factory
        List<String> countries = new List<String>{'Italy', 'Germany', 'France', 'Spain', 'United Kingdom', 'Netherlands', 'Japan'};
        Map<String, Invoice__c> invoicesByCountry = TestScenarioFactory.createMultiCountryInvoices(countries);
        
        // Expected tax rates by country
        Map<String, Decimal> expectedRates = new Map<String, Decimal>{
            'Italy' => 22.0,
            'Germany' => 19.0,
            'France' => 20.0,
            'Spain' => 21.0,
            'United Kingdom' => 20.0,
            'Netherlands' => 21.0,
            'Japan' => 0.0 // Unsupported country
        };
        
        // Verify tax rates calculated correctly
        for (String country : countries) {
            Invoice__c invoice = invoicesByCountry.get(country);
            invoice = [SELECT Tax_Rate__c FROM Invoice__c WHERE Id = :invoice.Id];
            
            Decimal expected = expectedRates.get(country);
            System.assertEquals(expected, invoice.Tax_Rate__c, 
                'Tax rate should match for ' + country);
        }
        
        // Test edge cases
        InvoiceValidator.calculateTaxAmounts(new List<Invoice__c>{
            new Invoice__c(Account__c = null)
        }); // Should not throw exception
        
        InvoiceValidator.calculateTaxAmounts(new List<Invoice__c>());
        
        Test.stopTest();
    }
    
    // ========== RECALCULATION DETECTION ==========
    
    @isTest
    static void testGetInvoicesNeedingRecalculation() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        
        // Use scenario factory for recalculation testing
        Map<String, Invoice__c> testInvoices = TestScenarioFactory.createInvoicesForRecalculationTesting(acc.Id);
        
        List<Invoice__c> invoices = new List<Invoice__c>{
            testInvoices.get('sent'),
            testInvoices.get('paid'),
            testInvoices.get('draft')
        };
        
        Set<Id> needingRecalc = InvoiceValidator.getInvoicesNeedingRecalculation(invoices);
        
        System.assertEquals(2, needingRecalc.size(), 
            'Should detect Sent and Paid invoices needing recalculation');
        
        // Verify correct IDs
        System.assert(needingRecalc.contains(testInvoices.get('sent').Id), 'Should include Sent invoice');
        System.assert(needingRecalc.contains(testInvoices.get('paid').Id), 'Should include Paid invoice');
        System.assert(!needingRecalc.contains(testInvoices.get('draft').Id), 'Should not include Draft invoice');
        
        // Test empty list
        Set<Id> emptyRecalc = InvoiceValidator.getInvoicesNeedingRecalculation(new List<Invoice__c>());
        System.assertEquals(0, emptyRecalc.size(), 'Empty list should return empty set');
        
        Test.stopTest();
    }
    
    // ========== BULK OPERATIONS ==========
    
    @isTest
    static void testBulkOperations() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        
        // Create bulk invoices using scenario factory
        List<Invoice__c> invoices = TestScenarioFactory.createBulkDraftInvoices(acc.Id, 200);
        
        // Verify all got default values and tax calculation
        List<Invoice__c> insertedInvoices = [SELECT Status__c, Tax_Rate__c 
                                            FROM Invoice__c WHERE Id IN :invoices];
        
        for (Invoice__c inv : insertedInvoices) {
            System.assertEquals('Draft', inv.Status__c, 'All should have default status');
            System.assertEquals(22.0, inv.Tax_Rate__c, 'All should have Italy tax rate');
        }
        
        // Test bulk validation failure with invalid dates
        List<Invoice__c> invalidInvoices = new List<Invoice__c>();
        for (Integer i = 0; i < 50; i++) {
            invalidInvoices.add(TestDataFactory.createInvoiceWithInvalidDates(acc.Id));
        }
        
        try {
            insert invalidInvoices;
            System.assert(false, 'Bulk invalid dates should fail');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Due date cannot be before'));
        }
        
        Test.stopTest();
    }
    
    // ========== EDGE CASES ==========
    
    @isTest
    static void testEdgeCases() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        
        // Test all validator methods with empty lists
        InvoiceValidator.validateBusinessRules(new List<Invoice__c>(), false);
        InvoiceValidator.setDefaults(new List<Invoice__c>());
        InvoiceValidator.calculateTaxAmounts(new List<Invoice__c>());
        InvoiceValidator.generateInvoiceNumbers(new List<Invoice__c>());
        
        Set<Id> emptyResult = InvoiceValidator.getInvoicesNeedingRecalculation(new List<Invoice__c>());
        System.assertEquals(0, emptyResult.size(), 'Empty list should return empty set');
        
        // Test null account in tax calculation
        List<Invoice__c> nullAccountInvoices = new List<Invoice__c>{
            new Invoice__c(Account__c = null)
        };
        InvoiceValidator.calculateTaxAmounts(nullAccountInvoices); // Should handle gracefully
        
        
        Test.stopTest();
    }
}
/**
 * @description Test class for InvoiceAutomationService
 * @author Antonio Franco
 * @date 2025-01-09
 */
@isTest
private class InvoiceAutomationServiceTest {
    
    @testSetup
    static void setupTestData() {
        Account testAccount = TestDataFactory.createAccount();
        insert testAccount;
    }
    
    // ========== PROCESS NEW INVOICES ==========
    
    @isTest
    static void testProcessNewInvoicesCreatesTask() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        // Create draft invoice
        Invoice__c invoice = new Invoice__c(
            Account__c = acc.Id,
            Status__c = Constants.INVOICE_STATUS_DRAFT,
            Invoice_Date__c = Date.today(),
            Due_Date__c = Date.today().addDays(30)
        );
        insert invoice;
        
        Test.startTest();
        InvoiceAutomationService.processNewInvoices(new Set<Id>{invoice.Id});
        Test.stopTest();
        
        // Verify follow-up task created
        List<Task> tasks = [SELECT Subject, WhatId FROM Task WHERE WhatId = :invoice.Id];
        System.assertEquals(1, tasks.size(), 'Follow-up task should be created');
        System.assert(tasks[0].Subject.contains('Invoice'), 'Task should be invoice follow-up');
    }
    
    @isTest
    static void testProcessNewInvoicesEmptySet() {
        Test.startTest();
        InvoiceAutomationService.processNewInvoices(new Set<Id>());
        Test.stopTest();
        
        // Verify no tasks created
        List<Task> tasks = [SELECT Id FROM Task];
        System.assertEquals(0, tasks.size(), 'No tasks should be created for empty set');
    }
    
    // ========== PROCESS STATUS CHANGES ==========
    
    @isTest
    static void testProcessPaidInvoiceCreatesTask() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        // Create DRAFT invoice first
        Invoice__c invoice = new Invoice__c(
            Account__c = acc.Id,
            Status__c = Constants.INVOICE_STATUS_DRAFT,
            Invoice_Date__c = Date.today(),
            Due_Date__c = Date.today().addDays(30),
            Balance_Due__c = 0
        );
        insert invoice;
        
        // Add line item
        Invoice_Line_Item__c lineItem = new Invoice_Line_Item__c(
            Invoice__c = invoice.Id,
            Description__c = 'Test Item',
            Quantity__c = 1,
            Unit_Price__c = 100
        );
        insert lineItem;
        
        // Update to SENT (now has subtotal)
        invoice.Status__c = Constants.INVOICE_STATUS_SENT;
        update invoice;
        
        // Delete any tasks created by status change to SENT
        delete [SELECT Id FROM Task WHERE WhatId = :invoice.Id];
        
        Test.startTest();
        // Then mark as PAID - trigger will call processStatusChanges()
        invoice.Status__c = Constants.INVOICE_STATUS_PAID;
        update invoice;
        Test.stopTest();
        
        // Verify payment received task created
        List<Task> tasks = [SELECT Subject FROM Task WHERE WhatId = :invoice.Id];
        System.assertEquals(1, tasks.size(), 'Payment task should be created');
        System.assert(tasks[0].Subject.contains('Payment'), 'Should be payment received task');
    }
    
        @isTest
    static void testProcessOverdueInvoiceCreatesTask() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        // Create invoice in DRAFT first
        Invoice__c invoice = new Invoice__c(
            Account__c = acc.Id,
            Status__c = Constants.INVOICE_STATUS_DRAFT,
            Invoice_Date__c = Date.today().addDays(-40),
            Due_Date__c = Date.today().addDays(-10)
        );
        insert invoice;
        
        // Add line item
        Invoice_Line_Item__c lineItem = new Invoice_Line_Item__c(
            Invoice__c = invoice.Id,
            Description__c = 'Test Item',
            Quantity__c = 1,
            Unit_Price__c = 100
        );
        insert lineItem;
        
        // Update to SENT
        invoice.Status__c = Constants.INVOICE_STATUS_SENT;
        update invoice;
        
        // Delete any tasks created by status change to SENT
        delete [SELECT Id FROM Task WHERE WhatId = :invoice.Id];
        
        Test.startTest();
        // Mark as OVERDUE - trigger will call processStatusChanges()
        invoice.Status__c = Constants.INVOICE_STATUS_OVERDUE;
        update invoice;
        Test.stopTest();
        
        // Verify overdue task created
        List<Task> tasks = [SELECT Subject FROM Task WHERE WhatId = :invoice.Id];
        System.assertEquals(1, tasks.size(), 'Overdue task should be created');
        System.assert(tasks[0].Subject.contains('Overdue') || tasks[0].Subject.contains('URGENT'), 'Should be overdue task');
    }
    
    @isTest
    static void testProcessStatusChangesEmptySet() {
        Test.startTest();
        InvoiceAutomationService.processStatusChanges(new Set<Id>());
        Test.stopTest();
        
        // Verify no tasks created
        List<Task> tasks = [SELECT Id FROM Task];
        System.assertEquals(0, tasks.size(), 'No tasks for empty set');
    }
    
    @isTest
    static void testProcessDraftInvoiceNoTask() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        // Create draft invoice (no status change automation)
        Invoice__c invoice = new Invoice__c(
            Account__c = acc.Id,
            Status__c = Constants.INVOICE_STATUS_DRAFT
        );
        insert invoice;
        
        Test.startTest();
        InvoiceAutomationService.processStatusChanges(new Set<Id>{invoice.Id});
        Test.stopTest();
        
        // Verify no status task created (draft doesn't trigger automation)
        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId = :invoice.Id];
        System.assertEquals(0, tasks.size(), 'Draft status should not create task');
    }
}

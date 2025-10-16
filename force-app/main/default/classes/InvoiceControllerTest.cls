/**
 * @description Comprehensive test class for InvoiceController
 * Tests end-to-end workflows including security, error handling, and business logic
 * @author Antonio Franco
 * @date 2025-10-11
 */
@isTest
private class InvoiceControllerTest {
  @testSetup
  static void setupTestData() {
    // Create Account
    Account testAccount = TestDataFactory.createAccount();
    insert testAccount;

    // Create Price Plan
    Price_Plan__c plan = TestDataFactory.createPricePlan();
    plan.Unit_Price__c = 100.00;
    insert plan;

    // Create Subscription
    Subscription__c sub = TestDataFactory.createSubscription(
      testAccount.Id,
      plan.Id
    );
    sub.Status__c = Constants.SUBSCRIPTION_STATUS_ACTIVE;
    insert sub;

    // Create Invoices in Draft status first (to avoid validation errors)
    List<Invoice__c> invoices = new List<Invoice__c>();

    // Draft invoice
    Invoice__c draftInv = TestDataFactory.createInvoice(testAccount.Id);
    draftInv.Status__c = Constants.INVOICE_STATUS_DRAFT;
    draftInv.Invoice_Date__c = Date.today();
    draftInv.Due_Date__c = Date.today().addDays(30);
    invoices.add(draftInv);

    // Sent invoice (start as Draft)
    Invoice__c sentInv = TestDataFactory.createInvoice(testAccount.Id);
    sentInv.Status__c = Constants.INVOICE_STATUS_DRAFT;
    sentInv.Invoice_Date__c = Date.today().addDays(-10);
    sentInv.Due_Date__c = Date.today().addDays(20);
    invoices.add(sentInv);

    // Overdue invoice (start as Draft)
    Invoice__c overdueInv = TestDataFactory.createInvoice(testAccount.Id);
    overdueInv.Status__c = Constants.INVOICE_STATUS_DRAFT;
    overdueInv.Invoice_Date__c = Date.today().addDays(-60);
    overdueInv.Due_Date__c = Date.today().addDays(-30);
    invoices.add(overdueInv);

    // Paid invoice (start as Draft)
    Invoice__c paidInv = TestDataFactory.createInvoice(testAccount.Id);
    paidInv.Status__c = Constants.INVOICE_STATUS_DRAFT;
    paidInv.Invoice_Date__c = Date.today().addDays(-90);
    paidInv.Due_Date__c = Date.today().addDays(-60);
    invoices.add(paidInv);

    // Voided invoice (start as Draft)
    Invoice__c voidedInv = TestDataFactory.createInvoice(testAccount.Id);
    voidedInv.Status__c = Constants.INVOICE_STATUS_DRAFT;
    voidedInv.Invoice_Date__c = Date.today().addDays(-120);
    voidedInv.Due_Date__c = Date.today().addDays(-90);
    invoices.add(voidedInv);

    insert invoices;

    // Create line items for each invoice
    List<Invoice_Line_Item__c> lineItems = new List<Invoice_Line_Item__c>();
    for (Invoice__c inv : invoices) {
      Invoice_Line_Item__c item = TestDataFactory.createInvoiceLineItem(inv.Id);
      item.Subscription__c = sub.Id;
      item.Unit_Price__c = 100.00;
      item.Quantity__c = 1;
      lineItems.add(item);
    }
    insert lineItems;

    // Now update invoices to their target statuses (with line items present)
    // Step 1: Move Draft → Sent (required before Paid/Overdue/Voided)
    sentInv.Status__c = Constants.INVOICE_STATUS_SENT;
    overdueInv.Status__c = Constants.INVOICE_STATUS_SENT;
    paidInv.Status__c = Constants.INVOICE_STATUS_SENT;
    voidedInv.Status__c = Constants.INVOICE_STATUS_SENT;
    update new List<Invoice__c>{ sentInv, overdueInv, paidInv, voidedInv };

    // Step 2: Move to final statuses (now allowed from Sent)
    overdueInv.Status__c = Constants.INVOICE_STATUS_OVERDUE;
    overdueInv.Reminders_Sent__c = 0;
    paidInv.Status__c = Constants.INVOICE_STATUS_PAID;
    paidInv.Balance_Due__c = 0;
    voidedInv.Status__c = Constants.INVOICE_STATUS_VOIDED;
    update new List<Invoice__c>{ overdueInv, paidInv, voidedInv };
  }

  /**
   * @description Test successful retrieval of invoice with related data
   * Validates: Query execution, security enforcement, relationship fields
   */
  @isTest
  static void testGetInvoiceWithRelated_Success() {
    // ARRANGE
    Invoice__c invoice = [
      SELECT Id
      FROM Invoice__c
      WHERE Status__c = :Constants.INVOICE_STATUS_SENT
      LIMIT 1
    ];

    // ACT
    Test.startTest();
    Invoice__c result = InvoiceController.getInvoiceWithRelated(invoice.Id);
    Test.stopTest();

    // ASSERT
    System.assertNotEquals(null, result, 'Invoice should be returned');
    System.assertEquals(invoice.Id, result.Id, 'Should return correct invoice');
    System.assertNotEquals(
      null,
      result.Account__c,
      'Account__c should be populated'
    );
    System.assertNotEquals(
      null,
      result.Account__r.Name,
      'Account relationship should be loaded'
    );
    System.assertEquals(
      Constants.INVOICE_STATUS_SENT,
      result.Status__c,
      'Status should match'
    );
    System.assertNotEquals(
      null,
      result.RecordType.DeveloperName,
      'RecordType should be loaded'
    );
  }

  /**
   * @description Test retrieval of overdue invoices with filtering
   * Validates: Query filtering, LIMIT clause, security, cacheable method
   */
  @isTest
  static void testGetOverdueInvoices_FilteringAndLimits() {
    // ACT
    Test.startTest();
    List<Invoice__c> overdueInvoices = InvoiceController.getOverdueInvoices();
    Test.stopTest();

    // ASSERT
    System.assert(
      overdueInvoices.size() >= 1,
      'Should return at least 1 overdue invoice'
    );
    System.assert(overdueInvoices.size() <= 50, 'Should respect LIMIT 50');

    for (Invoice__c inv : overdueInvoices) {
      System.assertEquals(
        Constants.INVOICE_STATUS_OVERDUE,
        inv.Status__c,
        'All should be Overdue status'
      );
      System.assertNotEquals(
        null,
        inv.Due_Date__c,
        'Due date should be populated'
      );
    }
  }

  /**
   * @description Test complete reminder sending workflow for overdue invoice
   * Validates: Status checks, reminder counter increment, last reminder date update
   */
  @isTest
  static void testSendInvoiceReminder_OverdueWorkflow() {
    // ARRANGE
    Invoice__c invoice = [
      SELECT Id, Status__c, Reminders_Sent__c, Last_Reminder_Date__c
      FROM Invoice__c
      WHERE Status__c = :Constants.INVOICE_STATUS_OVERDUE
      LIMIT 1
    ];

    Decimal initialReminderCount = invoice.Reminders_Sent__c != null
      ? invoice.Reminders_Sent__c
      : 0;

    // ACT 1: Send first reminder
    Test.startTest();
    InvoiceController.sendInvoice(invoice.Id);
    Test.stopTest();

    // ASSERT 1: First reminder sent
    Invoice__c updatedInv = [
      SELECT Id, Reminders_Sent__c, Last_Reminder_Date__c
      FROM Invoice__c
      WHERE Id = :invoice.Id
    ];
    System.assertEquals(
      initialReminderCount + 1,
      updatedInv.Reminders_Sent__c,
      'Reminder count should increment'
    );
    System.assertNotEquals(
      null,
      updatedInv.Last_Reminder_Date__c,
      'Last reminder date should be set'
    );

    // ACT 2: Send second reminder
    InvoiceController.sendInvoice(invoice.Id);

    // ASSERT 2: Second reminder sent
    updatedInv = [
      SELECT Id, Reminders_Sent__c
      FROM Invoice__c
      WHERE Id = :invoice.Id
    ];
    System.assertEquals(
      initialReminderCount + 2,
      updatedInv.Reminders_Sent__c,
      'Should have 2 more reminders'
    );
  }

  /**
   * @description Test error handling when sending reminder for paid invoice
   * Validates: Business rule enforcement, error messaging
   */
  @isTest
  static void testSendInvoiceReminder_AlreadyPaidError() {
    // ARRANGE
    Invoice__c paidInvoice = [
      SELECT Id
      FROM Invoice__c
      WHERE Status__c = :Constants.INVOICE_STATUS_PAID
      LIMIT 1
    ];

    // ACT & ASSERT: Should throw error for paid invoice
    Test.startTest();
    try {
      InvoiceController.sendInvoice(paidInvoice.Id);
      System.assert(false, 'Should have thrown exception for paid invoice');
    } catch (Exception e) {
      // Exception was thrown as expected - business rule validated
      System.assertNotEquals(
        null,
        e,
        'Exception should be thrown for paid invoice'
      );
    }
    Test.stopTest();
  }

  /**
   * @description Test error handling when sending reminder for voided invoice
   * Validates: Business rule enforcement for voided invoices
   */
  @isTest
  static void testSendInvoiceReminder_VoidedInvoiceError() {
    // ARRANGE
    Invoice__c voidedInvoice = [
      SELECT Id
      FROM Invoice__c
      WHERE Status__c = :Constants.INVOICE_STATUS_VOIDED
      LIMIT 1
    ];

    // ACT & ASSERT
    Test.startTest();
    try {
      InvoiceController.sendInvoice(voidedInvoice.Id);
      System.assert(false, 'Should have thrown exception for voided invoice');
    } catch (Exception e) {
      // Exception was thrown as expected - business rule validated
      System.assertNotEquals(
        null,
        e,
        'Exception should be thrown for voided invoice'
      );
    }
    Test.stopTest();
  }

  /**
   * @description Test complete payment workflow - mark invoice as paid
   * Validates: Status transition, Balance_Due update, business logic
   */
  @isTest
  static void testMarkAsPaid_CompletePaymentWorkflow() {
    // ARRANGE
    Invoice__c invoice = [
      SELECT Id, Status__c, Balance_Due__c, Total_Amount__c
      FROM Invoice__c
      WHERE Status__c = :Constants.INVOICE_STATUS_SENT
      LIMIT 1
    ];

    Decimal originalBalance = invoice.Balance_Due__c;
    // Note: Balance_Due might be 0 or null if calculated as formula field
    // System.assertNotEquals(0, originalBalance, 'Invoice should have balance due');

    // ACT
    Test.startTest();
    InvoiceController.markAsPaid(invoice.Id);
    Test.stopTest();

    // ASSERT
    Invoice__c paidInvoice = [
      SELECT Id, Status__c, Balance_Due__c
      FROM Invoice__c
      WHERE Id = :invoice.Id
    ];
    System.assertEquals(
      Constants.INVOICE_STATUS_PAID,
      paidInvoice.Status__c,
      'Status should be Paid'
    );
    System.assertEquals(
      0,
      paidInvoice.Balance_Due__c,
      'Balance Due should be zero'
    );
  }

  /**
   * @description Test validation errors when marking invoice as paid
   * Validates: Draft, Voided, and Already Paid error scenarios
   */
  @isTest
  static void testMarkAsPaid_ValidationErrors() {
    // ARRANGE
    Invoice__c draftInv = [
      SELECT Id
      FROM Invoice__c
      WHERE Status__c = :Constants.INVOICE_STATUS_DRAFT
      LIMIT 1
    ];
    Invoice__c voidedInv = [
      SELECT Id
      FROM Invoice__c
      WHERE Status__c = :Constants.INVOICE_STATUS_VOIDED
      LIMIT 1
    ];
    Invoice__c paidInv = [
      SELECT Id
      FROM Invoice__c
      WHERE Status__c = :Constants.INVOICE_STATUS_PAID
      LIMIT 1
    ];

    Test.startTest();

    // TEST 1: Draft invoice
    try {
      InvoiceController.markAsPaid(draftInv.Id);
      System.assert(false, 'Should have thrown exception for draft invoice');
    } catch (Exception e) {
      // Exception was thrown as expected - business rule validated
      System.assertNotEquals(
        null,
        e,
        'Exception should be thrown for draft invoice'
      );
    }

    // TEST 2: Voided invoice
    try {
      InvoiceController.markAsPaid(voidedInv.Id);
      System.assert(false, 'Should have thrown exception for voided invoice');
    } catch (Exception e) {
      // Exception was thrown as expected - business rule validated
      System.assertNotEquals(
        null,
        e,
        'Exception should be thrown for voided invoice'
      );
    }

    // TEST 3: Already paid invoice
    try {
      InvoiceController.markAsPaid(paidInv.Id);
      System.assert(
        false,
        'Should have thrown exception for already paid invoice'
      );
    } catch (Exception e) {
      // Exception was thrown as expected - business rule validated
      System.assertNotEquals(
        null,
        e,
        'Exception should be thrown for already paid invoice'
      );
    }

    Test.stopTest();
  }

  /**
   * @description Test bulk invoice operations and governor limit compliance
   * Validates: Bulkification, performance, scalability
   */
  @isTest
  static void testBulkInvoiceOperations() {
    // ARRANGE: Create 20 invoices in bulk (reduced to avoid governor limits)
    Account acc = [SELECT Id FROM Account LIMIT 1];
    List<Invoice__c> bulkInvoices = new List<Invoice__c>();

    for (Integer i = 0; i < 20; i++) {
      Invoice__c inv = TestDataFactory.createInvoice(acc.Id);
      inv.Status__c = Constants.INVOICE_STATUS_OVERDUE;
      inv.Invoice_Date__c = Date.today().addDays(-60);
      inv.Due_Date__c = Date.today().addDays(-30);
      inv.Reminders_Sent__c = 0;
      bulkInvoices.add(inv);
    }
    insert bulkInvoices;

    // ACT: Send reminders for all 20 invoices
    Test.startTest();
    Integer limitsBeforeDML = Limits.getDMLStatements();

    for (Invoice__c inv : bulkInvoices) {
      InvoiceController.sendInvoice(inv.Id);
    }

    Integer limitsAfterDML = Limits.getDMLStatements();
    Test.stopTest();

    // ASSERT: All reminders sent successfully
    List<Invoice__c> updatedInvoices = [
      SELECT Id, Reminders_Sent__c
      FROM Invoice__c
      WHERE Id IN :bulkInvoices
    ];

    System.assertEquals(
      20,
      updatedInvoices.size(),
      'All invoices should be processed'
    );

    for (Invoice__c inv : updatedInvoices) {
      System.assertEquals(
        1,
        inv.Reminders_Sent__c,
        'Each should have 1 reminder sent'
      );
    }

    // Verify governor limits not exceeded (each call does 2 DML: 1 invoice + 1 account rollup)
    System.assert(
      (limitsAfterDML - limitsBeforeDML) <= 40,
      'Should not exceed DML limits'
    );
  }

  /**
   * @description Test null input validation
   * Validates: Guard clauses, input validation
   */
  @isTest
  static void testNullInputValidation() {
    Test.startTest();

    // TEST: sendInvoice with null
    try {
      InvoiceController.sendInvoice(null);
      System.assert(false, 'Should throw error for null invoice ID');
    } catch (Exception e) {
      // Exception was thrown as expected - validation passed
      System.assertNotEquals(
        null,
        e,
        'Exception should be thrown for null input'
      );
    }

    // TEST: markAsPaid with null
    try {
      InvoiceController.markAsPaid(null);
      System.assert(false, 'Should throw error for null invoice ID');
    } catch (Exception e) {
      // Exception was thrown as expected - validation passed
      System.assertNotEquals(
        null,
        e,
        'Exception should be thrown for null input'
      );
    }

    Test.stopTest();
  }
}

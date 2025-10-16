/**
 * @description Controller for Invoice LWC
 * @author Antonio Franco
 * @date 2025-09-16
 */
public with sharing class InvoiceController {
  @AuraEnabled(cacheable=false)
  public static Invoice__c getInvoiceWithRelated(Id invoiceId) {
    return [
      SELECT
        Id,
        Name,
        Account__c,
        Account__r.Name,
        Account__r.Type,
        Status__c,
        Invoice_Date__c,
        Due_Date__c,
        Payment_Terms__c,
        Tax_Rate__c,
        Subtotal__c,
        Tax_Amount__c,
        Total_Amount__c,
        Balance_Due__c,
        RecordType.DeveloperName
      FROM Invoice__c
      WHERE Id = :invoiceId
      WITH SECURITY_ENFORCED
      LIMIT 1
    ];
  }

  @AuraEnabled(cacheable=true)
  public static List<Invoice__c> getInvoicesByAccount(Id accountId) {
    return [
      SELECT
        Id,
        Name,
        Account__c,
        Account__r.Name,
        Status__c,
        Invoice_Date__c,
        Due_Date__c,
        Total_Amount__c,
        Balance_Due__c,
        RecordType.DeveloperName
      FROM Invoice__c
      WHERE Account__c = :accountId
      WITH SECURITY_ENFORCED
      ORDER BY Invoice_Date__c DESC
      LIMIT 100
    ];
  }

  @AuraEnabled(cacheable=true)
  public static List<Invoice__c> getRecentInvoices() {
    return [
      SELECT
        Id,
        Name,
        Account__c,
        Account__r.Name,
        Status__c,
        Invoice_Date__c,
        Due_Date__c,
        Total_Amount__c,
        Balance_Due__c,
        RecordType.DeveloperName
      FROM Invoice__c
      WITH SECURITY_ENFORCED
      ORDER BY Invoice_Date__c DESC
      LIMIT 50
    ];
  }

  @AuraEnabled(cacheable=true)
  public static List<Invoice__c> getOverdueInvoices() {
    List<Invoice__c> invoices = [
      SELECT
        Id,
        Name,
        Account__c,
        Account__r.Name,
        Status__c,
        Due_Date__c,
        Total_Amount__c,
        Balance_Due__c,
        Reminders_Sent__c,
        Last_Reminder_Date__c
      FROM Invoice__c
      WHERE Status__c = :Constants.INVOICE_STATUS_OVERDUE
      ORDER BY Due_Date__c ASC
      LIMIT 50
    ];

    SObjectAccessDecision decision = Security.stripInaccessible(
      AccessType.READABLE,
      invoices
    );

    return decision.getRecords();
  }

  /**
   * @description Send payment reminder for overdue invoice
   * @param invoiceId The ID of the invoice to send reminder for
   * @throws AuraHandledException if validation fails or DML error occurs
   */
  @AuraEnabled
  public static void sendInvoice(Id invoiceId) {
    // Guard clause: validate input
    if (invoiceId == null) {
      throw new AuraHandledException('Invoice ID is required');
    }

    // Query invoice with security enforced
    List<Invoice__c> invoices;
    try {
      invoices = [
        SELECT Id, Status__c, Reminders_Sent__c, Last_Reminder_Date__c
        FROM Invoice__c
        WHERE Id = :invoiceId
        WITH SECURITY_ENFORCED
        LIMIT 1
      ];
    } catch (QueryException e) {
      throw new AuraHandledException(
        'Invoice not found or insufficient permissions'
      );
    }

    // Early return: check if invoice exists
    if (invoices.isEmpty()) {
      throw new AuraHandledException(
        'Invoice not found or you do not have access'
      );
    }

    Invoice__c invoice = invoices[0];

    // Early return validations: check status before sending
    if (invoice.Status__c == Constants.INVOICE_STATUS_PAID) {
      throw new AuraHandledException(
        'Cannot send reminder for an invoice that is already paid'
      );
    }

    if (invoice.Status__c == Constants.INVOICE_STATUS_VOIDED) {
      throw new AuraHandledException(
        'Cannot send reminder for a voided invoice'
      );
    }

    // Happy path: increment reminder counter and update
    invoice.Reminders_Sent__c =
      (invoice.Reminders_Sent__c == null ? 0 : invoice.Reminders_Sent__c) + 1;
    invoice.Last_Reminder_Date__c = System.now();

    try {
      update invoice;
    } catch (DmlException e) {
      throw new AuraHandledException(
        'Error sending reminder: ' + e.getMessage()
      );
    }
  }

  /**
   * @description Mark invoice as paid by changing status to 'Paid' and Balance_Due to 0
   * @param invoiceId The ID of the invoice to mark as paid
   * @throws AuraHandledException if validation fails or DML error occurs
   */
  @AuraEnabled
  public static void markAsPaid(Id invoiceId) {
    // Guard clause: validate input
    if (invoiceId == null) {
      throw new AuraHandledException('Invoice ID is required');
    }

    // Query invoice with security enforced
    Invoice__c invoice;
    try {
      invoice = [
        SELECT Id, Status__c, Balance_Due__c, Total_Amount__c
        FROM Invoice__c
        WHERE Id = :invoiceId
        WITH SECURITY_ENFORCED
        LIMIT 1
      ];
    } catch (QueryException e) {
      throw new AuraHandledException(
        'Invoice not found or insufficient permissions'
      );
    }

    // Early return validations: check status before attempting update
    // Note: Draft → Paid validation is handled by Validation Rule (Cannot_Pay_Draft_Invoice)

    if (invoice.Status__c == Constants.INVOICE_STATUS_VOIDED) {
      throw new AuraHandledException('Cannot mark a voided invoice as paid');
    }

    if (invoice.Status__c == Constants.INVOICE_STATUS_PAID) {
      throw new AuraHandledException('Invoice is already marked as paid');
    }

    // Happy path: update invoice
    invoice.Status__c = Constants.INVOICE_STATUS_PAID;
    invoice.Balance_Due__c = 0;

    try {
      update invoice;
    } catch (DmlException e) {
      throw new AuraHandledException(
        'Error marking invoice as paid: ' + e.getMessage()
      );
    }
  }
}

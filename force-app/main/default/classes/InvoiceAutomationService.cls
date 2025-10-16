/**
 * @description Native Salesforce automation for invoice lifecycle management
 * @author Antonio Franco
 * @date 2025-09-24
 * @story STORY-006: Platform Events & Integration Layer (Simplified)
 */
public class InvoiceAutomationService {
  /**
   * @description Handles new invoice automation
   * @param invoiceIds Set of invoice IDs to process
   */
  public static void processNewInvoices(Set<Id> invoiceIds) {
    if (invoiceIds.isEmpty())
      return;

    List<Invoice__c> invoices = [
      SELECT
        Id,
        Name,
        Account__c,
        Account__r.Name,
        Status__c,
        Total_Amount__c,
        Due_Date__c,
        Invoice_Date__c
      FROM Invoice__c
      WHERE Id IN :invoiceIds
      WITH SECURITY_ENFORCED
    ];

    List<Task> followUpTasks = new List<Task>();

    for (Invoice__c invoice : invoices) {
      // Create payment follow-up task
      Task followUp = new Task(
        Subject = 'Invoice Follow-up - ' + invoice.Account__r?.Name,
        Description = 'Follow up on invoice ' +
          invoice.Name +
          ' payment status',
        WhatId = invoice.Id,
        Status = 'Not Started',
        Priority = 'Normal',
        ActivityDate = invoice.Due_Date__c?.addDays(-5) // 5 days before due date
      );
      followUpTasks.add(followUp);
    }

    if (!followUpTasks.isEmpty()) {
      insert followUpTasks;
    }

    // Update account payment metrics
    updateAccountPaymentMetrics(invoices);
  }

  /**
   * @description Handles invoice status changes - Creates tasks and updates metrics
   * Email notifications are handled via Flow for easier maintenance
   * @param invoiceIds Set of invoice IDs with status changes
   */
  public static void processStatusChanges(Set<Id> invoiceIds) {
    if (invoiceIds.isEmpty()) {
      return;
    }

    List<Invoice__c> invoices = [
      SELECT
        Id,
        Name,
        Account__c,
        Account__r.Name,
        Status__c,
        Total_Amount__c,
        Due_Date__c,
        Invoice_Date__c
      FROM Invoice__c
      WHERE Id IN :invoiceIds
      WITH SECURITY_ENFORCED
    ];

    List<Task> statusTasks = new List<Task>();

    // Create tasks based on invoice status
    for (Invoice__c invoice : invoices) {
      if (invoice.Status__c == Constants.INVOICE_STATUS_PAID) {
        statusTasks.add(createPaymentReceivedTask(invoice));
      } else if (invoice.Status__c == Constants.INVOICE_STATUS_OVERDUE) {
        statusTasks.add(createOverdueTask(invoice));
      }
    }

    if (!statusTasks.isEmpty()) {
      insert statusTasks;
    }

    // Update account payment metrics
    updateAccountPaymentMetrics(invoices);
  }

  /**
   * @description Creates task for payment received
   */
  private static Task createPaymentReceivedTask(Invoice__c invoice) {
    return new Task(
      Subject = 'Payment Received - Thank ' + invoice.Account__r?.Name,
      Description = 'Payment received for invoice ' +
        invoice.Name +
        '. Send thank you note and check for upsell opportunities.',
      WhatId = invoice.Id,
      Status = 'Not Started',
      Priority = 'Normal',
      ActivityDate = Date.today().addDays(1)
    );
  }

  /**
   * @description Creates urgent task for overdue invoice
   */
  private static Task createOverdueTask(Invoice__c invoice) {
    return new Task(
      Subject = 'URGENT: Overdue Payment - ' + invoice.Account__r?.Name,
      Description = 'Invoice ' +
        invoice.Name +
        ' is overdue. Contact customer immediately to resolve payment.',
      WhatId = invoice.Id,
      Status = 'Not Started',
      Priority = 'High',
      ActivityDate = Date.today()
    );
  }

  /**
   * @description Updates account payment metrics based on invoice data
   */
  private static void updateAccountPaymentMetrics(List<Invoice__c> invoices) {
    Set<Id> accountIds = new Set<Id>();
    for (Invoice__c inv : invoices) {
      if (inv.Account__c != null) {
        accountIds.add(inv.Account__c);
      }
    }

    if (accountIds.isEmpty())
      return;

    // Calculate payment metrics per account
    List<AggregateResult> paymentMetrics = [
      SELECT
        Account__c,
        SUM(Total_Amount__c) totalBilled,
        COUNT_DISTINCT(Id) invoiceCount,
        AVG(Total_Amount__c) avgInvoiceAmount
      FROM Invoice__c
      WHERE
        Account__c IN :accountIds
        AND Status__c IN (
          :Constants.INVOICE_STATUS_SENT,
          :Constants.INVOICE_STATUS_PAID,
          :Constants.INVOICE_STATUS_OVERDUE
        )
      GROUP BY Account__c
    ];

    List<Account> accountsToUpdate = new List<Account>();

    for (AggregateResult metric : paymentMetrics) {
      Id accountId = (Id) metric.get('Account__c');
      Decimal totalBilled = (Decimal) metric.get('totalBilled');
      Integer invoiceCount = (Integer) metric.get('invoiceCount');
      Decimal avgAmount = (Decimal) metric.get('avgInvoiceAmount');

      Account acc = new Account(
        Id = accountId,
        Total_Billed__c = totalBilled,
        Invoice_Count__c = invoiceCount,
        Average_Invoice_Amount__c = avgAmount,
        Last_Invoice_Date__c = Date.today()
      );
      accountsToUpdate.add(acc);
    }

    if (!accountsToUpdate.isEmpty()) {
      update accountsToUpdate;
    }
  }
}

/**
 * Scheduled Batch Job to automatically mark overdue invoices
 *
 * PURPOSE: Runs daily to identify invoices with Status = 'Sent' and Due_Date < TODAY,
 * then updates them to Status = 'Overdue'. This triggers automation for overdue tasks.
 *
 * SCHEDULE: Recommended to run daily at 2 AM
 * Example: System.schedule('Invoice Overdue Check', '0 0 2 * * ?', new InvoiceOverdueBatch());
 *
 * @author Antonio Franco
 * @date 2025-10-14
 */
public class InvoiceOverdueBatch implements Database.Batchable<sObject>, Schedulable {

    // Batch size for processing (default 200)
    private static final Integer BATCH_SIZE = 200;

    /**
     * Schedulable execute method - schedules the batch job
     */
    public void execute(SchedulableContext sc) {
        Database.executeBatch(this, BATCH_SIZE);
    }

    /**
     * Batch start method - queries invoices that are overdue
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Query invoices:
        // - Status = 'Sent' (not already marked overdue)
        // - Due_Date__c < TODAY (past due)
        // - Balance_Due__c > 0 (not fully paid)
        return Database.getQueryLocator([
            SELECT Id, Name, Account__c, Account__r.Name, Status__c,
                   Due_Date__c, Total_Amount__c, Balance_Due__c
            FROM Invoice__c
            WHERE Status__c = :Constants.INVOICE_STATUS_SENT
            AND Due_Date__c < TODAY
            AND Balance_Due__c > 0
            WITH SECURITY_ENFORCED
        ]);
    }

    /**
     * Batch execute method - marks invoices as overdue
     */
    public void execute(Database.BatchableContext bc, List<Invoice__c> invoices) {
        if (invoices == null || invoices.isEmpty()) {
            return;
        }

        // Update status to Overdue
        for (Invoice__c inv : invoices) {
            inv.Status__c = Constants.INVOICE_STATUS_OVERDUE;
        }

        // Update will trigger InvoiceTriggerHandler.afterUpdate()
        // which creates URGENT overdue tasks via InvoiceAutomationService
        try {
            update invoices;
            System.debug('Successfully marked ' + invoices.size() + ' invoices as overdue');
        } catch (DmlException e) {
            System.debug(LoggingLevel.ERROR, 'Error marking invoices as overdue: ' + e.getMessage());
            // In production, log to custom object or send alert
        }
    }

    /**
     * Batch finish method - logs completion
     */
    public void finish(Database.BatchableContext bc) {
        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                   TotalJobItems, CreatedDate, CompletedDate
            FROM AsyncApexJob
            WHERE Id = :bc.getJobId()
        ];

        System.debug('InvoiceOverdueBatch completed: ' +
                    job.TotalJobItems + ' batches, ' +
                    job.NumberOfErrors + ' errors');

        // In production: send summary email to finance team
    }
}

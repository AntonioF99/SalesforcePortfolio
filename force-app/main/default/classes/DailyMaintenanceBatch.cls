/**
 * Daily Maintenance Batch - Unified batch job for routine cleanup
 *
 * PURPOSE: Single batch that handles:
 * 1. Mark overdue invoices (Status: Sent → Overdue)
 * 2. Expire trial subscriptions (Status: Trial → Cancelled)
 *
 * SCHEDULE: Run daily at 2 AM
 * Example: System.schedule('Daily Maintenance', '0 0 2 * * ?', new DailyMaintenanceBatch());
 *
 * BENEFITS of unified approach:
 * - Single scheduler instead of two
 * - Shared transaction context
 * - Easier monitoring
 * - Reduced governor limit consumption
 *
 * @author Antonio Franco
 * @date 2025-10-16
 */
public class DailyMaintenanceBatch implements Database.Batchable<sObject>, Database.Stateful, Schedulable {

    // Batch size for processing
    private static final Integer BATCH_SIZE = 200;
    
    // Track results across batches
    private Integer invoicesProcessed = 0;
    private Integer subscriptionsProcessed = 0;
    private Integer totalErrors = 0;

    /**
     * Schedulable execute - schedules the batch
     */
    public void execute(SchedulableContext sc) {
        Database.executeBatch(this, BATCH_SIZE);
    }

    /**
     * Batch start - queries overdue invoices
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Name, Status__c, Due_Date__c, Total_Amount__c, Balance_Due__c
            FROM Invoice__c
            WHERE Status__c = 'Sent'
            AND Due_Date__c < TODAY
            AND Balance_Due__c > 0
            WITH SECURITY_ENFORCED
        ]);
    }

    /**
     * Batch execute - processes overdue invoices
     */
    public void execute(Database.BatchableContext bc, List<sObject> scope) {
        if (scope == null || scope.isEmpty()) {
            return;
        }

        List<Invoice__c> invoices = (List<Invoice__c>) scope;
        processOverdueInvoices(invoices);
    }

    /**
     * Batch finish - process subscriptions and send summary
     */
    public void finish(Database.BatchableContext bc) {
        // Now process expired trial subscriptions
        processExpiredTrials();

        // Log execution summary
        logExecutionSummary(bc);
        
        // Send email summary to admins (optional)
        sendAdminSummary(bc);
    }

    /**
     * Process overdue invoices
     */
    private void processOverdueInvoices(List<Invoice__c> invoices) {
        for (Invoice__c inv : invoices) {
            inv.Status__c = 'Overdue';
        }

        try {
            update invoices;
            invoicesProcessed += invoices.size();
            System.debug('Marked ' + invoices.size() + ' invoices as overdue');
        } catch (DmlException e) {
            totalErrors++;
            System.debug(LoggingLevel.ERROR, 'Error marking invoices as overdue: ' + e.getMessage());
        }
    }

    /**
     * Process expired trial subscriptions
     */
    private void processExpiredTrials() {
        List<Subscription__c> expiredTrials = [
            SELECT Id, Name, Status__c, Trial_End_Date__c
            FROM Subscription__c
            WHERE Status__c = 'Trial'
            AND Trial_End_Date__c < TODAY
            WITH SECURITY_ENFORCED
        ];

        if (expiredTrials.isEmpty()) {
            System.debug('No expired trials found');
            return;
        }

        // Update status to Cancelled with reason
        for (Subscription__c sub : expiredTrials) {
            sub.Status__c = 'Cancelled';
            sub.Cancellation_Reason__c = 'Trial period expired';
            sub.Cancellation_Date__c = Date.today();
        }

        try {
            update expiredTrials;
            subscriptionsProcessed = expiredTrials.size();
            System.debug('Expired ' + expiredTrials.size() + ' trial subscriptions');
        } catch (DmlException e) {
            totalErrors++;
            System.debug(LoggingLevel.ERROR, 'Error expiring trials: ' + e.getMessage());
        }
    }

    /**
     * Log execution summary
     */
    private void logExecutionSummary(Database.BatchableContext bc) {
        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems,
                   CreatedDate, CompletedDate
            FROM AsyncApexJob
            WHERE Id = :bc.getJobId()
        ];

        String summary = 'DailyMaintenanceBatch completed:\n' +
                        '- Invoices marked overdue: ' + invoicesProcessed + '\n' +
                        '- Trials expired: ' + subscriptionsProcessed + '\n' +
                        '- Total errors: ' + totalErrors + '\n' +
                        '- Job status: ' + job.Status + '\n' +
                        '- Batches processed: ' + job.JobItemsProcessed + '/' + job.TotalJobItems;

        System.debug(summary);
    }

    /**
     * Send email summary to system admins (optional)
     */
    private void sendAdminSummary(Database.BatchableContext bc) {
        // Skip in test context
        if (Test.isRunningTest()) {
            return;
        }

        // Only send email if there were errors or significant activity
        if (totalErrors > 0 || invoicesProcessed > 10 || subscriptionsProcessed > 5) {
            // TODO: Implement email notification to admins
            // Can use Messaging.SingleEmailMessage or custom notification
            System.debug('Email notification would be sent here');
        }
    }
}

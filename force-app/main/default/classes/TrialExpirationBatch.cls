/**
 * Scheduled Batch Job to automatically expire trial subscriptions
 *
 * PURPOSE: Runs daily to identify subscriptions with Status = 'Trial' and
 * Trial_End_Date__c < TODAY, then updates them to Status = 'Cancelled' with
 * appropriate cancellation reason.
 *
 * SCHEDULE: Recommended to run daily at 3 AM (after invoice overdue batch)
 * Example: System.schedule('Trial Expiration Check', '0 0 3 * * ?', new TrialExpirationBatch());
 *
 * @author Antonio Franco
 * @date 2025-10-14
 */
public class TrialExpirationBatch implements Database.Batchable<sObject>, Schedulable {

    // Batch size for processing (default 200)
    private static final Integer BATCH_SIZE = 200;

    /**
     * Schedulable execute method - schedules the batch job
     */
    public void execute(SchedulableContext sc) {
        Database.executeBatch(this, BATCH_SIZE);
    }

    /**
     * Batch start method - queries trial subscriptions that have expired
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Query subscriptions:
        // - Status = 'Trial' (not yet expired/converted)
        // - Trial_End_Date__c < TODAY (trial period ended)
        return Database.getQueryLocator([
            SELECT Id, Name, Account__c, Account__r.Name, Status__c,
                   Trial_End_Date__c, Start_Date__c, Price_Plan__c, Price_Plan__r.Name
            FROM Subscription__c
            WHERE Status__c = :Constants.SUBSCRIPTION_STATUS_TRIAL
            AND Trial_End_Date__c < TODAY
            WITH SECURITY_ENFORCED
        ]);
    }

    /**
     * Batch execute method - expires trial subscriptions
     */
    public void execute(Database.BatchableContext bc, List<Subscription__c> subscriptions) {
        if (subscriptions == null || subscriptions.isEmpty()) {
            return;
        }

        // Update status to Cancelled with trial expiration reason
        for (Subscription__c sub : subscriptions) {
            sub.Status__c = Constants.SUBSCRIPTION_STATUS_CANCELLED;
            sub.Cancellation_Reason__c = 'Trial Expired';
            sub.Cancellation_Comments__c = 'Trial period ended on ' +
                                          sub.Trial_End_Date__c.format() +
                                          '. Customer did not convert to paid subscription.';
            sub.Cancellation_Date__c = Date.today();
        }

        // Update will trigger SubscriptionTriggerHandler.afterUpdate()
        // which creates cancellation tasks and updates account health score
        try {
            update subscriptions;
            System.debug('Successfully expired ' + subscriptions.size() + ' trial subscriptions');
        } catch (DmlException e) {
            System.debug(LoggingLevel.ERROR, 'Error expiring trial subscriptions: ' + e.getMessage());
            // In production, log to custom object or send alert
        }
    }

    /**
     * Batch finish method - logs completion and sends summary
     */
    public void finish(Database.BatchableContext bc) {
        AsyncApexJob job = [
            SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                   TotalJobItems, CreatedDate, CompletedDate
            FROM AsyncApexJob
            WHERE Id = :bc.getJobId()
        ];

        System.debug('TrialExpirationBatch completed: ' +
                    job.TotalJobItems + ' batches, ' +
                    job.NumberOfErrors + ' errors');

        // In production: send summary email to customer success team
        // with list of expired trials for follow-up outreach
    }
}

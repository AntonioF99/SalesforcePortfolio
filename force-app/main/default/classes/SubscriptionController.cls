public with sharing class SubscriptionController {
    
    @AuraEnabled(cacheable=true)
    public static Subscription__c getSubscriptionWithRelated(Id subscriptionId) {
        List<Subscription__c> subscriptions = [
            SELECT Id, Name,
                   Account__c, Account__r.Name,
                   Price_Plan__c, Price_Plan__r.Name,
                   Status__c,
                   Quantity__c,
                   Start_Date__c,
                   Trial_End_Date__c,
                   Cancellation_Reason__c,
                   Cancellation_Comments__c,
                   Cancellation_Date__c,
                   MRR__c,
                   ARR__c,
                   Total_Contract_Value__c
            FROM Subscription__c
            WHERE Id = :subscriptionId
            LIMIT 1
        ];

        if (subscriptions.isEmpty()) {
            throw new AuraHandledException('Subscription not found or insufficient permissions');
        }

        SObjectAccessDecision decision = Security.stripInaccessible(
            AccessType.READABLE,
            subscriptions
        );

        return (Subscription__c) decision.getRecords()[0];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Subscription__c> getSubscriptionsByAccount(Id accountId) {
        List<Subscription__c> subscriptions = [
            SELECT Id, Name,
                   Account__c, Account__r.Name,
                   Price_Plan__c, Price_Plan__r.Name,
                   Status__c,
                   Start_Date__c,
                   MRR__c,
                   Total_Contract_Value__c
            FROM Subscription__c
            WHERE Account__c = :accountId
            ORDER BY Start_Date__c DESC
        ];

        SObjectAccessDecision decision = Security.stripInaccessible(
            AccessType.READABLE,
            subscriptions
        );

        return decision.getRecords();
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Subscription__c> getActiveSubscriptions() {
        List<Subscription__c> subscriptions = [
            SELECT Id, Name,
                   Account__c, Account__r.Name,
                   Price_Plan__c, Price_Plan__r.Name,
                   Status__c,
                   Start_Date__c,
                   MRR__c
            FROM Subscription__c
            WHERE Status__c IN (:Constants.SUBSCRIPTION_STATUS_ACTIVE, :Constants.SUBSCRIPTION_STATUS_TRIAL)
            ORDER BY Account__r.Name, Start_Date__c DESC
        ];

        SObjectAccessDecision decision = Security.stripInaccessible(
            AccessType.READABLE,
            subscriptions
        );

        return decision.getRecords();
    }

    /**
     * @description Activate subscription by changing status to 'Active'
     * @param subscriptionId The ID of the subscription to activate
     * @throws AuraHandledException if validation fails or DML error occurs
     */
    @AuraEnabled
    public static void activateSubscription(Id subscriptionId) {
        // Guard clause: validate input
        if (subscriptionId == null) {
            throw new AuraHandledException('Subscription ID is required');
        }

        // Query subscription
        List<Subscription__c> subscriptions;
        try {
            subscriptions = [
                SELECT Id, Status__c, Price_Plan__c
                FROM Subscription__c
                WHERE Id = :subscriptionId
                LIMIT 1
            ];
        } catch (QueryException e) {
            throw new AuraHandledException('Subscription not found or insufficient permissions');
        }

        // Early return: check if subscription exists
        if (subscriptions.isEmpty()) {
            throw new AuraHandledException('Subscription not found or insufficient permissions');
        }

        Subscription__c subscription = subscriptions[0];

        // Early return validations: check status before activation
        if (subscription.Status__c == Constants.SUBSCRIPTION_STATUS_ACTIVE) {
            throw new AuraHandledException('Subscription is already active');
        }

        if (subscription.Status__c == Constants.SUBSCRIPTION_STATUS_CANCELLED) {
            throw new AuraHandledException('Cannot activate a cancelled subscription');
        }

        if (subscription.Price_Plan__c == null) {
            throw new AuraHandledException('Cannot activate subscription without a Price Plan');
        }

        // Happy path: update status to Active
        subscription.Status__c = Constants.SUBSCRIPTION_STATUS_ACTIVE;

        try {
            update subscription;
        } catch (DmlException e) {
            throw new AuraHandledException('Error activating subscription: ' + e.getMessage());
        }
    }

    /**
     * @description Cancel subscription by changing status to 'Cancelled' and setting cancellation reason
     * @param subscriptionId The ID of the subscription to cancel
     * @param reason The reason for cancellation
     * @throws AuraHandledException if validation fails or DML error occurs
     */
    @AuraEnabled
    public static void cancelSubscription(Id subscriptionId, String reason) {
        // Guard clauses: validate inputs
        if (subscriptionId == null) {
            throw new AuraHandledException('Subscription ID is required');
        }

        if (String.isBlank(reason)) {
            throw new AuraHandledException('Cancellation reason is required');
        }

        // Query subscription
        List<Subscription__c> subscriptions;
        try {
            subscriptions = [
                SELECT Id, Status__c
                FROM Subscription__c
                WHERE Id = :subscriptionId
                LIMIT 1
            ];
        } catch (QueryException e) {
            throw new AuraHandledException('Subscription not found or insufficient permissions');
        }

        // Early return: check if subscription exists
        if (subscriptions.isEmpty()) {
            throw new AuraHandledException('Subscription not found or insufficient permissions');
        }

        Subscription__c subscription = subscriptions[0];

        // Early return validation: check if already cancelled
        if (subscription.Status__c == Constants.SUBSCRIPTION_STATUS_CANCELLED) {
            throw new AuraHandledException('Subscription is already cancelled');
        }

        // Happy path: update status to Cancelled and set details
        subscription.Status__c = Constants.SUBSCRIPTION_STATUS_CANCELLED;
        subscription.Cancellation_Reason__c = reason;
        subscription.Cancellation_Date__c = Date.today();

        try {
            update subscription;
        } catch (DmlException e) {
            throw new AuraHandledException('Error cancelling subscription: ' + e.getMessage());
        }
    }

    /**
     * @description Get subscriptions in Trial status expiring within next N days
     * @param daysAhead Number of days to look ahead (default 7)
     * @return List of Trial subscriptions expiring soon
     */
    @AuraEnabled(cacheable=true)
    public static List<Subscription__c> getExpiringTrialSubscriptions(Integer daysAhead) {
        if (daysAhead == null || daysAhead <= 0) {
            daysAhead = 7; // Default to 7 days
        }

        Date today = Date.today();
        Date endDate = today.addDays(daysAhead);

        List<Subscription__c> subscriptions = [
            SELECT Id, Name,
                   Account__c, Account__r.Name,
                   Price_Plan__c, Price_Plan__r.Name,
                   Status__c,
                   Trial_End_Date__c,
                   MRR__c
            FROM Subscription__c
            WHERE Status__c = :Constants.SUBSCRIPTION_STATUS_TRIAL
            AND Trial_End_Date__c >= :today
            AND Trial_End_Date__c <= :endDate
            ORDER BY Trial_End_Date__c ASC
            LIMIT 50
        ];

        SObjectAccessDecision decision = Security.stripInaccessible(
            AccessType.READABLE,
            subscriptions
        );

        return decision.getRecords();
    }
}
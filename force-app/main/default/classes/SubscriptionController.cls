public with sharing class SubscriptionController {
    
    @AuraEnabled(cacheable=false)
    public static Subscription__c getSubscriptionWithRelated(Id subscriptionId) {
        return [
            SELECT Id, Name, 
                   Account__c, Account__r.Name,
                   Price_Plan__c, Price_Plan__r.Name,
                   Status__c, 
                   Quantity__c, 
                   Start_Date__c, 
                   End_Date__c, 
                   Trial_End_Date__c,
                   Cancellation_Reason__c, 
                   Cancellation_Comments__c,
                   Cancellation_Date__c,
                   Next_Billing_Date__c,
                   MRR__c,
                   ARR__c,
                   Total_Contract_Value__c
            FROM Subscription__c 
            WHERE Id = :subscriptionId 
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
    }
    
    @AuraEnabled
    public static Id createSubscription(Subscription__c subscription) {
        if (subscription == null) {
            return null;
        }

        try {
            insert subscription;
            return subscription.Id;
        } catch (DmlException e) {
            throw new AuraHandledException('Error creating subscription: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateSubscription(Subscription__c subscription) {
        if (subscription?.Id == null) {
            return;
        }

        try {
            update subscription;
        } catch (DmlException e) {
            throw new AuraHandledException('Error updating subscription: ' + e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Subscription__c> getSubscriptionsByAccount(Id accountId) {
        return [
            SELECT Id, Name, 
                   Account__c, Account__r.Name,
                   Price_Plan__c, Price_Plan__r.Name,
                   Status__c, 
                   Start_Date__c, 
                   End_Date__c, 
                   MRR__c,
                   Total_Contract_Value__c
            FROM Subscription__c 
            WHERE Account__c = :accountId 
            WITH SECURITY_ENFORCED
            ORDER BY Start_Date__c DESC
        ];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Subscription__c> getActiveSubscriptions() {
        return [
            SELECT Id, Name, 
                   Account__c, Account__r.Name,
                   Price_Plan__c, Price_Plan__r.Name,
                   Status__c, 
                   Start_Date__c, 
                   Next_Billing_Date__c,
                   MRR__c
            FROM Subscription__c 
            WHERE Status__c IN ('Active', 'Trial')
            WITH SECURITY_ENFORCED
            ORDER BY Account__r.Name, Start_Date__c DESC
        ];
    }
}
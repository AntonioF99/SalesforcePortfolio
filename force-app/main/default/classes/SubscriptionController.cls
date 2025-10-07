public class SubscriptionController {
    
    @AuraEnabled(cacheable=false)
    public static Subscription__c getSubscriptionWithRelated(Id subscriptionId) {
        // SENZA WITH SECURITY_ENFORCED per ora
        Subscription__c result = [
            SELECT Id, Name, 
                   Account__c,
                   Price_Plan__c,
                   Status__c, 
                   Quantity__c, 
                   Start_Date__c, 
                   End_Date__c, 
                   Trial_End_Date__c,
                   Cancellation_Reason__c, 
                   Cancellation_Comments__c
            FROM Subscription__c 
            WHERE Id = :subscriptionId 
            LIMIT 1
        ];
        
        // Carica i related records separatamente
        if (result.Account__c != null) {
            result.Account__r = [SELECT Name FROM Account WHERE Id = :result.Account__c LIMIT 1];
        }
        
        if (result.Price_Plan__c != null) {
            result.Price_Plan__r = [SELECT Name FROM Price_Plan__c WHERE Id = :result.Price_Plan__c LIMIT 1];
        }
        
        return result;
    }
    
    @AuraEnabled
    public static Id createSubscription(Subscription__c subscription) {
        insert subscription;
        return subscription.Id;
    }
    
    @AuraEnabled
    public static void updateSubscription(Subscription__c subscription) {
        update subscription;
    }
}
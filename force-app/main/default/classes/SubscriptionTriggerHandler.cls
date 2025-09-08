
public class SubscriptionTriggerHandler implements IHandler {

    private static final String PERMISSION_CANCEL_ANY = 'Cancel_Any_Subscription';
    private static final Integer DEFAULT_TRIAL_DAYS = 14;

    private static final Map<String, Set<String>> VALID_TRANSITIONS = new Map<String, Set<String>>{
        'Draft' => new Set<String>{'Trial', 'Active'},
        'Trial' => new Set<String>{'Active', 'Cancelled'},
        'Active' => new Set<String>{'Suspended', 'Cancelled'},
        'Suspended' => new Set<String>{'Active', 'Cancelled'},
        'Cancelled' => new Set<String>(),  // Nessuna transizione permessa
        'Expired' => new Set<String>()
    };

    
    public void beforeInsert(List<SObject> newRecords) {
       List<Subscription__c> subscriptions = (List<Subscription__c>) newRecords;
        
        for (Subscription__c sub : subscriptions) {
            if (sub.Status__c == null) {
                sub.Status__c = 'Draft';
            }
            
            if (sub.Start_Date__c == null) {
                sub.Start_Date__c = Date.today();
            }
            
            if (sub.Status__c == 'Trial') {
                sub.Trial_End_Date__c = sub.Start_Date__c.addDays(14);
            }
        }
    }

    public void beforeUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {
        Map<Id, Subscription__c> oldSubs = (Map<Id, Subscription__c>) oldMap;
        Map<Id, Subscription__c> newSubs = (Map<Id, Subscription__c>) newMap;
        
        for (Id subscriptionId : newSubs.keySet()) {
            Subscription__c oldVersion = oldSubs.get(subscriptionId);
            Subscription__c newVersion = newSubs.get(subscriptionId);
            
            if (oldVersion.Status__c != newVersion.Status__c) {
                Set<String> allowedStatuses = VALID_TRANSITIONS.get(oldVersion.Status__c);
                
                if (!allowedStatuses.contains(newVersion.Status__c)) {
                    newVersion.addError('Can\'\t pass from status : ' + oldVersion.Status__c 
                    + ' to :' + newVersion.Status__c);
                }
                
                if (newVersion.Status__c == 'Cancelled' && 
                    String.isBlank(newVersion.Cancellation_Reason__c)) {
                    newVersion.addError('You must provide a cancellation reason to cancel a subscription');
                }
                
                if (newVersion.Status__c == 'Active' && oldVersion.Status__c != 'Active') {
                    newVersion.Next_Billing_Date__c = Date.today().addMonths(1);
                }
            }
        }
    }


    public void beforeDelete(Map<Id, SObject> oldMap) {
        Map<Id, Subscription__c> subscriptions = (Map<Id, Subscription__c>) oldMap;
        
        for (Subscription__c sub : subscriptions.values()) {
        
            if (sub.Status__c == 'Active') {
                sub.addError('An active subscription cannot be deleted');
            }
        }
    }

    public void afterInsert(Map<Id, SObject> newMap) {
        System.debug('afterInsert called with ' + newMap.size() + ' records');
    }

    public void afterUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {
        System.debug('afterUpdate called with ' + newMap.size() + ' records');
    }

    public void afterDelete(Map<Id, SObject> oldMap) {
        System.debug('afterDelete called with ' + oldMap.size() + ' records');
    }

    public void afterUndelete(Map<Id, SObject> newMap) {
        System.debug('afterUndelete called with ' + newMap.size() + ' records');
    }
}
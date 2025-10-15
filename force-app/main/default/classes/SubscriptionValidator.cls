/**
 * @description Validation and business rule checker for Subscription records
 * @author Antonio Franco
 * @date 2025-09-09
 * @story STORY-003: Trigger Framework
 */
public class SubscriptionValidator {
    
    private static final Map<String, Set<String>> VALID_TRANSITIONS = new Map<String, Set<String>>{
        Constants.SUBSCRIPTION_STATUS_DRAFT => new Set<String>{
            Constants.SUBSCRIPTION_STATUS_TRIAL,
            Constants.SUBSCRIPTION_STATUS_ACTIVE,
            Constants.SUBSCRIPTION_STATUS_CANCELLED
        },
        Constants.SUBSCRIPTION_STATUS_TRIAL => new Set<String>{
            Constants.SUBSCRIPTION_STATUS_ACTIVE,
            Constants.SUBSCRIPTION_STATUS_CANCELLED
        },
        Constants.SUBSCRIPTION_STATUS_ACTIVE => new Set<String>{
            Constants.SUBSCRIPTION_STATUS_SUSPENDED,
            Constants.SUBSCRIPTION_STATUS_CANCELLED
        },
        Constants.SUBSCRIPTION_STATUS_SUSPENDED => new Set<String>{
            Constants.SUBSCRIPTION_STATUS_ACTIVE,
            Constants.SUBSCRIPTION_STATUS_CANCELLED
        },
        Constants.SUBSCRIPTION_STATUS_CANCELLED => new Set<String>()
    };
    
    private static final Set<String> STATUSES_REQUIRING_REASON = new Set<String>{
        Constants.SUBSCRIPTION_STATUS_CANCELLED
    };
    
    /*
     * @description Validates state transitions for subscription status changes
     * @param oldSubscriptions Map of old subscription records
     * @param newSubscriptions Map of new subscription records
     */
    public static void validateStateTransitions(Map<Id, Subscription__c> oldSubscriptions, 
                                              Map<Id, Subscription__c> newSubscriptions) {
        
        for (Id subId : newSubscriptions.keySet()) {
            Subscription__c oldSub = oldSubscriptions.get(subId);
            Subscription__c newSub = newSubscriptions.get(subId);
            
            if (oldSub.Status__c == newSub.Status__c) {
                continue;
            }
            
            if (!isValidTransition(oldSub.Status__c, newSub.Status__c)) {
                newSub.addError(
                    'Status__c', 
                    String.format('Invalid status transition from {0} to {1}', 
                                new List<String>{oldSub.Status__c, newSub.Status__c})
                );
            }
            
            if (STATUSES_REQUIRING_REASON.contains(newSub.Status__c) && 
                String.isBlank(newSub.Cancellation_Reason__c)) {
                newSub.addError(
                    'Cancellation_Reason__c',
                    'Cancellation reason is required when status is ' + newSub.Status__c
                );
            }
        }
    }
    
    /*
     * @description Validates cancellation permissions for subscription status changes
     * @param oldSubscriptions Map of old subscription records
     * @param newSubscriptions Map of new subscription records
     */
    public static void validateCancellationPermissions(Map<Id, Subscription__c> oldSubscriptions, 
                                                    Map<Id, Subscription__c> newSubscriptions) {
        
        for (Id subId : newSubscriptions.keySet()) {
            Subscription__c oldSub = oldSubscriptions.get(subId);
            Subscription__c newSub = newSubscriptions.get(subId);
            
            // Only check cancellation permission for UPDATE (not INSERT)
            if (oldSub != null &&
                oldSub.Status__c != Constants.SUBSCRIPTION_STATUS_CANCELLED &&
                newSub.Status__c == Constants.SUBSCRIPTION_STATUS_CANCELLED) {

                if (!SecurityUtils.canCancelSubscription(oldSub)) {
                    newSub.addError('You do not have permission to cancel this subscription');
                }
            }
        }
    }

    public static void validateDeletionPermissions(List<Subscription__c> subscriptions) {
        
        for (Subscription__c sub : subscriptions) {
            if (sub.Status__c == Constants.SUBSCRIPTION_STATUS_ACTIVE) {
                sub.addError(Constants.ERROR_CANNOT_DELETE_ACTIVE);
            }
        }
    }
    
    public static void validateBusinessRules(List<Subscription__c> subscriptions, Boolean isUpdate) {
        
        for (Subscription__c sub : subscriptions) {
            
            if (sub.Status__c == Constants.SUBSCRIPTION_STATUS_TRIAL && sub.Trial_End_Date__c != null) {
                if (sub.Trial_End_Date__c <= Date.today()) {
                    sub.addError('Trial_End_Date__c', 'Trial end date must be in the future');
                }
                
                if (sub.Trial_End_Date__c > Date.today().addDays(Constants.DEFAULT_TRIAL_DAYS)) {
                    sub.addError('Trial_End_Date__c', 'Trial period cannot exceed ' + Constants.DEFAULT_TRIAL_DAYS + ' days');
                }
            }
            
            if (sub.Quantity__c != null && sub.Quantity__c <= 0) {
                sub.addError('Quantity__c', 'Quantity must be greater than zero');
            }
            
            if (sub.Status__c == Constants.SUBSCRIPTION_STATUS_ACTIVE) {
                if (sub.Price_Plan__c == null) {
                    sub.addError(Constants.FIELD_PRICE_PLAN, Constants.ERROR_PRICE_PLAN_REQUIRED);
                }
                
                if (sub.Start_Date__c == null) {
                    sub.addError('Start_Date__c', 'Start date is required for active subscriptions');
                }
            }
        }
    }
    
    public static void setDefaults(List<Subscription__c> subscriptions) {
        
        for (Subscription__c sub : subscriptions) {
            
            if (String.isBlank(sub.Status__c)) {
                sub.Status__c = Constants.SUBSCRIPTION_STATUS_DRAFT;
            }
            
            if (sub.Start_Date__c == null) {
                sub.Start_Date__c = Date.today();
            }
            
            // Auto-populate Trial_End_Date based on Start_Date (not today!)
            if (sub.Status__c == Constants.SUBSCRIPTION_STATUS_TRIAL && sub.Trial_End_Date__c == null) {
                Date baseDate = sub.Start_Date__c != null ? sub.Start_Date__c : Date.today();
                sub.Trial_End_Date__c = baseDate.addDays(Constants.DEFAULT_TRIAL_DAYS);
            }
            
            // Auto-populate Cancellation Date when Status = Cancelled
            if (sub.Status__c == Constants.SUBSCRIPTION_STATUS_CANCELLED && sub.Cancellation_Date__c == null) {
                sub.Cancellation_Date__c = Date.today();
            }
        }
    }


    /*
     * @description Identifies subscriptions that need invoice generation
     * @param oldSubscriptions Map of old subscription records
     * @param newSubscriptions Map of new subscription records
     * @return Set of subscription IDs that need invoice generation
     */
    public static Set<Id> getSubscriptionsNeedingInvoice(Map<Id, Subscription__c> oldSubscriptions,
                                                        Map<Id, Subscription__c> newSubscriptions) {
        
        Set<Id> subscriptionIds = new Set<Id>();
        
        for (Id subId : newSubscriptions.keySet()) {
            Subscription__c oldSub = oldSubscriptions.get(subId);
            Subscription__c newSub = newSubscriptions.get(subId);
            
            if (oldSub.Status__c != Constants.SUBSCRIPTION_STATUS_ACTIVE && newSub.Status__c == Constants.SUBSCRIPTION_STATUS_ACTIVE) {
                subscriptionIds.add(subId);
            }
        }
        
        return subscriptionIds;
    }
    
    private static Boolean isValidTransition(String fromStatus, String toStatus) {
        
        if (String.isBlank(fromStatus) || String.isBlank(toStatus)) {
            return false;
        }
        
        Set<String> validNextStatuses = VALID_TRANSITIONS.get(fromStatus);
        return validNextStatuses != null && validNextStatuses.contains(toStatus);
    }
}
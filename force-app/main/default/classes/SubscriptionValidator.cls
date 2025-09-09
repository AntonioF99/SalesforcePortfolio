/**
 * @description Validation and business rule checker for Subscription records
 * @author Antonio Franco
 * @date 2025-09-09
 * @story STORY-003: Trigger Framework
 */
public class SubscriptionValidator {
    
    // State machine configuration
    private static final Map<String, Set<String>> VALID_TRANSITIONS = new Map<String, Set<String>>{
        'Draft' => new Set<String>{'Trial', 'Active'},
        'Trial' => new Set<String>{'Active', 'Cancelled'},
        'Active' => new Set<String>{'Suspended', 'Cancelled'},
        'Suspended' => new Set<String>{'Active', 'Cancelled'},
        'Cancelled' => new Set<String>(),
        'Expired' => new Set<String>()
    };
    
    // Required fields for specific statuses
    private static final Set<String> STATUSES_REQUIRING_REASON = new Set<String>{
        'Cancelled', 'Suspended'
    };
    
    /**
     * @description Validates state transitions for subscription status changes
     * @param oldSubscriptions Map of old subscription records
     * @param newSubscriptions Map of new subscription records
     * @throws DmlException if invalid state transition detected
     */
    public static void validateStateTransitions(Map<Id, Subscription__c> oldSubscriptions, 
                                              Map<Id, Subscription__c> newSubscriptions) {
        
        for (Id subId : newSubscriptions.keySet()) {
            Subscription__c oldSub = oldSubscriptions.get(subId);
            Subscription__c newSub = newSubscriptions.get(subId);
            
            // Skip if status hasn't changed
            if (oldSub.Status__c == newSub.Status__c) {
                continue;
            }
            
            // Validate transition
            if (!isValidTransition(oldSub.Status__c, newSub.Status__c)) {
                newSub.addError(
                    'Status__c', 
                    String.format('Invalid status transition from {0} to {1}', 
                                new List<String>{oldSub.Status__c, newSub.Status__c})
                );
            }
            
            // Check if cancellation/suspension reason is required
            if (STATUSES_REQUIRING_REASON.contains(newSub.Status__c) && 
                String.isBlank(newSub.Cancellation_Reason__c)) {
                newSub.addError(
                    'Cancellation_Reason__c',
                    'Cancellation reason is required when status is ' + newSub.Status__c
                );
            }
        }
    }
    
    /**
     * @description Validates user permissions for subscription operations
     * @param subscriptions List of subscription records to validate
     * @param operation Type of operation (DELETE, CANCEL, etc.)
     */
    public static void validateUserPermissions(List<Subscription__c> subscriptions, String operation) {
        
        // Check permission for cancelling subscriptions
        if (operation == 'CANCEL') {
            Boolean canCancelAny = FeatureManagement.checkPermission('Cancel_Any_Subscription');
            
            if (!canCancelAny) {
                for (Subscription__c sub : subscriptions) {
                    // Only allow cancellation of draft subscriptions without special permission
                    if (sub.Status__c != 'Draft') {
                        sub.addError('You do not have permission to cancel active subscriptions');
                    }
                }
            }
        }
        
        // Check permission for deleting subscriptions
        if (operation == 'DELETE') {
            for (Subscription__c sub : subscriptions) {
                if (sub.Status__c == 'Active') {
                    sub.addError('Cannot delete active subscriptions. Cancel first, then delete.');
                }
            }
        }
    }
    
    /**
     * @description Validates business rules for subscription records
     * @param subscriptions List of subscription records to validate
     * @param isUpdate Whether this is an update operation
     */
    public static void validateBusinessRules(List<Subscription__c> subscriptions, Boolean isUpdate) {
        
        for (Subscription__c sub : subscriptions) {
            
            // Validate date logic
            if (sub.Start_Date__c != null && sub.End_Date__c != null) {
                if (sub.Start_Date__c >= sub.End_Date__c) {
                    sub.addError('End_Date__c', 'End date must be after start date');
                }
            }
            
            // Trial period validation
            if (sub.Status__c == 'Trial') {
                if (sub.Trial_End_Date__c == null) {
                    sub.addError('Trial_End_Date__c', 'Trial end date is required for trial subscriptions');
                }
                
                if (sub.Trial_End_Date__c != null && sub.Trial_End_Date__c <= Date.today()) {
                    sub.addError('Trial_End_Date__c', 'Trial end date must be in the future');
                }
            }
            
            // Active subscription validation
            if (sub.Status__c == 'Active') {
                if (sub.Price_Plan__c == null) {
                    sub.addError('Price_Plan__c', 'Price plan is required for active subscriptions');
                }
                
                if (sub.Start_Date__c == null) {
                    sub.addError('Start_Date__c', 'Start date is required for active subscriptions');
                }
            }
        }
    }
    
    /**
     * @description Sets default values for new subscription records
     * @param subscriptions List of subscription records to process
     */
    public static void setDefaults(List<Subscription__c> subscriptions) {
        
        for (Subscription__c sub : subscriptions) {
            
            // Set default status if not provided
            if (String.isBlank(sub.Status__c)) {
                sub.Status__c = 'Draft';
            }
            
            // Set default start date for draft subscriptions
            if (sub.Status__c == 'Draft' && sub.Start_Date__c == null) {
                sub.Start_Date__c = Date.today();
            }
            
            // Set trial end date if status is Trial and not provided
            if (sub.Status__c == 'Trial' && sub.Trial_End_Date__c == null) {
                sub.Trial_End_Date__c = Date.today().addDays(14); // Default 14-day trial
            }
        }
    }
    
    /**
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
            
            // Generate invoice when subscription becomes active
            if (oldSub.Status__c != 'Active' && newSub.Status__c == 'Active') {
                subscriptionIds.add(subId);
            }
        }
        
        return subscriptionIds;
    }
    
    // ========== PRIVATE HELPER METHODS ==========
    
    /**
     * @description Checks if a status transition is valid
     * @param fromStatus Current status
     * @param toStatus New status
     * @return true if transition is valid
     */
    private static Boolean isValidTransition(String fromStatus, String toStatus) {
        
        if (String.isBlank(fromStatus) || String.isBlank(toStatus)) {
            return false;
        }
        
        Set<String> validNextStatuses = VALID_TRANSITIONS.get(fromStatus);
        return validNextStatuses != null && validNextStatuses.contains(toStatus);
    }
}
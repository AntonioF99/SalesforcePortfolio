/**
 * @description Trigger handler for Subscription__c object - Orchestrator pattern
 * @author Antonio Franco
 * @date 2025-09-09
 * @story STORY-003: Trigger Framework
 * @pattern Thin Handler + Validator separation of concerns
 */
public class SubscriptionTriggerHandler implements IHandler {
    
    // ========== TRIGGER FRAMEWORK INTERFACE METHODS ==========
    
    /**
     * @description Before Insert handler
     * @param newRecords List of new Subscription records
     */
    public void beforeInsert(List<SObject> newRecords) {
        System.debug('SubscriptionTriggerHandler.beforeInsert: Processing ' + newRecords.size() + ' records');
        
        List<Subscription__c> subscriptions = (List<Subscription__c>) newRecords;
        
        // Set defaults for new subscriptions
        SubscriptionValidator.setDefaults(subscriptions);
        
        // Validate business rules
        SubscriptionValidator.validateBusinessRules(subscriptions, false);
        
        System.debug('SubscriptionTriggerHandler.beforeInsert: Completed');
    }
    
    /**
     * @description Before Update handler
     * @param oldMap Map of old Subscription records
     * @param newMap Map of new Subscription records
     */
    public void beforeUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {
        System.debug('SubscriptionTriggerHandler.beforeUpdate: Processing ' + newMap.size() + ' records');
        
        Map<Id, Subscription__c> oldSubscriptions = (Map<Id, Subscription__c>) oldMap;
        Map<Id, Subscription__c> newSubscriptions = (Map<Id, Subscription__c>) newMap;
        List<Subscription__c> subscriptionsList = newSubscriptions.values();
        
        // Validate state transitions
        SubscriptionValidator.validateStateTransitions(oldSubscriptions, newSubscriptions);
        
        // Check user permissions for status changes
        List<Subscription__c> cancellingSubscriptions = getCancellingSubscriptions(oldSubscriptions, newSubscriptions);
        if (!cancellingSubscriptions.isEmpty()) {
            SubscriptionValidator.validateUserPermissions(cancellingSubscriptions, 'CANCEL');
        }
        
        // Validate business rules
        SubscriptionValidator.validateBusinessRules(subscriptionsList, true);
        
        System.debug('SubscriptionTriggerHandler.beforeUpdate: Completed');
    }
    
    /**
     * @description Before Delete handler
     * @param oldMap Map of old Subscription records being deleted
     */
    public void beforeDelete(Map<Id, SObject> oldMap) {
        System.debug('SubscriptionTriggerHandler.beforeDelete: Processing ' + oldMap.size() + ' records');
        
        List<Subscription__c> subscriptions = (List<Subscription__c>) oldMap.values();
        
        // Validate user permissions for deletion
        SubscriptionValidator.validateUserPermissions(subscriptions, 'DELETE');
        
        System.debug('SubscriptionTriggerHandler.beforeDelete: Completed');
    }
    
    /**
     * @description After Insert handler
     * @param newMap Map of new Subscription records
     */
    public void afterInsert(Map<Id, SObject> newMap) {
        System.debug('SubscriptionTriggerHandler.afterInsert: Processing ' + newMap.size() + ' records');
        
        // Future enhancement: Create welcome tasks, send notifications, etc.
        handlePostInsertActions((Map<Id, Subscription__c>) newMap);
        
        System.debug('SubscriptionTriggerHandler.afterInsert: Completed');
    }
    
    /**
     * @description After Update handler
     * @param oldMap Map of old Subscription records
     * @param newMap Map of new Subscription records
     */
    public void afterUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {
        System.debug('SubscriptionTriggerHandler.afterUpdate: Processing ' + newMap.size() + ' records');
        
        Map<Id, Subscription__c> oldSubscriptions = (Map<Id, Subscription__c>) oldMap;
        Map<Id, Subscription__c> newSubscriptions = (Map<Id, Subscription__c>) newMap;
        
        // Handle invoice generation for newly active subscriptions
        handleInvoiceGeneration(oldSubscriptions, newSubscriptions);
        
        // Handle other post-update actions
        handlePostUpdateActions(oldSubscriptions, newSubscriptions);
        
        System.debug('SubscriptionTriggerHandler.afterUpdate: Completed');
    }
    
    /**
     * @description After Delete handler
     * @param oldMap Map of deleted Subscription records
     */
    public void afterDelete(Map<Id, SObject> oldMap) {
        System.debug('SubscriptionTriggerHandler.afterDelete: Processing ' + oldMap.size() + ' records');
        
        // Future enhancement: Cleanup related records, send notifications, etc.
        handlePostDeleteActions((Map<Id, Subscription__c>) oldMap);
        
        System.debug('SubscriptionTriggerHandler.afterDelete: Completed');
    }
    
    /**
     * @description After Undelete handler
     * @param newMap Map of undeleted Subscription records
     */
    public void afterUndelete(Map<Id, SObject> newMap) {
        System.debug('SubscriptionTriggerHandler.afterUndelete: Processing ' + newMap.size() + ' records');
        
        // Future enhancement: Restore related data, send notifications, etc.
        handlePostUndeleteActions((Map<Id, Subscription__c>) newMap);
        
        System.debug('SubscriptionTriggerHandler.afterUndelete: Completed');
    }
    
    // ========== PRIVATE HELPER METHODS ==========
    
    /**
     * @description Identifies subscriptions being cancelled
     * @param oldSubscriptions Map of old subscription records
     * @param newSubscriptions Map of new subscription records
     * @return List of subscriptions being cancelled
     */
    private List<Subscription__c> getCancellingSubscriptions(Map<Id, Subscription__c> oldSubscriptions,
                                                           Map<Id, Subscription__c> newSubscriptions) {
        
        List<Subscription__c> cancellingSubscriptions = new List<Subscription__c>();
        
        for (Id subId : newSubscriptions.keySet()) {
            Subscription__c oldSub = oldSubscriptions.get(subId);
            Subscription__c newSub = newSubscriptions.get(subId);
            
            if (oldSub.Status__c != 'Cancelled' && newSub.Status__c == 'Cancelled') {
                cancellingSubscriptions.add(newSub);
            }
        }
        
        return cancellingSubscriptions;
    }
    
    /**
     * @description Handles invoice generation for subscriptions becoming active
     * @param oldSubscriptions Map of old subscription records
     * @param newSubscriptions Map of new subscription records
     */
    private void handleInvoiceGeneration(Map<Id, Subscription__c> oldSubscriptions,
                                       Map<Id, Subscription__c> newSubscriptions) {
        
        Set<Id> subscriptionsNeedingInvoice = SubscriptionValidator.getSubscriptionsNeedingInvoice(
            oldSubscriptions, 
            newSubscriptions
        );
        
        if (!subscriptionsNeedingInvoice.isEmpty()) {
            System.debug('Subscriptions needing invoice generation: ' + subscriptionsNeedingInvoice);
            
            // TODO: Implement in STORY-005 - Invoice Generation Engine
            // For now, just log the IDs that need processing
            // Future: Call InvoiceService.generateInvoicesForSubscriptions(subscriptionsNeedingInvoice);
            
            // Prepare data for future implementation
            storeSubscriptionsForInvoiceGeneration(subscriptionsNeedingInvoice);
        }
    }
    
    /**
     * @description Handles post-insert actions
     * @param newSubscriptions Map of newly inserted subscriptions
     */
    private void handlePostInsertActions(Map<Id, Subscription__c> newSubscriptions) {
        // Future enhancements:
        // - Create welcome tasks
        // - Send confirmation emails
        // - Log to audit trail
        
        System.debug('Post-insert actions placeholder for ' + newSubscriptions.size() + ' subscriptions');
    }
    
    /**
     * @description Handles post-update actions
     * @param oldSubscriptions Map of old subscription records
     * @param newSubscriptions Map of new subscription records
     */
    private void handlePostUpdateActions(Map<Id, Subscription__c> oldSubscriptions,
                                       Map<Id, Subscription__c> newSubscriptions) {
        // Future enhancements:
        // - Send status change notifications
        // - Update related cases
        // - Platform events publishing
        
        System.debug('Post-update actions placeholder for ' + newSubscriptions.size() + ' subscriptions');
    }
    
    /**
     * @description Handles post-delete actions
     * @param deletedSubscriptions Map of deleted subscription records
     */
    private void handlePostDeleteActions(Map<Id, Subscription__c> deletedSubscriptions) {
        // Future enhancements:
        // - Archive related data
        // - Send deletion confirmations
        // - Update analytics
        
        System.debug('Post-delete actions placeholder for ' + deletedSubscriptions.size() + ' subscriptions');
    }
    
    /**
     * @description Handles post-undelete actions
     * @param undeletedSubscriptions Map of undeleted subscription records
     */
    private void handlePostUndeleteActions(Map<Id, Subscription__c> undeletedSubscriptions) {
        // Future enhancements:
        // - Restore related data
        // - Send restoration notifications
        
        System.debug('Post-undelete actions placeholder for ' + undeletedSubscriptions.size() + ' subscriptions');
    }
    
    /**
     * @description Temporary method to store subscription IDs for future invoice generation
     * @param subscriptionIds Set of subscription IDs needing invoice generation
     */
    private void storeSubscriptionsForInvoiceGeneration(Set<Id> subscriptionIds) {
        // TODO: Remove this method in STORY-005 when InvoiceService is implemented
        // For now, just log the IDs that would be processed
        
        System.debug('=== INVOICE GENERATION QUEUE ===');
        for (Id subId : subscriptionIds) {
            System.debug('Subscription ' + subId + ' needs invoice generation');
        }
        System.debug('=== END INVOICE GENERATION QUEUE ===');
        
        // Future: Store in custom setting or platform event for async processing
    }
}
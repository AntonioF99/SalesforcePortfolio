/**
 * @description Trigger handler for Invoice__c object - Orchestrator pattern
 * @author Antonio Franco
 * @date 2025-09-09
 * @story STORY-003: Trigger Framework
 * @pattern Thin Handler + Validator separation of concerns
 */
public class InvoiceTriggerHandler implements IHandler {
    
    // ========== TRIGGER FRAMEWORK INTERFACE METHODS ==========
    
    /**
     * @description Before Insert handler
     * @param newRecords List of new Invoice records
     */
    public void beforeInsert(List<SObject> newRecords) {
        System.debug('InvoiceTriggerHandler.beforeInsert: Processing ' + newRecords.size() + ' records');
        
        List<Invoice__c> invoices = (List<Invoice__c>) newRecords;
        
        // Set defaults for new invoices
        InvoiceValidator.setDefaults(invoices);
        
        // Generate invoice numbers
        InvoiceValidator.generateInvoiceNumbers(invoices);
        
        // Calculate tax amounts
        InvoiceValidator.calculateTaxAmounts(invoices);
        
        // Validate business rules
        InvoiceValidator.validateBusinessRules(invoices, false);
        
        System.debug('InvoiceTriggerHandler.beforeInsert: Completed');
    }
    
    /**
     * @description Before Update handler
     * @param oldMap Map of old Invoice records
     * @param newMap Map of new Invoice records
     */
    public void beforeUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {
        System.debug('InvoiceTriggerHandler.beforeUpdate: Processing ' + newMap.size() + ' records');
        
        Map<Id, Invoice__c> oldInvoices = (Map<Id, Invoice__c>) oldMap;
        Map<Id, Invoice__c> newInvoices = (Map<Id, Invoice__c>) newMap;
        List<Invoice__c> invoicesList = newInvoices.values();
        
        // Check user permissions for modifications
        InvoiceValidator.validateUserPermissions(invoicesList, 'UPDATE', oldInvoices);
        
        // Recalculate tax if tax rate changed (affects formula fields)
        List<Invoice__c> invoicesWithTaxRateChanges = getInvoicesWithTaxRateChanges(oldInvoices, newInvoices);
        if (!invoicesWithTaxRateChanges.isEmpty()) {
            InvoiceValidator.calculateTaxAmounts(invoicesWithTaxRateChanges);
        }
        
        // Validate business rules
        InvoiceValidator.validateBusinessRules(invoicesList, true);
        
        System.debug('InvoiceTriggerHandler.beforeUpdate: Completed');
    }
    
    /**
     * @description Before Delete handler
     * @param oldMap Map of old Invoice records being deleted
     */
    public void beforeDelete(Map<Id, SObject> oldMap) {
        System.debug('InvoiceTriggerHandler.beforeDelete: Processing ' + oldMap.size() + ' records');
        
        List<Invoice__c> invoices = (List<Invoice__c>) oldMap.values();
        
        // Validate user permissions for deletion
        InvoiceValidator.validateUserPermissions(invoices, 'DELETE', null);
        
        System.debug('InvoiceTriggerHandler.beforeDelete: Completed');
    }
    
    /**
     * @description After Insert handler
     * @param newMap Map of new Invoice records
     */
    public void afterInsert(Map<Id, SObject> newMap) {
        System.debug('InvoiceTriggerHandler.afterInsert: Processing ' + newMap.size() + ' records');
        
        Map<Id, Invoice__c> newInvoices = (Map<Id, Invoice__c>) newMap;
        
        // Handle post-insert actions
        handlePostInsertActions(newInvoices);
        
        // Update account statistics
        updateAccountInvoiceStats(newInvoices.keySet());
        
        System.debug('InvoiceTriggerHandler.afterInsert: Completed');
    }
    
    /**
     * @description After Update handler
     * @param oldMap Map of old Invoice records
     * @param newMap Map of new Invoice records
     */
    public void afterUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {
        System.debug('InvoiceTriggerHandler.afterUpdate: Processing ' + newMap.size() + ' records');
        
        Map<Id, Invoice__c> oldInvoices = (Map<Id, Invoice__c>) oldMap;
        Map<Id, Invoice__c> newInvoices = (Map<Id, Invoice__c>) newMap;
        
        // Handle line item recalculation
        handleLineItemRecalculation(oldInvoices, newInvoices);
        
        // Handle status change actions
        handleStatusChangeActions(oldInvoices, newInvoices);
        
        // Update account statistics
        updateAccountInvoiceStats(newInvoices.keySet());
        
        System.debug('InvoiceTriggerHandler.afterUpdate: Completed');
    }
    
    /**
     * @description After Delete handler
     * @param oldMap Map of deleted Invoice records
     */
    public void afterDelete(Map<Id, SObject> oldMap) {
        System.debug('InvoiceTriggerHandler.afterDelete: Processing ' + oldMap.size() + ' records');
        
        Map<Id, Invoice__c> deletedInvoices = (Map<Id, Invoice__c>) oldMap;
        
        // Handle post-delete actions
        handlePostDeleteActions(deletedInvoices);
        
        // Update account statistics after deletion
        Set<Id> accountIds = getAccountIdsFromInvoices(deletedInvoices.values());
        updateAccountInvoiceStatsByAccountIds(accountIds);
        
        System.debug('InvoiceTriggerHandler.afterDelete: Completed');
    }
    
    /**
     * @description After Undelete handler
     * @param newMap Map of undeleted Invoice records
     */
    public void afterUndelete(Map<Id, SObject> newMap) {
        System.debug('InvoiceTriggerHandler.afterUndelete: Processing ' + newMap.size() + ' records');
        
        Map<Id, Invoice__c> undeletedInvoices = (Map<Id, Invoice__c>) newMap;
        
        // Handle post-undelete actions
        handlePostUndeleteActions(undeletedInvoices);
        
        // Update account statistics
        updateAccountInvoiceStats(undeletedInvoices.keySet());
        
        System.debug('InvoiceTriggerHandler.afterUndelete: Completed');
    }
    
    // ========== PRIVATE HELPER METHODS ==========
    
    /**
     * @description Identifies invoices with tax rate changes
     * @param oldInvoices Map of old invoice records
     * @param newInvoices Map of new invoice records
     * @return List of invoices with tax rate changes
     */
    private List<Invoice__c> getInvoicesWithTaxRateChanges(Map<Id, Invoice__c> oldInvoices,
                                                         Map<Id, Invoice__c> newInvoices) {
        
        List<Invoice__c> invoicesWithChanges = new List<Invoice__c>();
        
        for (Id invId : newInvoices.keySet()) {
            Invoice__c oldInv = oldInvoices.get(invId);
            Invoice__c newInv = newInvoices.get(invId);
            
            if (oldInv.Tax_Rate__c != newInv.Tax_Rate__c) {
                invoicesWithChanges.add(newInv);
            }
        }
        
        return invoicesWithChanges;
    }
    
    /**
     * @description Handles line item recalculation when needed
     * @param oldInvoices Map of old invoice records
     * @param newInvoices Map of new invoice records
     */
    private void handleLineItemRecalculation(Map<Id, Invoice__c> oldInvoices,
                                           Map<Id, Invoice__c> newInvoices) {
        
        Set<Id> invoicesNeedingRecalc = InvoiceValidator.getInvoicesNeedingRecalculation(
            newInvoices.values()
        );
        
        if (!invoicesNeedingRecalc.isEmpty()) {
            System.debug('Invoices needing line item recalculation: ' + invoicesNeedingRecalc);
            
            // TODO: Implement in future story - Invoice Line Item Service
            // For now, just log the IDs that need processing
            // Future: Call InvoiceLineItemService.recalculateInvoiceTotals(invoicesNeedingRecalc);
            
            storeInvoicesForRecalculation(invoicesNeedingRecalc);
        }
    }
    
    /**
     * @description Handles actions when invoice status changes
     * @param oldInvoices Map of old invoice records
     * @param newInvoices Map of new invoice records
     */
    private void handleStatusChangeActions(Map<Id, Invoice__c> oldInvoices,
                                         Map<Id, Invoice__c> newInvoices) {
        
        List<Invoice__c> sentInvoices = new List<Invoice__c>();
        List<Invoice__c> paidInvoices = new List<Invoice__c>();
        List<Invoice__c> overdueInvoices = new List<Invoice__c>();
        
        for (Id invId : newInvoices.keySet()) {
            Invoice__c oldInv = oldInvoices.get(invId);
            Invoice__c newInv = newInvoices.get(invId);
            
            // Track status changes
            if (oldInv.Status__c != newInv.Status__c) {
                switch on newInv.Status__c {
                    when 'Sent' {
                        sentInvoices.add(newInv);
                    }
                    when 'Paid' {
                        paidInvoices.add(newInv);
                    }
                    when 'Overdue' {
                        overdueInvoices.add(newInv);
                    }
                }
            }
        }
        
        // Handle specific status change actions
        handleSentInvoices(sentInvoices);
        handlePaidInvoices(paidInvoices);
        handleOverdueInvoices(overdueInvoices);
    }
    
    /**
     * @description Handles post-insert actions for new invoices
     * @param newInvoices Map of newly inserted invoices
     */
    private void handlePostInsertActions(Map<Id, Invoice__c> newInvoices) {
        // Future enhancements:
        // - Create invoice documents
        // - Send notifications
        // - Create related tasks
        
        System.debug('Post-insert actions placeholder for ' + newInvoices.size() + ' invoices');
    }
    
    /**
     * @description Handles post-delete actions for deleted invoices
     * @param deletedInvoices Map of deleted invoice records
     */
    private void handlePostDeleteActions(Map<Id, Invoice__c> deletedInvoices) {
        // Future enhancements:
        // - Archive invoice documents
        // - Send deletion notifications
        // - Update audit trail
        
        System.debug('Post-delete actions placeholder for ' + deletedInvoices.size() + ' invoices');
    }
    
    /**
     * @description Handles post-undelete actions for restored invoices
     * @param undeletedInvoices Map of undeleted invoice records
     */
    private void handlePostUndeleteActions(Map<Id, Invoice__c> undeletedInvoices) {
        // Future enhancements:
        // - Restore invoice documents
        // - Send restoration notifications
        
        System.debug('Post-undelete actions placeholder for ' + undeletedInvoices.size() + ' invoices');
    }
    
    /**
     * @description Handles actions for newly sent invoices
     * @param sentInvoices List of invoices that were just sent
     */
    private void handleSentInvoices(List<Invoice__c> sentInvoices) {
        if (!sentInvoices.isEmpty()) {
            System.debug('Processing ' + sentInvoices.size() + ' newly sent invoices');
            // Future: Send email notifications, create PDF documents, etc.
        }
    }
    
    /**
     * @description Handles actions for newly paid invoices
     * @param paidInvoices List of invoices that were just paid
     */
    private void handlePaidInvoices(List<Invoice__c> paidInvoices) {
        if (!paidInvoices.isEmpty()) {
            System.debug('Processing ' + paidInvoices.size() + ' newly paid invoices');
            // Future: Send payment confirmations, update subscription status, etc.
        }
    }
    
    /**
     * @description Handles actions for newly overdue invoices
     * @param overdueInvoices List of invoices that became overdue
     */
    private void handleOverdueInvoices(List<Invoice__c> overdueInvoices) {
        if (!overdueInvoices.isEmpty()) {
            System.debug('Processing ' + overdueInvoices.size() + ' newly overdue invoices');
            // Future: Send overdue notifications, create follow-up tasks, etc.
        }
    }
    
    /**
     * @description Updates account-level invoice statistics
     * @param invoiceIds Set of invoice IDs that were modified
     */
    private void updateAccountInvoiceStats(Set<Id> invoiceIds) {
        if (!invoiceIds.isEmpty()) {
            System.debug('Updating account statistics for ' + invoiceIds.size() + ' invoices');
            // Future: Call AccountStatsService to update rollup fields
        }
    }
    
    /**
     * @description Updates account-level invoice statistics by account IDs
     * @param accountIds Set of account IDs to update
     */
    private void updateAccountInvoiceStatsByAccountIds(Set<Id> accountIds) {
        if (!accountIds.isEmpty()) {
            System.debug('Updating statistics for ' + accountIds.size() + ' accounts');
            // Future: Call AccountStatsService to recalculate stats
        }
    }
    
    /**
     * @description Extracts account IDs from invoice records
     * @param invoices List of invoice records
     * @return Set of account IDs
     */
    private Set<Id> getAccountIdsFromInvoices(List<Invoice__c> invoices) {
        Set<Id> accountIds = new Set<Id>();
        
        for (Invoice__c inv : invoices) {
            if (inv.Account__c != null) {
                accountIds.add(inv.Account__c);
            }
        }
        
        return accountIds;
    }
    
    /**
     * @description Temporary method to store invoice IDs for future recalculation
     * @param invoiceIds Set of invoice IDs needing recalculation
     */
    private void storeInvoicesForRecalculation(Set<Id> invoiceIds) {
        // TODO: Remove this method when InvoiceLineItemService is implemented
        
        System.debug('=== INVOICE RECALCULATION QUEUE ===');
        for (Id invId : invoiceIds) {
            System.debug('Invoice ' + invId + ' needs line item recalculation');
        }
        System.debug('=== END INVOICE RECALCULATION QUEUE ===');
        
        // Future: Store in custom setting or platform event for async processing
    }
}
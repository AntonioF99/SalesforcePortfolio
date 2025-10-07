/**
 * @description Orchestrates Invoice trigger events using validator pattern
 * @author Antonio Franco
 * @date 2025-09-09
 * @story STORY-003: Trigger Framework
 */
public class InvoiceTriggerHandler implements IHandler {
    
    public void beforeInsert(List<SObject> newRecords) {
        List<Invoice__c> invoices = (List<Invoice__c>) newRecords;
        
        InvoiceValidator.setDefaults(invoices);
        RecordTypeUtils.assignInvoiceRecordTypes(invoices);
        InvoiceValidator.calculateTaxAmounts(invoices);
        InvoiceValidator.validateBusinessRules(invoices, false);
        InvoiceValidator.generateInvoiceNumbers(invoices);
    }
    
    public void beforeUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {
        List<Invoice__c> invoices = (List<Invoice__c>) newMap.values();
        Map<Id, Invoice__c> oldInvoices = (Map<Id, Invoice__c>) oldMap;
        
        InvoiceValidator.validateUserPermissions(invoices, 'UPDATE', oldInvoices);
        InvoiceValidator.validateBusinessRules(invoices, true);
    }
    
    public void beforeDelete(Map<Id, SObject> oldMap) {
        List<Invoice__c> invoices = (List<Invoice__c>) oldMap.values();
        
        InvoiceValidator.validateUserPermissions(invoices, 'DELETE', null);
    }
    
    public void afterInsert(Map<Id, SObject> newMap) {
        List<Invoice__c> invoices = (List<Invoice__c>) newMap.values();
        
        updateAccountInvoiceStats(invoices);
        handleNewInvoices(invoices);
        
        // Publish platform events for external integration
        PlatformEventPublisher.publishInvoiceEvents(invoices, 'Created');
    }
    
    public void afterUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {
        List<Invoice__c> invoices = (List<Invoice__c>) newMap.values();
        Map<Id, Invoice__c> oldInvoices = (Map<Id, Invoice__c>) oldMap;
        
        handleStatusChanges(invoices, oldInvoices);
        updateAccountInvoiceStats(invoices);
        
        Set<Id> needingRecalc = InvoiceValidator.getInvoicesNeedingRecalculation(invoices);
        if (!needingRecalc.isEmpty()) {
            storeInvoicesForRecalculation(needingRecalc);
        }
        
        // Publish consolidated platform events for status changes and updates
        PlatformEventPublisher.publishInvoiceStatusChanges(invoices, oldInvoices);
        // Note: publishInvoiceStatusChanges now handles both status changes and general updates
    }
    
    public void afterDelete(Map<Id, SObject> oldMap) {
        List<Invoice__c> invoices = (List<Invoice__c>) oldMap.values();
        
        updateAccountInvoiceStats(invoices);
        handleDeletedInvoices(invoices);
    }
    
    public void afterUndelete(Map<Id, SObject> newMap) {
        List<Invoice__c> invoices = (List<Invoice__c>) newMap.values();
        
        updateAccountInvoiceStats(invoices);
        handleUndeletedInvoices(invoices);
    }
    
    /*
     * @description Processes invoices based on status changes and routes to appropriate handlers
     * @param invoices List of updated invoice records
     * @param oldInvoices Map of invoice records before update
     */
    private void handleStatusChanges(List<Invoice__c> invoices, Map<Id, Invoice__c> oldInvoices) {
        List<Invoice__c> sentInvoices = new List<Invoice__c>();
        List<Invoice__c> paidInvoices = new List<Invoice__c>();
        List<Invoice__c> overdueInvoices = new List<Invoice__c>();
        
        for (Invoice__c inv : invoices) {
            Invoice__c oldInv = oldInvoices.get(inv.Id);
            
            if (oldInv.Status__c != inv.Status__c) {
                switch on inv.Status__c {
                    when 'Sent' { sentInvoices.add(inv); }
                    when 'Paid' { paidInvoices.add(inv); }
                    when 'Overdue' { overdueInvoices.add(inv); }
                }
            }
        }
        
        handleSentInvoices(sentInvoices);
        handlePaidInvoices(paidInvoices);
        handleOverdueInvoices(overdueInvoices);
    }
    
    private void handleSentInvoices(List<Invoice__c> sentInvoices) {
        if (!sentInvoices.isEmpty()) {
            System.debug('Processing ' + sentInvoices.size() + ' newly sent invoices');
            
            Set<Id> invoiceIds = new Set<Id>();
            for (Invoice__c inv : sentInvoices) {
                invoiceIds.add(inv.Id);
            }
            
            InvoiceAutomationService.processStatusChanges(invoiceIds);
        }
    }
    
    private void handlePaidInvoices(List<Invoice__c> paidInvoices) {
        if (!paidInvoices.isEmpty()) {
            System.debug('Processing ' + paidInvoices.size() + ' newly paid invoices');
            
            Set<Id> invoiceIds = new Set<Id>();
            for (Invoice__c inv : paidInvoices) {
                invoiceIds.add(inv.Id);
            }
            
            InvoiceAutomationService.processStatusChanges(invoiceIds);
        }
    }
    
    private void handleOverdueInvoices(List<Invoice__c> overdueInvoices) {
        if (!overdueInvoices.isEmpty()) {
            System.debug('Processing ' + overdueInvoices.size() + ' newly overdue invoices');
            
            Set<Id> invoiceIds = new Set<Id>();
            for (Invoice__c inv : overdueInvoices) {
                invoiceIds.add(inv.Id);
            }
            
            InvoiceAutomationService.processStatusChanges(invoiceIds);
        }
    }
    
    private void handleNewInvoices(List<Invoice__c> newInvoices) {
        if (!newInvoices.isEmpty()) {
            System.debug('Processing ' + newInvoices.size() + ' new invoices');
            // TODO: STORY-013 - Invoice number sequence management
        }
    }
    
    private void handleDeletedInvoices(List<Invoice__c> deletedInvoices) {
        if (!deletedInvoices.isEmpty()) {
            System.debug('Processing ' + deletedInvoices.size() + ' deleted invoices');
            // TODO: STORY-014 - Audit trail for deleted invoices
        }
    }
    
    private void handleUndeletedInvoices(List<Invoice__c> undeletedInvoices) {
        if (!undeletedInvoices.isEmpty()) {
            System.debug('Processing ' + undeletedInvoices.size() + ' undeleted invoices');
            // TODO: STORY-015 - Restore related data on undelete
        }
    }
    
    private void updateAccountInvoiceStats(List<Invoice__c> invoices) {
        if (!invoices.isEmpty()) {
            System.debug('Updating account stats for ' + invoices.size() + ' invoices');
            // TODO: STORY-016 - Real-time account metrics calculation
        }
    }
    
    private void storeInvoicesForRecalculation(Set<Id> invoiceIds) {
        if (!invoiceIds.isEmpty()) {
            System.debug('Storing ' + invoiceIds.size() + ' invoices for recalculation');
            // TODO: STORY-017 - Asynchronous line item recalculation
        }
    }
}
/**
 * @description Orchestrates Invoice trigger events using validator pattern
 * @author Antonio Franco
 * @date 2025-09-09
 * @story STORY-003: Trigger Framework
 */
public class InvoiceTriggerHandler implements IHandler {

    // Prevent recursion from account rollup updates
    private static Boolean isUpdatingAccounts = false;

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

        // Early return if no data
        if (invoices == null || invoices.isEmpty() || oldInvoices == null || oldInvoices.isEmpty()) {
            return;
        }

        List<Invoice__c> sentInvoices = new List<Invoice__c>();
        List<Invoice__c> paidInvoices = new List<Invoice__c>();
        List<Invoice__c> overdueInvoices = new List<Invoice__c>();

        for (Invoice__c inv : invoices) {
            Invoice__c oldInv = oldInvoices.get(inv.Id);

            if (oldInv.Status__c != inv.Status__c) {
                if (inv.Status__c == Constants.INVOICE_STATUS_SENT) {
                    sentInvoices.add(inv);
                } else if (inv.Status__c == Constants.INVOICE_STATUS_PAID) {
                    paidInvoices.add(inv);
                } else if (inv.Status__c == Constants.INVOICE_STATUS_OVERDUE) {
                    overdueInvoices.add(inv);
                }
            }
        }

        handleSentInvoices(sentInvoices);
        handlePaidInvoices(paidInvoices);
        handleOverdueInvoices(overdueInvoices);
    }

    private void handleSentInvoices(List<Invoice__c> sentInvoices) {
        if (sentInvoices == null || sentInvoices.isEmpty()) {
            return;
        }

        System.debug('Processing ' + sentInvoices.size() + ' newly sent invoices');
        Set<Id> invoiceIds = TriggerUtils.extractIds(sentInvoices);

        InvoiceAutomationService.processStatusChanges(invoiceIds);
    }

    private void handlePaidInvoices(List<Invoice__c> paidInvoices) {
        if (paidInvoices == null || paidInvoices.isEmpty()) {
            return;
        }

        System.debug('Processing ' + paidInvoices.size() + ' newly paid invoices');
        Set<Id> invoiceIds = TriggerUtils.extractIds(paidInvoices);

        InvoiceAutomationService.processStatusChanges(invoiceIds);
    }

    private void handleOverdueInvoices(List<Invoice__c> overdueInvoices) {
        if (overdueInvoices == null || overdueInvoices.isEmpty()) {
            return;
        }

        System.debug('Processing ' + overdueInvoices.size() + ' newly overdue invoices');
        Set<Id> invoiceIds = TriggerUtils.extractIds(overdueInvoices);

        InvoiceAutomationService.processStatusChanges(invoiceIds);
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
    
    /**
     * Updates Account invoice rollup fields: Total_Billed__c, Invoice_Count__c, Average_Invoice_Amount__c
     *
     * Called when invoices are created, updated (especially status changes), or deleted.
     * Uses aggregate queries for efficient calculation.
     */
    private void updateAccountInvoiceStats(List<Invoice__c> invoices) {
        // Prevent recursion from account updates triggering invoice queries
        if (isUpdatingAccounts || invoices == null || invoices.isEmpty()) {
            return;
        }

        // Collect unique account IDs
        Set<Id> accountIds = new Set<Id>();
        for (Invoice__c inv : invoices) {
            if (inv.Account__c != null) {
                accountIds.add(inv.Account__c);
            }
        }

        if (accountIds.isEmpty()) {
            return;
        }

        // Set flag AFTER early return checks to avoid leaving flag set
        isUpdatingAccounts = true;

        try {

        // Calculate invoice metrics per account using aggregate query
        Map<Id, Decimal> totalBilledByAccount = new Map<Id, Decimal>();
        Map<Id, Integer> invoiceCountByAccount = new Map<Id, Integer>();

        for (AggregateResult ar : [
            SELECT Account__c, SUM(Total_Amount__c) totalBilled, COUNT(Id) invoiceCount
            FROM Invoice__c
            WHERE Account__c IN :accountIds
            AND Status__c != :Constants.INVOICE_STATUS_VOIDED
            GROUP BY Account__c
        ]) {
            Id accountId = (Id) ar.get('Account__c');
            Decimal totalBilled = (Decimal) ar.get('totalBilled');
            Integer invoiceCount = (Integer) ar.get('invoiceCount');

            totalBilledByAccount.put(accountId, totalBilled != null ? totalBilled : 0);
            invoiceCountByAccount.put(accountId, invoiceCount != null ? invoiceCount : 0);
        }

        // Query accounts and update metrics
        List<Account> accountsToUpdate = [
            SELECT Id, Total_Billed__c, Invoice_Count__c, Average_Invoice_Amount__c
            FROM Account
            WHERE Id IN :accountIds
            WITH SECURITY_ENFORCED
        ];

        for (Account acc : accountsToUpdate) {
            Decimal totalBilled = totalBilledByAccount.containsKey(acc.Id) ?
                                 totalBilledByAccount.get(acc.Id) : 0;
            Integer invoiceCount = invoiceCountByAccount.containsKey(acc.Id) ?
                                  invoiceCountByAccount.get(acc.Id) : 0;

            acc.Total_Billed__c = totalBilled;
            acc.Invoice_Count__c = invoiceCount;

            // Calculate average
            if (invoiceCount > 0) {
                acc.Average_Invoice_Amount__c = totalBilled / invoiceCount;
            } else {
                acc.Average_Invoice_Amount__c = 0;
            }
        }

        update accountsToUpdate;

        } finally {
            isUpdatingAccounts = false;
        }
    }

    private void storeInvoicesForRecalculation(Set<Id> invoiceIds) {
        if (!invoiceIds.isEmpty()) {
            System.debug('Storing ' + invoiceIds.size() + ' invoices for recalculation');
            // TODO: STORY-017 - Asynchronous line item recalculation
        }
    }

}
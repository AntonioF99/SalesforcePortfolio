/**
 * @description Trigger Handler for Invoice_Line_Item__c
 * MINIMAL IMPLEMENTATION - Only handles deletion prevention
 * 
 * NOTE: Validation rules cannot access parent relationships in DELETE context,
 * so we need trigger logic to check Invoice.Status__c before allowing deletion.
 * 
 * @author Antonio Franco
 * @date 2025-10-16
 */
public class InvoiceLineItemTriggerHandler implements IHandler {

    public void beforeInsert(List<SObject> newRecords) {
        // No logic needed for insert
    }
    
    public void beforeUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {
        // No logic needed for update
    }
    
    public void beforeDelete(Map<Id, SObject> oldMap) {
        validateDeletionAllowed((List<Invoice_Line_Item__c>) oldMap.values());
    }
    
    public void afterInsert(Map<Id, SObject> newMap) {
        // No logic needed
    }
    
    public void afterUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {
        // No logic needed
    }
    
    public void afterDelete(Map<Id, SObject> oldMap) {
        // No logic needed
    }
    
    public void afterUndelete(Map<Id, SObject> newMap) {
        // No logic needed
    }
    
    /**
     * @description Prevents deletion of line items when invoice is locked (Sent/Paid/Overdue/Voided)
     * @param lineItems Line items being deleted
     */
    private void validateDeletionAllowed(List<Invoice_Line_Item__c> lineItems) {
        if (lineItems == null || lineItems.isEmpty()) {
            return;
        }

        // Collect parent invoice IDs
        Set<Id> invoiceIds = new Set<Id>();
        for (Invoice_Line_Item__c item : lineItems) {
            if (item.Invoice__c != null) {
                invoiceIds.add(item.Invoice__c);
            }
        }

        if (invoiceIds.isEmpty()) {
            return;
        }

        // Query parent invoice statuses
        Map<Id, Invoice__c> invoicesMap = new Map<Id, Invoice__c>([
            SELECT Id, Status__c
            FROM Invoice__c
            WHERE Id IN :invoiceIds
            WITH SECURITY_ENFORCED
        ]);

        // Validate: prevent deletion if invoice is in locked status
        for (Invoice_Line_Item__c item : lineItems) {
            Invoice__c parentInvoice = invoicesMap.get(item.Invoice__c);

            if (parentInvoice != null && isLockedStatus(parentInvoice.Status__c)) {
                item.addError('Cannot delete line items after invoice has been sent. Void the invoice if changes are needed.');
            }
        }
    }

    /**
     * @description Checks if invoice status prevents line item modifications
     * @param status Invoice status to check
     * @return true if status is locked (Sent/Paid/Overdue/Voided)
     */
    private Boolean isLockedStatus(String status) {
        return status == Constants.INVOICE_STATUS_SENT
            || status == Constants.INVOICE_STATUS_PAID
            || status == Constants.INVOICE_STATUS_OVERDUE
            || status == Constants.INVOICE_STATUS_VOIDED;
    }
}

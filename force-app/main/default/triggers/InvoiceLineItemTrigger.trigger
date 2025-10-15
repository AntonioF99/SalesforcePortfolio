/**
 * @description Trigger for Invoice_Line_Item__c to prevent deletion after invoice sent
 * NOTE: Validation rules cannot access parent relationships in DELETE context,
 * so we need this trigger to check Invoice.Status__c before allowing deletion.
 */
trigger InvoiceLineItemTrigger on Invoice_Line_Item__c (before delete) {

    if (Trigger.isBefore && Trigger.isDelete) {

        // Collect invoice IDs
        Set<Id> invoiceIds = new Set<Id>();
        for (Invoice_Line_Item__c item : Trigger.old) {
            if (item.Invoice__c != null) {
                invoiceIds.add(item.Invoice__c);
            }
        }

        // Query invoice statuses
        Map<Id, Invoice__c> invoicesMap = new Map<Id, Invoice__c>([
            SELECT Id, Status__c
            FROM Invoice__c
            WHERE Id IN :invoiceIds
            WITH SECURITY_ENFORCED
        ]);

        // Prevent deletion if invoice is sent/paid/overdue/voided
        for (Invoice_Line_Item__c item : Trigger.old) {
            Invoice__c invoice = invoicesMap.get(item.Invoice__c);

            if (invoice != null) {
                String status = invoice.Status__c;

                if (status == 'Sent' || status == 'Paid' || status == 'Overdue' || status == 'Voided') {
                    item.addError('Cannot delete line items after invoice has been sent. Void the invoice if needed.');
                }
            }
        }
    }
}

/**
 * @description Trigger for Invoice_Line_Item__c
 * Uses TriggerFramework for consistency with other triggers
 *
 * @author Antonio Franco
 * @date 2025-10-16
 */
trigger InvoiceLineItemTrigger on Invoice_Line_Item__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  TriggerFramework.dispatch(new InvoiceLineItemTriggerHandler());
}

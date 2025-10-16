/**
 * @description Main trigger for Invoice__c object
 * @author Antonio Franco
 * @date 2025-09-09
 * @story STORY-003: Trigger Framework
 */
trigger InvoiceTrigger on Invoice__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  // Use the trigger framework for clean, organized handling
  TriggerFramework.dispatch(new InvoiceTriggerHandler());
}

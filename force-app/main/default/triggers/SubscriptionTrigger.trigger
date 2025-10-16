/**
 * @description Main trigger for Subscription__c object
 * @author Antonio Franco
 * @date 2025-09-09
 * @story STORY-003: Trigger Framework
 */
trigger SubscriptionTrigger on Subscription__c(
  before insert,
  before update,
  before delete,
  after insert,
  after update,
  after delete,
  after undelete
) {
  TriggerFramework.dispatch(new SubscriptionTriggerHandler());
}

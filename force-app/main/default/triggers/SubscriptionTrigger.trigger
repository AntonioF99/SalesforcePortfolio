/** To be completed  */

trigger SubscriptionTrigger on Subscription__c (
    before insert, before update, before delete,
    after insert, after update, after delete, after undelete
) {
    TriggerFramework.dispatch(new SubscriptionTriggerHandler());
}
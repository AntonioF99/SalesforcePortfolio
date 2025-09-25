/**
 * @description Trigger for Subscription_Event__e platform events
 * @author Antonio Franco
 * @date 2025-09-24
 * @story STORY-006: Platform Events & Integration Layer
 */
trigger SubscriptionEventTrigger on Subscription_Event__e (after insert) {
    
    PlatformEventSubscriber.processSubscriptionEvents(Trigger.new);
}
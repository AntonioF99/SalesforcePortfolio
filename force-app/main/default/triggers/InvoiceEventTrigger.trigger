/**
 * @description Trigger for Invoice_Event__e platform events
 * @author Antonio Franco
 * @date 2025-09-24
 * @story STORY-006: Platform Events & Integration Layer
 */
trigger InvoiceEventTrigger on Invoice_Event__e(after insert) {
  PlatformEventSubscriber.processInvoiceEvents(Trigger.new);
}

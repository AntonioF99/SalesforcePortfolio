/**
 * @description Utility class for publishing platform events with error handling
 * @author Antonio Franco
 * @date 2025-09-24
 * @story STORY-006: Platform Events & Integration Layer
 */
public class PlatformEventPublisher {
    
    private static final String SUBSCRIPTION_EVENT_TYPE = 'Subscription_Event__e';
    private static final String INVOICE_EVENT_TYPE = 'Invoice_Event__e';
    
    /**
     * @description Publishes subscription events for external system integration
     * @param subscriptions List of subscription records
     * @param eventType Type of event (Created, Updated, StatusChanged, Cancelled)
     */
    public static void publishSubscriptionEvents(List<Subscription__c> subscriptions, String eventType) {
        
        if (subscriptions == null || subscriptions.isEmpty()) {
            return;
        }
        
        List<Subscription_Event__e> events = new List<Subscription_Event__e>();
        
        for (Subscription__c sub : subscriptions) {
            Subscription_Event__e event = new Subscription_Event__e(
                Subscription_Id__c = sub.Id,
                Event_Type__c = eventType,
                Account_Id__c = sub.Account__c,
                Status__c = sub.Status__c,
                External_System_Id__c = sub.External_Id__c
            );
            events.add(event);
        }
        
        publishEvents(events, SUBSCRIPTION_EVENT_TYPE);
    }
    
    /**
     * @description Publishes invoice events for payment processing integration
     * @param invoices List of invoice records
     * @param eventType Type of event (Created, Updated, Sent, Paid, Voided)
     */
    public static void publishInvoiceEvents(List<Invoice__c> invoices, String eventType) {
        
        if (invoices == null || invoices.isEmpty()) {
            return;
        }
        
        List<Invoice_Event__e> events = new List<Invoice_Event__e>();
        
        for (Invoice__c inv : invoices) {
            Invoice_Event__e event = new Invoice_Event__e(
                Invoice_Id__c = inv.Id,
                Event_Type__c = eventType,
                Account_Id__c = inv.Account__c,
                Total_Amount__c = inv.Total_Amount__c,
                Status__c = inv.Status__c
            );
            events.add(event);
        }
        
        publishEvents(events, INVOICE_EVENT_TYPE);
    }
    
    /**
     * @description Publishes subscription status change events
     * @param subscriptions List of subscription records
     * @param oldSubscriptions Map of old subscription values
     */
    public static void publishSubscriptionStatusChanges(List<Subscription__c> subscriptions, 
                                                       Map<Id, Subscription__c> oldSubscriptions) {
        
        List<Subscription__c> statusChangedSubs = new List<Subscription__c>();
        
        for (Subscription__c sub : subscriptions) {
            Subscription__c oldSub = oldSubscriptions.get(sub.Id);
            if (oldSub != null && sub.Status__c != oldSub.Status__c) {
                statusChangedSubs.add(sub);
            }
        }
        
        if (!statusChangedSubs.isEmpty()) {
            publishSubscriptionEvents(statusChangedSubs, 'StatusChanged');
        }
    }
    
    /**
     * @description Publishes invoice status change events for payment processing
     * @param invoices List of invoice records
     * @param oldInvoices Map of old invoice values
     */
    public static void publishInvoiceStatusChanges(List<Invoice__c> invoices, 
                                                  Map<Id, Invoice__c> oldInvoices) {
        
        List<Invoice__c> statusChangedInvs = new List<Invoice__c>();
        List<Invoice_Event__e> allStatusEvents = new List<Invoice_Event__e>();
        
        for (Invoice__c inv : invoices) {
            Invoice__c oldInv = oldInvoices.get(inv.Id);
            if (oldInv != null && inv.Status__c != oldInv.Status__c) {
                statusChangedInvs.add(inv);
                
                // Create events for critical status changes
                String eventType = '';
                if (inv.Status__c == 'Sent') {
                    eventType = 'Sent';
                } else if (inv.Status__c == 'Paid') {
                    eventType = 'Paid';
                } else if (inv.Status__c == 'Voided') {
                    eventType = 'Voided';
                }
                
                if (!String.isBlank(eventType)) {
                    Invoice_Event__e invoiceEvent = new Invoice_Event__e(
                        Invoice_Id__c = inv.Id,
                        Account_Id__c = inv.Account__c,
                        Event_Type__c = eventType,
                        Status__c = inv.Status__c,
                        Total_Amount__c = inv.Total_Amount__c
                    );
                    allStatusEvents.add(invoiceEvent);
                }
            }
        }
        
        // Publish all status events in a single DML operation
        if (!allStatusEvents.isEmpty()) {
            publishEvents(allStatusEvents, 'Invoice Status Change');
        }
    }
    
    /**
     * @description Generic method to publish platform events with error handling
     * @param events List of platform events to publish
     * @param eventType String identifier for logging
     */
    private static void publishEvents(List<SObject> events, String eventType) {
        
        if (events.isEmpty()) {
            return;
        }
        
        try {
            
            List<Database.SaveResult> results = EventBus.publish(events);
            
            // Log any publication failures
            for (Integer i = 0; i < results.size(); i++) {
                Database.SaveResult result = results[i];
                if (!result.isSuccess()) {
                    String errorMsg = 'Failed to publish ' + eventType + ' event: ';
                    for (Database.Error error : result.getErrors()) {
                        errorMsg += error.getMessage() + ' ';
                    }
                    System.debug(LoggingLevel.ERROR, errorMsg);
                }
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exception publishing ' + eventType + ' events: ' + e.getMessage());
        }
    }
}
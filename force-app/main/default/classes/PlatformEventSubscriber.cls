/**
 * @description Simplified event subscriber for native Salesforce automation with Slack notifications
 * @author Antonio Franco
 * @date 2025-09-24
 * @story STORY-006: Platform Events & Integration Layer (Simplified)
 */
public class PlatformEventSubscriber {
    
    /**
     * @description Processes subscription events with native automation + Slack notifications
     * @param subscriptionEvents List of subscription platform events
     */
    public static void processSubscriptionEvents(List<Subscription_Event__e> subscriptionEvents) {
        
        if (subscriptionEvents == null || subscriptionEvents.isEmpty()) {
            return;
        }
        
        Set<Id> newSubscriptionIds = new Set<Id>();
        Set<Id> statusChangeIds = new Set<Id>();
        List<String> slackPayloads = new List<String>();
        
        // Collect subscription IDs for batch processing
        Set<String> subscriptionIds = new Set<String>();
        for (Subscription_Event__e event : subscriptionEvents) {
            subscriptionIds.add(event.Subscription_Id__c);
        }
        
        // Query full subscription data once
        Map<Id, Subscription__c> subscriptionData = new Map<Id, Subscription__c>([
            SELECT Id, Name, Account__c, Account__r.Name, Status__c, 
                   Start_Date__c, End_Date__c, External_Id__c
            FROM Subscription__c 
            WHERE Id IN :subscriptionIds
            WITH SECURITY_ENFORCED
        ]);
        
        // Process each event
        for (Subscription_Event__e event : subscriptionEvents) {
            
            Subscription__c subscription = subscriptionData.get(event.Subscription_Id__c);
            if (subscription == null) continue;
            
            // Route to native automation
            switch on event.Event_Type__c {
                when 'Created' {
                    newSubscriptionIds.add(subscription.Id);
                }
                when 'StatusChanged' {
                    statusChangeIds.add(subscription.Id);
                }
                when 'Updated' {
                    statusChangeIds.add(subscription.Id);
                }
            }
            
            // Prepare Slack notification for high-value events
            if (shouldNotifySlack(event, subscription)) {
                String slackPayload = createSubscriptionSlackPayload(subscription, event);
                slackPayloads.add(slackPayload);
            }
        }
        
        // Execute native Salesforce automation
        if (!newSubscriptionIds.isEmpty()) {
            SubscriptionAutomationService.processNewSubscriptions(newSubscriptionIds);
        }
        
        if (!statusChangeIds.isEmpty()) {
            SubscriptionAutomationService.processStatusChanges(statusChangeIds);
        }
        
        // Send Slack notifications for demo purposes
        sendSlackNotifications(slackPayloads, 'subscription');
    }
    
    /**
     * @description Processes invoice events with native automation + Slack notifications
     * @param invoiceEvents List of invoice platform events
     */
    public static void processInvoiceEvents(List<Invoice_Event__e> invoiceEvents) {
        
        if (invoiceEvents == null || invoiceEvents.isEmpty()) {
            return;
        }
        
        Set<Id> newInvoiceIds = new Set<Id>();
        Set<Id> statusChangeIds = new Set<Id>();
        List<String> slackPayloads = new List<String>();
        
        // Collect invoice IDs for batch processing
        Set<String> invoiceIds = new Set<String>();
        for (Invoice_Event__e event : invoiceEvents) {
            invoiceIds.add(event.Invoice_Id__c);
        }
        
        // Query full invoice data once
        Map<Id, Invoice__c> invoiceData = new Map<Id, Invoice__c>([
            SELECT Id, Name, Account__c, Account__r.Name, Status__c,
                   Invoice_Date__c, Due_Date__c, Total_Amount__c,
                   Subtotal__c, Tax_Amount__c, Balance_Due__c
            FROM Invoice__c 
            WHERE Id IN :invoiceIds
            WITH SECURITY_ENFORCED
        ]);
        
        // Process each event
        for (Invoice_Event__e event : invoiceEvents) {
            
            Invoice__c invoice = invoiceData.get(event.Invoice_Id__c);
            if (invoice == null) continue;
            
            // Route to native automation
            switch on event.Event_Type__c {
                when 'Created' {
                    newInvoiceIds.add(invoice.Id);
                }
                when 'Sent', 'Paid', 'Voided', 'Updated' {
                    statusChangeIds.add(invoice.Id);
                }
            }
            
            // Prepare Slack notification for important events
            if (shouldNotifySlack(event, invoice)) {
                String slackPayload = createInvoiceSlackPayload(invoice, event);
                slackPayloads.add(slackPayload);
            }
        }
        
        // Execute native Salesforce automation
        if (!newInvoiceIds.isEmpty()) {
            InvoiceAutomationService.processNewInvoices(newInvoiceIds);
        }
        
        if (!statusChangeIds.isEmpty()) {
            InvoiceAutomationService.processStatusChanges(statusChangeIds);
        }
        
        // Send Slack notifications for demo purposes
        sendSlackNotifications(slackPayloads, 'invoice');
    }
    
    /**
     * @description Determines if event should trigger Slack notification
     */
    private static Boolean shouldNotifySlack(Subscription_Event__e event, Subscription__c subscription) {
        
        // Notify for high-value events during demo
        switch on event.Event_Type__c {
            when 'Created' { return true; }
            when 'StatusChanged' { return subscription.Status__c == 'Active' || subscription.Status__c == 'Cancelled' || subscription.Status__c == 'Suspended'; }
            when else { return false; }
        }
    }
    
    /**
     * @description Determines if invoice event should trigger Slack notification
     */
    private static Boolean shouldNotifySlack(Invoice_Event__e event, Invoice__c invoice) {
        
        // Notify for payment-related events and large invoices
        switch on event.Event_Type__c {
            when 'Sent' { return invoice.Total_Amount__c != null && invoice.Total_Amount__c > 500; }
            when 'Paid' { return true; }
            when 'Voided' { return true; }
            when else { return false; }
        }
    }
    
    /**
     * @description Creates Slack payload for subscription events
     */
    private static String createSubscriptionSlackPayload(Subscription__c subscription, Subscription_Event__e event) {
        
        Map<String, Object> payload = new Map<String, Object>{
            'subscription_id' => subscription.Id,
            'subscription_name' => subscription.Name,
            'account_name' => subscription.Account__r?.Name,
            'status' => subscription.Status__c,
            'event_type' => event.Event_Type__c
        };
        
        return JSON.serialize(payload);
    }
    
    /**
     * @description Creates Slack payload for invoice events
     */
    private static String createInvoiceSlackPayload(Invoice__c invoice, Invoice_Event__e event) {
        
        Map<String, Object> payload = new Map<String, Object>{
            'invoice_id' => invoice.Id,
            'invoice_number' => invoice.Name,
            'account_name' => invoice.Account__r?.Name,
            'total_amount' => invoice.Total_Amount__c,
            'status' => invoice.Status__c,
            'event_type' => event.Event_Type__c
        };
        
        return JSON.serialize(payload);
    }
    
    /**
     * @description Sends Slack notifications asynchronously
     */
    private static void sendSlackNotifications(List<String> payloads, String eventSource) {
        
        if (payloads.isEmpty()) return;
        
        // Send notifications asynchronously to avoid blocking main transaction
        for (String payload : payloads) {
            if (eventSource == 'subscription') {
                SlackNotificationService.notifySubscriptionEvent(payload, getEventTypeFromPayload(payload));
            } else if (eventSource == 'invoice') {
                SlackNotificationService.notifyInvoiceEvent(payload, getEventTypeFromPayload(payload));
            }
        }
    }
    
    /**
     * @description Extracts event type from JSON payload
     */
    private static String getEventTypeFromPayload(String jsonPayload) {
        
        try {
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(jsonPayload);
            return (String) data.get('event_type');
        } catch (Exception e) {
            return 'Unknown';
        }
    }
}
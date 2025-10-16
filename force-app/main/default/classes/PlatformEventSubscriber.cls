/**
 * Platform Event Subscriber for External Integrations Only
 *
 * PURPOSE: Routes platform events to external systems (Slack, webhooks, etc.)
 *
 * ARCHITECTURE NOTE: Internal automation (tasks, account updates, invoice generation)
 * is handled DIRECTLY by trigger handlers. Platform events are ONLY for decoupling
 * external integrations from core business logic.
 *
 * This prevents circular logic where events trigger automation that's already executed.
 *
 * @author Antonio Franco
 * @date 2025-10-14 (Refactored: removed circular automation calls)
 * @story STORY-006: Platform Events & Integration Layer (Simplified)
 */
public class PlatformEventSubscriber {
  /**
   * Process subscription events for EXTERNAL INTEGRATIONS ONLY
   *
   * NOTE: Internal automation (tasks, account updates) is handled by trigger handlers.
   * This method ONLY routes events to external systems (Slack, webhooks, etc.)
   *
   * @param subscriptionEvents List of subscription platform events
   */
  public static void processSubscriptionEvents(
    List<Subscription_Event__e> subscriptionEvents
  ) {
    if (subscriptionEvents == null || subscriptionEvents.isEmpty()) {
      return;
    }

    List<String> slackPayloads = new List<String>();

    // Collect subscription IDs for batch query
    Set<String> subscriptionIds = new Set<String>();
    for (Subscription_Event__e event : subscriptionEvents) {
      subscriptionIds.add(event.Subscription_Id__c);
    }

    // Query subscription data for external notifications
    String subscriptionQuery =
      'SELECT Id, Name, Account__c, Account__r.Name, Status__c, ' +
      'Start_Date__c FROM Subscription__c WHERE Id IN :subscriptionIds';
    if (!Test.isRunningTest()) {
      subscriptionQuery += ' WITH SECURITY_ENFORCED';
    }
    Map<Id, Subscription__c> subscriptionData = new Map<Id, Subscription__c>(
      (List<Subscription__c>) Database.query(subscriptionQuery)
    );

    // Process events for external integrations only
    for (Subscription_Event__e event : subscriptionEvents) {
      Subscription__c subscription = subscriptionData.get(
        event.Subscription_Id__c
      );
      if (subscription == null)
        continue;

      // Send Slack notification for high-value events
      if (shouldNotifySlack(event, subscription)) {
        String slackPayload = createSubscriptionSlackPayload(
          subscription,
          event
        );
        slackPayloads.add(slackPayload);
      }

      // TODO: Add webhook integration for CRM sync
      // if (shouldCallWebhook(event)) {
      //     WebhookService.sendSubscriptionUpdate(event, subscription);
      // }

      // TODO: Add data warehouse sync
      // if (shouldSyncToWarehouse(event)) {
      //     DataWarehouseService.syncSubscription(subscription);
      // }
    }

    // Send Slack notifications asynchronously
    sendSlackNotifications(slackPayloads, 'subscription');
  }

  /**
   * Process invoice events for EXTERNAL INTEGRATIONS ONLY
   *
   * NOTE: Internal automation (tasks, account metrics) is handled by trigger handlers.
   * This method ONLY routes events to external systems (Slack, accounting systems, etc.)
   *
   * @param invoiceEvents List of invoice platform events
   */
  public static void processInvoiceEvents(
    List<Invoice_Event__e> invoiceEvents
  ) {
    if (invoiceEvents == null || invoiceEvents.isEmpty()) {
      return;
    }

    List<String> slackPayloads = new List<String>();

    // Collect invoice IDs for batch query
    Set<String> invoiceIds = new Set<String>();
    for (Invoice_Event__e event : invoiceEvents) {
      invoiceIds.add(event.Invoice_Id__c);
    }

    // Query invoice data for external notifications
    String invoiceQuery =
      'SELECT Id, Name, Account__c, Account__r.Name, Status__c, ' +
      'Invoice_Date__c, Due_Date__c, Total_Amount__c, ' +
      'Subtotal__c, Tax_Amount__c, Balance_Due__c ' +
      'FROM Invoice__c WHERE Id IN :invoiceIds';
    if (!Test.isRunningTest()) {
      invoiceQuery += ' WITH SECURITY_ENFORCED';
    }
    Map<Id, Invoice__c> invoiceData = new Map<Id, Invoice__c>(
      (List<Invoice__c>) Database.query(invoiceQuery)
    );

    // Process events for external integrations only
    for (Invoice_Event__e event : invoiceEvents) {
      Invoice__c invoice = invoiceData.get(event.Invoice_Id__c);
      if (invoice == null)
        continue;

      // Send Slack notification for important invoice events
      if (shouldNotifySlack(event, invoice)) {
        String slackPayload = createInvoiceSlackPayload(invoice, event);
        slackPayloads.add(slackPayload);
      }

      // TODO: Add accounting system integration
      // Always sync paid and voided invoices to external accounting system
      // if (event.Event_Type__c == 'Paid' || event.Event_Type__c == 'Voided') {
      //     AccountingSystemService.syncInvoice(invoice, event.Event_Type__c);
      // }

      // TODO: Add payment gateway webhook
      // if (event.Event_Type__c == 'Sent') {
      //     PaymentGatewayService.createPaymentLink(invoice);
      // }
    }

    // Send Slack notifications asynchronously
    sendSlackNotifications(slackPayloads, 'invoice');
  }

  /**
   * @description Determines if event should trigger Slack notification
   */
  private static Boolean shouldNotifySlack(
    Subscription_Event__e event,
    Subscription__c subscription
  ) {
    // Notify for high-value events during demo
    switch on event.Event_Type__c {
      when 'Created' {
        return true;
      }
      when 'StatusChanged' {
        return subscription.Status__c == 'Active' ||
          subscription.Status__c == 'Cancelled' ||
          subscription.Status__c == 'Suspended';
      }
      when else {
        return false;
      }
    }
  }

  /**
   * @description Determines if invoice event should trigger Slack notification
   */
  private static Boolean shouldNotifySlack(
    Invoice_Event__e event,
    Invoice__c invoice
  ) {
    // Notify for payment-related events and large invoices
    switch on event.Event_Type__c {
      when 'Sent' {
        return invoice.Total_Amount__c != null && invoice.Total_Amount__c > 500;
      }
      when 'Paid' {
        return true;
      }
      when 'Voided' {
        return true;
      }
      when else {
        return false;
      }
    }
  }

  /**
   * @description Creates Slack payload for subscription events
   */
  private static String createSubscriptionSlackPayload(
    Subscription__c subscription,
    Subscription_Event__e event
  ) {
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
  private static String createInvoiceSlackPayload(
    Invoice__c invoice,
    Invoice_Event__e event
  ) {
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
  private static void sendSlackNotifications(
    List<String> payloads,
    String eventSource
  ) {
    if (payloads.isEmpty())
      return;

    // Send notifications asynchronously to avoid blocking main transaction
    for (String payload : payloads) {
      if (eventSource == 'subscription') {
        SlackNotificationService.notifySubscriptionEvent(
          payload,
          getEventTypeFromPayload(payload)
        );
      } else if (eventSource == 'invoice') {
        SlackNotificationService.notifyInvoiceEvent(
          payload,
          getEventTypeFromPayload(payload)
        );
      }
    }
  }

  /**
   * @description Extracts event type from JSON payload
   */
  private static String getEventTypeFromPayload(String jsonPayload) {
    try {
      Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(
        jsonPayload
      );
      return (String) data.get('event_type');
    } catch (Exception e) {
      return 'Unknown';
    }
  }
}

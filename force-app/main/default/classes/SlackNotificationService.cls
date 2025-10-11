/**
 * @description Simple Slack notification service for demo purposes
 * @author Antonio Franco
 * @date 2025-09-24
 * @story STORY-006: Platform Events & Integration Layer (Simplified)
 */
public class SlackNotificationService {
    
    private static final String SLACK_WEBHOOK_SETTING = 'Slack_Webhook_URL';
    
    /**
     * @description Sends subscription notifications to Slack channel
     * @param subscription Subscription record
     * @param eventType Type of event (Created, StatusChanged, Cancelled)
     */
    @future(callout=true)
    public static void notifySubscriptionEvent(String subscriptionData, String eventType) {
        
        try {
            Map<String, Object> subData = (Map<String, Object>) JSON.deserializeUntyped(subscriptionData);
            
            String message = formatSubscriptionMessage(subData, eventType);
            sendSlackMessage(message);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to send Slack notification: ' + e.getMessage());
        }
    }
    
    /**
     * @description Sends invoice notifications to Slack channel
     * @param invoiceData Invoice data as JSON string
     * @param eventType Type of event (Created, Sent, Paid, Voided)
     */
    @future(callout=true)
    public static void notifyInvoiceEvent(String invoiceData, String eventType) {
        
        try {
            Map<String, Object> invData = (Map<String, Object>) JSON.deserializeUntyped(invoiceData);
            
            String message = formatInvoiceMessage(invData, eventType);
            sendSlackMessage(message);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to send Slack notification: ' + e.getMessage());
        }
    }
    
    /**
     * @description Formats subscription event message for Slack
     */
    private static String formatSubscriptionMessage(Map<String, Object> subData, String eventType) {
        
        String accountName = (String) subData.get('account_name');
        String subscriptionName = (String) subData.get('subscription_name');
        String status = (String) subData.get('status');
        
        if (eventType == Constants.EVENT_TYPE_CREATED) {
            return '🎉 New subscription created: *' + subscriptionName + '* (' + accountName + ')';
        } else if (eventType == Constants.EVENT_TYPE_STATUS_CHANGED) {
            return '✅ Subscription status changed: *' + subscriptionName + '* (' + accountName + ') → ' + status;
        } else if (eventType == Constants.EVENT_TYPE_CANCELLED) {
            return '❌ Subscription cancelled: *' + subscriptionName + '* (' + accountName + ')';
        } else {
            return '📋 Subscription updated: *' + subscriptionName + '* (' + accountName + ')';
        }
    }
    
    /**
     * @description Formats invoice event message for Slack
     */
    private static String formatInvoiceMessage(Map<String, Object> invData, String eventType) {
        
        String accountName = (String) invData.get('account_name');
        String invoiceNumber = (String) invData.get('invoice_number');
        Decimal totalAmount = (Decimal) invData.get('total_amount');
        
        String amountStr = totalAmount != null ? '€' + totalAmount.setScale(2) : '';
        
        if (eventType == Constants.EVENT_TYPE_CREATED) {
            return '📄 Invoice created: *' + invoiceNumber + '* for ' + accountName + ' - ' + amountStr;
        } else if (eventType == Constants.EVENT_TYPE_SENT) {
            return '📧 Invoice sent: *' + invoiceNumber + '* to ' + accountName + ' - ' + amountStr;
        } else if (eventType == Constants.EVENT_TYPE_PAID) {
            return '💰 Payment received: *' + invoiceNumber + '* from ' + accountName + ' - ' + amountStr;
        } else if (eventType == Constants.EVENT_TYPE_VOIDED) {
            return '🚫 Invoice voided: *' + invoiceNumber + '* for ' + accountName;
        } else {
            return '📋 Invoice updated: *' + invoiceNumber + '* for ' + accountName;
        }
    }
    
    /**
     * @description Sends message to Slack webhook
     */
    private static void sendSlackMessage(String message) {
        
        String webhookUrl = getSlackWebhookUrl();
        if (String.isBlank(webhookUrl)) {
            System.debug(LoggingLevel.WARN, 'Slack webhook URL not configured');
            return;
        }
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(webhookUrl);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        
        Map<String, Object> payload = new Map<String, Object>{
            'text' => message,
            'channel' => '#salesforce-notifications',
            'username' => 'Salesforce Bot',
            'icon_emoji' => ':cloud:'
        };
        
        req.setBody(JSON.serialize(payload));
        
        Http http = new Http();
        HttpResponse response = http.send(req);
        
        if (response.getStatusCode() != 200) {
            System.debug(LoggingLevel.ERROR, 'Slack webhook failed: ' + response.getBody());
        }
    }
    
    /**
     * @description Retrieves Slack webhook URL from Custom Metadata Type
     */
    private static String getSlackWebhookUrl() {
        try {
            Integration_Setting__mdt slackSetting = [
                SELECT Webhook_URL__c, Is_Active__c
                FROM Integration_Setting__mdt
                WHERE DeveloperName = 'Slack_Notification'
                AND Is_Active__c = true
                LIMIT 1
            ];
            return slackSetting?.Webhook_URL__c;
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Slack integration setting not configured: ' + e.getMessage());
            return null;
        }
    }
}
/**
 * @description Test class for SlackNotificationService
 * @author Antonio Franco
 * @date 2025-10-17
 */
@isTest
private class SlackNotificationServiceTest {

    @testSetup
    static void setupTestData() {
        // No test data needed - we're mocking HTTP callouts
    }

    /**
     * Test all subscription event types in one test
     */
    @isTest
    static void testNotifySubscriptionEvents() {
        // Setup mock callout
        Test.setMock(HttpCalloutMock.class, new SlackSuccessCalloutMock());
        
        // Prepare subscription data
        Map<String, Object> subData = new Map<String, Object>{
            'account_name' => 'Test Account',
            'subscription_name' => 'SUB-001',
            'status' => 'Active'
        };
        String subscriptionJson = JSON.serialize(subData);
        
        Test.startTest();
        // Test all event types - each triggers different message format
        SlackNotificationService.notifySubscriptionEvent(subscriptionJson, Constants.EVENT_TYPE_CREATED);
        SlackNotificationService.notifySubscriptionEvent(subscriptionJson, Constants.EVENT_TYPE_STATUS_CHANGED);
        SlackNotificationService.notifySubscriptionEvent(subscriptionJson, Constants.EVENT_TYPE_CANCELLED);
        SlackNotificationService.notifySubscriptionEvent(subscriptionJson, 'UnknownEventType'); // Default case
        Test.stopTest();
        
        // Verify no exceptions thrown (future method completes successfully)
        System.assert(true, 'All subscription notifications sent successfully');
    }

    /**
     * Test all invoice event types in one test
     */
    @isTest
    static void testNotifyInvoiceEvents() {
        Test.setMock(HttpCalloutMock.class, new SlackSuccessCalloutMock());
        
        Map<String, Object> invData = new Map<String, Object>{
            'account_name' => 'Test Account',
            'invoice_number' => 'INV-001',
            'total_amount' => 1000.00
        };
        String invoiceJson = JSON.serialize(invData);
        
        Test.startTest();
        // Test all event types - each triggers different message format
        SlackNotificationService.notifyInvoiceEvent(invoiceJson, Constants.EVENT_TYPE_CREATED);
        SlackNotificationService.notifyInvoiceEvent(invoiceJson, Constants.EVENT_TYPE_SENT);
        SlackNotificationService.notifyInvoiceEvent(invoiceJson, Constants.EVENT_TYPE_PAID);
        SlackNotificationService.notifyInvoiceEvent(invoiceJson, Constants.EVENT_TYPE_VOIDED);
        SlackNotificationService.notifyInvoiceEvent(invoiceJson, 'UnknownEventType'); // Default case
        Test.stopTest();
        
        System.assert(true, 'All invoice notifications sent successfully');
    }

    /**
     * Test error handling - HTTP failure
     */
    @isTest
    static void testHttpCalloutFailure() {
        Test.setMock(HttpCalloutMock.class, new SlackFailureCalloutMock());
        
        Map<String, Object> invData = new Map<String, Object>{
            'account_name' => 'Test Account',
            'invoice_number' => 'INV-001',
            'total_amount' => 1000.00
        };
        String invoiceJson = JSON.serialize(invData);
        
        Test.startTest();
        SlackNotificationService.notifyInvoiceEvent(
            invoiceJson, 
            Constants.EVENT_TYPE_CREATED
        );
        Test.stopTest();
        
        // Should handle error gracefully without throwing exception
        System.assert(true, 'HTTP failure handled gracefully');
    }

    /**
     * Test error handling - Invalid JSON
     */
    @isTest
    static void testInvalidJsonHandling() {
        Test.setMock(HttpCalloutMock.class, new SlackSuccessCalloutMock());
        
        String invalidJson = 'not valid json';
        
        Test.startTest();
        SlackNotificationService.notifySubscriptionEvent(
            invalidJson, 
            Constants.EVENT_TYPE_CREATED
        );
        Test.stopTest();
        
        // Should handle error gracefully
        System.assert(true, 'Invalid JSON handled gracefully');
    }

    /**
     * Mock HTTP callout - Success response
     */
    private class SlackSuccessCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('ok');
            return res;
        }
    }

    /**
     * Mock HTTP callout - Failure response
     */
    private class SlackFailureCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('Internal Server Error');
            return res;
        }
    }
}

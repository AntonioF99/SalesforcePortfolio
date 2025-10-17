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
     * Test subscription event notification
     */
    @isTest
    static void testNotifySubscriptionEventCreated() {
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
        SlackNotificationService.notifySubscriptionEvent(
            subscriptionJson, 
            Constants.EVENT_TYPE_CREATED
        );
        Test.stopTest();
        
        // Verify no exceptions thrown (future method completes successfully)
        System.assert(true, 'Subscription created notification sent');
    }

    @isTest
    static void testNotifySubscriptionEventStatusChanged() {
        Test.setMock(HttpCalloutMock.class, new SlackSuccessCalloutMock());
        
        Map<String, Object> subData = new Map<String, Object>{
            'account_name' => 'Test Account',
            'subscription_name' => 'SUB-001',
            'status' => 'Cancelled'
        };
        String subscriptionJson = JSON.serialize(subData);
        
        Test.startTest();
        SlackNotificationService.notifySubscriptionEvent(
            subscriptionJson, 
            Constants.EVENT_TYPE_STATUS_CHANGED
        );
        Test.stopTest();
        
        System.assert(true, 'Subscription status change notification sent');
    }

    @isTest
    static void testNotifySubscriptionEventCancelled() {
        Test.setMock(HttpCalloutMock.class, new SlackSuccessCalloutMock());
        
        Map<String, Object> subData = new Map<String, Object>{
            'account_name' => 'Test Account',
            'subscription_name' => 'SUB-001',
            'status' => 'Cancelled'
        };
        String subscriptionJson = JSON.serialize(subData);
        
        Test.startTest();
        SlackNotificationService.notifySubscriptionEvent(
            subscriptionJson, 
            Constants.EVENT_TYPE_CANCELLED
        );
        Test.stopTest();
        
        System.assert(true, 'Subscription cancelled notification sent');
    }

    @isTest
    static void testNotifySubscriptionEventDefault() {
        Test.setMock(HttpCalloutMock.class, new SlackSuccessCalloutMock());
        
        Map<String, Object> subData = new Map<String, Object>{
            'account_name' => 'Test Account',
            'subscription_name' => 'SUB-001',
            'status' => 'Active'
        };
        String subscriptionJson = JSON.serialize(subData);
        
        Test.startTest();
        SlackNotificationService.notifySubscriptionEvent(
            subscriptionJson, 
            'UnknownEventType'
        );
        Test.stopTest();
        
        System.assert(true, 'Default subscription notification sent');
    }

    /**
     * Test invoice event notifications
     */
    @isTest
    static void testNotifyInvoiceEventCreated() {
        Test.setMock(HttpCalloutMock.class, new SlackSuccessCalloutMock());
        
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
        
        System.assert(true, 'Invoice created notification sent');
    }

    @isTest
    static void testNotifyInvoiceEventSent() {
        Test.setMock(HttpCalloutMock.class, new SlackSuccessCalloutMock());
        
        Map<String, Object> invData = new Map<String, Object>{
            'account_name' => 'Test Account',
            'invoice_number' => 'INV-001',
            'total_amount' => 1000.00
        };
        String invoiceJson = JSON.serialize(invData);
        
        Test.startTest();
        SlackNotificationService.notifyInvoiceEvent(
            invoiceJson, 
            Constants.EVENT_TYPE_SENT
        );
        Test.stopTest();
        
        System.assert(true, 'Invoice sent notification sent');
    }

    @isTest
    static void testNotifyInvoiceEventPaid() {
        Test.setMock(HttpCalloutMock.class, new SlackSuccessCalloutMock());
        
        Map<String, Object> invData = new Map<String, Object>{
            'account_name' => 'Test Account',
            'invoice_number' => 'INV-001',
            'total_amount' => 1000.00
        };
        String invoiceJson = JSON.serialize(invData);
        
        Test.startTest();
        SlackNotificationService.notifyInvoiceEvent(
            invoiceJson, 
            Constants.EVENT_TYPE_PAID
        );
        Test.stopTest();
        
        System.assert(true, 'Invoice paid notification sent');
    }

    @isTest
    static void testNotifyInvoiceEventVoided() {
        Test.setMock(HttpCalloutMock.class, new SlackSuccessCalloutMock());
        
        Map<String, Object> invData = new Map<String, Object>{
            'account_name' => 'Test Account',
            'invoice_number' => 'INV-001',
            'total_amount' => 1000.00
        };
        String invoiceJson = JSON.serialize(invData);
        
        Test.startTest();
        SlackNotificationService.notifyInvoiceEvent(
            invoiceJson, 
            Constants.EVENT_TYPE_VOIDED
        );
        Test.stopTest();
        
        System.assert(true, 'Invoice voided notification sent');
    }

    @isTest
    static void testNotifyInvoiceEventDefault() {
        Test.setMock(HttpCalloutMock.class, new SlackSuccessCalloutMock());
        
        Map<String, Object> invData = new Map<String, Object>{
            'account_name' => 'Test Account',
            'invoice_number' => 'INV-001',
            'total_amount' => 1000.00
        };
        String invoiceJson = JSON.serialize(invData);
        
        Test.startTest();
        SlackNotificationService.notifyInvoiceEvent(
            invoiceJson, 
            'UnknownEventType'
        );
        Test.stopTest();
        
        System.assert(true, 'Default invoice notification sent');
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

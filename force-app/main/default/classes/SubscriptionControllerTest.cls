/**
 * @description Test class for SubscriptionController
 * @author Antonio Franco
 * @date 2025-01-17
 */
@isTest
private class SubscriptionControllerTest {
    
    @testSetup
    static void setupTestData() {
        Account testAccount = TestDataFactory.createAccount();
        insert testAccount;
        
        Price_Plan__c plan = TestDataFactory.createPricePlan();
        insert plan;
    }
    
    // ========== GET SUBSCRIPTION WITH RELATED ==========
    
    @isTest
    static void testGetSubscriptionWithRelated() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Price_Plan__c plan = [SELECT Id FROM Price_Plan__c LIMIT 1];
        
        Subscription__c sub = new Subscription__c(
            Account__c = acc.Id,
            Price_Plan__c = plan.Id,
            Status__c = Constants.SUBSCRIPTION_STATUS_ACTIVE,
            Start_Date__c = Date.today(),
            Quantity__c = 1
        );
        insert sub;
        
        Test.startTest();
        Subscription__c result = SubscriptionController.getSubscriptionWithRelated(sub.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result);
        System.assertEquals(sub.Id, result.Id);
    }
    
    @isTest
    static void testGetSubscriptionWithRelatedNotFound() {
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            // Use null to trigger exception
            SubscriptionController.getSubscriptionWithRelated(null);
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Should have thrown exception for null ID');
    }
    
    // ========== GET SUBSCRIPTIONS BY ACCOUNT ==========
    
    @isTest
    static void testGetSubscriptionsByAccount() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Price_Plan__c plan = [SELECT Id FROM Price_Plan__c LIMIT 1];
        
        List<Subscription__c> subs = new List<Subscription__c>();
        for (Integer i = 0; i < 3; i++) {
            subs.add(new Subscription__c(
                Account__c = acc.Id,
                Price_Plan__c = plan.Id,
                Status__c = Constants.SUBSCRIPTION_STATUS_ACTIVE,
                Start_Date__c = Date.today().addDays(-i),
                Quantity__c = 1
            ));
        }
        insert subs;
        
        Test.startTest();
        List<Subscription__c> results = SubscriptionController.getSubscriptionsByAccount(acc.Id);
        Test.stopTest();
        
        System.assertEquals(3, results.size());
    }
    
    // ========== GET ACTIVE SUBSCRIPTIONS ==========
    
    @isTest
    static void testGetActiveSubscriptions() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Price_Plan__c plan = [SELECT Id FROM Price_Plan__c LIMIT 1];
        
        // Create active and trial subscriptions
        Subscription__c activeSub = new Subscription__c(
            Account__c = acc.Id,
            Price_Plan__c = plan.Id,
            Status__c = Constants.SUBSCRIPTION_STATUS_ACTIVE,
            Start_Date__c = Date.today(),
            Quantity__c = 1
        );
        Subscription__c trialSub = new Subscription__c(
            Account__c = acc.Id,
            Price_Plan__c = plan.Id,
            Status__c = Constants.SUBSCRIPTION_STATUS_TRIAL,
            Start_Date__c = Date.today(),
            Trial_End_Date__c = Date.today().addDays(14),
            Quantity__c = 1
        );
        Subscription__c cancelledSub = new Subscription__c(
            Account__c = acc.Id,
            Price_Plan__c = plan.Id,
            Status__c = Constants.SUBSCRIPTION_STATUS_CANCELLED,
            Start_Date__c = Date.today().addDays(-30),
            Quantity__c = 1,
            Cancellation_Reason__c = 'Other',
            Cancellation_Date__c = Date.today()
        );
        insert new List<Subscription__c>{activeSub, trialSub, cancelledSub};
        
        Test.startTest();
        List<Subscription__c> results = SubscriptionController.getActiveSubscriptions();
        Test.stopTest();
        
        System.assertEquals(2, results.size(), 'Should return active + trial');
    }
    
    // ========== ACTIVATE SUBSCRIPTION ==========
    
    @isTest
    static void testActivateSubscription() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Price_Plan__c plan = [SELECT Id FROM Price_Plan__c LIMIT 1];
        
        Subscription__c sub = new Subscription__c(
            Account__c = acc.Id,
            Price_Plan__c = plan.Id,
            Status__c = Constants.SUBSCRIPTION_STATUS_TRIAL,
            Start_Date__c = Date.today(),
            Trial_End_Date__c = Date.today().addDays(14),
            Quantity__c = 1
        );
        insert sub;
        
        Test.startTest();
        SubscriptionController.activateSubscription(sub.Id);
        Test.stopTest();
        
        Subscription__c updated = [SELECT Status__c FROM Subscription__c WHERE Id = :sub.Id];
        System.assertEquals(Constants.SUBSCRIPTION_STATUS_ACTIVE, updated.Status__c);
    }
    
    @isTest
    static void testActivateSubscriptionNullId() {
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            SubscriptionController.activateSubscription(null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Should have thrown exception for null ID');
    }
    
    @isTest
    static void testActivateSubscriptionAlreadyActive() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Price_Plan__c plan = [SELECT Id FROM Price_Plan__c LIMIT 1];
        
        Subscription__c sub = new Subscription__c(
            Account__c = acc.Id,
            Price_Plan__c = plan.Id,
            Status__c = Constants.SUBSCRIPTION_STATUS_ACTIVE,
            Start_Date__c = Date.today(),
            Quantity__c = 1
        );
        insert sub;
        
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            SubscriptionController.activateSubscription(sub.Id);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Should have thrown exception for already active');
    }
    
    @isTest
    static void testActivateSubscriptionCancelled() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Price_Plan__c plan = [SELECT Id FROM Price_Plan__c LIMIT 1];
        
        Subscription__c sub = new Subscription__c(
            Account__c = acc.Id,
            Price_Plan__c = plan.Id,
            Status__c = Constants.SUBSCRIPTION_STATUS_CANCELLED,
            Start_Date__c = Date.today(),
            Quantity__c = 1,
            Cancellation_Reason__c = 'Other',
            Cancellation_Date__c = Date.today()
        );
        insert sub;
        
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            SubscriptionController.activateSubscription(sub.Id);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Should have thrown exception for cancelled subscription');
    }
    
    // ========== CANCEL SUBSCRIPTION ==========
    
    @isTest
    static void testCancelSubscription() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Price_Plan__c plan = [SELECT Id FROM Price_Plan__c LIMIT 1];
        
        Subscription__c sub = new Subscription__c(
            Account__c = acc.Id,
            Price_Plan__c = plan.Id,
            Status__c = Constants.SUBSCRIPTION_STATUS_ACTIVE,
            Start_Date__c = Date.today(),
            Quantity__c = 1
        );
        insert sub;
        
        Test.startTest();
        SubscriptionController.cancelSubscription(sub.Id, 'Price Too High');
        Test.stopTest();
        
        Subscription__c updated = [
            SELECT Status__c, Cancellation_Reason__c, Cancellation_Date__c
            FROM Subscription__c WHERE Id = :sub.Id
        ];
        System.assertEquals(Constants.SUBSCRIPTION_STATUS_CANCELLED, updated.Status__c);
        System.assertEquals('Price Too High', updated.Cancellation_Reason__c);
        System.assertEquals(Date.today(), updated.Cancellation_Date__c);
    }
    
    @isTest
    static void testCancelSubscriptionNullId() {
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            SubscriptionController.cancelSubscription(null, 'Test');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Should have thrown exception for null ID');
    }
    
    @isTest
    static void testCancelSubscriptionNoReason() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Price_Plan__c plan = [SELECT Id FROM Price_Plan__c LIMIT 1];
        
        Subscription__c sub = new Subscription__c(
            Account__c = acc.Id,
            Price_Plan__c = plan.Id,
            Status__c = Constants.SUBSCRIPTION_STATUS_ACTIVE,
            Start_Date__c = Date.today(),
            Quantity__c = 1
        );
        insert sub;
        
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            SubscriptionController.cancelSubscription(sub.Id, '');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Should have thrown exception for empty reason');
    }
    
    @isTest
    static void testCancelSubscriptionAlreadyCancelled() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Price_Plan__c plan = [SELECT Id FROM Price_Plan__c LIMIT 1];
        
        Subscription__c sub = new Subscription__c(
            Account__c = acc.Id,
            Price_Plan__c = plan.Id,
            Status__c = Constants.SUBSCRIPTION_STATUS_CANCELLED,
            Start_Date__c = Date.today(),
            Quantity__c = 1,
            Cancellation_Reason__c = 'Other',
            Cancellation_Date__c = Date.today()
        );
        insert sub;
        
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            SubscriptionController.cancelSubscription(sub.Id, 'Price Too High');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Should have thrown exception for already cancelled');
    }
    
    // ========== GET EXPIRING TRIAL SUBSCRIPTIONS ==========
    
    @isTest
    static void testGetExpiringTrialSubscriptions() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Price_Plan__c plan = [SELECT Id FROM Price_Plan__c LIMIT 1];
        
        // Trial expiring in 3 days
        Subscription__c expiringSoon = new Subscription__c(
            Account__c = acc.Id,
            Price_Plan__c = plan.Id,
            Status__c = Constants.SUBSCRIPTION_STATUS_TRIAL,
            Start_Date__c = Date.today().addDays(-11),
            Trial_End_Date__c = Date.today().addDays(3),
            Quantity__c = 1
        );
        // Trial expiring in 20 days (outside 7-day window)
        Subscription__c expiringLater = new Subscription__c(
            Account__c = acc.Id,
            Price_Plan__c = plan.Id,
            Status__c = Constants.SUBSCRIPTION_STATUS_TRIAL,
            Start_Date__c = Date.today().addDays(-10),
            Trial_End_Date__c = Date.today().addDays(20),
            Quantity__c = 1
        );
        insert new List<Subscription__c>{expiringSoon, expiringLater};
        
        Test.startTest();
        List<Subscription__c> results = SubscriptionController.getExpiringTrialSubscriptions(7);
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should only return trial expiring within 7 days');
    }
    
    @isTest
    static void testGetExpiringTrialSubscriptionsDefaultDays() {
        Account acc = [SELECT Id FROM Account LIMIT 1];
        Price_Plan__c plan = [SELECT Id FROM Price_Plan__c LIMIT 1];
        
        Subscription__c trial = new Subscription__c(
            Account__c = acc.Id,
            Price_Plan__c = plan.Id,
            Status__c = Constants.SUBSCRIPTION_STATUS_TRIAL,
            Start_Date__c = Date.today(),
            Trial_End_Date__c = Date.today().addDays(5),
            Quantity__c = 1
        );
        insert trial;
        
        Test.startTest();
        List<Subscription__c> results = SubscriptionController.getExpiringTrialSubscriptions(null);
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should use default 7 days');
    }
}

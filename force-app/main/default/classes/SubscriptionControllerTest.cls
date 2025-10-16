/**
 * TEST CONTROLLER - Solo per debug
 */
public with sharing class SubscriptionControllerTest {
  @AuraEnabled
  public static Map<String, Object> testGetSubscription(Id subscriptionId) {
    Map<String, Object> result = new Map<String, Object>();

    try {
      // Query MINIMA - solo campi base
      Subscription__c sub = [
        SELECT Id, Name, Status__c, Quantity__c
        FROM Subscription__c
        WHERE Id = :subscriptionId
        LIMIT 1
      ];

      result.put('success', true);
      result.put('data', sub);
      result.put('message', 'Query base OK');

      // Test campo per campo
      try {
        Subscription__c sub2 = [
          SELECT Account__c
          FROM Subscription__c
          WHERE Id = :subscriptionId
        ];
        result.put('account_field_ok', true);
      } catch (Exception e) {
        result.put('account_field_error', e.getMessage());
      }

      try {
        Subscription__c sub3 = [
          SELECT Price_Plan__c
          FROM Subscription__c
          WHERE Id = :subscriptionId
        ];
        result.put('price_plan_field_ok', true);
      } catch (Exception e) {
        result.put('price_plan_field_error', e.getMessage());
      }
    } catch (Exception e) {
      result.put('success', false);
      result.put('error', e.getMessage());
      result.put('stackTrace', e.getStackTraceString());
    }

    return result;
  }
}

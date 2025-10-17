/**
 * @description Orchestrates Subscription trigger events using validator pattern
 * @author Antonio Franco
 * @date 2025-09-09
 * @story STORY-003: Trigger Framework
 */
public class SubscriptionTriggerHandler implements IHandler {
  // Prevent recursion from account rollup updates
  private static Boolean isUpdatingAccounts = false;

  public void beforeInsert(List<SObject> newRecords) {
    List<Subscription__c> subscriptions = (List<Subscription__c>) newRecords;

    SubscriptionValidator.setDefaults(subscriptions);
    RecordTypeUtils.assignSubscriptionRecordTypes(subscriptions);
    SubscriptionValidator.validateBusinessRules(subscriptions, false);
  }

  public void beforeUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {
    Map<Id, Subscription__c> oldSubscriptions = (Map<Id, Subscription__c>) oldMap;

    SubscriptionValidator.validateStateTransitions(
      oldSubscriptions,
      (Map<Id, Subscription__c>) newMap
    );
    SubscriptionValidator.validateCancellationPermissions(
      oldSubscriptions,
      (Map<Id, Subscription__c>) newMap
    );
  }

  public void beforeDelete(Map<Id, SObject> oldMap) {
    List<Subscription__c> subscriptions = (List<Subscription__c>) oldMap.values();

    SubscriptionValidator.validateDeletionPermissions(subscriptions);
  }

  public void afterInsert(Map<Id, SObject> newMap) {
    List<Subscription__c> subscriptions = (List<Subscription__c>) newMap.values();

    handleNewSubscriptions(subscriptions);
    updateAccountSubscriptionStats(subscriptions);

    // Publish platform events only for Active subscriptions (not Draft/Trial)
    List<Subscription__c> activeSubscriptions = new List<Subscription__c>();
    for (Subscription__c sub : subscriptions) {
      if (sub.Status__c == Constants.SUBSCRIPTION_STATUS_ACTIVE) {
        activeSubscriptions.add(sub);
      }
    }
    PlatformEventPublisher.publishSubscriptionEvents(
      activeSubscriptions,
      'Created'
    );
  }

  public void afterUpdate(Map<Id, SObject> oldMap, Map<Id, SObject> newMap) {
    Map<Id, Subscription__c> oldSubscriptions = (Map<Id, Subscription__c>) oldMap;
    Map<Id, Subscription__c> newSubscriptions = (Map<Id, Subscription__c>) newMap;

    handleStatusTransitions(oldSubscriptions, newSubscriptions);
    updateAccountSubscriptionStats((List<Subscription__c>) newMap.values());

    Set<Id> needingInvoice = SubscriptionValidator.getSubscriptionsNeedingInvoice(
      oldSubscriptions,
      newSubscriptions
    );
    if (!needingInvoice.isEmpty()) {
      queueInvoiceGeneration(needingInvoice);
    }

    // Publish platform events only for critical status changes (Active, Cancelled, Suspended)
    PlatformEventPublisher.publishSubscriptionStatusChanges(
      (List<Subscription__c>) newMap.values(),
      oldSubscriptions
    );
  }

  public void afterDelete(Map<Id, SObject> oldMap) {
    List<Subscription__c> subscriptions = (List<Subscription__c>) oldMap.values();

    updateAccountSubscriptionStats(subscriptions);
  }

  public void afterUndelete(Map<Id, SObject> newMap) {
    List<Subscription__c> subscriptions = (List<Subscription__c>) newMap.values();

    updateAccountSubscriptionStats(subscriptions);
  }

  /**
   * @description Processes subscriptions based on status changes and routes to appropriate handlers
   * @param oldSubscriptions Map of subscription records before update
   * @param newSubscriptions Map of subscription records after update
   */
  private void handleStatusTransitions(
    Map<Id, Subscription__c> oldSubscriptions,
    Map<Id, Subscription__c> newSubscriptions
  ) {
    if (
      oldSubscriptions == null ||
      oldSubscriptions.isEmpty() ||
      newSubscriptions == null ||
      newSubscriptions.isEmpty()
    ) {
      return;
    }

    List<Subscription__c> activatedSubs = new List<Subscription__c>();
    List<Subscription__c> cancelledSubs = new List<Subscription__c>();
    List<Subscription__c> suspendedSubs = new List<Subscription__c>();

    for (Id subId : newSubscriptions.keySet()) {
      Subscription__c oldSub = oldSubscriptions.get(subId);
      Subscription__c newSub = newSubscriptions.get(subId);

      if (oldSub.Status__c != newSub.Status__c) {
        if (newSub.Status__c == Constants.SUBSCRIPTION_STATUS_ACTIVE) {
          activatedSubs.add(newSub);
        } else if (
          newSub.Status__c == Constants.SUBSCRIPTION_STATUS_CANCELLED
        ) {
          cancelledSubs.add(newSub);
        } else if (
          newSub.Status__c == Constants.SUBSCRIPTION_STATUS_SUSPENDED
        ) {
          suspendedSubs.add(newSub);
        }
      }
    }

    handleActivatedSubscriptions(activatedSubs);
    handleCancelledSubscriptions(cancelledSubs);
    handleSuspendedSubscriptions(suspendedSubs);
  }

  private void handleActivatedSubscriptions(
    List<Subscription__c> activatedSubs
  ) {
    if (activatedSubs == null || activatedSubs.isEmpty()) {
      return;
    }

    System.debug(
      'Processing ' + activatedSubs.size() + ' activated subscriptions'
    );
    Set<Id> subscriptionIds = new Map<Id, Subscription__c>(activatedSubs)
      .keySet();

    SubscriptionAutomationService.processStatusChanges(subscriptionIds);
    SubscriptionAutomationService.generateInvoicesForActiveSubscriptions(
      subscriptionIds
    );
  }

  private void handleCancelledSubscriptions(
    List<Subscription__c> cancelledSubs
  ) {
    if (cancelledSubs == null || cancelledSubs.isEmpty()) {
      return;
    }

    System.debug(
      'Processing ' + cancelledSubs.size() + ' cancelled subscriptions'
    );
    Set<Id> subscriptionIds = new Map<Id, Subscription__c>(cancelledSubs)
      .keySet();

    SubscriptionAutomationService.processStatusChanges(subscriptionIds);
  }

  private void handleSuspendedSubscriptions(
    List<Subscription__c> suspendedSubs
  ) {
    if (suspendedSubs == null || suspendedSubs.isEmpty()) {
      return;
    }

    System.debug(
      'Processing ' + suspendedSubs.size() + ' suspended subscriptions'
    );
    Set<Id> subscriptionIds = new Map<Id, Subscription__c>(suspendedSubs)
      .keySet();

    SubscriptionAutomationService.processStatusChanges(subscriptionIds);
  }

  private void handleNewSubscriptions(List<Subscription__c> newSubscriptions) {
    if (newSubscriptions == null || newSubscriptions.isEmpty()) {
      return;
    }

    System.debug(
      'Processing ' + newSubscriptions.size() + ' new subscriptions'
    );
    Set<Id> subscriptionIds = new Map<Id, Subscription__c>(newSubscriptions)
      .keySet();

    SubscriptionAutomationService.processNewSubscriptions(subscriptionIds);
  }

  /**
   * Updates Account subscription status and health score based on current subscriptions
   *
   * Business Rules:
   * - Subscription_Status__c: Active Customer, Trial Customer, Former Customer, At Risk
   * - Health_Score__c: 0-100 based on subscription status and activity
   */
  private void updateAccountSubscriptionStats(
    List<Subscription__c> subscriptions
  ) {
    // Prevent recursion from account updates
    if (
      isUpdatingAccounts ||
      subscriptions == null ||
      subscriptions.isEmpty()
    ) {
      return;
    }

    // Collect account IDs
    Set<Id> accountIds = new Set<Id>();
    for (Subscription__c sub : subscriptions) {
      if (sub.Account__c != null) {
        accountIds.add(sub.Account__c);
      }
    }

    if (accountIds.isEmpty()) {
      return;
    }

    // Set flag AFTER early return checks to avoid leaving flag set
    isUpdatingAccounts = true;

    try {
      // Query all subscriptions for these accounts to calculate status
      Map<Id, List<Subscription__c>> subscriptionsByAccount = new Map<Id, List<Subscription__c>>();

      for (Subscription__c sub : [
        SELECT Id, Account__c, Status__c, Start_Date__c
        FROM Subscription__c
        WHERE Account__c IN :accountIds
        WITH SECURITY_ENFORCED
      ]) {
        if (!subscriptionsByAccount.containsKey(sub.Account__c)) {
          subscriptionsByAccount.put(
            sub.Account__c,
            new List<Subscription__c>()
          );
        }
        subscriptionsByAccount.get(sub.Account__c).add(sub);
      }

      // Query accounts and update
      List<Account> accountsToUpdate = [
        SELECT Id, Subscription_Status__c, Health_Score__c
        FROM Account
        WHERE Id IN :accountIds
        WITH SECURITY_ENFORCED
      ];

      for (Account acc : accountsToUpdate) {
        List<Subscription__c> accountSubs = subscriptionsByAccount.get(acc.Id);

        if (accountSubs == null || accountSubs.isEmpty()) {
          acc.Subscription_Status__c = null;
          acc.Health_Score__c = 0;
          continue;
        }

        // Determine account subscription status and health score
        Boolean hasActive = false;
        Boolean hasTrial = false;
        Boolean hasSuspended = false;
        Boolean hasCancelled = false;

        for (Subscription__c sub : accountSubs) {
          if (sub.Status__c == Constants.SUBSCRIPTION_STATUS_ACTIVE) {
            hasActive = true;
          } else if (sub.Status__c == Constants.SUBSCRIPTION_STATUS_TRIAL) {
            hasTrial = true;
          } else if (sub.Status__c == Constants.SUBSCRIPTION_STATUS_SUSPENDED) {
            hasSuspended = true;
          } else if (sub.Status__c == Constants.SUBSCRIPTION_STATUS_CANCELLED) {
            hasCancelled = true;
          }
        }

        // Set subscription status (priority: Active > Suspended > Trial > Cancelled)
        if (hasActive) {
          acc.Subscription_Status__c = 'Active Customer';
          acc.Health_Score__c = 100;
        } else if (hasSuspended) {
          acc.Subscription_Status__c = 'At Risk';
          acc.Health_Score__c = 25;
        } else if (hasTrial) {
          acc.Subscription_Status__c = 'Trial Customer';
          acc.Health_Score__c = 75;
        } else if (hasCancelled) {
          acc.Subscription_Status__c = 'Former Customer';
          acc.Health_Score__c = 0;
        }
      }

      update accountsToUpdate;
    } finally {
      isUpdatingAccounts = false;
    }
  }

  /**
   * @description Queues invoice generation for subscriptions that just became active
   * @param subscriptionIds Set of subscription IDs needing invoice generation
   */
  private void queueInvoiceGeneration(Set<Id> subscriptionIds) {
    if (subscriptionIds == null || subscriptionIds.isEmpty()) {
      return;
    }
    
    System.debug(
      'Queuing invoice generation for ' +
        subscriptionIds.size() +
        ' subscriptions'
    );
    // Invoice generation handled by SubscriptionAutomationService.generateInvoicesForActiveSubscriptions
    // Called from handleActivatedSubscriptions when subscriptions become active
  }
}

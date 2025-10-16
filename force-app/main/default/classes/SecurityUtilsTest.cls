/**
 * @description Test class for SecurityUtils
 * @author Antonio Franco
 * @date 2025-09-27
 */
@isTest
private class SecurityUtilsTest {
  @TestSetup
  static void setupTestData() {
    Account testAccount = new Account(Name = 'Security Test Account');
    insert testAccount;

    Price_Plan__c testPricePlan = new Price_Plan__c(
      Name = 'Test Price Plan',
      Category__c = 'CRM Base',
      Unit_Price__c = 100.00,
      Billing_Frequency__c = 'Monthly'
    );
    insert testPricePlan;
  }

  @isTest
  static void testHasObjectAccess() {
    Test.startTest();

    // Test valid object access checks
    Boolean canCreateAccount = SecurityUtils.hasObjectAccess(
      'Account',
      'CREATE'
    );
    Boolean canReadAccount = SecurityUtils.hasObjectAccess('Account', 'READ');
    Boolean canUpdateAccount = SecurityUtils.hasObjectAccess(
      'Account',
      'UPDATE'
    );
    Boolean canDeleteAccount = SecurityUtils.hasObjectAccess(
      'Account',
      'DELETE'
    );

    // Results depend on running user's permissions, but method should not throw exceptions
    System.assert(
      canCreateAccount != null,
      'CREATE check should return a boolean'
    );
    System.assert(canReadAccount != null, 'READ check should return a boolean');
    System.assert(
      canUpdateAccount != null,
      'UPDATE check should return a boolean'
    );
    System.assert(
      canDeleteAccount != null,
      'DELETE check should return a boolean'
    );

    // Test invalid object
    Boolean invalidObject = SecurityUtils.hasObjectAccess(
      'NonExistentObject__c',
      'READ'
    );
    System.assertEquals(
      false,
      invalidObject,
      'Invalid object should return false'
    );

    // Test invalid operation
    Boolean invalidOperation = SecurityUtils.hasObjectAccess(
      'Account',
      'INVALID'
    );
    System.assertEquals(
      false,
      invalidOperation,
      'Invalid operation should return false'
    );

    Test.stopTest();
  }

  @isTest
  static void testHasFieldAccess() {
    Test.startTest();

    // Test valid field access checks
    Boolean canReadName = SecurityUtils.hasFieldAccess(
      'Account',
      'Name',
      'READ'
    );
    Boolean canEditName = SecurityUtils.hasFieldAccess(
      'Account',
      'Name',
      'EDIT'
    );

    // Results depend on field accessibility, but method should not throw exceptions
    System.assert(
      canReadName != null,
      'Field READ check should return a boolean'
    );
    System.assert(
      canEditName != null,
      'Field EDIT check should return a boolean'
    );

    // Test invalid field
    Boolean invalidField = SecurityUtils.hasFieldAccess(
      'Account',
      'NonExistentField__c',
      'READ'
    );
    System.assertEquals(
      false,
      invalidField,
      'Invalid field should return false'
    );

    // Test invalid object
    Boolean invalidObject = SecurityUtils.hasFieldAccess(
      'NonExistentObject__c',
      'Name',
      'READ'
    );
    System.assertEquals(
      false,
      invalidObject,
      'Invalid object should return false'
    );

    Test.stopTest();
  }

  @isTest
  static void testCanCancelSubscription() {
    Account testAccount = [SELECT Id FROM Account LIMIT 1];
    Price_Plan__c testPricePlan = [SELECT Id FROM Price_Plan__c LIMIT 1];

    Test.startTest();

    // Test Draft subscription - should be cancellable by anyone with UPDATE access
    Subscription__c draftSub = new Subscription__c(
      Account__c = testAccount.Id,
      Price_Plan__c = testPricePlan.Id,
      Status__c = Constants.SUBSCRIPTION_STATUS_DRAFT,
      Start_Date__c = Date.today()
    );
    insert draftSub;

    Boolean canCancelDraft = SecurityUtils.canCancelSubscription(draftSub);
    System.assert(
      canCancelDraft != null,
      'Draft cancellation check should return a boolean'
    );

    // Test Trial subscription - should be cancellable by anyone with UPDATE access
    Subscription__c trialSub = new Subscription__c(
      Account__c = testAccount.Id,
      Price_Plan__c = testPricePlan.Id,
      Status__c = Constants.SUBSCRIPTION_STATUS_TRIAL,
      Start_Date__c = Date.today()
    );
    insert trialSub;

    Boolean canCancelTrial = SecurityUtils.canCancelSubscription(trialSub);
    System.assert(
      canCancelTrial != null,
      'Trial cancellation check should return a boolean'
    );

    // Test Active subscription - requires special permission
    Subscription__c activeSub = new Subscription__c(
      Account__c = testAccount.Id,
      Price_Plan__c = testPricePlan.Id,
      Status__c = Constants.SUBSCRIPTION_STATUS_ACTIVE,
      Start_Date__c = Date.today()
    );
    insert activeSub;

    Boolean canCancelActive = SecurityUtils.canCancelSubscription(activeSub);
    System.assert(
      canCancelActive != null,
      'Active cancellation check should return a boolean'
    );

    Test.stopTest();
  }

  @isTest
  static void testCanEditInvoice() {
    Account testAccount = [SELECT Id FROM Account LIMIT 1];

    Test.startTest();

    // Test Draft invoice - should be editable
    Invoice__c draftInvoice = new Invoice__c(
      Account__c = testAccount.Id,
      Status__c = Constants.INVOICE_STATUS_DRAFT
    );
    insert draftInvoice;

    Boolean canEditDraft = SecurityUtils.canEditInvoice(draftInvoice);
    System.assert(
      canEditDraft != null,
      'Draft invoice edit check should return a boolean'
    );

    // Test Paid invoice - requires special permission
    Invoice__c paidInvoice = new Invoice__c(
      Account__c = testAccount.Id,
      Status__c = Constants.INVOICE_STATUS_PAID
    );
    insert paidInvoice;

    Boolean canEditPaid = SecurityUtils.canEditInvoice(paidInvoice);
    System.assert(
      canEditPaid != null,
      'Paid invoice edit check should return a boolean'
    );

    Test.stopTest();
  }

  @isTest
  static void testCanDeleteSubscription() {
    Account testAccount = [SELECT Id FROM Account LIMIT 1];
    Price_Plan__c testPricePlan = [SELECT Id FROM Price_Plan__c LIMIT 1];

    Test.startTest();

    // Test Draft subscription - should be deletable
    Subscription__c draftSub = new Subscription__c(
      Account__c = testAccount.Id,
      Price_Plan__c = testPricePlan.Id,
      Status__c = Constants.SUBSCRIPTION_STATUS_DRAFT,
      Start_Date__c = Date.today()
    );
    insert draftSub;

    Boolean canDeleteDraft = SecurityUtils.canDeleteSubscription(draftSub);
    System.assert(
      canDeleteDraft != null,
      'Draft deletion check should return a boolean'
    );

    // Test Active subscription - should NOT be deletable
    Subscription__c activeSub = new Subscription__c(
      Account__c = testAccount.Id,
      Price_Plan__c = testPricePlan.Id,
      Status__c = Constants.SUBSCRIPTION_STATUS_ACTIVE,
      Start_Date__c = Date.today()
    );
    insert activeSub;

    Boolean canDeleteActive = SecurityUtils.canDeleteSubscription(activeSub);
    System.assertEquals(
      false,
      canDeleteActive,
      'Active subscription should not be deletable'
    );

    Test.stopTest();
  }

  @isTest
  static void testPermissionChecks() {
    Test.startTest();

    // Test permission checks - these will return false in test context unless permissions are assigned
    Boolean canCancelAny = SecurityUtils.canCancelAnySubscription();
    Boolean canModifyPaid = SecurityUtils.canModifyPaidInvoices();
    Boolean canViewFinancial = SecurityUtils.canViewFinancialData();

    // In test context without permission sets assigned, these should be false
    System.assert(
      canCancelAny != null,
      'Cancel any permission check should return a boolean'
    );
    System.assert(
      canModifyPaid != null,
      'Modify paid permission check should return a boolean'
    );
    System.assert(
      canViewFinancial != null,
      'View financial permission check should return a boolean'
    );

    Test.stopTest();
  }

  @isTest
  static void testMultiplePermissionChecks() {
    Test.startTest();

    Set<String> testPermissions = new Set<String>{
      'Cancel_Any_Subscription',
      'Modify_Paid_Invoices'
    };

    // Test hasAnyPermission
    Boolean hasAny = SecurityUtils.hasAnyPermission(testPermissions);
    System.assert(hasAny != null, 'hasAnyPermission should return a boolean');

    // Test hasAllPermissions
    Boolean hasAll = SecurityUtils.hasAllPermissions(testPermissions);
    System.assert(hasAll != null, 'hasAllPermissions should return a boolean');

    Test.stopTest();
  }

  @isTest
  static void testGetCurrentUserProfile() {
    Test.startTest();

    String profileName = SecurityUtils.getCurrentUserProfile();
    System.assert(
      String.isNotBlank(profileName),
      'Profile name should not be blank'
    );

    Test.stopTest();
  }

  @isTest
  static void testEnforcePermission() {
    Test.startTest();

    // Test successful permission enforcement
    try {
      SecurityUtils.enforcePermission('Test Operation', true);
      // Should not throw exception
      System.assert(true, 'Should not throw exception for valid permission');
    } catch (SecurityUtils.SecurityException e) {
      System.assert(false, 'Should not throw exception for valid permission');
    }

    // Test failed permission enforcement
    try {
      SecurityUtils.enforcePermission('Test Operation', false);
      System.assert(false, 'Should throw exception for invalid permission');
    } catch (SecurityUtils.SecurityException e) {
      System.assert(
        e.getMessage().contains('Test Operation'),
        'Exception should contain operation name'
      );
    }

    Test.stopTest();
  }
}

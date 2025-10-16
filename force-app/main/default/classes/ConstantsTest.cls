/**
 * @description Test class for Constants utility class
 * @author Antonio Franco
 * @date 2025-10-16
 */
@isTest
private class ConstantsTest {
    
    @isTest
    static void testSubscriptionStatusHelpers() {
        // Test isSubscriptionActive
        System.assert(Constants.isSubscriptionActive('Trial'), 'Trial should be active');
        System.assert(Constants.isSubscriptionActive('Active'), 'Active should be active');
        System.assert(!Constants.isSubscriptionActive('Draft'), 'Draft should not be active');
        System.assert(!Constants.isSubscriptionActive('Cancelled'), 'Cancelled should not be active');
        
        // Test isSubscriptionTerminal
        System.assert(Constants.isSubscriptionTerminal('Cancelled'), 'Cancelled should be terminal');
        System.assert(!Constants.isSubscriptionTerminal('Active'), 'Active should not be terminal');
        System.assert(!Constants.isSubscriptionTerminal('Draft'), 'Draft should not be terminal');
    }
    
    @isTest
    static void testInvoiceStatusHelpers() {
        // Test isInvoiceLocked
        System.assert(Constants.isInvoiceLocked('Paid'), 'Paid should be locked');
        System.assert(Constants.isInvoiceLocked('Voided'), 'Voided should be locked');
        System.assert(!Constants.isInvoiceLocked('Draft'), 'Draft should not be locked');
        System.assert(!Constants.isInvoiceLocked('Sent'), 'Sent should not be locked');
    }
    
    @isTest
    static void testStatusConstants() {
        // Verify subscription statuses
        System.assertEquals('Draft', Constants.SUBSCRIPTION_STATUS_DRAFT, 'Draft status constant');
        System.assertEquals('Trial', Constants.SUBSCRIPTION_STATUS_TRIAL, 'Trial status constant');
        System.assertEquals('Active', Constants.SUBSCRIPTION_STATUS_ACTIVE, 'Active status constant');
        System.assertEquals('Suspended', Constants.SUBSCRIPTION_STATUS_SUSPENDED, 'Suspended status constant');
        System.assertEquals('Cancelled', Constants.SUBSCRIPTION_STATUS_CANCELLED, 'Cancelled status constant');
        
        // Verify invoice statuses
        System.assertEquals('Draft', Constants.INVOICE_STATUS_DRAFT, 'Invoice draft status');
        System.assertEquals('Sent', Constants.INVOICE_STATUS_SENT, 'Invoice sent status');
        System.assertEquals('Paid', Constants.INVOICE_STATUS_PAID, 'Invoice paid status');
        System.assertEquals('Overdue', Constants.INVOICE_STATUS_OVERDUE, 'Invoice overdue status');
        System.assertEquals('Voided', Constants.INVOICE_STATUS_VOIDED, 'Invoice voided status');
    }
    
    @isTest
    static void testFieldConstants() {
        // Verify field name constants
        System.assertEquals('Price_Plan__c', Constants.FIELD_PRICE_PLAN, 'Price plan field');
        System.assertEquals('Status__c', Constants.FIELD_STATUS, 'Status field');
        System.assertEquals('Account__c', Constants.FIELD_ACCOUNT, 'Account field');
        System.assertEquals('Cancellation_Reason__c', Constants.FIELD_CANCELLATION_REASON, 'Cancellation reason field');
    }
    
    @isTest
    static void testErrorMessageConstants() {
        // Verify error messages exist and are not empty
        System.assert(String.isNotBlank(Constants.ERROR_PRICE_PLAN_REQUIRED), 'Price plan error message');
        System.assert(String.isNotBlank(Constants.ERROR_INVALID_STATUS_TRANSITION), 'Status transition error');
        System.assert(String.isNotBlank(Constants.ERROR_CANNOT_DELETE_ACTIVE), 'Cannot delete active error');
        System.assert(String.isNotBlank(Constants.ERROR_CANNOT_MODIFY_PAID_INVOICE), 'Cannot modify paid invoice error');
    }
    
    @isTest
    static void testDefaultValues() {
        // Verify default values
        System.assertEquals(14, Constants.DEFAULT_TRIAL_DAYS, 'Default trial days');
        System.assertEquals(30, Constants.DEFAULT_INVOICE_DUE_DAYS, 'Default invoice due days');
        System.assert(Constants.MAX_TRIAL_DAYS > 0, 'Max trial days should be positive');
    }
    
    @isTest
    static void testEventTypeConstants() {
        // Verify event type constants
        System.assertEquals('Created', Constants.EVENT_TYPE_CREATED, 'Created event');
        System.assertEquals('Updated', Constants.EVENT_TYPE_UPDATED, 'Updated event');
        System.assertEquals('Paid', Constants.EVENT_TYPE_PAID, 'Paid event');
        System.assertEquals('StatusChanged', Constants.EVENT_TYPE_STATUS_CHANGED, 'Status changed event');
    }
    
    @isTest
    static void testSetCollections() {
        // Verify active statuses set
        System.assert(Constants.SUBSCRIPTION_ACTIVE_STATUSES.contains('Trial'), 'Active statuses contains Trial');
        System.assert(Constants.SUBSCRIPTION_ACTIVE_STATUSES.contains('Active'), 'Active statuses contains Active');
        System.assertEquals(2, Constants.SUBSCRIPTION_ACTIVE_STATUSES.size(), 'Should have 2 active statuses');
        
        // Verify terminal statuses set
        System.assert(Constants.SUBSCRIPTION_TERMINAL_STATUSES.contains('Cancelled'), 'Terminal statuses contains Cancelled');
        System.assertEquals(1, Constants.SUBSCRIPTION_TERMINAL_STATUSES.size(), 'Should have 1 terminal status');
        
        // Verify locked invoice statuses set
        System.assert(Constants.INVOICE_LOCKED_STATUSES.contains('Paid'), 'Locked statuses contains Paid');
        System.assert(Constants.INVOICE_LOCKED_STATUSES.contains('Voided'), 'Locked statuses contains Voided');
        System.assertEquals(2, Constants.INVOICE_LOCKED_STATUSES.size(), 'Should have 2 locked statuses');
    }
    
    @isTest
    static void testBillingFrequencyConstants() {
        // Verify billing frequency constants
        System.assertEquals('Monthly', Constants.BILLING_FREQUENCY_MONTHLY, 'Monthly billing');
        System.assertEquals('Annual', Constants.BILLING_FREQUENCY_ANNUAL, 'Annual billing');
        System.assertEquals('Quarterly', Constants.BILLING_FREQUENCY_QUARTERLY, 'Quarterly billing');
    }
    
    @isTest
    static void testTaxRatesByCountry() {
        // Verify tax rates map
        System.assert(Constants.TAX_RATES_BY_COUNTRY.containsKey('Italy'), 'Should have Italy tax rate');
        System.assertEquals(22.0, Constants.TAX_RATES_BY_COUNTRY.get('Italy'), 'Italy tax rate should be 22%');
        System.assert(Constants.TAX_RATES_BY_COUNTRY.containsKey('Germany'), 'Should have Germany tax rate');
        System.assertEquals(19.0, Constants.TAX_RATES_BY_COUNTRY.get('Germany'), 'Germany tax rate should be 19%');
    }
    
    @isTest
    static void testCancellationReasonConstants() {
        // Verify cancellation reason constants
        System.assertEquals('Price Too High', Constants.CANCELLATION_REASON_PRICE_TOO_HIGH, 'Price too high reason');
        System.assertEquals('Other', Constants.CANCELLATION_REASON_OTHER, 'Other reason');
        System.assertEquals('Budget Constraints', Constants.CANCELLATION_REASON_BUDGET_CONSTRAINTS, 'Budget constraints');
    }
    
    @isTest
    static void testAccountStatusConstants() {
        // Verify account status constants
        System.assertEquals('Prospect', Constants.ACCOUNT_STATUS_PROSPECT, 'Prospect status');
        System.assertEquals('Active Customer', Constants.ACCOUNT_STATUS_ACTIVE_CUSTOMER, 'Active customer status');
        System.assertEquals('Former Customer', Constants.ACCOUNT_STATUS_FORMER_CUSTOMER, 'Former customer status');
    }
    
    @isTest
    static void testSObjectApiNames() {
        // Verify SObject API names
        System.assertEquals('Subscription__c', Constants.SOBJECT_SUBSCRIPTION, 'Subscription object name');
        System.assertEquals('Invoice__c', Constants.SOBJECT_INVOICE, 'Invoice object name');
        System.assertEquals('Price_Plan__c', Constants.SOBJECT_PRICE_PLAN, 'Price plan object name');
    }
}

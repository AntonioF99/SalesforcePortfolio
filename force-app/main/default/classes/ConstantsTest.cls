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
    static void testTaxRatesByCountry() {
        // Verify tax rates map (actual business logic)
        System.assert(Constants.TAX_RATES_BY_COUNTRY.containsKey('Italy'), 'Should have Italy tax rate');
        System.assertEquals(22.0, Constants.TAX_RATES_BY_COUNTRY.get('Italy'), 'Italy tax rate should be 22%');
        System.assert(Constants.TAX_RATES_BY_COUNTRY.containsKey('Germany'), 'Should have Germany tax rate');
        System.assertEquals(19.0, Constants.TAX_RATES_BY_COUNTRY.get('Germany'), 'Germany tax rate should be 19%');
    }
}

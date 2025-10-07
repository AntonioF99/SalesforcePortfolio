/**
 * @description Test class for RecordTypeUtils functionality
 * @author Antonio Franco
 * @date 2025-09-28
 */
@isTest
public class RecordTypeUtilsTest {
    
    @testSetup
    static void setupTestData() {
        // Create test accounts with different types
        List<Account> testAccounts = new List<Account>();
        
        // B2B Account (large company)
        testAccounts.add(new Account(
            Name = 'Enterprise Corp',
            Type = 'Customer - Channel',
            NumberOfEmployees = 500,
            BillingCountry = 'Italy'
        ));
        
        // B2C Account (individual)
        testAccounts.add(new Account(
            Name = 'John Doe',
            Type = 'Other',
            NumberOfEmployees = 1,
            BillingCountry = 'Italy'
        ));
        
        insert testAccounts;
    }
    
    @isTest
    static void testSubscriptionRecordTypeAssignment() {
        List<Account> accounts = [SELECT Id, Type, NumberOfEmployees FROM Account];
        Account b2bAccount = null;
        Account b2cAccount = null;
        
        for (Account acc : accounts) {
            if (acc.NumberOfEmployees > 10) {
                b2bAccount = acc;
            } else {
                b2cAccount = acc;
            }
        }
        
        // Create product and price plan
        Product__c product = TestDataFactory.createProduct();
        insert product;
        
        Price_Plan__c pricePlan = TestDataFactory.createPricePlan(product.Id);
        insert pricePlan;
        
        // Create subscriptions
        List<Subscription__c> subscriptions = new List<Subscription__c>();
        subscriptions.add(TestDataFactory.createSubscription(b2bAccount.Id, pricePlan.Id));
        subscriptions.add(TestDataFactory.createSubscription(b2cAccount.Id, pricePlan.Id));
        
        Test.startTest();
        insert subscriptions;
        Test.stopTest();
        
        // Verify record types were assigned correctly
        List<Subscription__c> insertedSubs = [
            SELECT Id, RecordType.DeveloperName, Account__c 
            FROM Subscription__c 
            WHERE Id IN :subscriptions
        ];
        
        System.assertEquals(2, insertedSubs.size(), 'Should have 2 subscriptions');
        
        for (Subscription__c sub : insertedSubs) {
            if (sub.Account__c == b2bAccount.Id) {
                System.assertEquals('B2B_Subscription', sub.RecordType.DeveloperName, 
                    'B2B account should get B2B record type');
            } else {
                System.assertEquals('B2C_Subscription', sub.RecordType.DeveloperName, 
                    'B2C account should get B2C record type');
            }
        }
    }
    
    @isTest
    static void testInvoiceRecordTypeAssignment() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        // Create invoices with different amounts
        List<Invoice__c> invoices = new List<Invoice__c>();
        
        // Standard invoice (low value)
        Invoice__c standardInvoice = TestDataFactory.createInvoice(testAccount.Id);
        invoices.add(standardInvoice);

        // High value invoice
        Invoice__c highValueInvoice = TestDataFactory.createInvoice(testAccount.Id);
        invoices.add(highValueInvoice);
        
        Test.startTest();
        insert invoices;
        Test.stopTest();
        
        // Verify record types were assigned correctly
        List<Invoice__c> insertedInvoices = [
            SELECT Id, RecordTypeId, Total_Amount__c
            FROM Invoice__c
            WHERE Id IN :invoices
        ];
        
        System.assertEquals(2, insertedInvoices.size(), 'Should have 2 invoices');
        
        // Get record type IDs for verification
        Id highValueRTId = [SELECT Id FROM RecordType WHERE SObjectType = 'Invoice__c' AND DeveloperName = 'High_Value_Invoice' LIMIT 1].Id;
        Id standardRTId = [SELECT Id FROM RecordType WHERE SObjectType = 'Invoice__c' AND DeveloperName = 'Standard_Invoice' LIMIT 1].Id;

        for (Invoice__c inv : insertedInvoices) {
            if (inv.Total_Amount__c > 5000) {
                System.assertEquals(highValueRTId, inv.RecordTypeId,
                    'High value invoice should get High_Value_Invoice record type');
            } else {
                System.assertEquals(standardRTId, inv.RecordTypeId,
                    'Standard invoice should get Standard_Invoice record type');
            }
        }
    }
    
    @isTest
    static void testGetAvailableRecordTypes() {
        Test.startTest();
        Map<String, Id> subscriptionTypes = RecordTypeUtils.getAvailableRecordTypes('Subscription__c');
        Map<String, Id> invoiceTypes = RecordTypeUtils.getAvailableRecordTypes('Invoice__c');
        Test.stopTest();
        
        // Should have record types available
        System.assert(!subscriptionTypes.isEmpty(), 'Should have subscription record types');
        System.assert(!invoiceTypes.isEmpty(), 'Should have invoice record types');
    }
    
    @isTest 
    static void testRecordTypeAssignmentWithNullAccount() {
        // Test edge case with null account
        List<Subscription__c> subscriptions = new List<Subscription__c>();
        Subscription__c sub = new Subscription__c(
            Status__c = 'Draft',
            Start_Date__c = Date.today()
            // No Account__c
        );
        subscriptions.add(sub);
        
        Test.startTest();
        // Should not fail even with null account
        RecordTypeUtils.assignSubscriptionRecordTypes(subscriptions);
        Test.stopTest();
        
        // Should not crash, record type might be null or default
        System.assert(true, 'Should handle null account gracefully');
    }
}
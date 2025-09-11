/**
 * @description Test data factory for creating test records across the subscription billing platform
 * @author Antonio Franco
 * @date 2025-09-10
 * @story STORY-004: Test Data Factory
 */
@isTest
public class TestDataFactory {
    
    // Counter for unique naming
    private static Integer counter = 0;
    
    // ========== ACCOUNT METHODS ==========
    
    /**
     * @description Creates test Account record with default values
     * @return Account record (not inserted)
     */
    public static Account createAccount() {
    String timestamp = String.valueOf(System.currentTimeMillis()).right(6); // Last 6 digits of timestamp
    String random = String.valueOf(Math.random()).substring(2, 4);          // 2 digit random
    String uniqueId = timestamp + random;                                 // Combine for uniqueness
    
        return new Account(
            Name = 'Test Account ' + uniqueId,
            BillingStreet = 'Via Roma ' + uniqueId.right(3),
            BillingCity = 'Milan',
            BillingPostalCode = '20121',
            BillingCountry = 'Italy',
            Phone = '+39 02 1234' + uniqueId.right(4),
            Industry = 'Technology'
        );
}
    
    /**
     * @description Creates test Account record with custom field overrides
     * @param overrides Map of field values to override defaults
     * @return Account record (not inserted)
     */
    public static Account createAccountWithOverrides(Map<String, Object> overrides) {
        Account acc = createAccount();
        applyOverrides(acc, overrides);
        return acc;
    }
    
    // ========== PRODUCT METHODS ==========
    
      /**
     * @description Creates test Product record with default values
     * @return Product__c record (not inserted)
     */
    public static Product__c createProduct() {
        counter++;
        // Use timestamp + counter to guarantee uniqueness even across parallel tests
        String uniqueId = System.currentTimeMillis() + '-' + counter;
        
        return new Product__c(
            Name = 'Test Product ' + counter,
            Description__c = 'Test product description for automated testing',
            Product_Type__c = 'Recurring',
            Product_Code__c = 'PROD-' + uniqueId,
            Status__c = 'Active'
            
        );
    }
    
    /**
     * @description Creates test Product record with custom field overrides
     * @param overrides Map of field values to override defaults
     * @return Product__c record (not inserted)
     */
    public static Product__c createProductWithOverrides(Map<String, Object> overrides) {
        Product__c product = createProduct();
        applyOverrides(product, overrides);
        return product;
    }
    
    // ========== PRICE PLAN METHODS ==========
    
    /**
     * @description Creates test Price Plan record with default values
     * @param productId ID of the Product to associate with
     * @return Price_Plan__c record (not inserted)
     */
    public static Price_Plan__c createPricePlan(Id productId) {
        counter++;
        
        return new Price_Plan__c(
            Name = 'Test Price Plan ' + counter,
            Product__c = productId,
            Price__c = 99.99,
            Billing_Frequency__c = 'Monthly',
            Currency_Code__c = 'USD',
            Is_Active__c = true
        );
    }
    
    /**
     * @description Creates test Price Plan record with custom field overrides
     * @param productId ID of the Product to associate with
     * @param overrides Map of field values to override defaults
     * @return Price_Plan__c record (not inserted)
     */
    public static Price_Plan__c createPricePlanWithOverrides(Id productId, Map<String, Object> overrides) {
        Price_Plan__c pricePlan = createPricePlan(productId);
        applyOverrides(pricePlan, overrides);
        return pricePlan;
    }
    
    // ========== SUBSCRIPTION METHODS ==========
    
    /**
     * @description Creates test Subscription record with default values
     * @param accountId ID of the Account to associate with
     * @param pricePlanId ID of the Price Plan to associate with
     * @return Subscription__c record (not inserted)
     */
    public static Subscription__c createSubscription(Id accountId, Id pricePlanId) {
        counter++;
        
        return new Subscription__c(
            Account__c = accountId,
            Price_Plan__c = pricePlanId,
            Status__c = 'Draft',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addMonths(12)
        );
    }
    
    /**
     * @description Creates test Subscription record with custom field overrides
     * @param accountId ID of the Account to associate with
     * @param pricePlanId ID of the Price Plan to associate with
     * @param overrides Map of field values to override defaults
     * @return Subscription__c record (not inserted)
     */
    public static Subscription__c createSubscriptionWithOverrides(Id accountId, Id pricePlanId, Map<String, Object> overrides) {
        Subscription__c subscription = createSubscription(accountId, pricePlanId);
        applyOverrides(subscription, overrides);
        return subscription;
    }
    
    // ========== INVOICE METHODS ==========
    
    /**
     * @description Creates test Invoice record with default values
     * @param accountId ID of the Account to associate with
     * @return Invoice__c record (not inserted)
     */
    public static Invoice__c createInvoice(Id accountId) {
        counter++;
        
        return new Invoice__c(
            Account__c = accountId,
            Status__c = 'Draft',
            Invoice_Date__c = Date.today(),
            Due_Date__c = Date.today().addDays(30),
            Balance_Due__c = 0
        );
    }
    
    /**
     * @description Creates test Invoice record with custom field overrides
     * @param accountId ID of the Account to associate with
     * @param overrides Map of field values to override defaults
     * @return Invoice__c record (not inserted)
     */
    public static Invoice__c createInvoiceWithOverrides(Id accountId, Map<String, Object> overrides) {
        Invoice__c invoice = createInvoice(accountId);
        applyOverrides(invoice, overrides);
        return invoice;
    }
    
    // ========== INVOICE LINE ITEM METHODS ==========
    
    /**
     * @description Creates test Invoice Line Item record with default values
     * @param invoiceId ID of the Invoice to associate with
     * @return Invoice_Line_Item__c record (not inserted)
     */
    public static Invoice_Line_Item__c createInvoiceLineItem(Id invoiceId) {
        counter++;
        
        return new Invoice_Line_Item__c(
            Invoice__c = invoiceId,
            Description__c = 'Test Line Item ' + counter,
            Quantity__c = 1,
            Unit_Price__c = 99.99,
            Type__c = 'Subscription'
        );
    }
    
    /**
     * @description Creates test Invoice Line Item record with custom field overrides
     * @param invoiceId ID of the Invoice to associate with
     * @param overrides Map of field values to override defaults
     * @return Invoice_Line_Item__c record (not inserted)
     */
    public static Invoice_Line_Item__c createInvoiceLineItemWithOverrides(Id invoiceId, Map<String, Object> overrides) {
        Invoice_Line_Item__c lineItem = createInvoiceLineItem(invoiceId);
        applyOverrides(lineItem, overrides);
        return lineItem;
    }
    
    // ========== SCENARIO METHODS ==========
    
    /**
     * @description Creates a complete active subscription with all dependencies
     * Creates and inserts: Account, Product, Price Plan, and Active Subscription
     * @return Map containing all created records with keys: Account, Product, PricePlan, Subscription
     */
    public static Map<String, SObject> createActiveSubscription() {
        // Create and insert dependencies
        Account acc = createAccount();
        insert acc;
        
        Product__c product = createProduct();
        insert product;
        
        Price_Plan__c pricePlan = createPricePlan(product.Id);
        insert pricePlan;
        
        // Create Active Subscription
        Subscription__c subscription = createSubscriptionWithOverrides(acc.Id, pricePlan.Id, 
            new Map<String, Object>{'Status__c' => 'Active'});
        insert subscription;
        
        return new Map<String, SObject>{
            'Account' => acc,
            'Product' => product,
            'PricePlan' => pricePlan,
            'Subscription' => subscription
        };
    }
    
    /**
     * @description Creates a complete invoice with line items for testing roll-up calculations
     * Creates and inserts: Account, Invoice, and multiple Line Items
     * @return Map containing all created records with keys: Account, Invoice, LineItems
     */
    public static Map<String, SObject> createInvoiceWithLineItems() {
        // Create and insert Account
        Account acc = createAccount();
        insert acc;
        
        // Create and insert Invoice
        Invoice__c invoice = createInvoice(acc.Id);
        insert invoice;
        
        // Create multiple Line Items for roll-up testing
        List<Invoice_Line_Item__c> lineItems = new List<Invoice_Line_Item__c>();
        
        // Subscription fee line item
        lineItems.add(createInvoiceLineItemWithOverrides(invoice.Id, new Map<String, Object>{
            'Description__c' => 'Monthly Subscription Fee',
            'Quantity__c' => 1,
            'Unit_Price__c' => 99.99,
            'Type__c' => 'Subscription'
        }));
        
        // Setup fee line item
        lineItems.add(createInvoiceLineItemWithOverrides(invoice.Id, new Map<String, Object>{
            'Description__c' => 'One-time Setup Fee',
            'Quantity__c' => 1,
            'Unit_Price__c' => 49.99,
            'Type__c' => 'Setup'
        }));
        
        insert lineItems;
        
        return new Map<String, SObject>{
            'Account' => acc,
            'Invoice' => invoice,
            'LineItems' => lineItems[0] // Return first line item instead of List
        };
    }
    
    /**
     * @description Creates test data for subscription state transitions testing
     * Creates and inserts: Account, Product, Price Plan, and Subscriptions in different states
     * @return Map containing all created records with state-based keys
     */
    public static Map<String, SObject> createSubscriptionStateData() {
        // Create and insert dependencies
        Account acc = createAccount();
        insert acc;
        
        Product__c product = createProduct();
        insert product;
        
        Price_Plan__c pricePlan = createPricePlan(product.Id);
        insert pricePlan;
        
        // Create subscriptions in different states
        List<Subscription__c> subscriptions = new List<Subscription__c>();
        
        // Draft subscription
        subscriptions.add(createSubscriptionWithOverrides(acc.Id, pricePlan.Id, 
            new Map<String, Object>{'Status__c' => 'Draft'}));
        
        // Trial subscription
        subscriptions.add(createSubscriptionWithOverrides(acc.Id, pricePlan.Id, 
            new Map<String, Object>{
                'Status__c' => 'Trial',
                'Trial_End_Date__c' => Date.today().addDays(14)
            }));
        
        // Active subscription
        subscriptions.add(createSubscriptionWithOverrides(acc.Id, pricePlan.Id, 
            new Map<String, Object>{'Status__c' => 'Active'}));
        
        // Suspended subscription
        subscriptions.add(createSubscriptionWithOverrides(acc.Id, pricePlan.Id, 
            new Map<String, Object>{'Status__c' => 'Suspended'}));
        
        insert subscriptions;
        
        return new Map<String, SObject>{
            'Account' => acc,
            'Product' => product,
            'PricePlan' => pricePlan,
            'DraftSubscription' => subscriptions[0],
            'TrialSubscription' => subscriptions[1],
            'ActiveSubscription' => subscriptions[2],
            'SuspendedSubscription' => subscriptions[3]
        };
    }
    
    // ========== UTILITY METHODS ==========
    
    /**
     * @description Applies field overrides to an SObject record
     * @param record The record to modify
     * @param overrides Map of field API names to values
     */
    private static void applyOverrides(SObject record, Map<String, Object> overrides) {
        for (String fieldName : overrides.keySet()) {
            record.put(fieldName, overrides.get(fieldName));
        }
    }
    
    /**
     * @description Gets a unique counter value for test data
     * @return Unique integer value
     */
    public static Integer getUniqueCounter() {
        return ++counter;
    }
    
}
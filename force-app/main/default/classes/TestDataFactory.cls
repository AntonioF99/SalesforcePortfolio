/**
 * @description Minimal test data factory - focused on basic record creation only
 * @author Antonio Franco
 * @date 2025-09-12
 * @story STORY-005: Test Data Refactoring
 * @pattern Clean Factory - no overrides, no insertions, clear intent
 */
@isTest
public class TestDataFactory {
    
    private static Integer counter = 0;
    
    // ========== ACCOUNT METHODS ==========
    
    /**
     * @description Creates basic Account with Italian billing address
     * @return Account record (not inserted)
     */
    public static Account createAccount() {
        counter++;
        String uniqueId = String.valueOf(System.currentTimeMillis() + counter);
        
        return new Account(
            Name = 'Test Account ' + counter,
            BillingStreet = 'Via Roma ' + counter,
            BillingCity = 'Milan',
            BillingPostalCode = '20121',
            BillingCountry = 'Italy',
            Phone = '+39 02 1234' + uniqueId.right(4),
            Industry = 'Technology'
        );
    }
    
    /**
     * @description Creates Account for specific country (tax testing)
     * @param country Billing country for tax calculation
     * @return Account record (not inserted)
     */
    public static Account createAccountForCountry(String country) {
        Account acc = createAccount();
        acc.BillingCountry = country;
        
        // Country-specific realistic addresses
        switch on country {
            when 'Germany' {
                acc.BillingCity = 'Berlin';
                acc.BillingPostalCode = '10115';
                acc.BillingStreet = 'Unter den Linden ' + counter;
            }
            when 'United Kingdom' {
                acc.BillingCity = 'London';
                acc.BillingPostalCode = 'SW1A 2AA';
                acc.BillingStreet = 'Downing Street ' + counter;
            }
            when 'France' {
                acc.BillingCity = 'Paris';
                acc.BillingPostalCode = '75001';
                acc.BillingStreet = 'Rue de Rivoli ' + counter;
            }
            when 'Spain' {
                acc.BillingCity = 'Madrid';
                acc.BillingPostalCode = '28001';
                acc.BillingStreet = 'Gran Via ' + counter;
            }
            when 'Netherlands' {
                acc.BillingCity = 'Amsterdam';
                acc.BillingPostalCode = '1012';
                acc.BillingStreet = 'Damrak ' + counter;
            }
            when 'Japan' {
                acc.BillingCity = 'Tokyo';
                acc.BillingPostalCode = '100-0001';
                acc.BillingStreet = 'Chiyoda ' + counter;
            }
        }
        
        return acc;
    }
    
    // ========== PRODUCT METHODS ==========
    
    /**
     * @description Creates basic Product
     * @return Product__c record (not inserted)
     */
    public static Product__c createProduct() {
        counter++;
        String uniqueId = String.valueOf(System.currentTimeMillis() + counter);
        
        return new Product__c(
            Name = 'Test Product ' + counter,
            Description__c = 'Test product for automated testing',
            Product_Type__c = 'Recurring',
            Product_Code__c = 'PROD-' + uniqueId,
            Status__c = 'Active'
        );
    }
    
    // ========== PRICE PLAN METHODS ==========
    
    /**
     * @description Creates basic Price Plan
     * @param productId Product to associate with
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
    
    // ========== SUBSCRIPTION METHODS ==========
    
    /**
     * @description Creates basic Subscription in Draft status
     * @param accountId Account to associate with
     * @param pricePlanId Price Plan to associate with
     * @return Subscription__c record (not inserted)
     */
    public static Subscription__c createSubscription(Id accountId, Id pricePlanId) {
        return new Subscription__c(
            Account__c = accountId,
            Price_Plan__c = pricePlanId,
            Status__c = 'Draft',
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addMonths(12)
        );
    }
    
    // ========== INVOICE METHODS ==========
    
    /**
     * @description Creates basic Invoice in Draft status
     * @param accountId Account to associate with
     * @return Invoice__c record (not inserted)
     */
    public static Invoice__c createInvoice(Id accountId) {
        return new Invoice__c(
            Account__c = accountId,
            Status__c = 'Draft',
            Invoice_Date__c = Date.today(),
            Due_Date__c = Date.today().addDays(30),
            Balance_Due__c = 0
        );
    }
    
    /**
     * @description Creates Invoice with invalid dates for validation testing
     * @param accountId Account to associate with
     * @return Invoice__c record with invalid dates (not inserted)
     */
    public static Invoice__c createInvoiceWithInvalidDates(Id accountId) {
        Invoice__c invoice = createInvoice(accountId);
        invoice.Invoice_Date__c = Date.today();
        invoice.Due_Date__c = Date.today().addDays(-5); // Invalid: due before invoice
        return invoice;
    }
    
    /**
     * @description Creates Invoice with negative balance for validation testing
     * @param accountId Account to associate with
     * @return Invoice__c record with negative balance (not inserted)
     */
    public static Invoice__c createInvoiceWithNegativeBalance(Id accountId) {
        Invoice__c invoice = createInvoice(accountId);
        invoice.Balance_Due__c = -100.00;
        return invoice;
    }
    
    // ========== INVOICE LINE ITEM METHODS ==========
    
    /**
     * @description Creates basic Invoice Line Item
     * @param invoiceId Invoice to associate with
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
     * @description Creates Invoice Line Item with custom amount
     * @param invoiceId Invoice to associate with  
     * @param unitPrice Unit price for the line item
     * @return Invoice_Line_Item__c record (not inserted)
     */
    public static Invoice_Line_Item__c createLineItemWithAmount(Id invoiceId, Decimal unitPrice) {
        Invoice_Line_Item__c lineItem = createInvoiceLineItem(invoiceId);
        lineItem.Unit_Price__c = unitPrice;
        return lineItem;
    }
    
    // ========== UTILITY METHODS ==========
    
    /**
     * @description Gets unique counter for naming
     * @return Incremented counter value
     */
    public static Integer getUniqueCounter() {
        return ++counter;
    }
}
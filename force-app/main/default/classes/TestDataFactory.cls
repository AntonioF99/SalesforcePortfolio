/**
 * @description Minimal test data factory - focused on basic record creation only
 * @author Antonio Franco
 * @date 2025-09-12
 * @story STORY-005: Test Data Refactoring
 */
@isTest
public class TestDataFactory {
    
    private static Integer counter = 0;
    
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
     * @description Creates a Contact record for testing
     * @param accountId The Account to associate the Contact with
     * @return Contact record (not inserted)
     */
    public static Contact createContact(Id accountId) {
        counter++;
        String uniqueId = String.valueOf(System.currentTimeMillis() + counter);

        return new Contact(
            FirstName = 'Test',
            LastName = 'Contact ' + counter,
            Email = 'test.contact' + counter + '@example.com',
            Phone = '+39 02 9876' + uniqueId.right(4),
            AccountId = accountId
        );
    }
    
    /*
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
    
    public static Price_Plan__c createPricePlan() {
        counter++;

        return new Price_Plan__c(
            Name = 'Test Plan ' + counter,
            Category__c = 'CRM Base',
            Unit_Price__c = 99.99,
            Billing_Frequency__c = 'Monthly',
            Currency_Code__c = 'USD'
        );
    }
    
    public static Subscription__c createSubscription(Id accountId, Id pricePlanId) {
        // RecordTypeId is intentionally left null to allow trigger to assign it based on Account
        return new Subscription__c(
            Account__c = accountId,
            Price_Plan__c = pricePlanId,
            Status__c = 'Draft',
            Start_Date__c = Date.today()
        );
    }
    
    // Overloaded method for simplified subscription creation
    public static Subscription__c createSubscription(Id accountId) {
        // Create a basic price plan if none provided
        Price_Plan__c pricePlan = createPricePlan();
        insert pricePlan;

        return createSubscription(accountId, pricePlan.Id);
    }
    
    public static Invoice__c createInvoice(Id accountId) {
        return new Invoice__c(
            Account__c = accountId,
            Status__c = 'Draft',
            Invoice_Date__c = Date.today(),
            Due_Date__c = Date.today().addDays(30),
            Balance_Due__c = 0
        );
    }
    
    public static Invoice__c createInvoiceWithInvalidDates(Id accountId) {
        Invoice__c invoice = createInvoice(accountId);
        invoice.Invoice_Date__c = Date.today();
        invoice.Due_Date__c = Date.today().addDays(-5); // Invalid: due before invoice
        return invoice;
    }
    
    public static Invoice__c createInvoiceWithNegativeBalance(Id accountId) {
        Invoice__c invoice = createInvoice(accountId);
        invoice.Balance_Due__c = -100.00;
        return invoice;
    }
    
    public static Invoice_Line_Item__c createInvoiceLineItem(Id invoiceId) {
        counter++;

        return new Invoice_Line_Item__c(
            Invoice__c = invoiceId,
            Description__c = 'Test Line Item ' + counter,
            Quantity__c = 1,
            Unit_Price__c = 99.99,
            Type__c = Constants.LINE_ITEM_TYPE_ADD_ON,
            Status__c = 'Active'
        );
    }
    
    /*
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
    
    public static Integer getUniqueCounter() {
        return ++counter;
    }
    
    // Utility method to generate fake Salesforce IDs for testing
    public static Id getFakeId(Schema.SObjectType sobjectType) {
        String sobjectPrefix = sobjectType.getDescribe().getKeyPrefix();
        String fakeIdPrefix = sobjectPrefix + '0'.repeat(12 - sobjectPrefix.length());
        String fakeIdSuffix = String.valueOf(Math.random()).substring(2, 5);
        return Id.valueOf(fakeIdPrefix + fakeIdSuffix);
    }
}
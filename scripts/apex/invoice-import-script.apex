// Anonymous Apex Script to Insert Invoice Test Data - Working Version
// Execute in Developer Console > Debug > Open Execute Anonymous Apex

// Get Account IDs for invoices
Map<String, Id> accountMap = new Map<String, Id>();
for (Account acc : [SELECT Id, Name FROM Account LIMIT 10]) {
    accountMap.put(acc.Name, acc.Id);
}

List<String> availableAccounts = new List<String>(accountMap.keySet());
System.debug('Available accounts: ' + availableAccounts);

// Create Invoice records with only confirmed existing fields
// Start with Draft status to avoid validation issues
List<Invoice__c> invoices = new List<Invoice__c>();

// Invoice 1 - Draft status
if (availableAccounts.size() > 0) {
    invoices.add(new Invoice__c(
        Account__c = accountMap.get(availableAccounts[0]),
        Status__c = 'Draft',
        Invoice_Date__c = Date.newInstance(2024, 1, 15),
        Due_Date__c = Date.newInstance(2024, 2, 14)
    ));
}

// Invoice 2 - Draft status
if (availableAccounts.size() > 1) {
    invoices.add(new Invoice__c(
        Account__c = accountMap.get(availableAccounts[1]),
        Status__c = 'Draft',
        Invoice_Date__c = Date.newInstance(2024, 11, 1),
        Due_Date__c = Date.newInstance(2024, 12, 1)
    ));
}

// Invoice 3 - Draft status
if (availableAccounts.size() > 2) {
    invoices.add(new Invoice__c(
        Account__c = accountMap.get(availableAccounts[2]),
        Status__c = 'Draft',
        Invoice_Date__c = Date.newInstance(2024, 11, 5),
        Due_Date__c = Date.newInstance(2024, 12, 5)
    ));
}

// Invoice 4 - Draft status
if (availableAccounts.size() > 3) {
    invoices.add(new Invoice__c(
        Account__c = accountMap.get(availableAccounts[3]),
        Status__c = 'Draft',
        Invoice_Date__c = Date.newInstance(2024, 3, 1),
        Due_Date__c = Date.newInstance(2024, 3, 31)
    ));
}

// Invoice 5 - Draft status
if (availableAccounts.size() > 4) {
    invoices.add(new Invoice__c(
        Account__c = accountMap.get(availableAccounts[4]),
        Status__c = 'Draft',
        Invoice_Date__c = Date.newInstance(2024, 4, 15),
        Due_Date__c = Date.newInstance(2024, 5, 15)
    ));
}

// Invoice 6 - Draft status
if (availableAccounts.size() > 5) {
    invoices.add(new Invoice__c(
        Account__c = accountMap.get(availableAccounts[5]),
        Status__c = 'Draft',
        Invoice_Date__c = Date.newInstance(2024, 10, 1),
        Due_Date__c = Date.newInstance(2024, 10, 31)
    ));
}

// Insert the invoices
try {
    insert invoices;
    System.debug('Successfully inserted ' + invoices.size() + ' invoice records');
    
    // Query back to see the auto-generated names
    List<Invoice__c> insertedInvoices = [SELECT Id, Name, Status__c, Account__r.Name FROM Invoice__c WHERE Id IN :invoices];
    for (Invoice__c inv : insertedInvoices) {
        System.debug('Invoice: ' + inv.Name + ' | Account: ' + inv.Account__r.Name + ' | Status: ' + inv.Status__c);
    }
    
    System.debug('=== INVOICE IMPORT COMPLETED SUCCESSFULLY ===');
    System.debug('Created ' + insertedInvoices.size() + ' invoices in Draft status');
    System.debug('You can now create invoice line items and then update status');
    
} catch (Exception e) {
    System.debug('Error inserting invoices: ' + e.getMessage());
    System.debug('Stack trace: ' + e.getStackTraceString());
}

System.debug('Invoice import script completed');
// Delete all test data before refactoring - use Database methods to bypass some validations

// Delete all Invoices (cascades to Line Items via Master-Detail)
List<Invoice__c> invoices = [SELECT Id FROM Invoice__c LIMIT 10000];
if (!invoices.isEmpty()) {
    Database.delete(invoices, false); // allOrNone = false
    System.debug('Attempted to delete ' + invoices.size() + ' invoices');
}

// Delete all Subscriptions
List<Subscription__c> subscriptions = [SELECT Id FROM Subscription__c LIMIT 10000];
if (!subscriptions.isEmpty()) {
    Database.delete(subscriptions, false);
    System.debug('Attempted to delete ' + subscriptions.size() + ' subscriptions');
}

// Delete all Products
List<Product__c> products = [SELECT Id FROM Product__c LIMIT 10000];
if (!products.isEmpty()) {
    Database.delete(products, false);
    System.debug('Attempted to delete ' + products.size() + ' products');
}

System.debug('✅ Cleanup completed');

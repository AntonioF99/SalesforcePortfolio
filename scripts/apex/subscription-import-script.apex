// Anonymous Apex Script to Insert Subscription Test Data - Using Existing Accounts
// Execute in Developer Console > Debug > Open Execute Anonymous Apex

// First, get Account and Price Plan IDs
Map<String, Id> accountMap = new Map<String, Id>();
for (Account acc : [SELECT Id, Name FROM Account]) {
    accountMap.put(acc.Name, acc.Id);
}

Map<String, Id> pricePlanMap = new Map<String, Id>();
for (Price_Plan__c pp : [SELECT Id, Name FROM Price_Plan__c]) {
    pricePlanMap.put(pp.Name, pp.Id);
}

System.debug('Accounts found: ' + accountMap.keySet());
System.debug('Price Plans found: ' + pricePlanMap.keySet());

// Get the first few accounts to use for testing
List<String> availableAccounts = new List<String>(accountMap.keySet());
List<String> availablePricePlans = new List<String>(pricePlanMap.keySet());

System.debug('Using account: ' + availableAccounts[0]);
System.debug('Using price plan: ' + availablePricePlans[0]);

// Create Subscription records using existing accounts and price plans
List<Subscription__c> subscriptions = new List<Subscription__c>();

// SUB-001 - Using first available account and price plan
subscriptions.add(new Subscription__c(
    Name = 'SUB-001',
    Account__c = accountMap.get(availableAccounts[0]),
    Price_Plan__c = pricePlanMap.get(availablePricePlans[0]),
    Status__c = 'Active',
    Start_Date__c = Date.newInstance(2024, 1, 15)
));

// SUB-002 - Using second account if available
if (availableAccounts.size() > 1 && availablePricePlans.size() > 1) {
    subscriptions.add(new Subscription__c(
        Name = 'SUB-002',
        Account__c = accountMap.get(availableAccounts[1]),
        Price_Plan__c = pricePlanMap.get(availablePricePlans[1]),
        Status__c = 'Active',
        Start_Date__c = Date.newInstance(2024, 2, 1)
    ));
}

// SUB-003 - Trial status
if (availableAccounts.size() > 2 && availablePricePlans.size() > 2) {
    subscriptions.add(new Subscription__c(
        Name = 'SUB-003',
        Account__c = accountMap.get(availableAccounts[2]),
        Price_Plan__c = pricePlanMap.get(availablePricePlans[2]),
        Status__c = 'Trial',
        Start_Date__c = Date.newInstance(2024, 11, 1)
    ));
}

// SUB-004
if (availableAccounts.size() > 3 && availablePricePlans.size() > 3) {
    subscriptions.add(new Subscription__c(
        Name = 'SUB-004',
        Account__c = accountMap.get(availableAccounts[3]),
        Price_Plan__c = pricePlanMap.get(availablePricePlans[3]),
        Status__c = 'Active',
        Start_Date__c = Date.newInstance(2024, 3, 1)
    ));
}

// SUB-005
if (availableAccounts.size() > 4 && availablePricePlans.size() > 4) {
    subscriptions.add(new Subscription__c(
        Name = 'SUB-005',
        Account__c = accountMap.get(availableAccounts[4]),
        Price_Plan__c = pricePlanMap.get(availablePricePlans[4]),
        Status__c = 'Active',
        Start_Date__c = Date.newInstance(2024, 4, 15)
    ));
}

// SUB-006 - Draft status
if (availableAccounts.size() > 5 && availablePricePlans.size() > 5) {
    subscriptions.add(new Subscription__c(
        Name = 'SUB-006',
        Account__c = accountMap.get(availableAccounts[5]),
        Price_Plan__c = pricePlanMap.get(availablePricePlans[5]),
        Status__c = 'Draft'
    ));
}

// SUB-007 - Cancelled status (if possible)
if (availableAccounts.size() > 6 && availablePricePlans.size() > 6) {
    subscriptions.add(new Subscription__c(
        Name = 'SUB-007',
        Account__c = accountMap.get(availableAccounts[6]),
        Price_Plan__c = pricePlanMap.get(availablePricePlans[6]),
        Status__c = 'Cancelled',
        Start_Date__c = Date.newInstance(2024, 6, 1)
    ));
}

// Insert the subscriptions
try {
    insert subscriptions;
    System.debug('Successfully inserted ' + subscriptions.size() + ' subscription records');
    
    // Print the IDs for reference
    for (Subscription__c sub : subscriptions) {
        System.debug('Inserted: ' + sub.Name + ' with ID: ' + sub.Id);
    }
    
} catch (Exception e) {
    System.debug('Error inserting subscriptions: ' + e.getMessage());
    System.debug('Stack trace: ' + e.getStackTraceString());
}

System.debug('Script execution completed');

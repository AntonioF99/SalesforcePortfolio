// Check ALL accounts
List<Account> accounts = [SELECT Id, Name FROM Account ORDER BY Name];

System.debug('Found ' + accounts.size() + ' total accounts:');
for (Account acc : accounts) {
    System.debug('- ' + acc.Name + ' (ID: ' + acc.Id + ')');
}
// Check if Subscription_Welcome email template exists
List<EmailTemplate> templates = [SELECT Id, Name, DeveloperName, Subject, Body FROM EmailTemplate WHERE DeveloperName = 'Subscription_Welcome'];

if (templates.isEmpty()) {
    System.debug('ERROR: Subscription_Welcome email template NOT FOUND!');

    // Check what email templates exist
    List<EmailTemplate> allTemplates = [SELECT Id, Name, DeveloperName FROM EmailTemplate ORDER BY DeveloperName];
    System.debug('Available templates (' + allTemplates.size() + '):');
    for (EmailTemplate t : allTemplates) {
        System.debug('- ' + t.DeveloperName + ' (' + t.Name + ')');
    }
} else {
    EmailTemplate template = templates[0];
    System.debug('Found Subscription_Welcome template:');
    System.debug('- ID: ' + template.Id);
    System.debug('- Name: ' + template.Name);
    System.debug('- DeveloperName: ' + template.DeveloperName);
    System.debug('- Subject: ' + template.Subject);
    System.debug('- Body length: ' + (template.Body != null ? template.Body.length() : 0));
}
// Update ALL Contact emails to antoniofranco.99@outlook.com

// First, check how many contacts we have
List<Contact> allContacts = [SELECT Id, Name, Email, AccountId FROM Contact];
System.debug('Found ' + allContacts.size() + ' total contacts');

// Update all contacts to use the new email
List<Contact> contactsToUpdate = new List<Contact>();

for (Contact contact : allContacts) {
    System.debug('Current: ' + contact.Name + ' - Email: ' + contact.Email);

    Contact updatedContact = new Contact(
        Id = contact.Id,
        Email = 'antoniofranco.99@outlook.com'
    );
    contactsToUpdate.add(updatedContact);
}

// Bulk update all contacts
if (!contactsToUpdate.isEmpty()) {
    update contactsToUpdate;
    System.debug('Successfully updated ' + contactsToUpdate.size() + ' contacts with new email');
} else {
    System.debug('No contacts to update');
}

// Verify the update
List<Contact> verifyContacts = [SELECT Id, Name, Email FROM Contact WHERE Email = 'antoniofranco.99@outlook.com'];
System.debug('Verification: ' + verifyContacts.size() + ' contacts now have the correct email');
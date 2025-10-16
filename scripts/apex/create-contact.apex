// Use direct account ID for Osaka Digital Systems
Id accountId = '001gK00000M3jdZQAR';

// Check if Contact already exists
List<Contact> existingContacts = [SELECT Id, Email FROM Contact WHERE AccountId = :accountId AND Email != null LIMIT 1];

if (existingContacts.isEmpty()) {
    // Create new Contact
    Contact newContact = new Contact(
        FirstName = 'Hiroshi',
        LastName = 'Tanaka',
        Email = 'hiroshi.tanaka@osakadigital.co.jp',
        AccountId = accountId,
        Phone = '+81-6-1234-5678',
        Title = 'IT Manager'
    );

    insert newContact;
    System.debug('Created Contact: ' + newContact.FirstName + ' ' + newContact.LastName + ' (' + newContact.Email + ')');
} else {
    System.debug('Contact already exists: ' + existingContacts[0].Email);
}
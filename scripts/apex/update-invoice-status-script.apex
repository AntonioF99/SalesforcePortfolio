// Anonymous Apex Script to Update Invoice Status
// Execute in Developer Console > Debug > Open Execute Anonymous Apex

// Get all draft invoices
List<Invoice__c> invoices = [SELECT Id, Name, Status__c FROM Invoice__c WHERE Status__c = 'Draft' ORDER BY CreatedDate];

System.debug('Found ' + invoices.size() + ' draft invoices to update');

// Update each invoice with different status
for (Integer i = 0; i < invoices.size(); i++) {
    Invoice__c inv = invoices[i];
    
    // Assign different statuses for variety
    switch on Math.mod(i, 5) {
        when 0 {
            inv.Status__c = 'Sent';
        }
        when 1 {
            inv.Status__c = 'Paid';
        }
        when 2 {
            inv.Status__c = 'Partially Paid';
        }
        when 3 {
            inv.Status__c = 'Overdue';
        }
        when else {
            inv.Status__c = 'Sent';
        }
    }
    
    System.debug('Updating ' + inv.Name + ' to status: ' + inv.Status__c);
}

// Update the invoices
try {
    update invoices;
    System.debug('Successfully updated ' + invoices.size() + ' invoice statuses');
    
    // Query back to confirm
    List<Invoice__c> updatedInvoices = [SELECT Id, Name, Status__c FROM Invoice__c WHERE Id IN :invoices];
    for (Invoice__c inv : updatedInvoices) {
        System.debug('Final status - ' + inv.Name + ': ' + inv.Status__c);
    }
    
} catch (Exception e) {
    System.debug('Error updating invoice statuses: ' + e.getMessage());
    System.debug('Stack trace: ' + e.getStackTraceString());
}

System.debug('Invoice status update script completed');
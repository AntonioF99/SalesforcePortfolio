/**
 * @description Controller for Invoice LWC
 * @author Antonio Franco
 * @date 2025-09-16
 */
public with sharing class InvoiceController {
    
    @AuraEnabled(cacheable=false)
    public static Invoice__c getInvoiceWithRelated(Id invoiceId) {
        return [
            SELECT Id, Name, 
                   Account__c, Account__r.Name, Account__r.Type,
                   Status__c,
                   Invoice_Date__c,
                   Due_Date__c,
                   Payment_Terms__c,
                   Tax_Rate__c,
                   Subtotal__c,
                   Tax_Amount__c,
                   Total_Amount__c,
                   Balance_Due__c,
                   RecordType.DeveloperName
            FROM Invoice__c 
            WHERE Id = :invoiceId 
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
    }
    
    // These methods are no longer needed but kept for LWC compatibility
    // Can be removed after updating JavaScript components
    @AuraEnabled
    public static Id createInvoice(Invoice__c invoice) {
        /**
         * SECURITY: Security.stripInaccessible() protects against attempts to set fields
         * without appropriate FLS permissions.
         *
         * WHY THIS IS NECESSARY:
         * This method receives a complete Invoice__c from the LWC. A user could attempt
         * to set protected fields like Balance_Due__c, Tax_Amount__c, Total_Amount__c
         * even without FLS create permissions.
         *
         * WHAT IT DOES:
         * - AccessType.CREATABLE = checks CREATE FLS for each invoice field
         * - Automatically removes non-permitted fields before insert
         * - Prevents FLS errors and privilege escalation attempts
         *
         * EXAMPLE:
         * Input: { Account__c: '001xxx', Invoice_Date__c: today, Balance_Due__c: 1000 }
         * If user CANNOT create Balance_Due__c (formula field):
         * After strip: { Account__c: '001xxx', Invoice_Date__c: today }
         * Balance_Due__c field is calculated automatically by the system.
         */
        SObjectAccessDecision decision = Security.stripInaccessible(
            AccessType.CREATABLE,
            new List<Invoice__c>{ invoice }
        );
        insert decision.getRecords();
        return ((Invoice__c)decision.getRecords()[0]).Id;
    }

    @AuraEnabled
    public static void updateInvoice(Invoice__c invoice) {
        /**
         * SECURITY: Security.stripInaccessible() filters fields modifiable by the user
         * based on FLS EDIT permissions.
         *
         * WHY THIS IS NECESSARY:
         * The LWC can send an Invoice__c with any modified field. Without this protection,
         * a user could bypass FLS permissions and modify restricted fields
         * like Balance_Due__c, Tax_Rate__c, or audit fields.
         *
         * WHAT IT DOES:
         * - AccessType.UPDATABLE = checks UPDATE FLS for each modified field
         * - Removes non-permitted fields before the update
         * - Permitted fields are updated normally
         *
         * EXAMPLE:
         * Input: { Id: '001xxx', Status__c: 'Paid', Balance_Due__c: 0, Tax_Rate__c: 25 }
         * If user can modify Status__c but NOT Balance_Due__c and Tax_Rate__c:
         * After strip: { Id: '001xxx', Status__c: 'Paid' }
         * Only Status__c is updated, other fields are silently ignored.
         *
         * NOTE: InvoiceValidator will continue to validate business rules on permitted fields.
         */
        SObjectAccessDecision decision = Security.stripInaccessible(
            AccessType.UPDATABLE,
            new List<Invoice__c>{ invoice }
        );
        update decision.getRecords();
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Invoice__c> getInvoicesByAccount(Id accountId) {
        return [
            SELECT Id, Name,
                   Account__c, Account__r.Name,
                   Status__c,
                   Invoice_Date__c,
                   Due_Date__c,
                   Total_Amount__c,
                   Balance_Due__c,
                   RecordType.DeveloperName
            FROM Invoice__c
            WHERE Account__c = :accountId
            WITH SECURITY_ENFORCED
            ORDER BY Invoice_Date__c DESC
            LIMIT 100
        ];
    }

    @AuraEnabled(cacheable=true)
    public static List<Invoice__c> getRecentInvoices() {
        return [
            SELECT Id, Name,
                   Account__c, Account__r.Name,
                   Status__c,
                   Invoice_Date__c,
                   Due_Date__c,
                   Total_Amount__c,
                   Balance_Due__c,
                   RecordType.DeveloperName
            FROM Invoice__c
            WITH SECURITY_ENFORCED
            ORDER BY Invoice_Date__c DESC
            LIMIT 50
        ];
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Invoice__c> getOverdueInvoices() {
        List<Invoice__c> invoices = [
            SELECT Id, Name,
                   Account__c, Account__r.Name,
                   Status__c,
                   Due_Date__c,
                   Total_Amount__c,
                   Balance_Due__c,
                   Reminders_Sent__c,
                   Last_Reminder_Date__c
            FROM Invoice__c
            WHERE Status__c = :Constants.INVOICE_STATUS_OVERDUE
            ORDER BY Due_Date__c ASC
            LIMIT 50
        ];

        SObjectAccessDecision decision = Security.stripInaccessible(
            AccessType.READABLE,
            invoices
        );

        return decision.getRecords();
    }

    /**
     * @description Send payment reminder for overdue invoice
     * @param invoiceId The ID of the invoice to send reminder for
     * @throws AuraHandledException if validation fails or DML error occurs
     */
    @AuraEnabled
    public static void sendInvoice(Id invoiceId) {
        // Guard clause: validate input
        if (invoiceId == null) {
            throw new AuraHandledException('Invoice ID is required');
        }

        // Query invoice with security enforced
        List<Invoice__c> invoices;
        try {
            invoices = [
                SELECT Id, Status__c, Reminders_Sent__c, Last_Reminder_Date__c
                FROM Invoice__c
                WHERE Id = :invoiceId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
        } catch (QueryException e) {
            throw new AuraHandledException('Invoice not found or insufficient permissions');
        }

        // Early return: check if invoice exists
        if (invoices.isEmpty()) {
            throw new AuraHandledException('Invoice not found or you do not have access');
        }

        Invoice__c invoice = invoices[0];

        // Early return validations: check status before sending
        if (invoice.Status__c == Constants.INVOICE_STATUS_PAID) {
            throw new AuraHandledException('Cannot send reminder for an invoice that is already paid');
        }

        if (invoice.Status__c == Constants.INVOICE_STATUS_VOIDED) {
            throw new AuraHandledException('Cannot send reminder for a voided invoice');
        }

        // Happy path: increment reminder counter and update
        invoice.Reminders_Sent__c = (invoice.Reminders_Sent__c == null ? 0 : invoice.Reminders_Sent__c) + 1;
        invoice.Last_Reminder_Date__c = System.now();

        try {
            update invoice;
        } catch (DmlException e) {
            throw new AuraHandledException('Error sending reminder: ' + e.getMessage());
        }
    }

    /**
     * @description Mark invoice as paid by changing status to 'Paid' and Balance_Due to 0
     * @param invoiceId The ID of the invoice to mark as paid
     * @throws AuraHandledException if validation fails or DML error occurs
     */
    @AuraEnabled
    public static void markAsPaid(Id invoiceId) {
        // Guard clause: validate input
        if (invoiceId == null) {
            throw new AuraHandledException('Invoice ID is required');
        }

        // Query invoice with security enforced
        Invoice__c invoice;
        try {
            invoice = [
                SELECT Id, Status__c, Balance_Due__c, Total_Amount__c
                FROM Invoice__c
                WHERE Id = :invoiceId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
        } catch (QueryException e) {
            throw new AuraHandledException('Invoice not found or insufficient permissions');
        }

        // Early return validations: check status before attempting update
        if (invoice.Status__c == Constants.INVOICE_STATUS_DRAFT) {
            throw new AuraHandledException('Cannot mark a draft invoice as paid. Please send it first.');
        }

        if (invoice.Status__c == Constants.INVOICE_STATUS_VOIDED) {
            throw new AuraHandledException('Cannot mark a voided invoice as paid');
        }

        if (invoice.Status__c == Constants.INVOICE_STATUS_PAID) {
            throw new AuraHandledException('Invoice is already marked as paid');
        }

        // Happy path: update invoice
        invoice.Status__c = Constants.INVOICE_STATUS_PAID;
        invoice.Balance_Due__c = 0;

        try {
            update invoice;
        } catch (DmlException e) {
            throw new AuraHandledException('Error marking invoice as paid: ' + e.getMessage());
        }
    }

}
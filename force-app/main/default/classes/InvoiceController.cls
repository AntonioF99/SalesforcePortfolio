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
        insert invoice;
        return invoice.Id;
    }
    
    @AuraEnabled
    public static void updateInvoice(Invoice__c invoice) {
        update invoice;
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
    public static List<Invoice__c> getOverdueInvoices() {
        return [
            SELECT Id, Name,
                   Account__c, Account__r.Name,
                   Status__c,
                   Due_Date__c,
                   Total_Amount__c,
                   Balance_Due__c
            FROM Invoice__c 
            WHERE Status__c = 'Overdue'
            AND Balance_Due__c > 0
            WITH SECURITY_ENFORCED
            ORDER BY Due_Date__c ASC
            LIMIT 50
        ];
    }
    
}
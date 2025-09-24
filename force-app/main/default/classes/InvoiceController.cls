/**
 * @description Controller for Invoice LWC
 * @author Antonio Franco
 * @date 2025-09-16
 */
public with sharing class InvoiceController {
    
    @AuraEnabled(cacheable=false)
    public static Invoice__c getInvoiceWithRelated(Id invoiceId) {
        Invoice__c result = [
            SELECT Id, Name, 
                   Account__c,
                   Status__c,
                   Invoice_Date__c,
                   Due_Date__c,
                   Payment_Terms__c,
                   Tax_Rate__c,
                   Subtotal__c,
                   Tax_Amount__c,
                   Total_Amount__c,
                   Balance_Due__c
            FROM Invoice__c 
            WHERE Id = :invoiceId 
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        
        // Load Account name
        if (result.Account__c != null) {
            result.Account__r = [SELECT Name FROM Account WHERE Id = :result.Account__c WITH SECURITY_ENFORCED LIMIT 1];
        }
        
        return result;
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
}
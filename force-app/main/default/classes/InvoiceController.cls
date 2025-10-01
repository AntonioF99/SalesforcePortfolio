/**
 * @description Controller for Invoice LWC
 * @author Antonio Franco
 * @date 2025-09-16
 */
public with sharing class InvoiceController {
    
    @AuraEnabled(cacheable=false)
    public static Invoice__c getInvoiceWithRelated(Id invoiceId) {
        PerformanceMonitor.PerformanceSnapshot baseline = new PerformanceMonitor.PerformanceSnapshot();
        
        Invoice__c result = [
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
        
        PerformanceMonitor.logPerformanceMetrics('InvoiceController.getInvoiceWithRelated', baseline);
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
    
    @AuraEnabled(cacheable=true)
    public static List<Invoice__c> getInvoicesByAccount(Id accountId) {
        PerformanceMonitor.PerformanceSnapshot baseline = new PerformanceMonitor.PerformanceSnapshot();
        
        List<Invoice__c> results = [
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
        
        PerformanceMonitor.logPerformanceMetrics('InvoiceController.getInvoicesByAccount', baseline);
        return results;
    }
    
    @AuraEnabled(cacheable=true) 
    public static List<Invoice__c> getOverdueInvoices() {
        PerformanceMonitor.PerformanceSnapshot baseline = new PerformanceMonitor.PerformanceSnapshot();
        
        List<Invoice__c> results = [
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
        
        PerformanceMonitor.logPerformanceMetrics('InvoiceController.getOverdueInvoices', baseline);
        return results;
    }
    
    @AuraEnabled
    public static Map<String, Object> getPerformanceStats() {
        return PerformanceMonitor.getCurrentUsage();
    }
}
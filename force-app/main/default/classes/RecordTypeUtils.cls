/**
 * @description Utility class for automatic record type assignment
 * @author Antonio Franco  
 * @date 2025-09-28
 * @purpose Simplify user experience with intelligent record type selection
 */
public class RecordTypeUtils {
    
    // Cache for record type IDs to avoid repeated queries
    private static Map<String, Id> recordTypeCache = new Map<String, Id>();
    
    /**
     * @description Assigns appropriate record types to subscriptions based on account type
     * @param subscriptions List of subscription records to process
     */
    public static void assignSubscriptionRecordTypes(List<Subscription__c> subscriptions) {
        
        if (subscriptions.isEmpty()) return;
        
        // Get Account information for business logic
        Set<Id> accountIds = new Set<Id>();
        for (Subscription__c sub : subscriptions) {
            // Only auto-assign if RecordTypeId is not already set
            if (sub.Account__c != null && sub.RecordTypeId == null) {
                accountIds.add(sub.Account__c);
            }
        }
        
        if (accountIds.isEmpty()) return;
        
        Map<Id, Account> accountsMap = new Map<Id, Account>([
            SELECT Id, Type, NumberOfEmployees 
            FROM Account 
            WHERE Id IN :accountIds
            WITH SECURITY_ENFORCED
        ]);
        
        // Get record type IDs
        Id b2bRecordTypeId = getSubscriptionRecordTypeId('B2B_Subscription');
        Id b2cRecordTypeId = getSubscriptionRecordTypeId('B2C_Subscription');
        
        for (Subscription__c sub : subscriptions) {
            // Only auto-assign if RecordTypeId is not already set
            if (sub.RecordTypeId == null && sub.Account__c != null && accountsMap.containsKey(sub.Account__c)) {
                Account acc = accountsMap.get(sub.Account__c);
                
                // DEBUG: Log account details
                System.debug('### RecordTypeUtils - Account: ' + acc.Name + ' | Type: ' + acc.Type + ' | Employees: ' + acc.NumberOfEmployees);
                Boolean isBusiness = isBusinessAccount(acc);
                System.debug('### RecordTypeUtils - isBusinessAccount result: ' + isBusiness);
                
                // Business logic: B2B if company account or >10 employees
                if (isBusiness) {
                    sub.RecordTypeId = b2bRecordTypeId;
                    System.debug('### RecordTypeUtils - Assigned B2B RecordType');
                } else {
                    sub.RecordTypeId = b2cRecordTypeId;
                    System.debug('### RecordTypeUtils - Assigned B2C RecordType');
                }
            }
        }
    }
    
    /**
     * @description Assigns appropriate record types to invoices based on amount
     * @param invoices List of invoice records to process
     */
    public static void assignInvoiceRecordTypes(List<Invoice__c> invoices) {
        
        if (invoices.isEmpty()) return;
        
        // Get record type IDs
        Id standardRecordTypeId = getInvoiceRecordTypeId('Standard_Invoice');
        Id highValueRecordTypeId = getInvoiceRecordTypeId('High_Value_Invoice');
        
        for (Invoice__c inv : invoices) {
            // Business logic: High value if Total > €5000
            if (inv.Total_Amount__c != null && inv.Total_Amount__c > 5000) {
                inv.RecordTypeId = highValueRecordTypeId;
            } else {
                inv.RecordTypeId = standardRecordTypeId;
            }
        }
    }
    
    /**
     * @description Determines if an account should use B2B record type
     * @param acc Account record to evaluate
     * @return true if should use B2B record type
     */
    private static Boolean isBusinessAccount(Account acc) {
        // B2B criteria: explicit business type OR more than 10 employees
        return (acc.Type != null && 
                (acc.Type.contains('Channel') || 
                 acc.Type.contains('Customer') || 
                 acc.Type.contains('Partner'))) ||
               (acc.NumberOfEmployees != null && acc.NumberOfEmployees > 10);
    }
    
    /**
     * @description Gets subscription record type ID with caching
     * @param developerName Record type developer name
     * @return Record type ID
     */
    private static Id getSubscriptionRecordTypeId(String developerName) {
        String cacheKey = 'Subscription__c.' + developerName;
        
        if (!recordTypeCache.containsKey(cacheKey)) {
            List<RecordType> recordTypes = [
                SELECT Id FROM RecordType 
                WHERE SObjectType = 'Subscription__c' 
                AND DeveloperName = :developerName 
                AND IsActive = true
                LIMIT 1
            ];
            
            if (!recordTypes.isEmpty()) {
                recordTypeCache.put(cacheKey, recordTypes[0].Id);
            }
        }
        
        return recordTypeCache.get(cacheKey);
    }
    
    /**
     * @description Gets invoice record type ID with caching
     * @param developerName Record type developer name
     * @return Record type ID
     */
    private static Id getInvoiceRecordTypeId(String developerName) {
        String cacheKey = 'Invoice__c.' + developerName;
        
        if (!recordTypeCache.containsKey(cacheKey)) {
            List<RecordType> recordTypes = [
                SELECT Id FROM RecordType 
                WHERE SObjectType = 'Invoice__c' 
                AND DeveloperName = :developerName 
                AND IsActive = true
                LIMIT 1
            ];
            
            if (!recordTypes.isEmpty()) {
                recordTypeCache.put(cacheKey, recordTypes[0].Id);
            }
        }
        
        return recordTypeCache.get(cacheKey);
    }
    
    /**
     * @description Gets available record types for a user
     * @param objectName SObject API name
     * @return Map of record type name to ID
     */
    public static Map<String, Id> getAvailableRecordTypes(String objectName) {
        Map<String, Id> availableTypes = new Map<String, Id>();
        
        List<RecordType> recordTypes = [
            SELECT Id, Name, DeveloperName 
            FROM RecordType 
            WHERE SObjectType = :objectName 
            AND IsActive = true
        ];
        
        for (RecordType rt : recordTypes) {
            availableTypes.put(rt.Name, rt.Id);
        }
        
        return availableTypes;
    }
}
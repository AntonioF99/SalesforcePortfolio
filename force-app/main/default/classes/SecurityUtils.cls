/**
 * @description Centralized security checks for the application
 * @author Antonio Franco
 * @date 2025-09-27
 * @purpose Consolidate security logic and provide clean APIs for permission checks
 */
public class SecurityUtils {
    
    // =============================================================================
    // PERMISSION-BASED CHECKS (using existing Permission Sets)
    // =============================================================================
    
    /**
     * @description Check if current user can cancel any subscription
     * @return true if user has Cancel_Any_Subscription permission
     */
    public static Boolean canCancelAnySubscription() {
        return FeatureManagement.checkPermission('Cancel_Any_Subscription');
    }
    
    /**
     * @description Check if current user can modify paid invoices
     * @return true if user has Modify_Paid_Invoices permission  
     */
    public static Boolean canModifyPaidInvoices() {
        return FeatureManagement.checkPermission('Modify_Paid_Invoices');
    }
    
    // =============================================================================
    // OBJECT-LEVEL SECURITY CHECKS
    // =============================================================================
    
    /**
     * @description Check if user has specific access to an object
     * @param objectName API name of the object
     * @param operation CRUD operation (CREATE, READ, UPDATE, DELETE)
     * @return true if user has access
     */
    public static Boolean hasObjectAccess(String objectName, String operation) {
        Schema.DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe()
            .get(objectName)?.getDescribe();
            
        if (objectDescribe == null) return false;
        
        switch on operation.toUpperCase() {
            when 'CREATE' { return objectDescribe.isCreateable(); }
            when 'READ'   { return objectDescribe.isAccessible(); }
            when 'UPDATE' { return objectDescribe.isUpdateable(); }
            when 'DELETE' { return objectDescribe.isDeletable(); }
            when else     { return false; }
        }
    }
    
    /**
     * @description Check if user can edit invoices based on business rules
     * @param invoice The invoice to check
     * @return true if user can edit this invoice
     */
    public static Boolean canEditInvoice(Invoice__c invoice) {
        // Business rule: Can't edit Paid or Voided invoices unless has special permission
        if (Constants.INVOICE_LOCKED_STATUSES.contains(invoice.Status__c)) {
            return canModifyPaidInvoices();
        }
        
        // For other statuses, check standard object permissions
        return hasObjectAccess(Constants.SOBJECT_INVOICE, 'UPDATE');
    }
    
    /**
     * @description Check if user can cancel a subscription based on business rules
     * @param subscription The subscription to check
     * @return true if user can cancel this subscription
     */
    public static Boolean canCancelSubscription(Subscription__c subscription) {
        // Business rule: Anyone can cancel Draft/Trial, but need permission for Active
        if (subscription.Status__c == Constants.SUBSCRIPTION_STATUS_DRAFT ||
            subscription.Status__c == Constants.SUBSCRIPTION_STATUS_TRIAL) {
            return hasObjectAccess(Constants.SOBJECT_SUBSCRIPTION, 'UPDATE');
        }

        // For Active subscriptions, need special permission
        return canCancelAnySubscription();
    }
    
    // =============================================================================
    // FIELD-LEVEL SECURITY CHECKS  
    // =============================================================================
    
    /**
     * @description Check if user can access a specific field
     * @param objectName API name of the object
     * @param fieldName API name of the field
     * @param operation Field operation (READ, EDIT)
     * @return true if user has field access
     */
    public static Boolean hasFieldAccess(String objectName, String fieldName, String operation) {
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        if (objectType == null) return false;
        
        Schema.DescribeFieldResult fieldDescribe = objectType.getDescribe()
            .fields.getMap().get(fieldName)?.getDescribe();
            
        if (fieldDescribe == null) return false;
        
        switch on operation.toUpperCase() {
            when 'READ' { return fieldDescribe.isAccessible(); }
            when 'EDIT' { return fieldDescribe.isUpdateable(); }
            when else   { return false; }
        }
    }
    
    // =============================================================================
    // UTILITY METHODS FOR COMMON PATTERNS
    // =============================================================================
    
    /**
     * @description Enforce security for sensitive operations
     * @param operationName Name of the operation for error message
     * @param hasPermission Result of permission check
     * @throws SecurityException if permission denied
     */
    public static void enforcePermission(String operationName, Boolean hasPermission) {
        if (!hasPermission) {
            throw new SecurityException('Insufficient permissions for operation: ' + operationName);
        }
    }
    
    /**
     * @description Get current user's profile name (useful for logging)
     * @return Current user's profile name
     */
    public static String getCurrentUserProfile() {
        return [SELECT Profile.Name FROM User WHERE Id = :UserInfo.getUserId() WITH SECURITY_ENFORCED].Profile.Name;
    }
    
    /**
     * @description Check if current user has any of the specified permissions
     * @param permissionNames Set of permission API names to check
     * @return true if user has at least one of the permissions
     */
    public static Boolean hasAnyPermission(Set<String> permissionNames) {
        for (String permissionName : permissionNames) {
            if (FeatureManagement.checkPermission(permissionName)) {
                return true;
            }
        }
        return false;
    }
    
    /**
     * @description Check if current user has all of the specified permissions
     * @param permissionNames Set of permission API names to check
     * @return true if user has all of the permissions
     */
    public static Boolean hasAllPermissions(Set<String> permissionNames) {
        for (String permissionName : permissionNames) {
            if (!FeatureManagement.checkPermission(permissionName)) {
                return false;
            }
        }
        return true;
    }
    
    // =============================================================================
    // BUSINESS LOGIC SECURITY HELPERS
    // =============================================================================
    
    /**
     * @description Check if user can delete a subscription based on business rules
     * @param subscription The subscription to check
     * @return true if user can delete this subscription
     */
    public static Boolean canDeleteSubscription(Subscription__c subscription) {
        // Business rule: Cannot delete active subscriptions
        if (subscription.Status__c == Constants.SUBSCRIPTION_STATUS_ACTIVE) {
            return false;
        }
        
        // For other statuses, check standard object permissions
        return hasObjectAccess(Constants.SOBJECT_SUBSCRIPTION, 'DELETE');
    }
    
    /**
     * @description Check if user can view sensitive financial data
     * @return true if user can view financial information
     */
    public static Boolean canViewFinancialData() {
        // This could be enhanced with custom permissions in the future
        return hasFieldAccess(Constants.SOBJECT_INVOICE, 'Balance_Due__c', 'READ');
    }
    
    // =============================================================================
    // CUSTOM EXCEPTION CLASS
    // =============================================================================
    
    public class SecurityException extends Exception {}
}
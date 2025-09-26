/**
 * @description Constants class for maintaining string literals across the application
 * @author Antonio Franco
 * @date 2025-09-26
 * @purpose Interview Portfolio - Demonstrates best practices for maintainable code
 */
public class Constants {
    
    // =============================================================================
    // SUBSCRIPTION STATUS VALUES
    // =============================================================================
    public static final String SUBSCRIPTION_STATUS_DRAFT = 'Draft';
    public static final String SUBSCRIPTION_STATUS_TRIAL = 'Trial';
    public static final String SUBSCRIPTION_STATUS_ACTIVE = 'Active';
    public static final String SUBSCRIPTION_STATUS_SUSPENDED = 'Suspended';
    public static final String SUBSCRIPTION_STATUS_CANCELLED = 'Cancelled';
    public static final String SUBSCRIPTION_STATUS_EXPIRED = 'Expired';
    
    // Subscription Status Sets for Validation Logic
    public static final Set<String> SUBSCRIPTION_ACTIVE_STATUSES = new Set<String>{
        SUBSCRIPTION_STATUS_TRIAL,
        SUBSCRIPTION_STATUS_ACTIVE
    };
    
    public static final Set<String> SUBSCRIPTION_TERMINAL_STATUSES = new Set<String>{
        SUBSCRIPTION_STATUS_CANCELLED,
        SUBSCRIPTION_STATUS_EXPIRED
    };
    
    // =============================================================================
    // INVOICE STATUS VALUES  
    // =============================================================================
    public static final String INVOICE_STATUS_DRAFT = 'Draft';
    public static final String INVOICE_STATUS_SENT = 'Sent';
    public static final String INVOICE_STATUS_PAID = 'Paid';
    public static final String INVOICE_STATUS_PARTIALLY_PAID = 'Partially Paid';
    public static final String INVOICE_STATUS_OVERDUE = 'Overdue';
    public static final String INVOICE_STATUS_VOIDED = 'Voided';
    
    // Invoice Status Sets for Business Logic
    public static final Set<String> INVOICE_LOCKED_STATUSES = new Set<String>{
        INVOICE_STATUS_PAID,
        INVOICE_STATUS_VOIDED
    };
    
    public static final Set<String> INVOICE_BILLABLE_STATUSES = new Set<String>{
        INVOICE_STATUS_SENT,
        INVOICE_STATUS_PARTIALLY_PAID,
        INVOICE_STATUS_OVERDUE
    };
    
    // =============================================================================
    // PRODUCT STATUS VALUES
    // =============================================================================
    public static final String PRODUCT_STATUS_DRAFT = 'Draft';
    public static final String PRODUCT_STATUS_ACTIVE = 'Active';
    public static final String PRODUCT_STATUS_DISCONTINUED = 'Discontinued';
    public static final String PRODUCT_STATUS_RETIRED = 'Retired';
    
    // =============================================================================
    // PLATFORM EVENT TYPES
    // =============================================================================
    public static final String EVENT_TYPE_CREATED = 'Created';
    public static final String EVENT_TYPE_UPDATED = 'Updated';
    public static final String EVENT_TYPE_STATUS_CHANGED = 'StatusChanged';
    public static final String EVENT_TYPE_SENT = 'Sent';
    public static final String EVENT_TYPE_PAID = 'Paid';
    public static final String EVENT_TYPE_CANCELLED = 'Cancelled';
    public static final String EVENT_TYPE_DELETED = 'Deleted';
    
    // =============================================================================
    // BILLING FREQUENCY VALUES (matches Global Value Set)
    // =============================================================================
    public static final String BILLING_FREQUENCY_MONTHLY = 'Monthly';
    public static final String BILLING_FREQUENCY_QUARTERLY = 'Quarterly';
    public static final String BILLING_FREQUENCY_SEMI_ANNUAL = 'Semi-Annual';
    public static final String BILLING_FREQUENCY_ANNUAL = 'Annual';
    public static final String BILLING_FREQUENCY_ONE_TIME = 'One-Time';
    
    // =============================================================================
    // PAYMENT TERMS VALUES
    // =============================================================================
    public static final String PAYMENT_TERMS_NET_15 = 'Net 15';
    public static final String PAYMENT_TERMS_NET_30 = 'Net 30';
    public static final String PAYMENT_TERMS_NET_45 = 'Net 45';
    public static final String PAYMENT_TERMS_DUE_ON_RECEIPT = 'Due on Receipt';
    
    // =============================================================================
    // CANCELLATION REASONS
    // =============================================================================
    public static final String CANCELLATION_REASON_PRICE_TOO_HIGH = 'Price Too High';
    public static final String CANCELLATION_REASON_MISSING_FEATURES = 'Missing Features';
    public static final String CANCELLATION_REASON_SWITCHED_COMPETITOR = 'Switched to Competitor';
    public static final String CANCELLATION_REASON_NO_LONGER_NEEDED = 'No Longer Needed';
    public static final String CANCELLATION_REASON_BUDGET_CONSTRAINTS = 'Budget Constraints';
    public static final String CANCELLATION_REASON_TECHNICAL_ISSUES = 'Technical Issues';
    public static final String CANCELLATION_REASON_CONTRACT_ENDED = 'Contract Ended';
    public static final String CANCELLATION_REASON_OTHER = 'Other';
    
    // =============================================================================
    // FIELD API NAMES (for dynamic SOQL and validation)
    // =============================================================================
    public static final String FIELD_STATUS = 'Status__c';
    public static final String FIELD_ACCOUNT = 'Account__c';
    public static final String FIELD_PRICE_PLAN = 'Price_Plan__c';
    public static final String FIELD_CANCELLATION_REASON = 'Cancellation_Reason__c';
    public static final String FIELD_CANCELLATION_DATE = 'Cancellation_Date__c';
    
    // =============================================================================
    // SOBJECT API NAMES
    // =============================================================================
    public static final String SOBJECT_SUBSCRIPTION = 'Subscription__c';
    public static final String SOBJECT_INVOICE = 'Invoice__c';
    public static final String SOBJECT_PRODUCT = 'Product__c';
    public static final String SOBJECT_PRICE_PLAN = 'Price_Plan__c';
    public static final String SOBJECT_INVOICE_LINE_ITEM = 'Invoice_Line_Item__c';
    
    // =============================================================================
    // ERROR MESSAGES (centralized for consistency)
    // =============================================================================
    public static final String ERROR_PRICE_PLAN_REQUIRED = 'Price plan is required for active subscriptions';
    public static final String ERROR_CANNOT_DELETE_ACTIVE = 'Cannot delete active subscriptions. Cancel first, then delete.';
    public static final String ERROR_INVALID_STATUS_TRANSITION = 'Invalid status transition from {0} to {1}';
    public static final String ERROR_CANNOT_MODIFY_PAID_INVOICE = 'Cannot modify paid or voided invoices';
    public static final String ERROR_CANCELLATION_REASON_REQUIRED = 'Cancellation reason is required when status is Cancelled';
    
    // =============================================================================
    // UTILITY METHODS
    // =============================================================================
    
    /**
     * @description Check if a subscription status is active (Trial or Active)
     * @param status The status to check
     * @return true if status is active
     */
    public static Boolean isSubscriptionActive(String status) {
        return SUBSCRIPTION_ACTIVE_STATUSES.contains(status);
    }
    
    /**
     * @description Check if a subscription status is terminal (cannot be changed)
     * @param status The status to check
     * @return true if status is terminal
     */
    public static Boolean isSubscriptionTerminal(String status) {
        return SUBSCRIPTION_TERMINAL_STATUSES.contains(status);
    }
    
    /**
     * @description Check if an invoice status is locked (cannot be modified)
     * @param status The status to check
     * @return true if status is locked
     */
    public static Boolean isInvoiceLocked(String status) {
        return INVOICE_LOCKED_STATUSES.contains(status);
    }
    
    /**
     * @description Check if an invoice status is billable
     * @param status The status to check  
     * @return true if status is billable
     */
    public static Boolean isInvoiceBillable(String status) {
        return INVOICE_BILLABLE_STATUSES.contains(status);
    }
    
    /**
     * @description Get all valid subscription statuses
     * @return Set of all valid subscription statuses
     */
    public static Set<String> getAllSubscriptionStatuses() {
        return new Set<String>{
            SUBSCRIPTION_STATUS_DRAFT,
            SUBSCRIPTION_STATUS_TRIAL,
            SUBSCRIPTION_STATUS_ACTIVE,
            SUBSCRIPTION_STATUS_SUSPENDED,
            SUBSCRIPTION_STATUS_CANCELLED,
            SUBSCRIPTION_STATUS_EXPIRED
        };
    }
    
    /**
     * @description Get all valid invoice statuses
     * @return Set of all valid invoice statuses
     */
    public static Set<String> getAllInvoiceStatuses() {
        return new Set<String>{
            INVOICE_STATUS_DRAFT,
            INVOICE_STATUS_SENT,
            INVOICE_STATUS_PAID,
            INVOICE_STATUS_PARTIALLY_PAID,
            INVOICE_STATUS_OVERDUE,
            INVOICE_STATUS_VOIDED
        };
    }
}
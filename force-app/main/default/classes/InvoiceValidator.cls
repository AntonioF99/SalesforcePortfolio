/**
 * @description Validation and business rule validator for Invoice records
 * @author Antonio Franco
 * @date 2025-09-09
 * @story STORY-003: Trigger Framework
 */
public class InvoiceValidator {
    
    private static final Set<String> LOCKED_STATUSES = new Set<String>{'Paid', 'Voided'};
    private static final Set<String> PROTECTED_FIELDS = new Set<String>{
        'Tax_Rate__c', 'Balance_Due__c', 'Due_Date__c', 'Invoice_Date__c', 'Status__c'
    };
    
    /*
     * @description Validates user permissions for invoice operations
     * @param invoices List of invoice records to validate
     * @param operation Type of operation (UPDATE, DELETE, etc.)
     * @param oldInvoices Map of old invoice records (for updates)
     */
    public static void validateUserPermissions(List<Invoice__c> invoices, String operation, 
                                             Map<Id, Invoice__c> oldInvoices) {
        
        // Note: User permission validation moved to SecurityUtils for demonstration
        // In production, this would be implemented based on business requirements
        
        if (operation == 'UPDATE') {
            // Future: Add permission-based validation here if needed
            // For now, SecurityUtils provides the logic for controllers/services
        }
        
        if (operation == 'DELETE') {
            validateInvoiceDeletion(invoices);
        }
    }
    
    public static void validateBusinessRules(List<Invoice__c> invoices, Boolean isUpdate) {
        
        for (Invoice__c inv : invoices) {
            
            if (inv.Account__c == null) {
                inv.addError('Account__c', 'Account is required for invoices');
            }
            
            if (inv.Invoice_Date__c != null && inv.Due_Date__c != null) {
                if (inv.Invoice_Date__c > inv.Due_Date__c) {
                    inv.addError('Due_Date__c', 'Due date cannot be before invoice date');
                }
            }
            
            if (inv.Subtotal__c != null && inv.Subtotal__c < 0) {
                inv.addError('Subtotal__c', 'Invoice subtotal cannot be negative');
            }
            
            if (inv.Tax_Amount__c != null && inv.Tax_Amount__c < 0) {
                inv.addError('Tax_Amount__c', 'Tax amount cannot be negative');
            }
            
            if (inv.Balance_Due__c != null && inv.Balance_Due__c < 0) {
                inv.addError('Balance_Due__c', 'Balance due cannot be negative');
            }
            
            validateStatusSpecificRules(inv);
        }
    }
    
    public static void setDefaults(List<Invoice__c> invoices) {
        
        for (Invoice__c inv : invoices) {
            
            if (String.isBlank(inv.Status__c)) {
                inv.Status__c = 'Draft';
            }
            
            if (inv.Invoice_Date__c == null) {
                inv.Invoice_Date__c = Date.today();
            }
            
            if (inv.Due_Date__c == null && inv.Invoice_Date__c != null) {
                inv.Due_Date__c = inv.Invoice_Date__c.addDays(30);
            }
            
            if (inv.Tax_Rate__c == null) {
                inv.Tax_Rate__c = 0;
            }
            
            if (inv.Balance_Due__c == null) {
                inv.Balance_Due__c = 0;
            }
        }
    }
    
    /*
     * @description Calculates tax amounts based on account billing address
     * @param invoices List of invoice records to process
     */
    public static void calculateTaxAmounts(List<Invoice__c> invoices) {
        
        Set<Id> accountIds = new Set<Id>();
        for (Invoice__c inv : invoices) {
            if (inv.Account__c != null) {
                accountIds.add(inv.Account__c);
            }
        }
        
        if (accountIds.isEmpty()) {
            return;
        }
        
        Map<Id, Account> accountsMap = new Map<Id, Account>([
            SELECT Id, BillingState, BillingCountry 
            FROM Account 
            WHERE Id IN :accountIds
        ]);
        
        for (Invoice__c inv : invoices) {
            if (inv.Account__c != null && accountsMap.containsKey(inv.Account__c)) {
                Account acc = accountsMap.get(inv.Account__c);
                
                Decimal taxRate = getTaxRate(acc.BillingState, acc.BillingCountry);
                
                if (taxRate > 0) {
                    inv.Tax_Rate__c = taxRate;
                }
            }
        }
    }
    
    public static void generateInvoiceNumbers(List<Invoice__c> invoices) {
        System.debug('Auto-numbering handled by Name field for ' + invoices.size() + ' invoices');
    }
    
    /*
     * @description Identifies invoices that need line item recalculation
     * @param invoices List of invoice records to check
     * @return Set of invoice IDs needing recalculation
     */
    public static Set<Id> getInvoicesNeedingRecalculation(List<Invoice__c> invoices) {
        
        Set<Id> invoiceIds = new Set<Id>();
        
        for (Invoice__c inv : invoices) {
            if (inv.Status__c == 'Sent' || inv.Status__c == 'Paid') {
                invoiceIds.add(inv.Id);
            }
        }
        
        return invoiceIds;
    }
    
    private static void validatePaidInvoiceModifications(List<Invoice__c> invoices, 
                                                       Map<Id, Invoice__c> oldInvoices) {
        
        for (Invoice__c inv : invoices) {
            Invoice__c oldInv = oldInvoices.get(inv.Id);
            
            if (LOCKED_STATUSES.contains(oldInv.Status__c)) {
                
                if (hasProtectedFieldChanges(inv, oldInv)) {
                    inv.addError('You do not have permission to modify paid/cancelled invoices. ' +
                               'Contact your administrator for the "Modify Paid Invoices" permission.');
                }
            }
        }
    }
    
    private static void validateInvoiceDeletion(List<Invoice__c> invoices) {
        
        for (Invoice__c inv : invoices) {
            if (LOCKED_STATUSES.contains(inv.Status__c)) {
                inv.addError('Cannot delete invoices with status: ' + inv.Status__c);
            }
        }
    }
    
    private static void validateStatusSpecificRules(Invoice__c inv) {
        
        switch on inv.Status__c {
            when 'Sent' {
                if (inv.Subtotal__c == null || inv.Subtotal__c <= 0) {
                    inv.addError('Status__c', 'Cannot send invoice with zero or negative subtotal');
                }
                if (inv.Due_Date__c == null) {
                    inv.addError('Due_Date__c', 'Due date is required for sent invoices');
                }
            }
            when 'Paid' {
                if (inv.Balance_Due__c != null && inv.Balance_Due__c > 0) {
                    inv.addError('Status__c', 'Cannot mark as paid while balance due is positive');
                }
            }
            when 'Overdue' {
                if (inv.Due_Date__c == null || inv.Due_Date__c >= Date.today()) {
                    inv.addError('Status__c', 'Cannot mark as overdue if due date is not past');
                }
            }
        }
    }
    
    /*
    * @description Checks if any protected fields have been modified between old and new invoice versions
    * @param newInv Updated invoice record
    * @param oldInv Original invoice record before update
    * @return true if any protected field has changed, false otherwise
    */
    private static Boolean hasProtectedFieldChanges(Invoice__c newInv, Invoice__c oldInv){

        return (newInv.Tax_Rate__c != oldInv.Tax_Rate__c ||
                newInv.Balance_Due__c != oldInv.Balance_Due__c ||
                newInv.Due_Date__c != oldInv.Due_Date__c ||
                newInv.Invoice_Date__c != oldInv.Invoice_Date__c ||
                newInv.Status__c != oldInv.Status__c);
    }
    
    private static Decimal getTaxRate(String state, String country) {
        switch on country {
            when 'Italy' { return 22.0; }
            when 'Germany' { return 19.0; }
            when 'France' { return 20.0; }
            when 'Spain' { return 21.0; }
            when 'United Kingdom' { return 20.0; }
            when 'Netherlands' { return 21.0; }
            when else { return 0.0; }
        }
    }
}
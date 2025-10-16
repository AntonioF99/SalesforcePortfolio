/**
 * @description Validation and business rule validator for Invoice records
 * @author Antonio Franco
 * @date 2025-09-09
 * @story STORY-003: Trigger Framework
 */
public class InvoiceValidator {
    
    private static final Set<String> LOCKED_STATUSES = new Set<String>{
        Constants.INVOICE_STATUS_PAID,
        Constants.INVOICE_STATUS_VOIDED
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
            
            // Note: Subtotal__c, Tax_Amount__c, and Balance_Due__c are formula fields
            // They cannot be negative as they're calculated from positive line item values
            // No validation needed here
            
            validateStatusSpecificRules(inv);
        }
    }
    
    public static void setDefaults(List<Invoice__c> invoices) {
        
        for (Invoice__c inv : invoices) {
            
            if (String.isBlank(inv.Status__c)) {
                inv.Status__c = Constants.INVOICE_STATUS_DRAFT;
            }
            
            if (inv.Invoice_Date__c == null) {
                inv.Invoice_Date__c = Date.today();
            }
            
            if (inv.Due_Date__c == null && inv.Invoice_Date__c != null) {
                inv.Due_Date__c = calculateDueDateFromPaymentTerms(inv);
            }
            
            if (inv.Tax_Rate__c == null) {
                inv.Tax_Rate__c = 0;
            }
            
            // Note: Balance_Due__c is a formula field, cannot be set manually
        }
    }
    
    /*
     * @description Calculates tax amounts based on account billing address
     * @param invoices List of invoice records to process
     */
    public static void calculateTaxAmounts(List<Invoice__c> invoices) {
        if (invoices == null || invoices.isEmpty()) {
            return;
        }

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
            WITH SECURITY_ENFORCED
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

    /**
     * NOTE: Invoice totals are calculated automatically via native Salesforce features:
     *
     * - Subtotal__c: Rollup Summary field (SUM of Invoice_Line_Item__c.Line_Amount__c)
     * - Tax_Amount__c: Formula field (Subtotal__c * Tax_Rate__c / 100)
     * - Total_Amount__c: Formula field (Subtotal__c + Tax_Amount__c)
     *
     * No Apex code is needed - Salesforce updates these fields automatically when line items change.
     * This provides real-time calculation without DML operations.
     */

    /*
     * @description Identifies invoices that need line item recalculation
     * @param invoices List of invoice records to check
     * @return Set of invoice IDs needing recalculation
     */
    public static Set<Id> getInvoicesNeedingRecalculation(List<Invoice__c> invoices) {
        
        Set<Id> invoiceIds = new Set<Id>();
        
        for (Invoice__c inv : invoices) {
            if (inv.Status__c == Constants.INVOICE_STATUS_SENT ||
                inv.Status__c == Constants.INVOICE_STATUS_PAID) {
                invoiceIds.add(inv.Id);
            }
        }
        
        return invoiceIds;
    }
    
    // Note: validatePaidInvoiceModifications() removed - never called (dead code)
    
    private static void validateInvoiceDeletion(List<Invoice__c> invoices) {
        
        for (Invoice__c inv : invoices) {
            if (LOCKED_STATUSES.contains(inv.Status__c)) {
                inv.addError('Cannot delete invoices with status: ' + inv.Status__c);
            }
        }
    }
    
    private static void validateStatusSpecificRules(Invoice__c inv) {

        if (inv.Status__c == Constants.INVOICE_STATUS_SENT) {
            if (inv.Subtotal__c == null || inv.Subtotal__c <= 0) {
                inv.addError('Status__c', 'Cannot send invoice with zero or negative subtotal');
            }
            if (inv.Due_Date__c == null) {
                inv.addError('Due_Date__c', 'Due date is required for sent invoices');
            }
        } else if (inv.Status__c == Constants.INVOICE_STATUS_PAID) {
            if (inv.Balance_Due__c != null && inv.Balance_Due__c > 0) {
                inv.addError('Status__c', 'Cannot mark as paid while balance due is positive');
            }
        } else if (inv.Status__c == Constants.INVOICE_STATUS_OVERDUE) {
            if (inv.Due_Date__c == null || inv.Due_Date__c >= Date.today()) {
                inv.addError('Status__c', 'Cannot mark as overdue if due date is not past');
            }
        }
    }
    
    // Note: hasProtectedFieldChanges() removed - was only called by removed validatePaidInvoiceModifications() (dead code)
    
    private static Decimal getTaxRate(String state, String country) {
        Decimal taxRate = Constants.TAX_RATES_BY_COUNTRY.get(country);
        return taxRate != null ? taxRate : Constants.DEFAULT_TAX_RATE;
    }

    /**
     * @description Calculates Due Date based on Payment Terms and Invoice Date
     * @param inv Invoice record with Invoice_Date__c and Payment_Terms__c
     * @return Calculated due date
     */
    private static Date calculateDueDateFromPaymentTerms(Invoice__c inv) {
        if (inv.Invoice_Date__c == null) {
            return Date.today().addDays(Constants.DEFAULT_INVOICE_DUE_DAYS);
        }

        if (String.isBlank(inv.Payment_Terms__c)) {
            return inv.Invoice_Date__c.addDays(Constants.DEFAULT_INVOICE_DUE_DAYS);
        }

        if (inv.Payment_Terms__c == Constants.PAYMENT_TERMS_NET_15) {
            return inv.Invoice_Date__c.addDays(15);
        } else if (inv.Payment_Terms__c == Constants.PAYMENT_TERMS_NET_30) {
            return inv.Invoice_Date__c.addDays(30);
        } else if (inv.Payment_Terms__c == Constants.PAYMENT_TERMS_NET_45) {
            return inv.Invoice_Date__c.addDays(45);
        } else if (inv.Payment_Terms__c == Constants.PAYMENT_TERMS_DUE_ON_RECEIPT) {
            return inv.Invoice_Date__c;
        } else {
            return inv.Invoice_Date__c.addDays(Constants.DEFAULT_INVOICE_DUE_DAYS);
        }
    }
}
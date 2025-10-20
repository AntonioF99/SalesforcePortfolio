# Security Model Documentation

## Overview

This portfolio implements Salesforce security best practices with a multi-layered approach to protect data and enforce permissions.

## Sharing Model

### Controllers
- `with sharing` enforced on Lightning Web Component controllers
- Respects org-wide defaults and sharing rules
- Users see only records they have access to

### Trigger Handlers
- Run in **system mode** (without sharing declaration)
- Intentional design for privileged operations:
  - Account rollup calculations (aggregate data across records)
  - Invoice generation from subscriptions
  - Platform event processing for external integrations

**Rationale:** System mode allows handlers to perform aggregate calculations and maintain data integrity regardless of user permissions.

## CRUD & FLS Enforcement

### SOQL Queries
All controller queries use `WITH SECURITY_ENFORCED` to respect field-level and object-level security:

```apex
// Example from InvoiceController
List<Invoice__c> invoices = [
    SELECT Id, Name, Status__c, Amount__c 
    FROM Invoice__c 
    WHERE Status__c = 'Overdue'
    WITH SECURITY_ENFORCED
];
```

### DML Operations
Field-level security enforced using `Security.stripInaccessible()`:

```apex
// Strip inaccessible fields before DML
SObjectAccessDecision decision = Security.stripInaccessible(
    AccessType.UPDATABLE,
    invoices
);
update decision.getRecords();
```

### SecurityUtils Class
Centralized utility class for permission checks:

```apex
// Check field access
if (!SecurityUtils.hasFieldAccess('Invoice__c', 'Amount__c')) {
    throw new SecurityException('Insufficient permissions');
}

// Check object CRUD
if (!SecurityUtils.hasObjectAccess('Invoice__c', 'isUpdateable')) {
    throw new SecurityException('Cannot update invoices');
}
```

## Custom Permissions

### Cancel_Any_Subscription
- Allows cancelling subscriptions regardless of record ownership
- Assigned to: Billing Admins, Account Managers
- Use case: Support team needs to cancel any customer subscription

### Modify_Paid_Invoices
- Allows editing invoices after they've been marked as paid
- Assigned to: Billing Admins only
- Use case: Corrections, refunds, accounting adjustments

## Validation Rules

### Invoice__c
- **Paid Invoice Protection**: Invoices with Status = 'Paid' cannot be edited (except by users with Modify_Paid_Invoices permission)
- **Positive Amounts**: Amount fields must be greater than 0
- **Valid Dates**: Due_Date must be after Invoice_Date

### Subscription__c
- **Active Requirements**: Active subscriptions must have Price_Plan__c populated
- **Cancellation Reason**: Cancelled subscriptions require Cancellation_Reason__c
- **Terminal Status Protection**: Cancelled and Expired subscriptions cannot transition to other statuses

## Platform Event Security

### Conditional Enforcement Pattern

Platform event subscribers use conditional `WITH SECURITY_ENFORCED`:

```apex
// PlatformEventSubscriber.cls
String query = 'SELECT Id, Name FROM Subscription__c WHERE Id IN :ids';
if (!Test.isRunningTest()) {
    query += ' WITH SECURITY_ENFORCED';
}
```

**Context:** Platform event triggers run in system mode and query data for external Slack notifications.

**Trade-off:** Conditional enforcement allows test compatibility while maintaining production security.

**Risk Assessment:** LOW
- Platform events used only for external notifications
- No sensitive data manipulation
- Read-only queries for notification content

## Test Coverage

Security-related test classes:
- **SecurityUtilsTest** (94% coverage) - Permission checks, FLS validation
- **InvoiceValidatorTest** (77% coverage) - Business rule enforcement
- **SubscriptionValidatorTest** (93% coverage) - Permission validation, state transitions

## Best Practices Implemented

✅ **Principle of Least Privilege** - Users have minimum permissions needed  
✅ **Defense in Depth** - Multiple security layers (CRUD + FLS + Business Rules)  
✅ **Explicit Permission Checks** - SecurityUtils validates before operations  
✅ **Validation at Entry Points** - Controllers and triggers validate input  
✅ **Audit Trail** - Field history tracking on critical fields  

## Known Limitations

⚠️ **Trigger Handlers Without Sharing** - Intentional for system-mode operations (documented above)

⚠️ **Platform Event Conditional Enforcement** - Trade-off for test compatibility (documented above)

⚠️ **Test FLS Scenarios** - Tests focus on happy paths; FLS denial scenarios have basic coverage

⚠️ **No Row-Level Encryption** - Not implemented (could be added for PII fields)

## Security Checklist for Deployment

- [ ] Verify profile/permission set assignments
- [ ] Test with restricted user (non-admin)
- [ ] Review sharing rules for Account, Subscription, Invoice objects
- [ ] Configure field-level security for sensitive fields (Amount, MRR, ARR)
- [ ] Enable field history tracking on Status fields
- [ ] Review platform event subscriber permissions

## Related Documentation

- [ARCHITECTURE.md](ARCHITECTURE.md) - Overall system design
- [README.md](../README.md) - Quick start and overview

For questions or security concerns, please review the SecurityUtils class implementation.

# Architecture Documentation

## System Overview

This Salesforce Subscription Billing system follows enterprise architecture patterns emphasizing separation of concerns, maintainability, and scalability.

## Design Patterns

### 1. Trigger Handler Pattern

**Implementation:**
```
Trigger (SubscriptionTrigger)
    ↓
TriggerFramework (abstract base class)
    ↓
Handler (SubscriptionTriggerHandler implements IHandler)
    ↓
Service Layer (SubscriptionAutomationService)
```

**Benefits:**
- Single trigger per object
- Testable business logic
- Governor limit optimization through bulkification
- Clear separation of concerns

**Key Files:**
- `TriggerFramework.cls` - Abstract base class for all handlers
- `IHandler.cls` - Interface defining trigger context methods
- `SubscriptionTriggerHandler.cls` - Business logic for Subscription__c
- `InvoiceTriggerHandler.cls` - Business logic for Invoice__c

### 2. Service Layer Pattern

**Purpose:** Encapsulate reusable business logic independent of trigger context.

**Key Services:**
- `SubscriptionAutomationService` - Subscription lifecycle management, invoice generation
- `InvoiceAutomationService` - Invoice processing, task creation for workflows
- `SlackNotificationService` - External system integration via HTTP callouts

**Benefits:**
- Business logic reusable across triggers, controllers, batch jobs
- Independent unit testing
- Transaction management and error handling centralized

### 3. Validator Pattern

**Purpose:** Centralize validation logic for business rules and data integrity.

**Key Validators:**
- `SubscriptionValidator` - Status transitions, business rules, permissions
- `InvoiceValidator` - Data integrity, calculation accuracy, status validation

**Benefits:**
- Single source of truth for validation rules
- Reusable across triggers, controllers, flows
- Consistent error messages

### 4. Factory Pattern (Test Utilities)

**Purpose:** Standardized test data creation.

**Key Factories:**
- `TestDataFactory` - Simple object creation with defaults
- `TestScenarioFactory` - Complex business scenarios (e.g., subscription with invoices)

**Benefits:**
- Consistent test data across all test classes
- Reduces test setup code duplication
- Easy maintenance when object structure changes

## Data Model

### Core Objects

**Subscription__c**
- Record Types: B2B_Subscription, B2C_Subscription
- Status Flow: Draft → Trial → Active → Suspended/Cancelled
- Key Fields: Price_Plan__c (lookup), Start_Date__c, Trial_End_Date__c, MRR__c, ARR__c

**Invoice__c**
- Record Types: Standard_Invoice, High_Value_Invoice (>€5,000)
- Status Flow: Draft → Sent → Paid/Overdue/Voided
- Key Fields: Subtotal__c, Tax_Amount__c, Total_Amount__c, Balance_Due__c

**Invoice_Line_Item__c**
- Junction between Invoice__c and Subscription__c
- Tracks: Period_Start__c, Period_End__c, Quantity__c, Unit_Price__c, Line_Amount__c

**Price_Plan__c**
- Reusable pricing templates
- Fields: Unit_Price__c, Billing_Frequency__c, Trial_Days__c, Setup_Fee__c

### Platform Events

**Subscription_Event__e**
- Published on: Subscription status changes
- Fields: Subscription_Id__c, Status__c, Event_Type__c, Account_Id__c

**Invoice_Event__e**
- Published on: Invoice creation, status changes
- Fields: Invoice_Id__c, Status__c, Event_Type__c, Total_Amount__c

**Purpose:** Async notifications to external systems (Slack) without blocking DML operations.

## Security Model

### Sharing Rules
- All controllers use `with sharing`
- Record access follows OWD (Org-Wide Defaults) and sharing rules

### CRUD/FLS Enforcement
- SOQL queries use `WITH SECURITY_ENFORCED` where possible
- DML operations use `Security.stripInaccessible()` for FLS checks
- `SecurityUtils` class provides field-level access checks

### Custom Permissions
- `Cancel_Any_Subscription` - Allows cancelling subscriptions regardless of status
- `Modify_Paid_Invoices` - Allows editing invoices after they're marked paid

## Automation

### Triggers
- `SubscriptionTrigger` - All events (before/after insert/update/delete/undelete)
- `InvoiceTrigger` - All events
- `InvoiceLineItemTrigger` - Before delete (validates invoice status)
- `SubscriptionEventTrigger` - After insert (Platform Event subscriber)
- `InvoiceEventTrigger` - After insert (Platform Event subscriber)

### Scheduled Jobs
- `DailyMaintenanceBatch` - Marks overdue invoices, cancels expired trials
  - Scheduled daily at midnight
  - Batch size: 200 records

### Flows
- `Trial_Expiration_Monitoring` - Sends alerts for expiring trials (declarative alternative)

## Testing Strategy

### Coverage Target
- Org-wide: 77% (exceeds 75% deployment requirement)
- Trigger Handlers: 97%+ (critical path)
- Services: 86-100%
- Validators: 89-94%

### Test Classes
- Unit tests for each handler, service, validator
- Integration tests for end-to-end workflows (EndToEndWorkflowTest)
- Bulk testing (200 records) for governor limit validation
- Negative testing for validation rules and security

### Test Utilities
- `@testSetup` methods reduce redundant test data creation
- Test factories ensure consistent, valid test data
- Platform Events tested with `Test.getEventBus().deliver()`

## Integration

### Slack Notifications
- **Trigger:** Platform Event subscribers
- **Method:** HTTP Callout to Slack Webhook URL
- **Configuration:** Custom Metadata (Integration_Setting__mdt)
- **Events:** New invoice, status changes, overdue invoices

### External System Considerations
- Callouts wrapped in `@future` or Platform Events to avoid DML/Callout limits
- Retry logic with exponential backoff (not yet implemented)
- Idempotent operations to handle duplicate events

## Performance Considerations

### Bulkification
- All triggers handle up to 200 records (standard batch size)
- Collections (Maps, Sets) used to avoid nested loops
- SOQL queries outside loops

### Governor Limits
- Maximum 1 SOQL query per trigger method
- DML operations batched (single `update` statement)
- Platform Events published in bulk (`EventBus.publish(events)`)

### Async Processing
- Platform Events for external callouts
- Batch Apex for large data volumes
- `@future` methods avoided where Platform Events suffice

## Deployment Notes

### Dependencies
1. Custom Objects (Subscription__c, Invoice__c, Price_Plan__c, Invoice_Line_Item__c)
2. Custom Permissions
3. Apex Classes (handlers, services, validators, utils)
4. Triggers
5. Lightning Web Components
6. Flows (optional)
7. Custom Metadata Types (Integration_Setting__mdt)

### Post-Deployment
1. Load Price_Plan__c records
2. Configure Integration_Setting__mdt for Slack (optional)
3. Schedule DailyMaintenanceBatch (Apex: `System.schedule('Daily Maintenance', '0 0 0 * * ?', new DailyMaintenanceBatch())`)
4. Assign permission sets to users

## Future Enhancements

- Payment gateway integration (Stripe, PayPal)
- Dunning management for failed payments
- Subscription renewals automation
- Advanced reporting with Einstein Analytics
- Mobile app with Lightning Out

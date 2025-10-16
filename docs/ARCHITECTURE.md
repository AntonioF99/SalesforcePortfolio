# Architecture Overview

## 🏗️ System Architecture

This Salesforce Subscription Billing system follows enterprise-level architecture patterns emphasizing separation of concerns, maintainability, and scalability.

## 📊 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     USER INTERFACES                          │
│  Lightning Experience │ Lightning Web Components │ Mobile    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    CONTROLLERS LAYER                         │
│         SubscriptionController │ InvoiceController           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    VALIDATION LAYER                          │
│      SubscriptionValidator │ InvoiceValidator                │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     SERVICE LAYER                            │
│  SubscriptionAutomationService │ InvoiceAutomationService    │
│         SlackNotificationService (Integration)               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    TRIGGER LAYER                             │
│  Trigger Framework (IHandler, TriggerFramework)              │
│  SubscriptionTriggerHandler │ InvoiceTriggerHandler          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                     DATA LAYER                               │
│  Custom Objects │ Standard Objects │ Platform Events         │
│  Subscription__c │ Invoice__c │ InvoiceLineItem__c          │
└─────────────────────────────────────────────────────────────┘
```

## 🎯 Design Patterns

### 1. Trigger Handler Pattern

**Purpose**: Separate trigger logic from business logic

**Implementation**:

```
Trigger (SubscriptionTrigger)
    ↓
TriggerFramework (abstract base class)
    ↓
SubscriptionTriggerHandler (implements IHandler)
    ↓
Service Layer (SubscriptionAutomationService)
```

**Benefits**:

- Single Trigger per Object
- Testable business logic
- Governor limit optimization
- Clear separation of concerns

### 2. Service Layer Pattern

**Purpose**: Encapsulate business logic for reuse

**Key Services**:

- `SubscriptionAutomationService`: Subscription lifecycle management
- `InvoiceAutomationService`: Invoice generation and processing
- `SlackNotificationService`: External system integration

**Benefits**:

- Reusable business logic
- Independent testing
- Loose coupling
- Transaction management

### 3. Validator Pattern

**Purpose**: Centralize validation logic

**Key Validators**:

- `SubscriptionValidator`: Business rule validation
- `InvoiceValidator`: Data integrity checks

**Benefits**:

- Consistent validation
- Reusable across contexts
- Centralized error messages
- Easy to maintain

### 4. Factory Pattern

**Purpose**: Standardize object creation in tests

**Implementation**:

- `TestDataFactory`: Basic test data creation
- `TestScenarioFactory`: Complex scenario setup

**Benefits**:

- Consistent test data
- Reduced test code duplication
- Easy scenario creation
- Maintainable tests

## 🔄 Data Flow

### Subscription Creation Flow

```
1. User creates Subscription (UI)
        ↓
2. SubscriptionController validates input
        ↓
3. SubscriptionValidator checks business rules
        ↓
4. Record inserted
        ↓
5. SubscriptionTrigger fires
        ↓
6. SubscriptionTriggerHandler processes
        ↓
7. SubscriptionAutomationService executes business logic
        ↓
8. Platform Event published
        ↓
9. Platform Event Subscriber processes
        ↓
10. SlackNotificationService sends notification
```

### Invoice Generation Flow

```
1. DailyMaintenanceBatch runs (scheduled)
        ↓
2. Identifies active subscriptions needing invoices
        ↓
3. InvoiceAutomationService.generateInvoices()
        ↓
4. Creates Invoice__c records
        ↓
5. Creates InvoiceLineItem__c records
        ↓
6. InvoiceTrigger fires
        ↓
7. InvoiceTriggerHandler processes
        ↓
8. Platform Event published
        ↓
9. Email notification sent
```

## 🧩 Component Architecture

### Lightning Web Components

```
┌──────────────────────────────────────────────────┐
│         Lightning Web Components                  │
├──────────────────────────────────────────────────┤
│                                                   │
│  invoiceManager                                   │
│  ├── View/Edit Invoice                           │
│  ├── Lightning Record Form                       │
│  └── Custom Actions                              │
│                                                   │
│  subscriptionManager                              │
│  ├── View/Edit Subscription                      │
│  ├── Lightning Record Form                       │
│  └── Custom Actions                              │
│                                                   │
│  invoiceOverdueDashboard                          │
│  ├── Display Overdue Invoices                    │
│  ├── Send Reminders                              │
│  └── Navigate to Records                         │
│                                                   │
│  subscriptionExpiringWidget                       │
│  ├── Display Expiring Trials                     │
│  ├── Convert to Active                           │
│  └── Navigate to Records                         │
│                                                   │
│  invoiceAnalyticsDashboard                        │
│  ├── Display Metrics                             │
│  ├── Charts                                      │
│  └── Filters                                     │
│                                                   │
└──────────────────────────────────────────────────┘
```

### Apex Class Structure

```
Classes/
├── Controllers/
│   ├── SubscriptionController.cls
│   └── InvoiceController.cls
│
├── Services/
│   ├── SubscriptionAutomationService.cls
│   ├── InvoiceAutomationService.cls
│   └── SlackNotificationService.cls
│
├── Validators/
│   ├── SubscriptionValidator.cls
│   └── InvoiceValidator.cls
│
├── Trigger Handlers/
│   ├── TriggerFramework.cls (abstract)
│   ├── IHandler.cls (interface)
│   ├── SubscriptionTriggerHandler.cls
│   ├── InvoiceTriggerHandler.cls
│   └── InvoiceLineItemTriggerHandler.cls
│
├── Platform Events/
│   ├── PlatformEventPublisher.cls
│   └── PlatformEventSubscriber.cls
│
├── Utilities/
│   ├── Constants.cls
│   ├── SecurityUtils.cls
│   └── RecordTypeUtils.cls
│
├── Batch/
│   └── DailyMaintenanceBatch.cls
│
└── Test Classes/
    ├── TestDataFactory.cls
    ├── TestScenarioFactory.cls
    └── *Test.cls (15+ test classes)
```

## 🔐 Security Architecture

### Field-Level Security (FLS)

```
User Request
    ↓
SecurityUtils.checkFieldAccess()
    ↓
    ├── Read: SecurityUtils.isAccessible()
    ├── Create: SecurityUtils.isCreateable()
    └── Update: SecurityUtils.isUpdateable()
    ↓
Operation Allowed / Denied
```

### Object-Level Security (CRUD)

- Enforced through `WITH SECURITY_ENFORCED` in SOQL
- Checked explicitly with `SecurityUtils` methods
- Custom permissions for sensitive operations

### Sharing Rules

- Account-based sharing for Customer Success Team
- Finance Team access to all invoices
- Record Type-based data segregation

## 🔄 Event-Driven Architecture

### Platform Events

```
Business Event Occurs
    ↓
PlatformEventPublisher.publish()
    ↓
Platform Event Trigger
    ↓
PlatformEventSubscriber.handle()
    ↓
Process Event (async)
    ├── SlackNotificationService
    ├── Email Notifications
    └── External System Integration
```

**Benefits**:

- Asynchronous processing
- Decoupled components
- Scalability
- Error handling

## 📦 Deployment Architecture

### CI/CD Pipeline

```
Developer Push
    ↓
GitHub Actions Triggered
    ↓
Validate Workflow
    ├── Syntax Check
    ├── Run Tests
    └── Code Coverage Check
    ↓
Deploy Workflow (on merge)
    ├── Deploy to Org
    └── Run Tests
    ↓
Success / Failure Notification
```

## 🎯 Design Principles

### SOLID Principles

1. **Single Responsibility**: Each class has one reason to change
2. **Open/Closed**: Open for extension, closed for modification
3. **Liskov Substitution**: Trigger handlers implement IHandler
4. **Interface Segregation**: IHandler provides minimal interface
5. **Dependency Inversion**: Depend on abstractions (IHandler)

### Salesforce Best Practices

1. **Bulkification**: All operations handle 200+ records
2. **Governor Limits**: Conscious design to avoid limits
3. **Security**: FLS, CRUD, and sharing rule enforcement
4. **Testing**: 75%+ code coverage (target: 90%+)
5. **Separation of Concerns**: Clear layer boundaries

## 🔧 Utility Components

### Constants Class

Centralized location for:

- Status values
- Record Type developer names
- Error messages
- Configuration values

### RecordTypeUtils

Helper methods for:

- Record Type ID retrieval
- Record Type checking
- Default Record Type determination

### SecurityUtils

Security enforcement for:

- Field-Level Security (FLS)
- CRUD permissions
- Sharing rule compliance

## 📈 Scalability Considerations

1. **Batch Processing**: DailyMaintenanceBatch for large data volumes
2. **Asynchronous Processing**: Platform Events for non-critical operations
3. **Query Optimization**: Selective queries with appropriate filters
4. **Bulkification**: All triggers and services handle bulk operations
5. **Caching**: Strategic use of static variables for query results

## 🧪 Testing Architecture

### Test Pyramid

```
              /\
             /  \
            / E2E \      EndToEndWorkflowTest
           /______\
          /        \
         /  Integr. \    Handler Tests, Service Tests
        /____________\
       /              \
      /   Unit Tests   \  Validator Tests, Utility Tests
     /__________________\
```

### Test Data Strategy

1. **TestDataFactory**: Basic object creation
2. **TestScenarioFactory**: Complex business scenarios
3. **@TestSetup**: One-time test data setup
4. **Test Isolation**: Each test independent

## 📚 Related Documentation

- [Security Documentation](SECURITY.md)
- [Workflow Analysis](WORKFLOW_ANALYSIS.md)
- [Manual Testing Guide](MANUAL_TESTING_GUIDE.md)
- [Analysis Report](../ANALYSIS_REPORT.md)

## 🔄 Future Enhancements

Potential architecture improvements:

1. **Queueable Apex**: For complex async operations
2. **Custom Metadata Types**: For configuration management
3. **Lightning Message Service**: For component communication
4. **Einstein Analytics**: For advanced reporting
5. **Apex REST Services**: For external API integration
6. **Change Data Capture**: For real-time data synchronization

---

_This architecture demonstrates enterprise-level Salesforce development patterns suitable for large-scale, production-grade applications._

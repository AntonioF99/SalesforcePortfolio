# Salesforce Subscription Billing Portfolio

Enterprise-grade Salesforce development portfolio demonstrating advanced Apex patterns, Lightning Web Components, and event-driven architecture.

## What This Demonstrates

**Core Competencies:**
- Trigger Framework pattern with clean separation of concerns
- Service Layer for reusable business logic
- Platform Events for event-driven architecture
- 77% test coverage with comprehensive test factories
- Lightning Web Components with Apex integration
- Security best practices (FLS, CRUD, Sharing)
- Scheduled batch jobs for maintenance automation

**Tech Stack:** Apex • LWC • Platform Events • Batch Apex • SOQL • DML • Custom Metadata

## Architecture Highlights

### Trigger Framework
```
Trigger → TriggerFramework → Handler (IHandler) → Service Layer
```
- Single trigger per object
- Bulkified operations
- Testable business logic separated from triggers

### Key Components
- **SubscriptionTriggerHandler**: Lifecycle management, invoice generation, account rollups
- **InvoiceTriggerHandler**: Status tracking, account statistics, platform events
- **SubscriptionAutomationService**: Invoice creation from active subscriptions
- **InvoiceAutomationService**: Task creation for invoice workflows
- **Platform Events**: Async notifications for invoice/subscription changes

### Data Model
- `Subscription__c` (B2B/B2C record types) → `Invoice__c` → `Invoice_Line_Item__c`
- `Price_Plan__c` (reusable pricing templates)
- Status workflows: Draft → Trial → Active → Cancelled/Suspended

## Quick Start

```bash
# Clone and setup
git clone https://github.com/AntonioF99/SalesforcePortfolio.git
cd SalesforcePortfolio

# Create scratch org and deploy
sf org create scratch -f config/project-scratch-def.json -a portfolio-scratch
sf project deploy start

# Run tests
sf apex run test --test-level RunLocalTests --code-coverage --result-format human
```

## Test Coverage

**Org-wide:** 77% (112 passing tests)

Key classes:
- Trigger Handlers: 97%+
- Validators: 89-94%
- Services: 86-100%
- Controllers: 86%+

## Security

- `with sharing` enforced on all controllers
- `WITH SECURITY_ENFORCED` in SOQL queries
- `Security.stripInaccessible()` for DML operations
- Field-level security (FLS) validation via `SecurityUtils`
- Custom permissions for privileged operations

## Project Structure

```
force-app/main/default/
├── classes/           # 20 Apex classes (handlers, services, validators, utils)
├── triggers/          # 5 triggers (Subscription, Invoice, InvoiceLineItem, Platform Events)
├── lwc/               # 5 Lightning Web Components
├── objects/           # Custom objects and fields
├── flows/             # Declarative automation (trial expiration)
└── applications/      # Custom app (Subscription Billing)
```

## About

This portfolio showcases professional Salesforce development practices suitable for enterprise environments. Built with focus on maintainability, testability, and scalability.

For detailed architecture documentation, see [ARCHITECTURE.md](docs/ARCHITECTURE.md).

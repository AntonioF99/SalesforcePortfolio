# Salesforce Subscription Billing Portfolio

Enterprise-grade Salesforce development portfolio demonstrating advanced Apex patterns, Lightning Web Components, and event-driven architecture.

## What This Demonstrates

**Core Competencies:**
- Trigger Framework pattern with clean separation of concerns
- Service Layer for reusable business logic
- Platform Events for event-driven architecture
- 85% test coverage with 131 passing tests
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

**Org-wide:** 85% | **Test Run:** 92% | **Tests Passing:** 131/131

Key classes:
- Trigger Handlers: 98-99%
- Platform Events: 96-97%
- Services: 85-99%
- Validators: 77-93%
- Security Utils: 94%

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

## Documentation

- **[Architecture Guide](docs/ARCHITECTURE.md)** - Design patterns, data model, testing strategy
- **[Security Model](docs/SECURITY.md)** - Sharing rules, CRUD/FLS, permissions, best practices
- **[Scripts Reference](scripts/README.md)** - Apex and SOQL script catalog

## About

This portfolio showcases professional Salesforce development practices suitable for enterprise environments. Built with focus on maintainability, testability, and scalability.

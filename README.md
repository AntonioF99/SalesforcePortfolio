# Salesforce Portfolio

Enterprise-level Salesforce development portfolio showcasing advanced Apex patterns, Lightning Web Components, and modern integration architectures.

## 🎯 Overview

This repository demonstrates professional Salesforce development expertise through a comprehensive **Subscription Billing Management System**. The project showcases:

- ✅ Enterprise-grade Apex architecture (Trigger Framework, Service Layer, Validator Pattern)
- ✅ Comprehensive test coverage (71%+) with test factories and scenario builders
- ✅ Platform Events for event-driven architecture
- ✅ Custom metadata-driven configuration
- ✅ Security best practices (FLS, CRUD, Sharing)
- ✅ Integration patterns with external systems (Slack notifications)
- ✅ Scheduled jobs and batch processing
- ✅ Modern CI/CD with GitHub Actions

## 📁 Project Structure

```
├── force-app/main/default/
│   ├── classes/              # Apex classes (trigger handlers, services, validators)
│   ├── triggers/             # Apex triggers (5 triggers)
│   ├── objects/              # Custom objects (Subscription, Invoice, etc.)
│   ├── layouts/              # Page layouts
│   ├── flexipages/           # Lightning pages
│   ├── flows/                # Process automation flows
│   ├── email/                # Email templates
│   └── applications/         # Custom apps
├── scripts/
│   ├── apex/                 # Anonymous Apex scripts for setup/testing
│   └── soql/                 # SOQL queries for development
├── docs/                     # Additional documentation
│   ├── MANUAL_TESTING_GUIDE.md
│   ├── SECURITY.md
│   └── WORKFLOW_ANALYSIS.md
└── config/                   # Scratch org definitions
```

## 🏗️ Architecture Highlights

### Trigger Framework

- Custom trigger framework with `IHandler` interface
- Separation of concerns between triggers and business logic
- Bulkified operations for governor limit optimization

### Service Layer Pattern

- `SubscriptionAutomationService`: Handles subscription lifecycle automation
- `InvoiceAutomationService`: Manages invoice generation and processing
- `SlackNotificationService`: External system integration

### Validation Layer

- `SubscriptionValidator`: Business rule validation
- `InvoiceValidator`: Data integrity checks
- Centralized validation logic reusable across contexts

### Platform Events

- `SubscriptionEventTrigger`: Subscription state changes
- `InvoiceEventTrigger`: Invoice lifecycle events
- Event-driven architecture for loose coupling

## 🧪 Testing Strategy

- **Test Coverage**: 71% (targeting 90%+)
- **Test Utilities**:
  - `TestDataFactory`: Standardized test data creation
  - `TestScenarioFactory`: Complex business scenario setup
- **Test Classes**: 15+ comprehensive test classes covering:
  - Trigger handlers
  - Service classes
  - Controllers
  - Validators
  - Utility classes

## 🚀 Getting Started

### Prerequisites

- Salesforce CLI (`sf` or `sfdx`)
- Node.js (v18+) for linting and testing
- VS Code with Salesforce Extensions (recommended)

### Setup

1. **Clone the repository**

   ```bash
   git clone https://github.com/AntonioF99/SalesforcePortfolio.git
   cd SalesforcePortfolio
   ```

2. **Install dependencies**

   ```bash
   npm install
   ```

3. **Create a scratch org**

   ```bash
   sf org create scratch -f config/project-scratch-def.json -a portfolio-scratch
   ```

4. **Deploy the metadata**

   ```bash
   sf project deploy start
   ```

5. **Run tests**
   ```bash
   sf apex run test --test-level RunLocalTests --result-format human
   ```

## 🛠️ Development

### Code Quality Tools

- **Prettier**: Code formatting for Apex, LWC, and metadata

  ```bash
  npm run prettier        # Format all files
  npm run prettier:verify # Check formatting
  ```

- **ESLint**: JavaScript linting for LWC

  ```bash
  npm run lint
  ```

- **Jest**: Unit tests for LWC
  ```bash
  npm run test:unit
  ```

### Pre-commit Hooks

This project uses Husky for pre-commit hooks that automatically:

- Format staged files with Prettier
- Run ESLint on LWC files
- Execute related Jest tests

## 📊 Key Features

### Subscription Management

- Create and manage subscriptions with various billing frequencies
- Trial period handling with automatic state transitions
- Renewal and cancellation workflows
- Record types for B2B and B2C subscriptions

### Invoice Generation & Processing

- Automated invoice generation from active subscriptions
- Status lifecycle: Draft → Sent → Paid/Overdue
- Invoice line items with quantity and pricing
- Email notifications at key milestones

### Automation

- `DailyMaintenanceBatch`: Scheduled jobs for system maintenance
- Flow-based trial expiration monitoring
- Platform event-driven notifications

### Security

- Field-Level Security (FLS) checks via `SecurityUtils`
- `WITH SECURITY_ENFORCED` in SOQL queries
- Custom permissions for sensitive operations
- Record Type segregation for data access

## 📚 Documentation

- [Manual Testing Guide](docs/MANUAL_TESTING_GUIDE.md) - Step-by-step testing procedures
- [Security Documentation](docs/SECURITY.md) - Security implementation details
- [Workflow Analysis](docs/WORKFLOW_ANALYSIS.md) - Business process flows
- [Slack Setup](SLACK_SETUP.md) - External integration configuration

## 🔍 Code Analysis

See [ANALYSIS_REPORT.md](ANALYSIS_REPORT.md) for a detailed code quality analysis including:

- Identified issues and improvements
- Test coverage metrics
- Code quality metrics
- Refactoring opportunities

## 🤝 Contributing

This is a portfolio project, but suggestions and feedback are welcome through issues.

## 📄 License

This project is created for portfolio and educational purposes.

## 👤 Author

**Antonio Franco**

- GitHub: [@AntonioF99](https://github.com/AntonioF99)
- Email: antoniofranco.99@outlook.com

---

_This portfolio demonstrates professional Salesforce development skills including architecture design, testing strategies, CI/CD practices, and adherence to platform best practices._

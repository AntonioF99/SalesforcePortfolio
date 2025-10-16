# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Comprehensive README with architecture overview, setup instructions, and development workflow
- CONTRIBUTING.md guide for collaborators and feedback
- CHANGELOG.md for tracking project changes
- CODEOWNERS file for repository governance
- Scripts README documenting all utility scripts
- Pre-commit hooks with Husky and lint-staged

### Changed

- Improved repository organization by moving loose script files to `scripts/apex/`
- Applied Prettier formatting to all 200+ files for consistent code style
- Enhanced documentation structure and clarity

### Fixed

- ESLint errors in LWC components:
  - `@lwc/lwc/no-api-reassignments` in invoiceManager and subscriptionManager
  - `consistent-return` in invoiceOverdueDashboard
  - `no-else-return` in invoiceOverdueDashboard and subscriptionExpiringWidget
- README typo: "SalesforcePorfoltio" → "Salesforce Portfolio"

### Removed

- `test.txt` file from repository root (no purpose)

## [1.0.0] - Initial Portfolio Release

### Added

- **Core Architecture**
  - Trigger Framework pattern with IHandler interface
  - TriggerFramework base class for consistent trigger handling
  - Service layer pattern for business logic

- **Subscription Management**
  - Subscription custom object with B2B and B2C record types
  - Status lifecycle: Draft → Trial → Active → Cancelled/Suspended
  - SubscriptionTrigger with comprehensive handler
  - SubscriptionAutomationService for lifecycle automation
  - SubscriptionValidator for business rule validation
  - SubscriptionController for UI operations

- **Invoice Management**
  - Invoice and InvoiceLineItem custom objects
  - Status workflow: Draft → Sent → Paid/Overdue
  - InvoiceTrigger with handler
  - InvoiceAutomationService for generation and processing
  - InvoiceValidator for data integrity
  - InvoiceController for UI operations

- **Lightning Web Components**
  - invoiceManager: Invoice management interface
  - subscriptionManager: Subscription management interface
  - invoiceOverdueDashboard: Overdue invoice tracking
  - subscriptionExpiringWidget: Trial expiration monitoring
  - invoiceAnalyticsDashboard: Invoice analytics and metrics

- **Automation & Integration**
  - DailyMaintenanceBatch: Scheduled maintenance jobs
  - SlackNotificationService: External notifications
  - Platform Events (SubscriptionEvent**e, InvoiceEvent**e)
  - Platform Event publishers and subscribers
  - Flow: Trial Expiration Monitoring

- **Security & Utilities**
  - SecurityUtils: FLS and CRUD checks
  - RecordTypeUtils: Record Type helper methods
  - Constants: Centralized constant values
  - Custom permissions for sensitive operations

- **Testing Infrastructure**
  - TestDataFactory: Test data creation
  - TestScenarioFactory: Complex scenario setup
  - 15+ comprehensive test classes
  - 71% code coverage

- **CI/CD & DevOps**
  - GitHub Actions workflows (validate, deploy)
  - ESLint configuration for LWC
  - Jest configuration for LWC testing
  - Prettier configuration for code formatting
  - Husky pre-commit hooks

- **Documentation**
  - ANALYSIS_REPORT.md: Code quality analysis
  - SECURITY.md: Security implementation details
  - MANUAL_TESTING_GUIDE.md: Testing procedures
  - MANUAL_UI_TESTING_GUIDE.md: UI testing guide
  - WORKFLOW_ANALYSIS.md: Business process flows
  - SLACK_SETUP.md: Integration setup

- **Custom Metadata**
  - Email templates (Invoice_Notification, Invoice_Overdue, Subscription_Welcome)
  - Page layouts for different use cases
  - Flexipages (Subscription_Billing_Home, Subscription_Billing_UtilityBar)
  - Custom app (SubscriptionBilling)
  - Groups (Customer_Success_Team, Finance_Team)
  - Sharing rules and permissions

### Technical Highlights

- Bulkified operations throughout
- Governor limit considerations
- WITH SECURITY_ENFORCED in queries
- Comprehensive error handling
- Separation of concerns
- DRY principle adherence
- Test-driven development

---

## Version History Legend

- **Added**: New features
- **Changed**: Changes to existing functionality
- **Deprecated**: Soon-to-be removed features
- **Removed**: Removed features
- **Fixed**: Bug fixes
- **Security**: Security improvements

## Upgrade Notes

### From Initial Release to Current

1. Run `npm install` to update dependencies
2. Apply Prettier formatting: `npm run prettier`
3. Verify ESLint passes: `npm run lint`
4. Review new documentation files
5. Update any local scripts referencing moved files

## Support

For questions or issues, please:

- Check the documentation in `/docs`
- Review the CONTRIBUTING.md guide
- Open an issue on GitHub
- Contact: antoniofranco.99@outlook.com

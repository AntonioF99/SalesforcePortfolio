# Scripts Directory

This directory contains utility scripts for development, testing, and data management.

## 📂 Structure

### `/apex` - Anonymous Apex Scripts

Scripts that can be executed in Salesforce using the Developer Console or VS Code's "Execute Anonymous Apex" feature.

#### Setup & Demo Scripts

- **`hello.apex`** - Simple hello world script for testing execution
- **`international-data.apex`** - Creates sample accounts and contacts from various countries (demo data)
- **`check-accounts.apex`** - Lists all accounts in the org (diagnostic)
- **`check-email-template.apex`** - Verifies email template configuration (diagnostic)
- **`create-contact.apex`** - Creates a specific contact for testing

#### Data Management Scripts

- **`subscription-import-script.apex`** - Bulk import subscriptions
- **`invoice-import-script.apex`** - Bulk import invoices
- **`invoice-line-items-script.apex`** - Manage invoice line items
- **`update-invoice-status-script.apex`** - Batch update invoice statuses
- **`update-price-plans.apex`** - Update pricing plan configurations
- **`update-all-contact-emails.apex`** - Bulk update contact emails (personal/testing only)
- **`cleanup-all-data.apex`** - Remove all test data (use with caution!)

### `/soql` - SOQL Queries

Reusable SOQL queries for development and debugging.

- **`account.soql`** - Basic account query template

## 🚀 Usage

### Executing Apex Scripts in VS Code

1. Open the script file
2. Select all text (Ctrl/Cmd + A)
3. Right-click and select "SFDX: Execute Anonymous Apex with Selected Text"
4. Or use command palette: `Ctrl/Cmd + Shift + P` → "SFDX: Execute Anonymous Apex with Editor Contents"

### Executing SOQL Queries in VS Code

1. Open the .soql file
2. Select the query
3. Right-click and select "SFDX: Execute SOQL Query with Currently Selected Text"

## ⚠️ Important Notes

### Safety Warnings

- **`cleanup-all-data.apex`**: This script deletes ALL data. Only use in scratch orgs or sandboxes!
- **`update-all-contact-emails.apex`**: Contains personal email address. For testing only.
- **`international-data.apex`**: Creates many records. Review before executing.

### Best Practices

1. **Always review scripts** before executing, especially data manipulation scripts
2. **Use scratch orgs** for testing destructive operations
3. **Backup data** before running bulk update or delete scripts
4. **Check limits** - Some scripts may hit governor limits in orgs with large data volumes

### Order of Execution for Demo Data

To set up a complete demo environment:

1. Execute `international-data.apex` - Creates accounts
2. Execute `subscription-import-script.apex` - Creates subscriptions
3. Execute `invoice-import-script.apex` - Creates invoices
4. Execute `invoice-line-items-script.apex` - Adds line items

## 🔧 Customization

Scripts can be modified for your specific needs:

- Update hardcoded IDs with your org's record IDs
- Adjust data volumes and ranges
- Modify field values to match your requirements

## 📝 Creating New Scripts

When adding new scripts:

1. Use descriptive names following the pattern: `action-object-type.apex`
2. Add comments explaining the script's purpose
3. Include safety checks for destructive operations
4. Update this README with the new script description

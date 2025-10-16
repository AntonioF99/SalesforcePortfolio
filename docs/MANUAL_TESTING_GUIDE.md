# Salesforce Portfolio - Comprehensive Manual Testing Guide

## Table of Contents

1. [Setup & Prerequisites](#setup--prerequisites)
2. [Subscription Lifecycle Workflows](#subscription-lifecycle-workflows)
3. [Invoice Generation & Management](#invoice-generation--management)
4. [Status Transitions & Automation](#status-transitions--automation)
5. [Validation Rules Testing](#validation-rules-testing)
6. [Platform Events & Slack Notifications](#platform-events--slack-notifications)
7. [Line Items & Calculations](#line-items--calculations)
8. [Overdue Invoice Management](#overdue-invoice-management)
9. [Security & Permissions](#security--permissions)
10. [Troubleshooting & Debug Logs](#troubleshooting--debug-logs)

---

## Setup & Prerequisites

### Initial Data Setup

Before testing any workflow, create the following baseline data in your Salesforce org:

#### 1. Create Test Accounts

```
Navigate to: Accounts Tab → New
Required Fields:
- Account Name: "Acme Corporation"
- Billing Country: "Italy"
- Billing State: (any)
Status: Active
Save the record
```

**Verification:**

- Account record created successfully
- Record ID starts with `001`

#### 2. Create Price Plans

```
Navigate to: Price Plans Tab → New
Create three price plans:

Plan 1 - Basic:
- Name: "Basic Plan"
- Unit Price: 99.00
- Billing Frequency: Monthly
- Trial Days: 14
- Setup Fee: 0
- Category: Subscription

Plan 2 - Professional:
- Name: "Professional Plan"
- Unit Price: 199.00
- Billing Frequency: Quarterly
- Trial Days: 30
- Setup Fee: 500
- Category: Subscription

Plan 3 - Enterprise:
- Name: "Enterprise Plan"
- Unit Price: 499.00
- Billing Frequency: Annual
- Trial Days: 0
- Setup Fee: 2000
- Category: Subscription
```

**Verification:**

- All three Price Plans visible in list view
- Unit Price displays with currency symbol
- Billing Frequency populated correctly

#### 3. Enable Debug Logs

```
Navigate to: Setup → Debug Logs → New
Traced Entity Type: User
User: [Your Username]
Debug Level: [Create/Select with ALL categories set to FINEST]
Expiration: 1 hour from now
Save
```

---

## Subscription Lifecycle Workflows

### Workflow 1: Create Draft Subscription

**Purpose:** Test subscription creation with default values

**Setup:**

- Ensure at least one Account exists
- At least one Price Plan exists

**Steps:**

1. Navigate to `Subscriptions Tab → New`
2. Fill in fields:
   - **Account**: Select "Acme Corporation"
   - **Price Plan**: Select "Basic Plan"
   - **Quantity**: 5
   - Leave **Status** blank (defaults to Draft)
   - Leave **Start Date** blank (defaults to Today)
3. Click **Save**

**Expected Results:**

- ✅ Record saves successfully
- ✅ Status auto-populated to "Draft"
- ✅ Start Date auto-populated to Today
- ✅ Next Billing Date remains blank (only required for Active)
- ✅ MRR and ARR calculated automatically (5 × 99 = 495 MRR)

**Verification Queries:**

```sql
SELECT Id, Name, Status__c, Start_Date__c, MRR__c, ARR__c, Quantity__c
FROM Subscription__c
WHERE Account__r.Name = 'Acme Corporation'
ORDER BY CreatedDate DESC
LIMIT 1
```

**Debug Log Checks:**

- Look for: `SubscriptionTriggerHandler.beforeInsert`
- Look for: `SubscriptionValidator.setDefaults`
- Look for: `RecordTypeUtils.assignSubscriptionRecordTypes`

---

### Workflow 2: Transition Draft → Trial

**Purpose:** Test status transition and trial date auto-population

**Setup:**

- Complete Workflow 1 (Draft subscription exists)

**Steps:**

1. Open the Draft subscription created in Workflow 1
2. Click **Edit**
3. Change **Status** to "Trial"
4. Leave **Trial End Date** blank
5. Click **Save**

**Expected Results:**

- ✅ Record saves successfully
- ✅ Status updated to "Trial"
- ✅ Trial End Date auto-populated to 14 days from today (Basic Plan default)
- ✅ Onboarding tasks created (Welcome Call, Week 1 Check-in, Month 1 Review)
- ✅ Welcome email sent to primary contact (if contact exists)
- ✅ Account Subscription Status updated to "Trial Customer"
- ✅ Account Health Score updated to 75
- ✅ Platform event published

**Verification Queries:**

```sql
-- Check subscription
SELECT Id, Name, Status__c, Trial_End_Date__c
FROM Subscription__c
WHERE Id = '[Your Subscription Id]'

-- Check tasks created
SELECT Id, Subject, WhatId, ActivityDate, Priority
FROM Task
WHERE WhatId = '[Your Subscription Id]'
ORDER BY ActivityDate

-- Check account updates
SELECT Id, Name, Subscription_Status__c, Health_Score__c, Last_Subscription_Date__c
FROM Account
WHERE Id = '[Your Account Id]'
```

**Debug Log Checks:**

- Look for: `SubscriptionTriggerHandler.afterUpdate`
- Look for: `SubscriptionAutomationService.processStatusChanges`
- Look for: `createOnboardingTasks`
- Look for: `PlatformEventPublisher.publishSubscriptionStatusChanges`

**Validation Rule Tests:**
Try these invalid scenarios to verify validation rules:

- ❌ Set Trial End Date to yesterday → Should fail: "Trial end date must be in the future"
- ❌ Set Trial End Date to 400 days ahead → Should fail: "Trial period cannot exceed 365 days"

---

### Workflow 3: Activate Subscription (Trial → Active)

**Purpose:** Test activation workflow and automatic invoice generation

**Setup:**

- Complete Workflow 2 (Trial subscription exists)

**Steps:**

1. Open the Trial subscription
2. Click **Edit**
3. Change **Status** to "Active"
4. Verify **Price Plan** is populated (required for activation)
5. Click **Save**

**Expected Results:**

- ✅ Record saves successfully
- ✅ Status updated to "Active"
- ✅ **NEW INVOICE CREATED AUTOMATICALLY** (Draft status)
- ✅ Invoice Line Item created with subscription details
- ✅ Line Item fields populated:
  - Quantity = Subscription Quantity (5)
  - Unit Price = Price Plan Unit Price (99.00)
  - Period Start = Today
  - Period End = Today + 1 month - 1 day
  - Line Amount = 495.00 (5 × 99)
- ✅ Status-specific task created: "Subscription Activated"
- ✅ Account Subscription Status updated to "Active Customer"
- ✅ Account Health Score updated to 100
- ✅ Platform event published: `Subscription_Event__e` with Event Type "StatusChanged"

**Verification Queries:**

```sql
-- Check subscription
SELECT Id, Name, Status__c, Next_Billing_Date__c
FROM Subscription__c
WHERE Id = '[Your Subscription Id]'

-- Check invoice was created
SELECT Id, Name, Account__c, Status__c, Invoice_Date__c, Due_Date__c, Subtotal__c
FROM Invoice__c
WHERE Account__c = '[Your Account Id]'
ORDER BY CreatedDate DESC
LIMIT 1

-- Check invoice line item
SELECT Id, Invoice__c, Subscription__c, Quantity__c, Unit_Price__c,
       Line_Amount__c, Period_Start__c, Period_End__c
FROM Invoice_Line_Item__c
WHERE Subscription__c = '[Your Subscription Id]'
```

**Debug Log Checks:**

- Look for: `SubscriptionTriggerHandler.afterUpdate`
- Look for: `handleActivatedSubscriptions`
- Look for: `SubscriptionAutomationService.generateInvoicesForActiveSubscriptions`
- Look for: `Created X invoices` and `Created X invoice line items`
- Look for: `PlatformEventPublisher.publishInvoiceEvents`

**Important Notes:**

- If invoice already exists for current period, no duplicate invoice is created
- Invoice remains in Draft status (must be manually sent)
- Tax calculation happens automatically based on Account Billing Country

---

### Workflow 4: Suspend Active Subscription

**Purpose:** Test suspension workflow and at-risk account status

**Setup:**

- Complete Workflow 3 (Active subscription exists)

**Steps:**

1. Open the Active subscription
2. Click **Edit**
3. Change **Status** to "Suspended"
4. Click **Save**

**Expected Results:**

- ✅ Status updated to "Suspended"
- ✅ URGENT task created: "URGENT: Subscription Suspended - [Account Name]"
- ✅ Task Priority set to "High"
- ✅ Task Activity Date = Today
- ✅ Account Subscription Status updated to "At Risk"
- ✅ Account Health Score updated to 25
- ✅ Platform event published with Event Type "StatusChanged"

**Verification Queries:**

```sql
-- Check subscription
SELECT Id, Name, Status__c
FROM Subscription__c
WHERE Id = '[Your Subscription Id]'

-- Check urgent task
SELECT Id, Subject, Description, Priority, ActivityDate
FROM Task
WHERE WhatId = '[Your Subscription Id]'
AND Subject LIKE '%URGENT: Subscription Suspended%'

-- Check account health
SELECT Id, Name, Subscription_Status__c, Health_Score__c
FROM Account
WHERE Id = '[Your Account Id]'
```

**Valid Transitions from Suspended:**

- ✅ Suspended → Active (reactivation)
- ✅ Suspended → Cancelled
- ❌ Suspended → Draft (invalid)
- ❌ Suspended → Trial (invalid)

---

### Workflow 5: Cancel Subscription

**Purpose:** Test cancellation workflow with mandatory reason

**Setup:**

- Active or Suspended subscription exists

**Steps:**

1. Open the subscription
2. Click **Edit**
3. Change **Status** to "Cancelled"
4. **DO NOT fill Cancellation Reason** (test validation)
5. Click **Save**

**Expected Results:**

- ❌ Save fails with error: "Cancellation reason is required when status is Cancelled. Please select a reason from the dropdown."

**Steps (Correct Flow):**

1. Click **Edit** again
2. Change **Status** to "Cancelled"
3. **Fill Cancellation Reason**: Select "Price Too High"
4. **Add Cancellation Comments**: "Customer found cheaper alternative"
5. Click **Save**

**Expected Results:**

- ✅ Record saves successfully
- ✅ Status updated to "Cancelled"
- ✅ Cancellation Date auto-populated to Today
- ✅ Cancellation Reason saved
- ✅ Task created: "Subscription Cancelled - [Account Name]"
- ✅ Task Priority set to "High"
- ✅ Account Subscription Status updated to "Former Customer"
- ✅ Account Health Score updated to 0
- ✅ Subscription is now TERMINAL (cannot change status anymore)

**Verification Queries:**

```sql
SELECT Id, Name, Status__c, Cancellation_Reason__c,
       Cancellation_Comments__c, Cancellation_Date__c
FROM Subscription__c
WHERE Id = '[Your Subscription Id]'
```

**Terminal Status Validation:**
Try to change status from Cancelled:

1. Click **Edit**
2. Change **Status** to "Active"
3. Click **Save**
4. **Expected:** ❌ Error: "Cannot change status from Cancelled. This is a terminal status."

**Debug Log Checks:**

- Look for: `SubscriptionValidator.validateStateTransitions`
- Look for: `Status_Transition_Terminal` validation rule

---

### Workflow 6: Subscription Without Price Plan (Validation)

**Purpose:** Test validation rule preventing activation without Price Plan

**Setup:**

- New Draft subscription

**Steps:**

1. Create new subscription with:
   - Account: Select any
   - **DO NOT select Price Plan**
   - Status: Draft
2. Save successfully (Draft allows blank Price Plan)
3. Click **Edit**
4. Change **Status** to "Active"
5. Click **Save**

**Expected Results:**

- ❌ Save fails with error: "Price plan is required for active subscriptions"

**Verification:**
This validation is checked in both:

- `SubscriptionValidator.validateBusinessRules` (Apex)
- `Price_Plan_Required_Active.validationRule` (Validation Rule)

---

## Invoice Generation & Management

### Workflow 7: Manual Invoice Creation

**Purpose:** Test manual invoice creation with automatic calculations

**Setup:**

- Account exists

**Steps:**

1. Navigate to `Invoices Tab → New`
2. Fill in fields:
   - **Account**: Select "Acme Corporation"
   - **Status**: Draft (default)
   - **Invoice Date**: Today (default)
   - **Payment Terms**: Select "Net 30"
   - Leave **Due Date** blank
3. Click **Save**

**Expected Results:**

- ✅ Record saves successfully
- ✅ Status defaults to "Draft"
- ✅ Invoice Date defaults to Today
- ✅ **Due Date auto-calculated** = Invoice Date + 30 days
- ✅ Tax Rate auto-calculated based on Account Billing Country (Italy = 22%)
- ✅ Invoice Number auto-generated (Name field)
- ✅ Balance Due defaults to 0 (no line items yet)

**Verification Queries:**

```sql
SELECT Id, Name, Account__r.Name, Status__c, Invoice_Date__c,
       Due_Date__c, Payment_Terms__c, Tax_Rate__c, Balance_Due__c
FROM Invoice__c
WHERE Account__r.Name = 'Acme Corporation'
ORDER BY CreatedDate DESC
LIMIT 1
```

**Debug Log Checks:**

- Look for: `InvoiceTriggerHandler.beforeInsert`
- Look for: `InvoiceValidator.setDefaults`
- Look for: `InvoiceValidator.calculateTaxAmounts`
- Look for: `RecordTypeUtils.assignInvoiceRecordTypes`

---

### Workflow 8: Invoice Status Transition (Draft → Sent)

**Purpose:** Test invoice sending with validation

**Setup:**

- Draft invoice with Subtotal > 0 (has line items)

**Steps:**

1. Open Draft invoice
2. Click **Edit**
3. Change **Status** to "Sent"
4. Click **Save**

**Expected Results:**

- ✅ Status updated to "Sent"
- ✅ Follow-up task created: "Invoice Follow-up - [Account Name]"
- ✅ Task Activity Date = Due Date - 5 days
- ✅ Account payment metrics updated
- ✅ Platform event published with Event Type "Sent"

**Validation Test (Invoice with Zero Subtotal):**

1. Create invoice with NO line items (Subtotal = 0)
2. Try to change Status to "Sent"
3. **Expected:** ❌ Error: "Cannot send invoice with zero or negative subtotal"

**Verification Queries:**

```sql
-- Check invoice
SELECT Id, Name, Status__c, Subtotal__c, Due_Date__c
FROM Invoice__c
WHERE Id = '[Your Invoice Id]'

-- Check task
SELECT Id, Subject, ActivityDate, WhatId
FROM Task
WHERE WhatId = '[Your Invoice Id]'
```

**Debug Log Checks:**

- Look for: `InvoiceTriggerHandler.afterUpdate`
- Look for: `handleSentInvoices`
- Look for: `InvoiceAutomationService.processStatusChanges`

---

### Workflow 9: Mark Invoice as Paid

**Purpose:** Test payment receipt workflow

**Setup:**

- Invoice in "Sent" status

**Steps:**

1. Open Sent invoice
2. Click **Edit**
3. Change **Status** to "Paid"
4. Set **Balance Due** to 0
5. Click **Save**

**Expected Results:**

- ✅ Status updated to "Paid"
- ✅ Balance Due = 0
- ✅ Task created: "Payment Received - Thank [Account Name]"
- ✅ Task Activity Date = Tomorrow
- ✅ Account payment metrics updated (Total Billed, Invoice Count, Average Invoice Amount)
- ✅ Platform event published with Event Type "Paid"
- ✅ **Invoice is now LOCKED** (cannot edit most fields)

**Verification Queries:**

```sql
-- Check invoice
SELECT Id, Name, Status__c, Balance_Due__c
FROM Invoice__c
WHERE Id = '[Your Invoice Id]'

-- Check account metrics
SELECT Id, Name, Total_Billed__c, Invoice_Count__c,
       Average_Invoice_Amount__c, Last_Invoice_Date__c
FROM Account
WHERE Id = '[Your Account Id]'
```

**Locked Status Test:**

1. Try to edit Paid invoice
2. Change **Tax Rate** or **Due Date**
3. **Expected:** ❌ Cannot modify locked fields on Paid/Voided invoice

---

### Workflow 10: Void Invoice

**Purpose:** Test invoice cancellation

**Setup:**

- Invoice in Sent or Overdue status

**Steps:**

1. Open invoice
2. Click **Edit**
3. Change **Status** to "Voided"
4. Click **Save**

**Expected Results:**

- ✅ Status updated to "Voided"
- ✅ Platform event published with Event Type "Voided"
- ✅ **Invoice is now LOCKED** (terminal status)
- ✅ Cannot send reminders for voided invoice

**Verification:**
Try to send reminder via LWC or controller:

```javascript
// Should throw error
InvoiceController.sendInvoice(voidedInvoiceId);
// Expected: "Cannot send reminder for a voided invoice"
```

---

## Status Transitions & Automation

### Workflow 11: Overdue Invoice Auto-Detection

**Purpose:** Test overdue status trigger

**Setup:**

- Invoice in "Sent" status with Due Date in the past

**Steps:**

1. Create invoice with:
   - Status: Sent
   - Invoice Date: 45 days ago
   - Due Date: 15 days ago (past due)
2. Save
3. Edit invoice (to trigger validation)
4. Try to change Status to "Overdue"

**Expected Results:**

- ✅ Status can be manually set to "Overdue" (for testing)
- ✅ URGENT task created: "URGENT: Overdue Payment - [Account Name]"
- ✅ Task Priority = "High"
- ✅ Task Activity Date = Today

**Validation Test:**

1. Create invoice with Due Date = Tomorrow
2. Try to set Status to "Overdue"
3. **Expected:** ❌ Error: "Cannot mark as overdue if due date is not past"

**Note:** In production, a scheduled batch job would auto-update Sent invoices to Overdue when Due Date passes.

---

## Validation Rules Testing

### Workflow 12: Subscription Validation Rules

**Test 1: Account Required**

```
Create subscription WITHOUT Account
Expected: ❌ Error: "Account is required"
```

**Test 2: Positive Quantity**

```
Create subscription with Quantity = 0 or negative
Expected: ❌ Error: "Quantity must be greater than zero"
```

**Test 3: End Date After Start Date**

```
Create subscription with:
- Start Date: 2025-10-01
- End Date: 2025-09-01 (before start)
Expected: ❌ Error: "End date must be after start date"
```

**Test 4: Trial Date After Start Date**

```
Create Trial subscription with:
- Start Date: 2025-10-01
- Trial End Date: 2025-09-15 (before start)
Expected: ❌ Error via validation rule
```

---

### Workflow 13: Invoice Validation Rules

**Test 1: Due Date After Invoice Date**

```
Create invoice with:
- Invoice Date: 2025-10-15
- Due Date: 2025-10-10 (before invoice)
Expected: ❌ Error: "Due Date must be on or after Invoice Date"
```

**Test 2: Tax Rate Range**

```
Create invoice with Tax Rate = 150%
Expected: ❌ Error: "Tax rate must be between 0 and 100"
```

**Test 3: Account Required**

```
Create invoice WITHOUT Account
Expected: ❌ Error: "Account is required for invoices"
```

---

### Workflow 14: Line Item Validation Rules

**Test 1: Positive Quantity**

```
Create line item with Quantity = -5
Expected: ❌ Error: "Quantity must be positive"
```

**Test 2: Non-Negative Unit Price**

```
Create line item with Unit Price = -50
Expected: ❌ Error: "Unit price cannot be negative"
```

**Test 3: Discount Range**

```
Create line item with Discount Percent = 150%
Expected: ❌ Error: "Discount must be between 0 and 100"
```

---

## Platform Events & Slack Notifications

### Workflow 15: Subscription Events

**Purpose:** Test platform event publishing for subscription changes

**Setup:**

- Enable Debug Logs with FINEST level on Workflow category
- Subscription in any status

**Test Events:**

**Event 1: Subscription Created**

```
1. Create new subscription
2. Save
Expected Platform Event:
- Object: Subscription_Event__e
- Event_Type__c: "Created"
- Subscription_Id__c: [ID]
- Account_Id__c: [Account ID]
- Status__c: "Draft"
```

**Event 2: Status Changed**

```
1. Change subscription from Trial → Active
2. Save
Expected Platform Events (2 events):
- Event 1: Event_Type__c = "StatusChanged"
- Event 2: Event_Type__c = "Updated"
```

**Verification:**
Check debug logs for:

```
PlatformEventPublisher.publishSubscriptionEvents
Publishing X platform events
EventBus.publish
```

**Slack Notification Test:**
For high-value events (Created, Activated, Cancelled):

```
Debug Log should show:
- PlatformEventSubscriber.processSubscriptionEvents
- shouldNotifySlack = true
- SlackNotificationService.notifySubscriptionEvent
- Payload: {"subscription_id":"...", "status":"Active"}
```

---

### Workflow 16: Invoice Events

**Test Events:**

**Event 1: Invoice Created (from Subscription Activation)**

```
1. Activate subscription
2. Invoice auto-generated
Expected Platform Event:
- Object: Invoice_Event__e
- Event_Type__c: "Created"
- Invoice_Id__c: [ID]
- Total_Amount__c: [Amount]
```

**Event 2: Invoice Sent**

```
1. Change invoice Status to "Sent"
Expected Platform Event:
- Event_Type__c: "Sent"
- Status__c: "Sent"
```

**Event 3: Invoice Paid**

```
1. Mark invoice as Paid
Expected Platform Event:
- Event_Type__c: "Paid"
- Status__c: "Paid"
Slack Notification: YES (always notified for payments)
```

**Verification Queries (Debug Logs):**

```
Search for: publishInvoiceStatusChanges
Search for: EventBus.publish
Search for: SlackNotificationService.notifyInvoiceEvent
```

---

## Line Items & Calculations

### Workflow 17: Invoice Line Item Creation

**Purpose:** Test line item with automatic calculations

**Setup:**

- Invoice in Draft status exists

**Steps:**

1. Navigate to invoice detail page
2. Click **New Invoice Line Item**
3. Fill in:
   - **Invoice**: (auto-populated from parent)
   - **Type**: Add-on
   - **Status**: Active
   - **Quantity**: 10
   - **Unit Price**: 50.00
   - **Discount Percent**: 10
   - **Period Start**: 2025-10-01
   - **Period End**: 2025-10-31
4. Click **Save**

**Expected Results:**

- ✅ Line Amount auto-calculated = (10 × 50) - 10% = 450.00
- ✅ Invoice Subtotal recalculated = Sum of all line amounts
- ✅ Invoice Tax Amount recalculated = Subtotal × Tax Rate
- ✅ Invoice Total Amount = Subtotal + Tax Amount
- ✅ Invoice Balance Due updated

**Verification Queries:**

```sql
-- Check line item
SELECT Id, Quantity__c, Unit_Price__c, Discount_Percent__c, Line_Amount__c
FROM Invoice_Line_Item__c
WHERE Invoice__c = '[Invoice Id]'

-- Check invoice totals
SELECT Id, Subtotal__c, Tax_Amount__c, Total_Amount__c, Balance_Due__c
FROM Invoice__c
WHERE Id = '[Invoice Id]'
```

**Formula Field Check:**
Line_Amount\_\_c formula:

```
(Quantity__c * Unit_Price__c) * (1 - Discount_Percent__c / 100)
```

---

### Workflow 18: Line Item from Subscription

**Purpose:** Test automatic line item creation when subscription activates

**Setup:**

- Subscription with Price Plan

**Steps:**

1. Create subscription with:
   - Price Plan: Professional Plan (Unit Price = 199, Billing Frequency = Quarterly)
   - Quantity: 3
   - Status: Draft
2. Change Status to "Active"
3. Save

**Expected Results:**

- ✅ Invoice created automatically
- ✅ **Line item auto-created with:**
  - Subscription\_\_c = [Subscription ID]
  - Quantity = 3 (from subscription)
  - Unit Price = 199.00 (from price plan)
  - Period Start = Today
  - Period End = Today + 3 months - 1 day (Quarterly)
  - Line Amount = 3 × 199 = 597.00
  - Discount = 0%

**Verification:**

```sql
SELECT Id, Invoice__c, Subscription__c, Quantity__c, Unit_Price__c,
       Period_Start__c, Period_End__c, Line_Amount__c
FROM Invoice_Line_Item__c
WHERE Subscription__c = '[Subscription Id]'
```

**Period End Calculation Test:**
| Billing Frequency | Period Start | Expected Period End |
|------------------|--------------|---------------------|
| Monthly | 2025-10-01 | 2025-10-31 |
| Quarterly | 2025-10-01 | 2025-12-31 |
| Semi-Annual | 2025-10-01 | 2026-03-31 |
| Annual | 2025-10-01 | 2026-09-30 |

---

## Overdue Invoice Management

### Workflow 19: Send Payment Reminder

**Purpose:** Test reminder tracking for overdue invoices

**Setup:**

- Invoice in "Overdue" status

**Steps:**

1. Navigate to invoice detail page
2. Click custom button/action: **Send Reminder** (or call via controller)
3. Or use Developer Console:

```apex
InvoiceController.sendInvoice('[Invoice Id]');
```

**Expected Results:**

- ✅ Reminders_Sent\_\_c incremented by 1
- ✅ Last_Reminder_Date\_\_c updated to now
- ✅ Success message displayed

**Verification Queries:**

```sql
SELECT Id, Name, Status__c, Reminders_Sent__c, Last_Reminder_Date__c
FROM Invoice__c
WHERE Id = '[Invoice Id]'
```

**Validation Tests:**
Try to send reminder for Paid invoice:

```apex
// Should throw error
InvoiceController.sendInvoice('[Paid Invoice Id]');
// Expected: "Cannot send reminder for an invoice that is already paid"
```

Try to send reminder for Voided invoice:

```apex
// Should throw error
InvoiceController.sendInvoice('[Voided Invoice Id]');
// Expected: "Cannot send reminder for a voided invoice"
```

---

### Workflow 20: Overdue Dashboard LWC

**Purpose:** Test overdue invoice dashboard component

**Setup:**

- At least 3 invoices in Overdue status

**Steps:**

1. Add LWC component to Home page or Account page:
   - Component Name: `invoiceOverdueDashboard`
2. Component displays list of overdue invoices
3. Each row shows:
   - Invoice Number
   - Account Name
   - Due Date
   - Total Amount
   - Days Overdue (calculated)
   - Reminders Sent count
   - **Send Reminder** button

**Expected Results:**

- ✅ List sorted by Due Date (oldest first)
- ✅ Limit 50 records
- ✅ Click "Send Reminder" button increments counter
- ✅ Toast message confirms success
- ✅ List refreshes automatically

**Controller Method:**

```apex
@AuraEnabled(cacheable=true)
public static List<Invoice__c> getOverdueInvoices()
```

---

## Security & Permissions

### Workflow 21: Field-Level Security (FLS)

**Purpose:** Test Security.stripInaccessible in controllers

**Setup:**

- Create test user with custom profile
- Remove FLS on Invoice**c.Tax_Rate**c (read and edit)

**Test 1: Read Permission**

```
1. Login as restricted user
2. Query invoice via controller:
   InvoiceController.getInvoiceWithRelated(invoiceId)
3. Expected: Tax_Rate__c field NOT returned (stripped)
```

**Test 2: Create Permission**

```
1. Login as restricted user
2. Try to create invoice with Tax_Rate__c = 25
3. Expected: Invoice created but Tax_Rate__c ignored (defaults to account's tax rate)
```

**Test 3: Update Permission**

```
1. Login as restricted user
2. Try to update existing invoice and change Tax_Rate__c
3. Expected: Update succeeds but Tax_Rate__c field ignored
```

**Verification:**
Debug logs show:

```
Security.stripInaccessible(AccessType.READABLE)
Removed fields: [Tax_Rate__c]
```

---

### Workflow 22: Cancellation Permissions

**Purpose:** Test custom permission for cancelling subscriptions

**Setup:**

- User WITHOUT "Cancel Subscriptions" custom permission

**Steps:**

1. Login as restricted user
2. Open Active subscription
3. Try to change Status to "Cancelled"
4. Save

**Expected Results:**

- ❌ Error: "You do not have permission to cancel this subscription"
- Validation checked in `SubscriptionValidator.validateCancellationPermissions`
- Uses `SecurityUtils.canCancelSubscription()`

**Grant Permission Test:**

1. Assign "Cancel Subscriptions" permission to user
2. Try again
3. **Expected:** ✅ Cancellation succeeds

---

### Workflow 23: Invoice Deletion Permissions

**Purpose:** Test deletion restrictions on locked invoices

**Setup:**

- Invoice in Paid status

**Steps:**

1. Open Paid invoice
2. Click **Delete**
3. Confirm deletion

**Expected Results:**

- ❌ Error: "Cannot delete invoices with status: Paid"
- Validation in `InvoiceValidator.validateInvoiceDeletion`

**Allowed Deletion Test:**

```
Draft invoice → Can delete
Sent invoice → Can delete
Overdue invoice → Can delete
Paid invoice → CANNOT delete
Voided invoice → CANNOT delete
```

---

## Troubleshooting & Debug Logs

### How to Read Debug Logs

**Enable Logging:**

```
Setup → Debug Logs → New
User: [Your User]
Debug Level: SFDC_DevConsole (or create custom with all FINEST)
Expiration: 1 hour
```

**Key Log Patterns to Search:**

**1. Trigger Execution:**

```
Search: "SubscriptionTriggerHandler"
Expected: beforeInsert, afterInsert, beforeUpdate, afterUpdate
```

**2. Validation Errors:**

```
Search: "FIELD_CUSTOM_VALIDATION_EXCEPTION"
Shows: Which validation rule failed and error message
```

**3. Platform Events:**

```
Search: "EventBus.publish"
Shows: Number of events published and any failures
```

**4. Automation Service:**

```
Search: "SubscriptionAutomationService"
Shows: processNewSubscriptions, generateInvoicesForActiveSubscriptions
```

**5. SOQL Queries:**

```
Search: "SOQL_EXECUTE_BEGIN"
Shows: All queries executed and number of rows returned
```

**6. DML Operations:**

```
Search: "DML_BEGIN"
Shows: INSERT, UPDATE, DELETE operations
```

---

### Common Issues & Solutions

**Issue 1: Invoice Not Generated on Activation**

```
Symptoms: Subscription activated but no invoice created
Debug Log Check:
- Search for "generateInvoicesForActiveSubscriptions"
- Check if Price Plan is populated
- Verify subscription Status = 'Active'
Solution: Ensure Price Plan is set before activation
```

**Issue 2: Validation Rule Blocks Save**

```
Symptoms: Cannot save record with generic error
Debug Log Check:
- Search for "FIELD_CUSTOM_VALIDATION_EXCEPTION"
- Read errorMessage field
Solution: Fix the field value causing validation failure
```

**Issue 3: Platform Event Not Published**

```
Symptoms: No Slack notification received
Debug Log Check:
- Search for "publishSubscriptionEvents" or "publishInvoiceEvents"
- Check if EventBus.publish succeeded
- Look for SaveResult failures
Solution: Check Integration_Setting__mdt configuration
```

**Issue 4: Tasks Not Created**

```
Symptoms: Subscription activated but no tasks created
Debug Log Check:
- Search for "createOnboardingTasks"
- Check if insert succeeded
Solution: Verify user has Create permission on Task object
```

---

### Query Templates for Verification

**Check Subscription with Related Data:**

```sql
SELECT Id, Name, Status__c, Account__r.Name,
       Price_Plan__r.Name, Price_Plan__r.Unit_Price__c,
       MRR__c, ARR__c, Next_Billing_Date__c,
       (SELECT Id, Subject, ActivityDate FROM Tasks)
FROM Subscription__c
WHERE Id = '[Subscription Id]'
```

**Check Invoice with Line Items:**

```sql
SELECT Id, Name, Status__c, Account__r.Name,
       Subtotal__c, Tax_Amount__c, Total_Amount__c, Balance_Due__c,
       (SELECT Id, Quantity__c, Unit_Price__c, Line_Amount__c FROM Invoice_Line_Items__r)
FROM Invoice__c
WHERE Id = '[Invoice Id]'
```

**Check Account Metrics:**

```sql
SELECT Id, Name,
       Subscription_Status__c, Health_Score__c,
       Total_Billed__c, Invoice_Count__c, Average_Invoice_Amount__c,
       Last_Subscription_Date__c, Last_Invoice_Date__c
FROM Account
WHERE Id = '[Account Id]'
```

**Find All Overdue Invoices:**

```sql
SELECT Id, Name, Account__r.Name, Due_Date__c,
       Total_Amount__c, Balance_Due__c, Reminders_Sent__c
FROM Invoice__c
WHERE Status__c = 'Overdue'
ORDER BY Due_Date__c ASC
```

**Find Expiring Trial Subscriptions:**

```sql
SELECT Id, Name, Account__r.Name, Trial_End_Date__c, Status__c
FROM Subscription__c
WHERE Status__c = 'Trial'
AND Trial_End_Date__c >= TODAY
AND Trial_End_Date__c <= NEXT_N_DAYS:7
ORDER BY Trial_End_Date__c ASC
```

---

## Testing Checklist Summary

### Subscription Workflows

- [ ] Create Draft subscription with defaults
- [ ] Transition Draft → Trial (auto-populate trial date)
- [ ] Transition Trial → Active (generate invoice)
- [ ] Transition Active → Suspended (urgent task)
- [ ] Transition to Cancelled (require reason)
- [ ] Test terminal status validation (cannot change from Cancelled)
- [ ] Test validation: Price Plan required for Active
- [ ] Test validation: Positive quantity
- [ ] Test validation: End date after start date

### Invoice Workflows

- [ ] Create Draft invoice with auto-calculations
- [ ] Transition Draft → Sent (validation for subtotal > 0)
- [ ] Mark invoice as Paid (lock fields)
- [ ] Void invoice (terminal status)
- [ ] Test Overdue status validation (due date must be past)
- [ ] Test validation: Due date after invoice date

### Automation

- [ ] Onboarding tasks created on Trial status
- [ ] Status-specific tasks created on status changes
- [ ] Invoice auto-generated on subscription activation
- [ ] Line items auto-created from subscription
- [ ] Account metrics updated (Subscription Status, Health Score)
- [ ] Account payment metrics updated (Total Billed, Invoice Count)

### Platform Events

- [ ] Subscription Created event published
- [ ] Subscription StatusChanged event published
- [ ] Invoice Created event published
- [ ] Invoice Sent/Paid/Voided events published
- [ ] Platform event triggers execute
- [ ] Slack notifications sent for high-value events

### Line Items & Calculations

- [ ] Manual line item with discount calculation
- [ ] Line item from subscription activation
- [ ] Invoice totals recalculate on line item changes
- [ ] Period end dates calculated per billing frequency
- [ ] Tax amounts calculated from account billing country

### Security

- [ ] FLS enforced via Security.stripInaccessible
- [ ] Cancellation permission checked
- [ ] Deletion restrictions on locked invoices
- [ ] WITH SECURITY_ENFORCED on SOQL queries

### Validation Rules

- [ ] All Subscription validation rules tested
- [ ] All Invoice validation rules tested
- [ ] All Line Item validation rules tested
- [ ] Terminal status transitions blocked

---

## Appendix: Key File Locations

**Apex Classes:**

- [InvoiceController.cls](../force-app/main/default/classes/InvoiceController.cls)
- [SubscriptionController.cls](../force-app/main/default/classes/SubscriptionController.cls)
- [InvoiceTriggerHandler.cls](../force-app/main/default/classes/InvoiceTriggerHandler.cls)
- [SubscriptionTriggerHandler.cls](../force-app/main/default/classes/SubscriptionTriggerHandler.cls)
- [InvoiceAutomationService.cls](../force-app/main/default/classes/InvoiceAutomationService.cls)
- [SubscriptionAutomationService.cls](../force-app/main/default/classes/SubscriptionAutomationService.cls)

**Triggers:**

- [InvoiceTrigger.trigger](../force-app/main/default/triggers/InvoiceTrigger.trigger)
- [SubscriptionTrigger.trigger](../force-app/main/default/triggers/SubscriptionTrigger.trigger)

**LWC Components:**

- [invoiceOverdueDashboard](../force-app/main/default/lwc/invoiceOverdueDashboard/)
- [subscriptionExpiringWidget](../force-app/main/default/lwc/subscriptionExpiringWidget/)

---

**End of Manual Testing Guide**

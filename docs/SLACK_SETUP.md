# Slack Integration Setup

## Configure Slack Webhook

After deploying the code, configure the Slack webhook in Salesforce:

### Steps:

1. **Navigate to Setup** → Custom Metadata Types
2. **Click "Manage Records"** next to "Integration Setting"
3. **Click "New"** to create a new record
4. **Fill in the fields:**
   - **Label**: `Slack Notification`
   - **Integration Setting Name**: `Slack_Notification` (must match exactly)
   - **Webhook URL**: `<your-slack-webhook-url-here>` (get from Slack workspace settings)
   - **Is Active**: ✅ (checked)
5. **Click "Save"**

### Verification:

- The webhook URL is **NOT** stored in the Git repository (secure ✅)
- The integration will only work if the Custom Metadata record is configured
- You can enable/disable the integration by toggling the "Is Active" checkbox

### How it works:

- `SlackNotificationService.cls` queries the Custom Metadata Type for active Slack settings
- If not configured or inactive, notifications are silently skipped (no errors)
- Platform events for subscriptions and invoices trigger Slack notifications

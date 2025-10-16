/**
 * @description Dashboard showing overdue invoices with days overdue calculation
 * @author Antonio Franco
 * @date 2025-10-08
 */
import { LightningElement, wire } from "lwc";
import { refreshApex } from "@salesforce/apex";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getOverdueInvoices from "@salesforce/apex/InvoiceController.getOverdueInvoices";
import sendInvoice from "@salesforce/apex/InvoiceController.sendInvoice";

export default class InvoiceOverdueDashboard extends NavigationMixin(
  LightningElement
) {
  // ========== PRIVATE PROPERTIES ==========

  overdueInvoices = [];
  isLoading = false;
  error;
  sendingInvoiceIds = new Set();
  wiredResult;

  // ========== WIRE METHODS ==========

  @wire(getOverdueInvoices)
  wiredOverdueInvoices(result) {
    this.wiredResult = result;
    const { error, data } = result;
    this.isLoading = true;

    if (data) {
      this.overdueInvoices = data.map((invoice) => {
        const daysOverdue = this.calculateDaysOverdue(invoice.Due_Date__c);
        const remindersSent = invoice.Reminders_Sent__c || 0;
        const hasReminders = remindersSent > 0;

        return {
          ...invoice,
          AccountName: invoice.Account__r?.Name || "N/A",
          daysOverdue: daysOverdue,
          overdueClass: this.getOverdueClass(daysOverdue),
          overdueLabel: `${daysOverdue} day${daysOverdue !== 1 ? "s" : ""} overdue`,
          remindersSent: remindersSent,
          hasReminders: hasReminders,
          reminderBadge: hasReminders
            ? `${remindersSent} reminder${remindersSent !== 1 ? "s" : ""} sent`
            : null
        };
      });
      this.error = undefined;
    } else if (error) {
      this.error = this.getErrorMessage(error);
      this.overdueInvoices = [];
    }

    this.isLoading = false;
  }

  // ========== COMPUTED PROPERTIES ==========

  get hasOverdueInvoices() {
    return this.overdueInvoices && this.overdueInvoices.length > 0;
  }

  get overdueCount() {
    return this.overdueInvoices ? this.overdueInvoices.length : 0;
  }

  get totalOverdueAmount() {
    if (!this.overdueInvoices || this.overdueInvoices.length === 0) {
      return 0;
    }
    return this.overdueInvoices.reduce(
      (sum, inv) => sum + (inv.Total_Amount__c || 0),
      0
    );
  }

  get showNoDataMessage() {
    return !this.isLoading && !this.error && !this.hasOverdueInvoices;
  }

  get invoiceCountLabel() {
    return this.overdueCount === 1 ? "Invoice" : "Invoices";
  }

  // ========== EVENT HANDLERS ==========

  handleSendReminder(event) {
    const invoiceId = event.target.dataset.id;
    this.sendReminder(invoiceId);
  }

  handleViewInvoice(event) {
    const invoiceId = event.target.dataset.id;
    this.navigateToRecord(invoiceId);
  }

  // ========== HELPER METHODS ==========

  async sendReminder(invoiceId) {
    this.sendingInvoiceIds.add(invoiceId);
    this.overdueInvoices = [...this.overdueInvoices]; // Trigger re-render

    try {
      await sendInvoice({ invoiceId: invoiceId });

      this.showToast("Success", "Reminder sent successfully", "success");

      // Refresh data
      return await refreshApex(this.wiredResult);
    } catch (error) {
      this.showToast("Error", this.getErrorMessage(error), "error");
      return undefined;
    } finally {
      this.sendingInvoiceIds.delete(invoiceId);
      this.overdueInvoices = [...this.overdueInvoices]; // Trigger re-render
    }
  }

  calculateDaysOverdue(dueDate) {
    if (!dueDate) return 0;

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const due = new Date(dueDate);
    due.setHours(0, 0, 0, 0);

    const diffTime = today - due;
    const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));

    return diffDays > 0 ? diffDays : 0;
  }

  getOverdueClass(daysOverdue) {
    if (daysOverdue > 30) {
      return "slds-badge slds-theme_error";
    }
    if (daysOverdue > 7) {
      return "slds-badge slds-theme_warning";
    }
    return "slds-badge slds-badge_lightest";
  }

  isSending(invoiceId) {
    return this.sendingInvoiceIds.has(invoiceId);
  }

  navigateToRecord(recordId) {
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: recordId,
        actionName: "view"
      }
    });
  }

  showToast(title, message, variant) {
    this.dispatchEvent(
      new ShowToastEvent({
        title: title,
        message: message,
        variant: variant
      })
    );
  }

  getErrorMessage(error) {
    if (error?.body?.message) {
      return error.body.message;
    } else if (error?.message) {
      return error.message;
    } else if (Array.isArray(error?.body)) {
      return error.body.map((e) => e.message).join(", ");
    }
    return "An unknown error occurred. Please try again.";
  }
}

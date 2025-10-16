import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

// Apex methods
import getInvoiceWithRelated from "@salesforce/apex/InvoiceController.getInvoiceWithRelated";

export default class InvoiceManager extends LightningElement {
  @api recordId;
  @api accountId;

  @track invoice = null;
  @track isEditing = false;
  @track isLoading = false;

  // Inizializzazione
  connectedCallback() {
    console.log("Invoice Manager - recordId:", this.recordId);

    if (this.recordId) {
      this.loadData();
    } else if (this.accountId) {
      // Nuova invoice
      this.invoice = {
        Account__c: this.accountId,
        Status__c: "Draft",
        Invoice_Date__c: new Date().toISOString().split("T")[0],
        Due_Date__c: this.calculateDueDate(30),
        Tax_Rate__c: 22 // Default 22% per Italia
      };
      this.isEditing = true;
    }
  }

  // Carica dati
  async loadData() {
    console.log("Loading invoice:", this.recordId);

    try {
      this.isLoading = true;

      const result = await getInvoiceWithRelated({
        invoiceId: this.recordId
      });

      console.log("Invoice loaded:", result);
      this.invoice = result;
    } catch (error) {
      console.error("Load failed:", error);
      const message = error?.body?.message || "Failed to load invoice";
      this.showToast("Error", message, "error");

      // Inizializza con dati vuoti
      this.invoice = {
        Id: this.recordId,
        Status__c: "Draft"
      };
    } finally {
      this.isLoading = false;
    }
  }

  // Handler per success del form
  handleSuccess(event) {
    console.log("Invoice saved successfully:", event.detail);

    this.showToast("Success", "Invoice saved successfully", "success");
    this.isEditing = false;

    // Se era nuovo record, naviga al record creato
    if (!this.recordId && event.detail.id) {
      this.navigateToRecord(event.detail.id);
      return;
    }

    // Ricarica i dati
    this.loadData();
  }

  // Handler per error del form
  handleError(event) {
    console.error("Form error:", event.detail);
    this.showToast("Error", "Failed to save invoice", "error");
  }

  // Handler per submit del form
  handleSubmit(event) {
    console.log("Form submitting:", event.detail.fields);

    // Qui puoi modificare i campi prima del save se necessario
    const fields = event.detail.fields;

    // Se è nuovo record e abbiamo accountId, assicurati che sia settato
    if (!this.recordId && this.accountId) {
      fields.Account__c = this.accountId;
    }
  }

  // Utility per calcolare due date
  calculateDueDate(days) {
    const date = new Date();
    date.setDate(date.getDate() + days);
    return date.toISOString().split("T")[0];
  }

  // Toggle edit mode
  handleEdit() {
    this.isEditing = true;
  }

  handleCancel() {
    this.isEditing = false;
    if (this.recordId) {
      this.loadData();
    }
  }

  // Utility
  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }

  // Getters per template
  get isViewMode() {
    return !this.isEditing && this.invoice;
  }

  get hasData() {
    return this.invoice !== null && this.invoice !== undefined;
  }

  get statusVariant() {
    if (!this.invoice || !this.invoice.Status__c) return "inverse";

    switch (this.invoice.Status__c) {
      case "Paid":
        return "success";
      case "Sent":
        return "warning";
      case "Overdue":
        return "error";
      case "Voided":
        return "error";
      default:
        return "inverse";
    }
  }

  get accountName() {
    if (!this.invoice) return "";
    return this.invoice.Account__r?.Name || "Not set";
  }

  get canEdit() {
    // Non permettere edit se Paid o Voided
    return (
      this.invoice?.Status__c !== "Paid" && this.invoice?.Status__c !== "Voided"
    );
  }

  get paymentTermsLabel() {
    const terms = this.invoice?.Payment_Terms__c;
    switch (terms) {
      case "Net_30":
        return "Net 30";
      case "Net_60":
        return "Net 60";
      case "Due_on_Receipt":
        return "Due on Receipt";
      default:
        return terms || "Not set";
    }
  }
}

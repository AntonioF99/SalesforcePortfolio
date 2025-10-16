/**
 * @description Widget showing Trial subscriptions expiring soon with quick convert action
 * @author Antonio Franco
 * @date 2025-10-08
 */
import { LightningElement, wire, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getExpiringTrialSubscriptions from "@salesforce/apex/SubscriptionController.getExpiringTrialSubscriptions";
import activateSubscription from "@salesforce/apex/SubscriptionController.activateSubscription";

export default class SubscriptionExpiringWidget extends NavigationMixin(
  LightningElement
) {
  // ========== PUBLIC PROPERTIES ==========

  @api daysAhead = 7; // Configurable in App Builder

  // ========== PRIVATE PROPERTIES ==========

  expiringSubscriptions = [];
  isLoading = false;
  error;
  convertingIds = new Set();

  // ========== WIRE METHODS ==========

  @wire(getExpiringTrialSubscriptions, { daysAhead: "$daysAhead" })
  wiredExpiring({ error, data }) {
    this.isLoading = true;

    if (data) {
      this.expiringSubscriptions = data.map((sub) => {
        const daysRemaining = this.calculateDaysRemaining(
          sub.Trial_End_Date__c
        );
        return {
          ...sub,
          AccountName: sub.Account__r?.Name || "N/A",
          PricePlanName: sub.Price_Plan__r?.Name || "N/A",
          daysRemaining: daysRemaining,
          urgencyClass: this.getUrgencyClass(daysRemaining),
          urgencyLabel: this.getUrgencyLabel(daysRemaining)
        };
      });
      this.error = undefined;
    } else if (error) {
      this.error = this.getErrorMessage(error);
      this.expiringSubscriptions = [];
    }

    this.isLoading = false;
  }

  // ========== COMPUTED PROPERTIES ==========

  get hasExpiring() {
    return this.expiringSubscriptions && this.expiringSubscriptions.length > 0;
  }

  get expiringCount() {
    return this.expiringSubscriptions ? this.expiringSubscriptions.length : 0;
  }

  get showNoDataMessage() {
    return !this.isLoading && !this.error && !this.hasExpiring;
  }

  get widgetTitle() {
    return `Trials Expiring in ${this.daysAhead} Days`;
  }

  get trialCountLabel() {
    return this.expiringCount === 1 ? "Trial" : "Trials";
  }

  // ========== EVENT HANDLERS ==========

  handleConvertToPaid(event) {
    const subscriptionId = event.target.dataset.id;
    this.convertToPaid(subscriptionId);
  }

  handleViewSubscription(event) {
    const subscriptionId = event.target.dataset.id;
    this.navigateToRecord(subscriptionId);
  }

  // ========== HELPER METHODS ==========

  async convertToPaid(subscriptionId) {
    this.convertingIds.add(subscriptionId);
    this.expiringSubscriptions = [...this.expiringSubscriptions]; // Trigger re-render

    try {
      await activateSubscription({ subscriptionId: subscriptionId });

      this.showToast(
        "Success",
        "Subscription activated successfully",
        "success"
      );

      // Remove from list
      this.expiringSubscriptions = this.expiringSubscriptions.filter(
        (sub) => sub.Id !== subscriptionId
      );
    } catch (error) {
      this.showToast("Error", this.getErrorMessage(error), "error");
    } finally {
      this.convertingIds.delete(subscriptionId);
    }
  }

  calculateDaysRemaining(trialEndDate) {
    if (!trialEndDate) return 0;

    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const endDate = new Date(trialEndDate);
    endDate.setHours(0, 0, 0, 0);

    const diffTime = endDate - today;
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

    return diffDays >= 0 ? diffDays : 0;
  }

  getUrgencyClass(daysRemaining) {
    if (daysRemaining === 0) {
      return "slds-badge slds-theme_error";
    }
    if (daysRemaining <= 3) {
      return "slds-badge slds-theme_warning";
    }
    return "slds-badge slds-theme_success";
  }

  getUrgencyLabel(daysRemaining) {
    if (daysRemaining === 0) {
      return "Expires today!";
    }
    if (daysRemaining === 1) {
      return "1 day left";
    }
    return `${daysRemaining} days left`;
  }

  isConverting(subscriptionId) {
    return this.convertingIds.has(subscriptionId);
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

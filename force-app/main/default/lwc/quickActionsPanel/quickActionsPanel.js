/**
 * @description Lightning Web Component for rapid actions on Invoice and Subscription records
 * @author Antonio Franco
 * @date 2025-10-08
 */
import { LightningElement, api } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from 'lightning/confirm';

// Invoice Apex methods
import sendInvoice from '@salesforce/apex/InvoiceController.sendInvoice';
import markAsPaid from '@salesforce/apex/InvoiceController.markAsPaid';

// Subscription Apex methods
import activateSubscription from '@salesforce/apex/SubscriptionController.activateSubscription';
import cancelSubscription from '@salesforce/apex/SubscriptionController.cancelSubscription';

export default class QuickActionsPanel extends LightningElement {
    // ========== PUBLIC PROPERTIES ==========

    /**
     * Record ID - auto-populated when on record page
     */
    @api recordId;

    /**
     * Object API name - auto-populated when on record page
     */
    @api objectApiName;

    // ========== PRIVATE PROPERTIES ==========

    /**
     * Current status - will be fetched via getRecord
     */
    currentStatus;

    // ========== PRIVATE PROPERTIES ==========

    /**
     * Loading states for each button
     */
    isSendingInvoice = false;
    isMarkingPaid = false;
    isActivating = false;
    isCancelling = false;

    /**
     * Cancellation reason input
     */
    cancellationReason = '';

    /**
     * Show cancellation modal
     */
    showCancellationModal = false;

    // ========== COMPUTED PROPERTIES ==========

    /**
     * Check if this is an invoice record
     * @returns {Boolean}
     */
    get isInvoice() {
        return this.objectApiName === 'Invoice__c';
    }

    /**
     * Check if this is a subscription record
     * @returns {Boolean}
     */
    get isSubscription() {
        return this.objectApiName === 'Subscription__c';
    }

    /**
     * Get status field API name based on object type
     * @returns {String}
     */
    get statusFieldName() {
        return `${this.objectApiName}.Status__c`;
    }

    /**
     * Check if "Send Invoice" button should be disabled
     * @returns {Boolean}
     */
    get isSendButtonDisabled() {
        return (
            this.isSendingInvoice ||
            this.currentStatus === 'Paid' ||
            this.currentStatus === 'Sent' ||
            this.currentStatus === 'Voided'
        );
    }

    /**
     * Check if "Mark as Paid" button should be disabled
     * @returns {Boolean}
     */
    get isPaidButtonDisabled() {
        return (
            this.isMarkingPaid ||
            this.currentStatus === 'Paid' ||
            this.currentStatus === 'Voided' ||
            this.currentStatus === 'Draft'
        );
    }

    /**
     * Check if "Activate" button should be disabled
     * @returns {Boolean}
     */
    get isActivateButtonDisabled() {
        return (
            this.isActivating ||
            this.currentStatus === 'Active' ||
            this.currentStatus === 'Cancelled'
        );
    }

    /**
     * Check if "Cancel" button should be disabled
     * @returns {Boolean}
     */
    get isCancelButtonDisabled() {
        return (
            this.isCancelling ||
            this.currentStatus === 'Cancelled'
        );
    }

    /**
     * Check if any action is in progress
     * @returns {Boolean}
     */
    get isAnyActionInProgress() {
        return (
            this.isSendingInvoice ||
            this.isMarkingPaid ||
            this.isActivating ||
            this.isCancelling
        );
    }

    // ========== INVOICE ACTION HANDLERS ==========

    /**
     * Handle "Send Invoice" button click
     */
    async handleSendInvoice() {
        this.isSendingInvoice = true;

        try {
            await sendInvoice({ invoiceId: this.recordId });

            this.showSuccessToast('Invoice sent successfully');

            // Refresh the page to show updated status
            this.refreshPage();
        } catch (error) {
            this.showErrorToast('Failed to send invoice', this.getErrorMessage(error));
            console.error('Error sending invoice:', error);
        } finally {
            this.isSendingInvoice = false;
        }
    }

    /**
     * Handle "Mark as Paid" button click
     */
    async handleMarkAsPaid() {
        // Show confirmation dialog
        const result = await LightningConfirm.open({
            message: 'Are you sure you want to mark this invoice as paid? This will set the balance to zero.',
            variant: 'default',
            label: 'Confirm Payment',
            theme: 'success'
        });

        if (!result) {
            return; // User cancelled
        }

        this.isMarkingPaid = true;

        try {
            await markAsPaid({ invoiceId: this.recordId });

            this.showSuccessToast('Invoice marked as paid');

            // Refresh the page to show updated status
            this.refreshPage();
        } catch (error) {
            this.showErrorToast('Failed to mark invoice as paid', this.getErrorMessage(error));
            console.error('Error marking invoice as paid:', error);
        } finally {
            this.isMarkingPaid = false;
        }
    }

    // ========== SUBSCRIPTION ACTION HANDLERS ==========

    /**
     * Handle "Activate" button click
     */
    async handleActivate() {
        // Show confirmation dialog
        const result = await LightningConfirm.open({
            message: 'Are you sure you want to activate this subscription?',
            variant: 'default',
            label: 'Confirm Activation',
            theme: 'success'
        });

        if (!result) {
            return; // User cancelled
        }

        this.isActivating = true;

        try {
            await activateSubscription({ subscriptionId: this.recordId });

            this.showSuccessToast('Subscription activated successfully');

            // Refresh the page to show updated status
            this.refreshPage();
        } catch (error) {
            this.showErrorToast('Failed to activate subscription', this.getErrorMessage(error));
            console.error('Error activating subscription:', error);
        } finally {
            this.isActivating = false;
        }
    }

    /**
     * Handle "Cancel" button click - opens modal
     */
    handleCancelClick() {
        this.showCancellationModal = true;
    }

    /**
     * Handle cancellation modal close
     */
    handleCancelModalClose() {
        this.showCancellationModal = false;
        this.cancellationReason = '';
    }

    /**
     * Handle cancellation reason input change
     */
    handleReasonChange(event) {
        this.cancellationReason = event.target.value;
    }

    /**
     * Handle subscription cancellation confirmation
     */
    async handleCancelConfirm() {
        if (!this.cancellationReason || this.cancellationReason.trim().length === 0) {
            this.showErrorToast('Cancellation reason is required', 'Please provide a reason for cancellation.');
            return;
        }

        this.isCancelling = true;
        this.showCancellationModal = false;

        try {
            await cancelSubscription({
                subscriptionId: this.recordId,
                reason: this.cancellationReason
            });

            this.showSuccessToast('Subscription cancelled successfully');

            // Refresh the page to show updated status
            this.refreshPage();
        } catch (error) {
            this.showErrorToast('Failed to cancel subscription', this.getErrorMessage(error));
            console.error('Error cancelling subscription:', error);
        } finally {
            this.isCancelling = false;
            this.cancellationReason = '';
        }
    }

    // ========== HELPER METHODS ==========

    /**
     * Show success toast notification
     * @param {String} message - Success message
     */
    showSuccessToast(message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: message,
                variant: 'success'
            })
        );
    }

    /**
     * Show error toast notification
     * @param {String} title - Error title
     * @param {String} message - Error message
     */
    showErrorToast(title, message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: 'error',
                mode: 'sticky'
            })
        );
    }

    /**
     * Extract user-friendly error message from Apex error
     * @param {Object} error - Error object from Apex call
     * @returns {String} User-friendly error message
     */
    getErrorMessage(error) {
        if (error?.body?.message) {
            return error.body.message;
        } else if (error?.message) {
            return error.message;
        } else if (Array.isArray(error?.body)) {
            return error.body.map(e => e.message).join(', ');
        }
        return 'An unknown error occurred. Please try again or contact your administrator.';
    }

    /**
     * Refresh the page to show updated data
     */
    refreshPage() {
        // Use eval to refresh the page without navigation
        // This is safe in Lightning context
        // eslint-disable-next-line no-eval
        eval("$A.get('e.force:refreshView').fire();");
    }
}

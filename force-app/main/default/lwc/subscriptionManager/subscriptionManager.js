import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// Apex methods
import getSubscriptionWithRelated from '@salesforce/apex/SubscriptionController.getSubscriptionWithRelated';

export default class SubscriptionManager extends LightningElement {
    @api recordId;
    @api accountId;
    
    @track subscription = null;
    @track isEditing = false;
    @track isLoading = false;
    
    // Inizializzazione
    connectedCallback() {
        console.log('Component init - recordId:', this.recordId);
        
        if (this.recordId) {
            this.loadData();
        } else if (this.accountId) {
            // Nuovo record - entra in edit mode
            this.isEditing = true;
        }
    }
    
    // Carica dati
    async loadData() {
        console.log('Loading subscription:', this.recordId);
        
        try {
            this.isLoading = true;
            
            const result = await getSubscriptionWithRelated({ 
                subscriptionId: this.recordId 
            });
            
            console.log('Loaded data:', result);
            this.subscription = result;
            
        } catch (error) {
            console.error('Load failed:', error);
            const message = error?.body?.message || error?.message || 'Failed to load subscription';
            this.showToast('Error', message, 'error');
        } finally {
            this.isLoading = false;
        }
    }
    
    // Handler per success del form
    handleSuccess(event) {
        console.log('Form saved successfully:', event.detail);
        
        this.showToast('Success', 'Subscription saved successfully', 'success');
        this.isEditing = false;
        
        // Se era nuovo record, ora abbiamo l'ID
        if (!this.recordId && event.detail.id) {
            this.recordId = event.detail.id;
        }
        
        // Ricarica i dati
        this.loadData();
    }
    
    // Handler per error del form
    handleError(event) {
        console.error('Form error:', event.detail);
        this.showToast('Error', 'Failed to save subscription', 'error');
    }
    
    // Handler per submit del form
    handleSubmit(event) {
        console.log('Form submitting:', event.detail.fields);
        
        // Qui puoi modificare i campi prima del save se necessario
        const fields = event.detail.fields;
        
        // Se è nuovo record e abbiamo accountId, assicurati che sia settato
        if (!this.recordId && this.accountId) {
            fields.Account__c = this.accountId;
        }
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
        return !this.isEditing && this.subscription;
    }
    
    get hasData() {
        return this.subscription !== null && this.subscription !== undefined;
    }
    
    get statusVariant() {
        if (!this.subscription || !this.subscription.Status__c) return 'inverse';
        
        switch(this.subscription.Status__c) {
            case 'Active': return 'success';
            case 'Trial': return 'warning';
            case 'Cancelled': return 'error';
            default: return 'inverse';
        }
    }
    
    get accountName() {
        if (!this.subscription) return '';
        return this.subscription.Account__r?.Name || 'Not set';
    }
    
    get pricePlanName() {
        if (!this.subscription) return '';
        return this.subscription.Price_Plan__r?.Name || 'Not set';
    }
    
    get showTrialFields() {
        return this.subscription?.Status__c === 'Trial';
    }
    
    get showCancellationFields() {
        return this.subscription?.Status__c === 'Cancelled' || 
               this.subscription?.Status__c === 'Suspended';
    }
}
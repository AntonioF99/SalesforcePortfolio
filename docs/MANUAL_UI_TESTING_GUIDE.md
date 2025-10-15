# Manual UI Testing Guide

Guida completa per testare manualmente tutti i workflow dell'applicazione dall'interfaccia Salesforce, basata sull'implementazione reale del codice.

## Prerequisiti

1. Login a Salesforce con profilo **System Administrator**
2. Accedere all'App **Subscription Management**
3. Avere almeno un Account esistente con Type = "B2B" o "B2C"
4. Avere almeno un **Price Plan** configurato:
   - **Unit Price**: > 0 (es. 100.00)
   - **Billing Frequency**: Monthly, Quarterly, Semi-Annual, o Annual
   - **Currency Code**: EUR o USD
   - **Trial Days**: 14 (opzionale)

### Setup Rapido Price Plan (se non esiste)

1. Navigare a **Price Plans** tab
2. Click **New**
3. Compilare:
   - **Name**: "Professional Plan"
   - **Unit Price**: 100.00
   - **Billing Frequency**: Monthly
   - **Currency Code**: EUR
   - **Category**: Standard
4. Click **Save**

---

## 📋 Indice dei Test

1. [Subscription: Creazione e Attivazione (Trial → Active)](#1-subscription-creazione-e-attivazione-trial--active)
2. [Subscription: Cancellazione con Permessi](#2-subscription-cancellazione-con-permessi)
3. [Invoice: Generazione Automatica da Subscription](#3-invoice-generazione-automatica-da-subscription)
4. [Invoice: Workflow Overdue e Reminder](#4-invoice-workflow-overdue-e-reminder)
5. [Invoice: Workflow Pagamento](#5-invoice-workflow-pagamento)
6. [Account Rollup Fields](#6-account-rollup-fields)
7. [Batch Jobs Automation](#7-batch-jobs-automation)
8. [Dashboard LWC](#8-dashboard-lwc)

---

## 1. Subscription: Creazione e Attivazione (Trial → Active)

**Obiettivo**: Testare il workflow completo Trial → Active con generazione automatica Invoice.

### Step 1.1: Creare Subscription in Trial

1. Navigare a **Subscriptions** tab
2. Click su **New**
3. Compilare:
   - **Account**: Selezionare un account esistente (es. "Acme Corporation")
   - **Price Plan**: Selezionare "Professional Plan" (deve avere Unit Price > 0 e Billing Frequency = Monthly)
   - **Status**: `Trial`
   - **Start Date**: Data di oggi
   - **Trial End Date**: Oggi + 14 giorni
   - **Quantity**: 1
4. Click **Save**

> **Nota**: Il campo `Billing Frequency` è sul **Price Plan**, non sulla Subscription. Viene ereditato automaticamente dal Price Plan selezionato.

**✅ Verifiche Immediate**:
- Subscription creata con Status = `Trial`
- Refresh della pagina per vedere i campi formula (MRR, ARR, etc.)
- **NON** viene generata alcuna Invoice (le trial non generano invoice)

**✅ Verifiche Automation Service** (dalla classe `SubscriptionAutomationService`):
- Vai alla Related List **Open Activities** o **Tasks**
- Verifica che sono state create **3 Task di onboarding**:
  1. "Welcome Call - [Account Name]" (ActivityDate = oggi + 1 giorno, Priority = High)
  2. "Week 1 Check-in - [Account Name]" (ActivityDate = oggi + 7 giorni, Priority = Normal)
  3. "Month 1 Success Review - [Account Name]" (ActivityDate = oggi + 30 giorni, Priority = Normal)

**✅ Verifiche Account Updates**:
- Aprire l'Account associato
- Controllare campi:
  - **Subscription Status**: `Trial Customer`
  - **Health Score**: 75
  - **Last Subscription Date**: Data di oggi

### Step 1.2: Attivare Subscription (Trigger Invoice Generation)

1. Aprire la Subscription in Trial
2. Click **Edit**
3. Modificare:
   - **Status**: Cambiare da `Trial` a `Active`
   - **End Date**: Oggi + 365 giorni
4. Click **Save**

**✅ Verifiche Automation** (dalla classe `SubscriptionAutomationService.generateInvoicesForActiveSubscriptions`):

1. **Invoice Generata Automaticamente**:
   - Scorrere alla Related List **Invoices**
   - Deve esserci 1 Invoice con:
     - **Status**: `Draft`
     - **Invoice Date**: Data di oggi
     - **Payment Terms**: `Net 30`
     - **Account**: Stesso account della subscription

2. **Invoice Line Item Generato**:
   - Aprire l'Invoice generata
   - Scorrere alla Related List **Invoice Line Items**
   - Deve esserci 1 Line Item con:
     - **Subscription**: Link alla subscription attivata
     - **Type**: `Add-On`
     - **Quantity**: 1 (o valore dalla subscription)
     - **Unit Price**: Valore dal Price Plan
     - **Period Start**: Data di oggi
     - **Period End**: Fine del periodo (es. oggi + 30 giorni per Monthly)
     - **Status**: `Active`

3. **Account Updated**:
   - **Subscription Status**: `Active Customer`
   - **Health Score**: 100

4. **Task Created**:
   - Controllare Tasks
   - "Subscription Activated - [Account Name]" (Priority = Normal)

**✅ Verifiche Campi Formula Invoice**:
- **Subtotal**: Somma automatica dei Line Items (Rollup Summary Field)
- **Tax Amount**: Calcolato da formula (Subtotal * Tax Rate / 100)
- **Total Amount**: Subtotal + Tax Amount

---

## 2. Subscription: Cancellazione con Permessi

**Obiettivo**: Testare validazioni di sicurezza e cancellazione.

### Step 2.1: Cancellazione con Permessi (System Admin)

**Prerequisito**: Login come **System Administrator**

1. Aprire Subscription attiva
2. Click **Edit**
3. Modificare:
   - **Status**: `Cancelled`
   - **Cancellation Reason**: (dipende dal RecordType Account):
     - Per B2B: "Budget Constraints", "Service Not Needed", "Switching to Competitor"
     - Per B2C: "Too Expensive", "Service Not Needed", "Technical Issues"
   - **Cancellation Date**: Data di oggi
   - **Cancellation Comments**: "Test cancellation"
4. Click **Save**

**✅ Verifiche**:
1. **Subscription Updated**:
   - Status = `Cancelled`
   - Cancellation Date = Oggi
   - Cancellation Reason popolato

2. **Task Created** (da `SubscriptionAutomationService.processStatusChanges`):
   - Subject: "Subscription Cancelled - [Account Name]"
   - Description: "Subscription cancelled. Schedule exit interview..."
   - Priority: `High`
   - ActivityDate: Oggi

3. **Account Updated**:
   - **Subscription Status**: `Former Customer`
   - **Health Score**: 0

4. **Immutabilità**:
   - Tentare di modificare di nuovo la subscription
   - Errore: "Cannot modify cancelled subscriptions"

---

## 3. Invoice: Generazione Automatica da Subscription

**Obiettivo**: Verificare che le invoice NON vengono duplicate per lo stesso periodo.

### Step 3.1: Tentare Generazione Duplicata

1. Aprire una Subscription **Active** che ha già generato un'invoice questo mese
2. Click **Edit**
3. Modificare un campo NON critico (es. Quantity +1)
4. Click **Save**

**✅ Verifica Duplicate Prevention**:
- Controllare Related List **Invoices**
- Deve esserci ancora **1 sola Invoice** per il periodo corrente
- NON deve essere generata una seconda invoice

---

## 4. Invoice: Workflow Overdue e Reminder

**Obiettivo**: Testare gestione invoice scadute e invio reminder.

### Step 4.1: Creare Invoice Overdue (Manualmente)

1. Navigare a **Invoices** tab
2. Click **New**
3. Compilare:
   - **Account**: Acme Corporation
   - **Invoice Date**: 60 giorni fa
   - **Due Date**: 30 giorni fa (nel passato!)
   - **Status**: `Draft`
   - **Payment Terms**: `Net 30`
4. Click **Save**

5. **Aggiungere Line Item**:
   - Dalla Related List **Invoice Line Items**, click **New**
   - Compilare:
     - **Description**: "Test Service"
     - **Quantity**: 1
     - **Unit Price**: 500.00
   - Click **Save**

6. **Cambiare Status a Overdue**:
   - Tornare all'Invoice
   - Click **Edit**
   - **Status**: `Overdue`
   - Click **Save**

**✅ Verifiche Automation**:
- Task creata:
  - Subject: "URGENT: Overdue Payment - [Account Name]"
  - Priority: `High`
  - ActivityDate: Oggi

---

## 5. Invoice: Workflow Pagamento

**Obiettivo**: Marcare invoice come pagata.

### Step 5.1: Mark as Paid Manualmente

**Prerequisito**: Invoice in Status = `Sent` o `Overdue`

1. Aprire l'Invoice
2. Click **Edit**
3. Modificare:
   - **Status**: `Paid`
   - **Balance Due**: 0
4. Click **Save**

**✅ Verifiche**:
1. **Task Created**:
   - Subject: "Payment Received - Thank [Account Name]"
   - Priority: `Normal`
   - ActivityDate: Oggi + 1 giorno

---

## 6. Account Rollup Fields

**Obiettivo**: Verificare che i campi rollup dell'Account si aggiornano automaticamente.

### Step 6.1: Verificare Invoice Rollup

1. Aprire un **Account** che ha almeno 2-3 Invoice
2. Controllare:
   - **Total Billed**: Somma di tutte le invoice con Status != `Voided`
   - **Invoice Count**: COUNT delle invoice
   - **Average Invoice Amount**: Total Billed / Invoice Count

**✅ Test Dinamico**:
1. Annotare i valori attuali
2. Creare una nuova Invoice:
   - Status: `Sent`
   - Total Amount: 1000.00 (aggiungere line item)
3. Salvare
4. **Refresh** la pagina dell'Account
5. **Verifiche**:
   - **Total Billed** incrementato di 1000.00
   - **Invoice Count** incrementato di 1
   - **Average Invoice Amount** ricalcolato

### Step 6.2: Verificare Subscription Rollup

1. Aprire un **Account**
2. Controllare:
   - **Subscription Status**:
     - `Active Customer` se ha subscription Active
     - `Trial Customer` se solo Trial
     - `At Risk` se Suspended
     - `Former Customer` se solo Cancelled
   - **Health Score**:
     - 100 = Active Customer
     - 75 = Trial Customer
     - 25 = At Risk
     - 0 = Former Customer

**✅ Test Dinamico**:
1. Account con subscription `Active` → Health Score = 100
2. Modificare subscription a `Suspended` → Health Score = 25
3. Modificare a `Cancelled` → Health Score = 0

---

## 7. Batch Jobs Automation

**Obiettivo**: Testare il batch job schedulato unificato.

### Step 7.1: DailyMaintenanceBatch

Il `DailyMaintenanceBatch` gestisce sia le invoice scadute che le trial expirate in un unico job.

**Test Manuale via Developer Console**:

1. **Setup dati test**:
   - Creare Invoice: Status = `Sent`, Due Date = 5 giorni fa, Balance Due = 100.00
   - Creare Subscription: Status = `Trial`, Trial End Date = 5 giorni fa

2. Aprire **Developer Console** → **Debug** → **Execute Anonymous**

3. Eseguire:
```apex
DailyMaintenanceBatch batch = new DailyMaintenanceBatch();
Database.executeBatch(batch, 200);
```

4. **Verifiche Invoice Overdue**:
   - Invoice cambiata a Status = `Overdue`
   - Task creata

5. **Verifiche Trial Expiration**:
   - Subscription:
     - Status: `Cancelled`
     - Cancellation Reason: `Trial Expired`
     - Cancellation Date: TODAY

---

## 8. Dashboard LWC

**Obiettivo**: Verificare componenti LWC.

### Step 8.1: Invoice Overdue Dashboard

1. Navigare alla Home Page
2. Localizzare **Invoice Overdue Dashboard**

**✅ Verifiche**:
- Mostra invoice con Status = `Overdue`
- Limite: 50 record
- Fields: Invoice Name, Account Name, Due Date, Total Amount

### Step 8.2: Subscription Expiring Widget

1. Localizzare **Subscription Expiring Widget**

**✅ Verifiche**:
- Mostra Trial subscription con Trial End Date < oggi + 7 giorni
- Limite: 50 record

---

## 📊 Checklist Completa Test

### Subscription Workflows
- [ ] Creazione Trial (genera 3 onboarding tasks)
- [ ] Attivazione Trial → Active (genera Invoice + Line Item)
- [ ] Duplicate prevention (no 2 invoice stesso mese)
- [ ] Cancellazione con Cancellation Reason
- [ ] Status terminale immutabile (Cancelled)
- [ ] Batch Trial Expiration

### Invoice Workflows
- [ ] Generazione automatica da Subscription Active
- [ ] Calcolo Subtotal (Rollup Summary)
- [ ] Calcolo Tax Amount (Formula)
- [ ] Mark as Paid
- [ ] Invoice Overdue automation
- [ ] Batch Invoice Overdue

### Account Rollup Fields
- [ ] Total Billed real-time update
- [ ] Invoice Count update
- [ ] Subscription Status update
- [ ] Health Score 0-100

### LWC Components
- [ ] Invoice Overdue Dashboard
- [ ] Subscription Expiring Widget

---

## 🐛 Troubleshooting

### Invoice non generata dopo attivazione
**Soluzione**: Verificare Price Plan con Unit Price > 0

### Rollup fields non aggiornano
**Soluzione**: Refresh manuale pagina Account

### Batch job non schedula
**Soluzione**: Controllare Setup → Scheduled Jobs

---

## 📝 Note Finali

- **Ambiente**: Sempre in **Sandbox** o **Developer Org**
- **Tempo stimato**: 2-3 ore per testing completo
- **Rollup fields**: Aggiornamenti real-time via trigger handlers
- **Email**: Gestite via Flow (non Apex)

**Coverage**: 100% workflow implementati

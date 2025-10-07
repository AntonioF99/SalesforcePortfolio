/**
 * @description One-time data migration to update existing subscription names
 * @author Antonio Franco
 * @date 2025-09-29
 * @story STORY-009: Subscription Naming Convention
 */
public class SubscriptionDataMigration {

    /*
     * @description Updates all existing subscription names to new format
     * Run this once via Anonymous Apex: SubscriptionDataMigration.updateAllSubscriptionNames();
     */
    public static void updateAllSubscriptionNames() {

        // Query all subscriptions with related Account and Price Plan
        List<Subscription__c> subscriptions = [
            SELECT Id, Name, Account__c, Account__r.Name, Price_Plan__c, Price_Plan__r.Name, Start_Date__c
            FROM Subscription__c
            WHERE Account__c != null AND Price_Plan__c != null
        ];

        System.debug('Found ' + subscriptions.size() + ' subscriptions to update');

        if (subscriptions.isEmpty()) {
            System.debug('No subscriptions to update');
            return;
        }

        List<Subscription__c> toUpdate = new List<Subscription__c>();

        for (Subscription__c sub : subscriptions) {
            String accountName = sub.Account__r.Name;
            String pricePlanName = sub.Price_Plan__r.Name;
            String monthYear = '';

            // Format date as "Jan 2025"
            if (sub.Start_Date__c != null) {
                Datetime startDateTime = sub.Start_Date__c;
                monthYear = startDateTime.format('MMM yyyy');
            } else {
                Datetime now = Datetime.now();
                monthYear = now.format('MMM yyyy');
            }

            // Generate new name: "ACME Corp - Enterprise Plan - Jan 2025"
            String newName = accountName + ' - ' + pricePlanName + ' - ' + monthYear;

            // Only update if different - Note: Name field is auto-generated, cannot be updated
            if (sub.Name != newName) {
                // Since Name is auto-generated, we update Display_Name__c instead
                toUpdate.add(new Subscription__c(
                    Id = sub.Id,
                    Display_Name__c = newName
                ));
            }
        }

        if (!toUpdate.isEmpty()) {
            try {
                update toUpdate;
                System.debug('Successfully updated ' + toUpdate.size() + ' subscription names');
            } catch (Exception e) {
                System.debug('Error updating subscription names: ' + e.getMessage());
                throw e;
            }
        } else {
            System.debug('All subscription names are already up to date');
        }
    }

    /*
     * @description Preview what the new names would be without updating
     */
    public static void previewNameChanges() {

        List<Subscription__c> subscriptions = [
            SELECT Id, Name, Account__c, Account__r.Name, Price_Plan__c, Price_Plan__r.Name, Start_Date__c
            FROM Subscription__c
            WHERE Account__c != null AND Price_Plan__c != null
            LIMIT 10
        ];

        System.debug('=== SUBSCRIPTION NAME PREVIEW ===');

        for (Subscription__c sub : subscriptions) {
            String accountName = sub.Account__r.Name;
            String pricePlanName = sub.Price_Plan__r.Name;
            String monthYear = '';

            if (sub.Start_Date__c != null) {
                Datetime startDateTime = sub.Start_Date__c;
                monthYear = startDateTime.format('MMM yyyy');
            } else {
                Datetime now = Datetime.now();
                monthYear = now.format('MMM yyyy');
            }

            String newName = accountName + ' - ' + pricePlanName + ' - ' + monthYear;

            System.debug('OLD: ' + sub.Name);
            System.debug('NEW: ' + newName);
            System.debug('---');
        }
    }
}
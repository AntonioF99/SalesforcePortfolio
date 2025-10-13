// Update the 4 remaining CRM Price Plans with Category and Prices

List<Price_Plan__c> plans = [
    SELECT Id, Name, Unit_Price__c, Category__c, Billing_Frequency__c
    FROM Price_Plan__c
    WHERE Name LIKE 'CRM%'
    ORDER BY Name
];

System.debug('Found ' + plans.size() + ' CRM plans');

for (Price_Plan__c plan : plans) {
    plan.Category__c = 'CRM Base';

    if (plan.Name.contains('Professional') && plan.Billing_Frequency__c == 'Monthly') {
        plan.Unit_Price__c = 49;
        System.debug('Updated: ' + plan.Name + ' = €49/month');
    }
    else if (plan.Name.contains('Professional') && plan.Billing_Frequency__c == 'Annual') {
        plan.Unit_Price__c = 490;
        System.debug('Updated: ' + plan.Name + ' = €490/year');
    }
    else if (plan.Name.contains('Enterprise') && plan.Billing_Frequency__c == 'Monthly') {
        plan.Unit_Price__c = 99;
        System.debug('Updated: ' + plan.Name + ' = €99/month');
    }
    else if (plan.Name.contains('Enterprise') && plan.Billing_Frequency__c == 'Annual') {
        plan.Unit_Price__c = 990;
        System.debug('Updated: ' + plan.Name + ' = €990/year');
    }
}

update plans;
System.debug('✅ Updated ' + plans.size() + ' Price Plans with Category and prices');

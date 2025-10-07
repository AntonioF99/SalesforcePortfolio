// Anonymous Apex Script to Discover Invoice Line Item Fields and Insert Test Data
// Execute in Developer Console > Debug > Open Execute Anonymous Apex

// First, discover what fields actually exist in Invoice_Line_Item__c
System.debug('=== DISCOVERING INVOICE LINE ITEM FIELDS ===');
Schema.SObjectType lineItemType = Invoice_Line_Item__c.SObjectType;
Schema.DescribeSObjectResult lineItemDescribe = lineItemType.getDescribe();
Map<String, Schema.SObjectField> fieldMap = lineItemDescribe.fields.getMap();

System.debug('All writable Invoice Line Item fields:');
for (String fieldName : fieldMap.keySet()) {
    Schema.DescribeFieldResult fieldDescribe = fieldMap.get(fieldName).getDescribe();
    if (fieldDescribe.isCreateable() && fieldDescribe.isUpdateable() && fieldDescribe.isCustom()) {
        System.debug('- ' + fieldDescribe.getName() + ' (' + fieldDescribe.getLabel() + ') - Type: ' + fieldDescribe.getType());
    }
}

// Get Invoice and Product IDs from existing data
Map<String, Id> invoiceMap = new Map<String, Id>();
for (Invoice__c inv : [SELECT Id, Name FROM Invoice__c ORDER BY CreatedDate DESC LIMIT 10]) {
    invoiceMap.put(inv.Name, inv.Id);
}

Map<String, Id> productMap = new Map<String, Id>();
for (Product__c prod : [SELECT Id, Product_Code__c, Name FROM Product__c]) {
    productMap.put(prod.Product_Code__c, prod.Id);
}

System.debug('Available invoices: ' + invoiceMap.keySet());
System.debug('Available products by code: ' + productMap.keySet());

List<String> availableInvoices = new List<String>(invoiceMap.keySet());
List<String> availableProducts = new List<String>(productMap.keySet());

// Test basic field accessibility
System.debug('=== TESTING BASIC FIELD ACCESS ===');
List<String> basicFields = new List<String>{
    'Invoice__c', 'Product__c', 'Description__c', 'Quantity__c', 'Unit_Price__c'
};

for (String field : basicFields) {
    if (fieldMap.containsKey(field)) {
        Schema.DescribeFieldResult fieldDesc = fieldMap.get(field).getDescribe();
        System.debug(field + ' - EXISTS, Type: ' + fieldDesc.getType() + ', Required: ' + (!fieldDesc.isNillable()));
    } else {
        System.debug(field + ' - DOES NOT EXIST');
    }
}

// Create Invoice Line Items with only confirmed safe fields
List<Invoice_Line_Item__c> lineItems = new List<Invoice_Line_Item__c>();

// Only proceed if we have invoices and products
if (availableInvoices.size() > 0 && availableProducts.size() > 0) {
    
    // Line item 1 - Use first invoice and first product
    Invoice_Line_Item__c item1 = new Invoice_Line_Item__c(
        Invoice__c = invoiceMap.get(availableInvoices[0])
    );
    
    // Add fields conditionally based on existence
    if (fieldMap.containsKey('Product__c') && availableProducts.size() > 0) {
        item1.put('Product__c', productMap.get(availableProducts[0]));
    }
    
    if (fieldMap.containsKey('Description__c')) {
        item1.put('Description__c', 'Test Product Line Item');
    }
    
    if (fieldMap.containsKey('Quantity__c')) {
        item1.put('Quantity__c', 1);
    }
    
    if (fieldMap.containsKey('Unit_Price__c')) {
        item1.put('Unit_Price__c', 99.00);
    }
    
    lineItems.add(item1);
    
    // Line item 2 - Use second invoice if available
    if (availableInvoices.size() > 1) {
        Invoice_Line_Item__c item2 = new Invoice_Line_Item__c(
            Invoice__c = invoiceMap.get(availableInvoices[1])
        );
        
        if (fieldMap.containsKey('Product__c') && availableProducts.size() > 1) {
            item2.put('Product__c', productMap.get(availableProducts[1]));
        }
        
        if (fieldMap.containsKey('Description__c')) {
            item2.put('Description__c', 'Second Product Line Item');
        }
        
        if (fieldMap.containsKey('Quantity__c')) {
            item2.put('Quantity__c', 2);
        }
        
        if (fieldMap.containsKey('Unit_Price__c')) {
            item2.put('Unit_Price__c', 199.00);
        }
        
        lineItems.add(item2);
    }
    
    // Line item 3 - Third invoice if available
    if (availableInvoices.size() > 2) {
        Invoice_Line_Item__c item3 = new Invoice_Line_Item__c(
            Invoice__c = invoiceMap.get(availableInvoices[2])
        );
        
        if (fieldMap.containsKey('Product__c') && availableProducts.size() > 2) {
            item3.put('Product__c', productMap.get(availableProducts[2]));
        }
        
        if (fieldMap.containsKey('Description__c')) {
            item3.put('Description__c', 'Third Product Line Item');
        }
        
        if (fieldMap.containsKey('Quantity__c')) {
            item3.put('Quantity__c', 1);
        }
        
        if (fieldMap.containsKey('Unit_Price__c')) {
            item3.put('Unit_Price__c', 299.00);
        }
        
        lineItems.add(item3);
    }
}

// Insert the line items
if (lineItems.size() > 0) {
    try {
        insert lineItems;
        System.debug('Successfully inserted ' + lineItems.size() + ' invoice line item records');
        
        // Query back to see what was created
        String queryFields = 'SELECT Id, Name, Invoice__c, Invoice__r.Name';
        if (fieldMap.containsKey('Product__c')) queryFields += ', Product__c, Product__r.Name';
        if (fieldMap.containsKey('Description__c')) queryFields += ', Description__c';
        if (fieldMap.containsKey('Quantity__c')) queryFields += ', Quantity__c';
        if (fieldMap.containsKey('Unit_Price__c')) queryFields += ', Unit_Price__c';
        queryFields += ' FROM Invoice_Line_Item__c WHERE Id IN :lineItems';
        
        List<Invoice_Line_Item__c> insertedItems = Database.query(queryFields);
        for (Invoice_Line_Item__c item : insertedItems) {
            System.debug('Line Item: ' + item.Name + ' | Invoice: ' + item.Invoice__r.Name);
        }
        
        System.debug('=== LINE ITEMS IMPORT COMPLETED SUCCESSFULLY ===');
        
    } catch (Exception e) {
        System.debug('Error inserting line items: ' + e.getMessage());
        System.debug('Stack trace: ' + e.getStackTraceString());
    }
} else {
    System.debug('No line items to insert - missing invoices or products');
}

System.debug('Invoice Line Items discovery script completed');
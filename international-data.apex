// ========== SCRIPT GENERAZIONE DATI INTERNAZIONALI ==========
// Script per generare account e contatti da varie nazioni

List<Account> accounts = new List<Account>();

// 🇪🇺 EUROPEAN ACCOUNTS
accounts.add(new Account(
    Name = 'ACME Technologies SRL', Type = 'Customer - Direct', NumberOfEmployees = 250,
    BillingStreet = 'Via Roma 123', BillingCity = 'Rome', BillingCountry = 'Italy',
    BillingCountryCode = 'IT', BillingPostalCode = '00156', Phone = '+39 06 1234567',
    Website = 'www.acmetechnologies.com', Industry = 'Technology', AnnualRevenue = 25000000
));

accounts.add(new Account(
    Name = 'Bavarian Motors GmbH', Type = 'Customer - Channel', NumberOfEmployees = 500,
    BillingStreet = 'Hauptstraße 45', BillingCity = 'Munich', BillingCountry = 'Germany',
    BillingCountryCode = 'DE', BillingPostalCode = '80331', Phone = '+49 89 1234567',
    Website = 'www.bavarianmotors.com', Industry = 'Manufacturing', AnnualRevenue = 50000000
));

accounts.add(new Account(
    Name = 'Nordic Solutions AS', Type = 'Prospect', NumberOfEmployees = 150,
    BillingStreet = 'Karl Johans gate 22', BillingCity = 'Oslo', BillingCountry = 'Norway',
    BillingCountryCode = 'NO', BillingPostalCode = '0150', Phone = '+47 22 123456',
    Website = 'www.nordicsolutions.com', Industry = 'Consulting', AnnualRevenue = 15000000
));

accounts.add(new Account(
    Name = 'Amsterdam Digital BV', Type = 'Customer - Direct', NumberOfEmployees = 300,
    BillingStreet = 'Prinsengracht 263', BillingCity = 'Amsterdam', BillingCountry = 'Netherlands',
    BillingCountryCode = 'NL', BillingPostalCode = '1016', Phone = '+31 20 1234567',
    Website = 'www.amsterdamdigital.com', Industry = 'Technology', AnnualRevenue = 30000000
));

accounts.add(new Account(
    Name = 'Barcelona Innovations SL', Type = 'Customer - Direct', NumberOfEmployees = 180,
    BillingStreet = 'Passeig de Gràcia 92', BillingCity = 'Barcelona', BillingCountry = 'Spain',
    BillingCountryCode = 'ES', BillingPostalCode = '08008', Phone = '+34 93 1234567',
    Website = 'www.barcelonainnovations.com', Industry = 'Technology', AnnualRevenue = 18000000
));

// 🌏 ASIAN ACCOUNTS
accounts.add(new Account(
    Name = 'Tokyo Tech Industries', Type = 'Customer - Channel', NumberOfEmployees = 1200,
    BillingStreet = '1-2-3 Shibuya', BillingCity = 'Tokyo', BillingCountry = 'Japan',
    BillingCountryCode = 'JP', BillingPostalCode = '150-0002', Phone = '+81 3 1234 5678',
    Website = 'www.tokyotech.com', Industry = 'Technology', AnnualRevenue = 120000000
));

accounts.add(new Account(
    Name = 'Singapore Digital Hub', Type = 'Customer - Direct', NumberOfEmployees = 400,
    BillingStreet = '1 Marina Bay', BillingCity = 'Singapore', BillingCountry = 'Singapore',
    BillingCountryCode = 'SG', BillingPostalCode = '018956', Phone = '+65 6123 4567',
    Website = 'www.singaporedigital.com', Industry = 'Technology', AnnualRevenue = 40000000
));

accounts.add(new Account(
    Name = 'Osaka Digital Systems', Type = 'Prospect', NumberOfEmployees = 600,
    BillingStreet = '2-3-4 Namba', BillingCity = 'Osaka', BillingCountry = 'Japan',
    BillingCountryCode = 'JP', BillingPostalCode = '542-0076', Phone = '+81 6 1234 5678',
    Website = 'www.osakadigital.com', Industry = 'Technology', AnnualRevenue = 60000000
));

// 🌍 AFRICAN ACCOUNTS
accounts.add(new Account(
    Name = 'Cape Town Solutions', Type = 'Customer - Direct', NumberOfEmployees = 120,
    BillingStreet = 'Long Street 456', BillingCity = 'Cape Town', BillingCountry = 'South Africa',
    BillingCountryCode = 'ZA', BillingPostalCode = '8001', Phone = '+27 21 123 4567',
    Website = 'www.capetownsolutions.com', Industry = 'Consulting', AnnualRevenue = 12000000
));

accounts.add(new Account(
    Name = 'Lagos Business Group', Type = 'Prospect', NumberOfEmployees = 200,
    BillingStreet = 'Victoria Island Plaza', BillingCity = 'Lagos', BillingCountry = 'Nigeria',
    BillingCountryCode = 'NG', BillingPostalCode = '101241', Phone = '+234 1 1234567',
    Website = 'www.lagosbusiness.com', Industry = 'Consulting', AnnualRevenue = 20000000
));

// 🌎 AMERICAN ACCOUNTS
accounts.add(new Account(
    Name = 'Silicon Valley Dynamics', Type = 'Customer - Channel', NumberOfEmployees = 800,
    BillingStreet = '123 Market Street', BillingCity = 'San Francisco', BillingCountry = 'United States',
    BillingCountryCode = 'US', BillingPostalCode = '94105', Phone = '+1 415 123 4567',
    Website = 'www.svdynamics.com', Industry = 'Technology', AnnualRevenue = 80000000
));

accounts.add(new Account(
    Name = 'Toronto Maple Systems', Type = 'Customer - Direct', NumberOfEmployees = 350,
    BillingStreet = '100 King Street W', BillingCity = 'Toronto', BillingCountry = 'Canada',
    BillingCountryCode = 'CA', BillingPostalCode = 'M5H 2N2', Phone = '+1 416 123 4567',
    Website = 'www.torontosystems.com', Industry = 'Technology', AnnualRevenue = 35000000
));

accounts.add(new Account(
    Name = 'Mexico City Innovations', Type = 'Prospect', NumberOfEmployees = 150,
    BillingStreet = 'Paseo de la Reforma 250', BillingCity = 'Mexico City', BillingCountry = 'Mexico',
    BillingCountryCode = 'MX', BillingPostalCode = '06600', Phone = '+52 55 1234 5678',
    Website = 'www.mexicocityinnovations.com', Industry = 'Technology', AnnualRevenue = 15000000
));

// 🌎 SOUTH AMERICAN ACCOUNTS
accounts.add(new Account(
    Name = 'São Paulo Tech Ltda', Type = 'Customer - Direct', NumberOfEmployees = 450,
    BillingStreet = 'Avenida Paulista 1578', BillingCity = 'São Paulo', BillingCountry = 'Brazil',
    BillingCountryCode = 'BR', BillingPostalCode = '01310-200', Phone = '+55 11 1234 5678',
    Website = 'www.saopaulotech.com', Industry = 'Technology', AnnualRevenue = 45000000
));

accounts.add(new Account(
    Name = 'Buenos Aires Digital SA', Type = 'Customer - Channel', NumberOfEmployees = 280,
    BillingStreet = 'Avenida Corrientes 348', BillingCity = 'Buenos Aires', BillingCountry = 'Argentina',
    BillingCountryCode = 'AR', BillingPostalCode = 'C1043', Phone = '+54 11 1234 5678',
    Website = 'www.buenosairesdigital.com', Industry = 'Technology', AnnualRevenue = 28000000
));

accounts.add(new Account(
    Name = 'Santiago Software SpA', Type = 'Prospect', NumberOfEmployees = 180,
    BillingStreet = 'Avenida Providencia 1208', BillingCity = 'Santiago', BillingCountry = 'Chile',
    BillingCountryCode = 'CL', BillingPostalCode = '7500000', Phone = '+56 2 1234 5678',
    Website = 'www.santiagosoftware.com', Industry = 'Technology', AnnualRevenue = 18000000
));

// INSERT ACCOUNTS
insert accounts;
System.debug('✅ Created ' + accounts.size() + ' international accounts');

// CREATE CONTACTS FOR EACH ACCOUNT
List<Contact> contacts = new List<Contact>();

// Italian contacts
contacts.add(new Contact(
    FirstName = 'Marco', LastName = 'Rossi', Title = 'Amministratore Delegato',
    Email = 'marco.rossi@acmetechnologies.com', Phone = '+39 06 1234567',
    AccountId = accounts[0].Id, MailingStreet = accounts[0].BillingStreet,
    MailingCity = accounts[0].BillingCity, MailingCountry = accounts[0].BillingCountry,
    MailingPostalCode = accounts[0].BillingPostalCode
));
contacts.add(new Contact(
    FirstName = 'Giulia', LastName = 'Bianchi', Title = 'CTO',
    Email = 'giulia.bianchi@acmetechnologies.com', Phone = '+39 06 1234567',
    AccountId = accounts[0].Id, MailingStreet = accounts[0].BillingStreet,
    MailingCity = accounts[0].BillingCity, MailingCountry = accounts[0].BillingCountry,
    MailingPostalCode = accounts[0].BillingPostalCode
));

// German contacts
contacts.add(new Contact(
    FirstName = 'Hans', LastName = 'Müller', Title = 'Geschäftsführer',
    Email = 'hans.mueller@bavarianmotors.com', Phone = '+49 89 1234567',
    AccountId = accounts[1].Id, MailingStreet = accounts[1].BillingStreet,
    MailingCity = accounts[1].BillingCity, MailingCountry = accounts[1].BillingCountry,
    MailingPostalCode = accounts[1].BillingPostalCode
));
contacts.add(new Contact(
    FirstName = 'Anna', LastName = 'Schmidt', Title = 'Technical Director',
    Email = 'anna.schmidt@bavarianmotors.com', Phone = '+49 89 1234567',
    AccountId = accounts[1].Id, MailingStreet = accounts[1].BillingStreet,
    MailingCity = accounts[1].BillingCity, MailingCountry = accounts[1].BillingCountry,
    MailingPostalCode = accounts[1].BillingPostalCode
));

// Norwegian contacts
contacts.add(new Contact(
    FirstName = 'Lars', LastName = 'Hansen', Title = 'CEO',
    Email = 'lars.hansen@nordicsolutions.com', Phone = '+47 22 123456',
    AccountId = accounts[2].Id, MailingStreet = accounts[2].BillingStreet,
    MailingCity = accounts[2].BillingCity, MailingCountry = accounts[2].BillingCountry,
    MailingPostalCode = accounts[2].BillingPostalCode
));
contacts.add(new Contact(
    FirstName = 'Ingrid', LastName = 'Larsen', Title = 'CTO',
    Email = 'ingrid.larsen@nordicsolutions.com', Phone = '+47 22 123456',
    AccountId = accounts[2].Id, MailingStreet = accounts[2].BillingStreet,
    MailingCity = accounts[2].BillingCity, MailingCountry = accounts[2].BillingCountry,
    MailingPostalCode = accounts[2].BillingPostalCode
));

// Dutch contacts
contacts.add(new Contact(
    FirstName = 'Pieter', LastName = 'De Jong', Title = 'CEO',
    Email = 'pieter.dejong@amsterdamdigital.com', Phone = '+31 20 1234567',
    AccountId = accounts[3].Id, MailingStreet = accounts[3].BillingStreet,
    MailingCity = accounts[3].BillingCity, MailingCountry = accounts[3].BillingCountry,
    MailingPostalCode = accounts[3].BillingPostalCode
));
contacts.add(new Contact(
    FirstName = 'Emma', LastName = 'Van Der Berg', Title = 'CTO',
    Email = 'emma.vanderberg@amsterdamdigital.com', Phone = '+31 20 1234567',
    AccountId = accounts[3].Id, MailingStreet = accounts[3].BillingStreet,
    MailingCity = accounts[3].BillingCity, MailingCountry = accounts[3].BillingCountry,
    MailingPostalCode = accounts[3].BillingPostalCode
));

// Spanish contacts
contacts.add(new Contact(
    FirstName = 'Carlos', LastName = 'García', Title = 'CEO',
    Email = 'carlos.garcia@barcelonainnovations.com', Phone = '+34 93 1234567',
    AccountId = accounts[4].Id, MailingStreet = accounts[4].BillingStreet,
    MailingCity = accounts[4].BillingCity, MailingCountry = accounts[4].BillingCountry,
    MailingPostalCode = accounts[4].BillingPostalCode
));
contacts.add(new Contact(
    FirstName = 'María', LastName = 'López', Title = 'CTO',
    Email = 'maria.lopez@barcelonainnovations.com', Phone = '+34 93 1234567',
    AccountId = accounts[4].Id, MailingStreet = accounts[4].BillingStreet,
    MailingCity = accounts[4].BillingCity, MailingCountry = accounts[4].BillingCountry,
    MailingPostalCode = accounts[4].BillingPostalCode
));

// Japanese contacts
contacts.add(new Contact(
    FirstName = 'Takeshi', LastName = 'Tanaka', Title = 'President',
    Email = 'takeshi.tanaka@tokyotech.com', Phone = '+81 3 1234 5678',
    AccountId = accounts[5].Id, MailingStreet = accounts[5].BillingStreet,
    MailingCity = accounts[5].BillingCity, MailingCountry = accounts[5].BillingCountry,
    MailingPostalCode = accounts[5].BillingPostalCode
));
contacts.add(new Contact(
    FirstName = 'Yuki', LastName = 'Sato', Title = 'VP Engineering',
    Email = 'yuki.sato@tokyotech.com', Phone = '+81 3 1234 5678',
    AccountId = accounts[5].Id, MailingStreet = accounts[5].BillingStreet,
    MailingCity = accounts[5].BillingCity, MailingCountry = accounts[5].BillingCountry,
    MailingPostalCode = accounts[5].BillingPostalCode
));

// Add more contacts for remaining accounts...
// (Limiting for brevity, but you can add the rest following the same pattern)

// INSERT CONTACTS
insert contacts;
System.debug('✅ Created ' + contacts.size() + ' international contacts');
System.debug('🎉 International data generation completed successfully!');
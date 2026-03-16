String stamp = String.valueOf(Datetime.now().getTime());

List<Account> accounts = new List<Account>{
    new Account(
        Name = 'Map Test - Germany - ' + stamp,
        BillingStreet = 'Pariser Platz 1',
        BillingCity = 'Berlin',
        BillingPostalCode = '10117',
        BillingCountry = 'Germany'
    ),
    new Account(
        Name = 'Map Test - Spain - ' + stamp,
        BillingStreet = 'Calle de Alcala 50',
        BillingCity = 'Madrid',
        BillingPostalCode = '28014',
        BillingCountry = 'Spain'
    ),
    new Account(
        Name = 'Map Test - Italy - ' + stamp,
        BillingStreet = 'Via del Corso 10',
        BillingCity = 'Rome',
        BillingPostalCode = '00186',
        BillingCountry = 'Italy'
    ),
    new Account(
        Name = 'Map Test - Netherlands - ' + stamp,
        BillingStreet = 'Damrak 1',
        BillingCity = 'Amsterdam',
        BillingPostalCode = '1012LG',
        BillingCountry = 'Netherlands'
    ),
    new Account(
        Name = 'Map Test - Canada - ' + stamp,
        BillingStreet = '100 King St W',
        BillingCity = 'Toronto',
        BillingPostalCode = 'M5X 1A9',
        BillingCountry = 'Canada'
    ),
    new Account(
        Name = 'Map Test - Australia - ' + stamp,
        BillingStreet = '1 Martin Place',
        BillingCity = 'Sydney',
        BillingPostalCode = '2000',
        BillingCountry = 'Australia'
    ),
    new Account(
        Name = 'Map Test - Japan - ' + stamp,
        BillingStreet = '1-1 Chiyoda\nTokyo 100-8111\nJapan',
        BillingCity = 'Tokyo'
    ),
    new Account(
        Name = 'Map Test - Brazil - ' + stamp,
        BillingStreet = 'Avenida Paulista, 1000\nSao Paulo, SP 01310-100\nBrazil',
        BillingCity = 'Sao Paulo'
    ),
    new Account(
        Name = 'Map Test - South Africa - ' + stamp,
        BillingStreet = '1 Long Street\nCape Town 8001\nSouth Africa',
        BillingCity = 'Cape Town'
    ),
    new Account(
        Name = 'Map Test - India - ' + stamp,
        BillingStreet = 'Bandra Kurla Complex',
        BillingCity = 'Mumbai',
        BillingPostalCode = '400051',
        BillingCountry = 'India'
    )
};

insert accounts;

List<Contact> contacts = new List<Contact>();
for (Account accountRecord : accounts) {
    contacts.add(new Contact(
        LastName = accountRecord.Name + ' Contact 1',
        AccountId = accountRecord.Id,
        Email = 'test1+' + accountRecord.Id + '@example.com'
    ));
    contacts.add(new Contact(
        LastName = accountRecord.Name + ' Contact 2',
        AccountId = accountRecord.Id,
        Email = 'test2+' + accountRecord.Id + '@example.com'
    ));
}

insert contacts;

System.debug('CREATED_ACCOUNT_COUNT=' + accounts.size());
for (Account accountRecord : accounts) {
    System.debug('CREATED_ACCOUNT=' + accountRecord.Id + ':' + accountRecord.Name);
}

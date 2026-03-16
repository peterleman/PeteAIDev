String segmentationField = 'Segmentation__c';
List<Account> existingAccounts = Database.query(
    'SELECT Id, Name FROM Account ORDER BY Name'
);

List<String> segments = new List<String>{ 'Bronze', 'Silver', 'Gold' };
for (Integer index = 0; index < existingAccounts.size(); index++) {
    existingAccounts[index].put(segmentationField, segments[Math.mod(index, segments.size())]);
}
update existingAccounts;

String stamp = String.valueOf(Datetime.now().getTime());
List<Account> newAccounts = new List<Account>();

for (Integer index = 1; index <= 20; index++) {
    String segment = segments[Math.mod(index - 1, segments.size())];
    Account newAccount = new Account(
        Name = 'UK Test Customer ' + index + ' - ' + stamp,
        Phone = '+44 20 7000 ' + String.valueOf(1000 + index),
        Website = 'https://uk-test-' + index + '.example.com',
        NumberOfEmployees = 50 + (index * 10),
        BillingStreet = index + ' Regent Street' + '\nLondon W1B ' + String.valueOf(10 + index) + 'AA' + '\nUnited Kingdom',
        BillingCity = 'London',
        BillingCountry = 'United Kingdom',
        BillingCountryCode = 'GB',
        ShippingStreet = index + ' Regent Street' + '\nLondon W1B ' + String.valueOf(10 + index) + 'AA' + '\nUnited Kingdom',
        ShippingCity = 'London',
        ShippingCountry = 'United Kingdom',
        ShippingCountryCode = 'GB',
        Description = 'Synthetic UK customer for map and segmentation testing.'
    );
    newAccount.put(segmentationField, segment);
    newAccounts.add(newAccount);
}

insert newAccounts;

List<Contact> newContacts = new List<Contact>();
for (Integer index = 0; index < newAccounts.size(); index++) {
    Account accountRecord = newAccounts[index];
    Integer customerNumber = index + 1;
    newContacts.add(new Contact(
        AccountId = accountRecord.Id,
        FirstName = 'Alex',
        LastName = 'Primary ' + customerNumber,
        Email = 'primary' + customerNumber + '.' + stamp + '@example.co.uk',
        Phone = '+44 20 8000 ' + String.valueOf(2000 + customerNumber)
    ));
    newContacts.add(new Contact(
        AccountId = accountRecord.Id,
        FirstName = 'Jamie',
        LastName = 'Secondary ' + customerNumber,
        Email = 'secondary' + customerNumber + '.' + stamp + '@example.co.uk',
        Phone = '+44 20 8100 ' + String.valueOf(3000 + customerNumber)
    ));
}
insert newContacts;

System.debug('UPDATED_EXISTING_ACCOUNTS=' + existingAccounts.size());
System.debug('CREATED_UK_ACCOUNTS=' + newAccounts.size());
for (Account accountRecord : newAccounts) {
    System.debug('CREATED_UK_ACCOUNT=' + accountRecord.Id + ':' + accountRecord.Name + ':' + String.valueOf(accountRecord.get(segmentationField)));
}

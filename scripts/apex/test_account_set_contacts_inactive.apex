String stamp = String.valueOf(Datetime.now().getTime());
Account acct = new Account(Name = 'Flow Test ' + stamp, Active__c = 'Yes');
insert acct;

Contact c1 = new Contact(LastName = 'Flow Test One ' + stamp, AccountId = acct.Id, Active__c = 'Yes');
Contact c2 = new Contact(LastName = 'Flow Test Two ' + stamp, AccountId = acct.Id, Active__c = 'Yes');
insert new List<Contact>{ c1, c2 };

acct.Active__c = 'No';
update acct;

List<Contact> contacts = [
    SELECT Id, Active__c
    FROM Contact
    WHERE AccountId = :acct.Id
    ORDER BY LastName
];

System.debug('FLOW_TEST_CONTACT_COUNT=' + contacts.size());
for (Contact c : contacts) {
    System.debug('FLOW_TEST_CONTACT=' + c.Id + ':' + c.Active__c);
}

Boolean allInactive = true;
for (Contact c : contacts) {
    if (c.Active__c != 'No') {
        allInactive = false;
    }
}

delete contacts;
delete acct;

if (!allInactive || contacts.size() != 2) {
    throw new AuraHandledException('Flow test failed. allInactive=' + allInactive + ', count=' + contacts.size());
}

System.debug('FLOW_TEST_RESULT=PASS');

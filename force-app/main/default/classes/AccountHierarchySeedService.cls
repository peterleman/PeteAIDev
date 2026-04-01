public with sharing class AccountHierarchySeedService {
    private static final String GENERATED_ACCOUNT_PREFIX = 'Hierarchy Seed - ';
    private static final String GENERATED_CONTACT_PREFIX = 'Hierarchy Seed Contact ';
    private static final String GENERATED_ACCOUNT_NUMBER_PREFIX = 'HIER-SEED-';
    private static final List<String> ACCOUNT_PREFIXES = new List<String>{
        'North Harbor', 'Summit Ridge', 'Blue Cedar', 'Silver Brook', 'Stonegate',
        'Riverbend', 'Crescent Bay', 'Redwood', 'Ironwood', 'Maple Crest'
    };
    private static final List<String> ACCOUNT_SUFFIXES = new List<String>{
        'Logistics', 'Advisory', 'Health Partners', 'Systems', 'Consulting',
        'Ventures', 'Manufacturing', 'Services', 'Distribution', 'Labs'
    };
    private static final List<String> CONTACT_FIRST_NAMES = new List<String>{
        'Mia', 'Lucas', 'Emma', 'Noah', 'Chloe', 'Ethan', 'Sofia', 'Liam', 'Nora', 'James',
        'Ava', 'Daniel', 'Leah', 'Henry', 'Grace', 'Owen'
    };
    private static final List<String> CONTACT_LAST_NAMES = new List<String>{
        'Bennett', 'Coleman', 'Foster', 'Hayes', 'Reed', 'Sullivan', 'Turner', 'Brooks',
        'Parker', 'Hayden', 'Morgan', 'Perry', 'Walsh', 'Carter', 'Lawson', 'Murphy'
    };
    private static final List<String> CONTACT_TITLES = new List<String>{
        'Operations Manager', 'Client Director', 'Regional Lead', 'Account Executive',
        'Customer Success Manager', 'Solutions Consultant', 'Program Manager', 'Sales Manager'
    };

    public static String seed() {
        List<Account> orderedGlobals = [
            SELECT Id, Name, Global_Account__c
            FROM Account
            WHERE Global_Account__c = true
            ORDER BY Name
        ];

        if (orderedGlobals.isEmpty()) {
            return 'No global accounts found. Check Global_Account__c on at least one Account first.';
        }

        Set<Id> globalIds = new Set<Id>();
        for (Account globalAccount : orderedGlobals) {
            globalIds.add(globalAccount.Id);
        }

        List<Account> candidateBaseAccounts = [
            SELECT Id, Name, ParentId, AccountNumber, Global_Account__c
            FROM Account
            WHERE Global_Account__c = false
            ORDER BY Name
        ];

        List<Account> baseAccounts = new List<Account>();
        for (Account candidateBaseAccount : candidateBaseAccounts) {
            String accountNumber = candidateBaseAccount.AccountNumber == null
                ? ''
                : candidateBaseAccount.AccountNumber;
            if (
                !candidateBaseAccount.Name.startsWith(GENERATED_ACCOUNT_PREFIX)
                && !accountNumber.startsWith(GENERATED_ACCOUNT_NUMBER_PREFIX)
            ) {
                baseAccounts.add(candidateBaseAccount);
            }
        }

        List<Account> accountsToReparent = new List<Account>();
        for (Integer index = 0; index < baseAccounts.size(); index++) {
            Account baseAccount = baseAccounts[index];
            Id targetGlobalId = orderedGlobals[Math.mod(index, orderedGlobals.size())].Id;
            if (baseAccount.ParentId == null || !globalIds.contains(baseAccount.ParentId)) {
                baseAccount.ParentId = targetGlobalId;
                accountsToReparent.add(baseAccount);
            }
        }

        if (!accountsToReparent.isEmpty()) {
            update accountsToReparent;
        }

        Map<Id, List<Account>> existingGeneratedChildrenByParentId = new Map<Id, List<Account>>();
        for (Account generatedChild : [
            SELECT Id, Name, ParentId, AccountNumber
            FROM Account
            WHERE Name LIKE :GENERATED_ACCOUNT_PREFIX + '%'
                OR AccountNumber LIKE :GENERATED_ACCOUNT_NUMBER_PREFIX + '%'
            ORDER BY ParentId, Name
        ]) {
            if (!existingGeneratedChildrenByParentId.containsKey(generatedChild.ParentId)) {
                existingGeneratedChildrenByParentId.put(generatedChild.ParentId, new List<Account>());
            }
            existingGeneratedChildrenByParentId.get(generatedChild.ParentId).add(generatedChild);
        }

        List<Account> generatedChildrenToInsert = new List<Account>();
        List<Account> generatedChildrenToUpdate = new List<Account>();
        for (Integer index = 0; index < baseAccounts.size(); index++) {
            Account baseAccount = baseAccounts[index];
            Integer childTarget = Math.mod(index, 4);
            List<Account> existingChildren = existingGeneratedChildrenByParentId.containsKey(baseAccount.Id)
                ? existingGeneratedChildrenByParentId.get(baseAccount.Id)
                : new List<Account>();

            for (Integer childIndex = 1; childIndex <= childTarget; childIndex++) {
                String generatedChildName = buildGeneratedAccountName(baseAccount, index, childIndex);
                String marker = buildGeneratedAccountMarker(baseAccount.Id, childIndex);

                if (existingChildren.size() >= childIndex) {
                    Account existingChild = existingChildren[childIndex - 1];
                    if (
                        existingChild.Name != generatedChildName
                        || existingChild.AccountNumber != marker
                    ) {
                        existingChild.Name = generatedChildName;
                        existingChild.AccountNumber = marker;
                        generatedChildrenToUpdate.add(existingChild);
                    }
                } else {
                    generatedChildrenToInsert.add(new Account(
                        Name = generatedChildName,
                        ParentId = baseAccount.Id,
                        AccountNumber = marker,
                        Type = 'Customer - Direct',
                        Global_Account__c = false
                    ));
                }
            }
        }

        if (!generatedChildrenToUpdate.isEmpty()) {
            update generatedChildrenToUpdate;
        }

        if (!generatedChildrenToInsert.isEmpty()) {
            insert generatedChildrenToInsert;
        }

        List<Account> generatedChildren = [
            SELECT Id, Name, ParentId, AccountNumber
            FROM Account
            WHERE AccountNumber LIKE :GENERATED_ACCOUNT_NUMBER_PREFIX + '%'
            ORDER BY ParentId, AccountNumber
        ];

        Map<Id, Integer> baseIndexById = new Map<Id, Integer>();
        for (Integer index = 0; index < baseAccounts.size(); index++) {
            baseIndexById.put(baseAccounts[index].Id, index);
        }

        Map<Id, List<Contact>> existingGeneratedContactsByAccountId = new Map<Id, List<Contact>>();
        for (Contact existingGeneratedContact : [
            SELECT Id, AccountId, FirstName, LastName, Title, Email, Phone
            FROM Contact
            WHERE Department = 'Hierarchy Seed'
            ORDER BY AccountId, LastName, FirstName
        ]) {
            if (!existingGeneratedContactsByAccountId.containsKey(existingGeneratedContact.AccountId)) {
                existingGeneratedContactsByAccountId.put(
                    existingGeneratedContact.AccountId,
                    new List<Contact>()
                );
            }
            existingGeneratedContactsByAccountId.get(existingGeneratedContact.AccountId)
                .add(existingGeneratedContact);
        }

        List<Contact> contactsToInsert = new List<Contact>();
        List<Contact> contactsToUpdate = new List<Contact>();
        for (Account generatedChild : generatedChildren) {
            Integer parentIndex = baseIndexById.containsKey(generatedChild.ParentId)
                ? baseIndexById.get(generatedChild.ParentId)
                : 0;
            Integer childIndex = getGeneratedChildIndex(generatedChild.AccountNumber);
            Integer contactTarget = Math.mod(parentIndex + childIndex, 4);
            List<Contact> existingContacts = existingGeneratedContactsByAccountId.containsKey(generatedChild.Id)
                ? existingGeneratedContactsByAccountId.get(generatedChild.Id)
                : new List<Contact>();

            for (Integer contactIndex = 1; contactIndex <= contactTarget; contactIndex++) {
                Contact desiredContact = buildGeneratedContact(generatedChild, parentIndex, childIndex, contactIndex);
                if (existingContacts.size() >= contactIndex) {
                    Contact existingContact = existingContacts[contactIndex - 1];
                    existingContact.FirstName = desiredContact.FirstName;
                    existingContact.LastName = desiredContact.LastName;
                    existingContact.Title = desiredContact.Title;
                    existingContact.Email = desiredContact.Email;
                    existingContact.Phone = desiredContact.Phone;
                    existingContact.Department = desiredContact.Department;
                    contactsToUpdate.add(existingContact);
                } else {
                    desiredContact.AccountId = generatedChild.Id;
                    contactsToInsert.add(desiredContact);
                }
            }
        }

        if (!contactsToUpdate.isEmpty()) {
            Database.update(prepareContactsForSave(contactsToUpdate), false);
        }

        if (!contactsToInsert.isEmpty()) {
            Database.insert(prepareContactsForSave(contactsToInsert), false);
        }

        return
            'globalAccountsUsed=' + orderedGlobals.size()
            + ', reparented=' + accountsToReparent.size()
            + ', generatedChildrenUpdated=' + generatedChildrenToUpdate.size()
            + ', generatedChildrenInserted=' + generatedChildrenToInsert.size()
            + ', generatedContactsUpdated=' + contactsToUpdate.size()
            + ', generatedContactsInserted=' + contactsToInsert.size();
    }

    private static String buildGeneratedAccountName(Account baseAccount, Integer parentIndex, Integer childIndex) {
        Integer prefixIndex = Math.mod(parentIndex + childIndex, ACCOUNT_PREFIXES.size());
        Integer suffixIndex = Math.mod(parentIndex * 2 + childIndex, ACCOUNT_SUFFIXES.size());
        return ACCOUNT_PREFIXES[prefixIndex] + ' ' + ACCOUNT_SUFFIXES[suffixIndex];
    }

    private static String buildGeneratedAccountMarker(Id parentId, Integer childIndex) {
        return GENERATED_ACCOUNT_NUMBER_PREFIX + String.valueOf(parentId).right(8) + '-' + childIndex;
    }

    private static Integer getGeneratedChildIndex(String accountNumber) {
        if (String.isBlank(accountNumber)) {
            return 1;
        }

        List<String> parts = accountNumber.split('-');
        if (parts.isEmpty()) {
            return 1;
        }

        return Integer.valueOf(parts[parts.size() - 1]);
    }

    private static Contact buildGeneratedContact(
        Account generatedChild,
        Integer parentIndex,
        Integer childIndex,
        Integer contactIndex
    ) {
        Integer firstIndex = Math.mod(parentIndex + childIndex + contactIndex, CONTACT_FIRST_NAMES.size());
        Integer lastIndex = Math.mod(parentIndex * 2 + childIndex + contactIndex, CONTACT_LAST_NAMES.size());
        Integer titleIndex = Math.mod(parentIndex + contactIndex, CONTACT_TITLES.size());
        String firstName = CONTACT_FIRST_NAMES[firstIndex];
        String lastName = CONTACT_LAST_NAMES[lastIndex];
        String email =
            (firstName + '.' + lastName + '.' + String.valueOf(generatedChild.Id).right(4))
                .toLowerCase()
                .replace(' ', '')
                + '@example.com';
        String phone = '+1 415 555 ' + String.valueOf(1000 + (parentIndex * 10) + (childIndex * 3) + contactIndex);

        return new Contact(
            FirstName = firstName,
            LastName = lastName,
            Title = CONTACT_TITLES[titleIndex],
            Email = email,
            Phone = phone,
            Department = 'Hierarchy Seed'
        );
    }

    private static List<Contact> prepareContactsForSave(List<Contact> contacts) {
        Database.DMLOptions dmlOptions = new Database.DMLOptions();
        dmlOptions.DuplicateRuleHeader.allowSave = true;
        dmlOptions.DuplicateRuleHeader.runAsCurrentUser = true;

        for (Contact contactRecord : contacts) {
            contactRecord.setOptions(dmlOptions);
        }

        return contacts;
    }
}
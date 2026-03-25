@IsTest
private class AccountHierarchyControllerTest {
    @IsTest
    static void returnsGlobalParentsOnlyWithRecursiveCounts() {
        Account globalOne = new Account(Name = 'Root Alpha', Global_Account__c = true);
        Account globalTwo = new Account(Name = 'Root Beta', Global_Account__c = true);
        Account nonGlobal = new Account(Name = 'Regional Parent', Global_Account__c = false);
        insert new List<Account>{ globalOne, globalTwo, nonGlobal };

        Account childOne = new Account(Name = 'Alpha Subsidiary', ParentId = globalOne.Id);
        Account childTwo = new Account(Name = 'Beta Subsidiary', ParentId = globalOne.Id);
        Account grandChild = new Account(Name = 'Alpha Branch', ParentId = childOne.Id);
        Account childThree = new Account(Name = 'Gamma Subsidiary', ParentId = globalTwo.Id);
        insert new List<Account>{ childOne, childTwo, grandChild, childThree };

        insert new List<Contact>{
            new Contact(LastName = 'One', AccountId = childOne.Id),
            new Contact(LastName = 'Two', AccountId = grandChild.Id),
            new Contact(LastName = 'Three', AccountId = childThree.Id)
        };

        Test.startTest();
        List<AccountHierarchyController.ParentAccountSummary> summaries =
            AccountHierarchyController.getCorporateParents('Root', 50);
        Test.stopTest();

        System.assertEquals(2, summaries.size(), 'Only global accounts should be returned.');
        System.assertEquals('Root Alpha', summaries[0].name);
        System.assertEquals(2, summaries[0].directChildCount);
        System.assertEquals(1, summaries[0].totalContactCount);
        System.assertEquals('Root Beta', summaries[1].name);
        System.assertEquals(1, summaries[1].directChildCount);
        System.assertEquals(1, summaries[1].totalContactCount);
    }

    @IsTest
    static void returnsRecursiveHierarchyWithoutLevelLimit() {
        Account globalParent = new Account(Name = 'Root Gamma', Global_Account__c = true);
        insert globalParent;

        Account levelOne = new Account(Name = 'Level One', ParentId = globalParent.Id);
        insert levelOne;

        Account levelTwo = new Account(Name = 'Level Two', ParentId = levelOne.Id);
        Account sibling = new Account(Name = 'Sibling', ParentId = globalParent.Id);
        insert new List<Account>{ levelTwo, sibling };

        insert new List<Contact>{
            new Contact(LastName = 'One', AccountId = levelOne.Id, Email = 'one@example.com'),
            new Contact(LastName = 'Two', AccountId = levelTwo.Id, Phone = '123'),
            new Contact(LastName = 'Three', AccountId = sibling.Id)
        };

        Test.startTest();
        AccountHierarchyController.AccountTreeNode hierarchy =
            AccountHierarchyController.getParentHierarchy(globalParent.Id);
        Test.stopTest();

        System.assertNotEquals(null, hierarchy);
        System.assertEquals(globalParent.Id, hierarchy.recordId);
        System.assertEquals(true, hierarchy.isGlobalAccount);
        System.assertEquals(2, hierarchy.directChildCount);
        System.assertEquals(3, hierarchy.totalDescendantCount);
        System.assertEquals(3, hierarchy.totalContactCount);
        System.assertEquals(2, hierarchy.children.size());

        System.assertEquals('Level One', hierarchy.children[0].name);
        System.assertEquals(1, hierarchy.children[0].contactCount);
        System.assertEquals(1, hierarchy.children[0].contacts.size());
        System.assertEquals('One', hierarchy.children[0].contacts[0].name);
        System.assertEquals(1, hierarchy.children[0].children.size());
        System.assertEquals('Level Two', hierarchy.children[0].children[0].name);
        System.assertEquals(1, hierarchy.children[0].children[0].contactCount);
        System.assertEquals(null, hierarchy.children[0].children[0].contacts[0].email);
        System.assertEquals('123', hierarchy.children[0].children[0].contacts[0].phone);

        System.assertEquals('Sibling', hierarchy.children[1].name);
        System.assertEquals(1, hierarchy.children[1].contactCount);
    }

    @IsTest
    static void seedServiceUsesCheckedGlobalsAndGeneratedHierarchy() {
        insert new List<Account>{
            new Account(Name = 'Checked Global A', Global_Account__c = true),
            new Account(Name = 'Checked Global B', Global_Account__c = true),
            new Account(Name = 'Base Account A'),
            new Account(Name = 'Base Account B'),
            new Account(Name = 'Base Account C'),
            new Account(Name = 'Base Account D')
        };

        Test.startTest();
        String result = AccountHierarchySeedService.seed();
        Test.stopTest();

        System.assert(result.contains('generatedChildrenInserted='));
        System.assert(result.contains('globalAccountsUsed=2'));
        System.assertEquals(
            2,
            [SELECT COUNT() FROM Account WHERE Global_Account__c = true],
            'The seed should only use accounts already flagged as global.'
        );
        System.assert(
            [SELECT COUNT() FROM Account WHERE AccountNumber LIKE 'HIER-SEED-%'] > 0,
            'Generated branch accounts should be created under non-global accounts.'
        );
        System.assert(
            [SELECT COUNT() FROM Contact WHERE Department = 'Hierarchy Seed'] >= 0,
            'Generated contacts should be insertable for the new branch accounts.'
        );
    }
}

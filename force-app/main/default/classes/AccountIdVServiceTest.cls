@IsTest
private class AccountIdVServiceTest {
    @IsTest
    static void passesWhenTwoValuesMatch() {
        Account accountRecord = new Account(
            Name = 'IDV Pass Account',
            AccountNumber = 'ACC-1001',
            Phone = '(555) 111-2222'
        );
        insert accountRecord;

        insert new Contact(
            AccountId = accountRecord.Id,
            LastName = 'Verifier',
            Email = 'customer@example.com',
            Phone = '+1 555 444 7777'
        );

        AccountIdVService.Request requestItem = new AccountIdVService.Request();
        requestItem.accountId = accountRecord.Id;
        requestItem.customerNumber = 'acc-1001';
        requestItem.phoneNumber = '5551112222';
        requestItem.email = 'wrong@example.com';

        Test.startTest();
        List<AccountIdVService.Response> responses = AccountIdVService.evaluate(
            new List<AccountIdVService.Request>{ requestItem }
        );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals(true, responses[0].customerNumberMatched);
        System.assertEquals(true, responses[0].phoneMatched);
        System.assertEquals(false, responses[0].emailMatched);
        System.assertEquals(2, responses[0].matchedCount);
        System.assertEquals(true, responses[0].passed);
    }

    @IsTest
    static void failsWhenFewerThanTwoValuesSupplied() {
        Account accountRecord = new Account(
            Name = 'IDV Not Enough Inputs',
            AccountNumber = 'ACC-2002',
            Phone = '(555) 999-0000'
        );
        insert accountRecord;

        AccountIdVService.Request requestItem = new AccountIdVService.Request();
        requestItem.accountId = accountRecord.Id;
        requestItem.customerNumber = 'ACC-2002';

        Test.startTest();
        List<AccountIdVService.Response> responses = AccountIdVService.evaluate(
            new List<AccountIdVService.Request>{ requestItem }
        );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals(1, responses[0].matchedCount);
        System.assertEquals(false, responses[0].passed);
        System.assertEquals('Enter at least two values to complete verification.', responses[0].resultMessage);
    }

    @IsTest
    static void matchesAgainstRelatedContactDetails() {
        Account accountRecord = new Account(
            Name = 'IDV Contact Match',
            AccountNumber = 'ACC-3003',
            Phone = '(555) 121-2121'
        );
        insert accountRecord;

        insert new Contact(
            AccountId = accountRecord.Id,
            LastName = 'Secondary',
            Email = 'secondary@example.com',
            MobilePhone = '+44 20 7000 1234'
        );

        AccountIdVService.Request requestItem = new AccountIdVService.Request();
        requestItem.accountId = accountRecord.Id;
        requestItem.phoneNumber = '442070001234';
        requestItem.email = 'SECONDARY@example.com';

        Test.startTest();
        List<AccountIdVService.Response> responses = AccountIdVService.evaluate(
            new List<AccountIdVService.Request>{ requestItem }
        );
        Test.stopTest();

        System.assertEquals(1, responses.size());
        System.assertEquals(true, responses[0].phoneMatched);
        System.assertEquals(true, responses[0].emailMatched);
        System.assertEquals(2, responses[0].matchedCount);
        System.assertEquals(true, responses[0].passed);
    }
}

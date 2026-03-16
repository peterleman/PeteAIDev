@IsTest
private class CustomerMapControllerTest {
    @IsTest
    static void returnsAccountsWithBillingAddresses() {
        Account included = new Account(
            Name = 'Included Account',
            Segmentation__c = 'Gold',
            BillingStreet = '1 Main St',
            BillingCity = 'Paris',
            BillingPostalCode = '75001',
            BillingCountry = 'France'
        );
        Account excluded = new Account(Name = 'Excluded Account');
        insert new List<Account>{ included, excluded };

        Test.startTest();
        List<CustomerMapController.AccountMapMarker> markers = CustomerMapController.getCustomerLocations();
        Test.stopTest();

        System.assertEquals(1, markers.size(), 'Only accounts with a billing address should be returned.');
        System.assertEquals(included.Id, markers[0].recordId);
        System.assertEquals('Included Account', markers[0].accountName);
        System.assertEquals('Gold', markers[0].segmentation);
        System.assert(markers[0].description.contains('1 Main St'));
        System.assert(markers[0].description.contains('Paris'));
    }
}

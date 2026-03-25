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

        System.assertEquals(1, markers.size(), 'Only accounts with a usable location should be returned.');
        System.assertEquals(included.Id, markers[0].recordId);
        System.assertEquals('Included Account', markers[0].accountName);
        System.assertEquals('Gold', markers[0].segmentation);
        System.assertEquals('France', markers[0].countryLabel);
        System.assert(markers[0].description.contains('1 Main St'));
        System.assert(markers[0].description.contains('Paris'));
    }

    @IsTest
    static void usesShippingAddressWhenBillingIsBlank() {
        Account shippingOnly = new Account(
            Name = 'Shipping Only',
            ShippingStreet = '10 Downing St',
            ShippingCity = 'London',
            ShippingPostalCode = 'SW1A 2AA',
            ShippingCountryCode = 'GB'
        );
        insert shippingOnly;

        Test.startTest();
        List<CustomerMapController.AccountMapMarker> markers = CustomerMapController.getCustomerLocations();
        Test.stopTest();

        System.assertEquals(1, markers.size());
        System.assertEquals(getExpectedCountryLabel('GB'), markers[0].countryLabel);
        System.assertEquals('10 Downing St', markers[0].street);
        System.assertEquals('London', markers[0].city);
    }

    @IsTest
    static void usesOrgMetadataToResolveCountryCodeLabels() {
        Account codeBased = new Account(
            Name = 'Code Based',
            BillingCity = 'Toronto',
            BillingPostalCode = 'M5H 2N2',
            BillingCountryCode = 'CA'
        );
        insert codeBased;

        Test.startTest();
        List<CustomerMapController.AccountMapMarker> markers = CustomerMapController.getCustomerLocations();
        Test.stopTest();

        System.assertEquals(1, markers.size());
        System.assertEquals(getExpectedCountryLabel('CA'), markers[0].countryLabel);
    }

    @IsTest
    static void excludesAccountsWithoutEnoughLocationData() {
        Account countryOnly = new Account(
            Name = 'Country Only',
            BillingCountryCode = 'DE'
        );
        Account postalAndCountry = new Account(
            Name = 'Postal And Country',
            BillingPostalCode = '10115',
            BillingCountryCode = 'DE'
        );
        insert new List<Account>{ countryOnly, postalAndCountry };

        Test.startTest();
        List<CustomerMapController.AccountMapMarker> markers = CustomerMapController.getCustomerLocations();
        Test.stopTest();

        System.assertEquals(1, markers.size(), 'Country-only records should not be returned.');
        System.assertEquals('Postal And Country', markers[0].accountName);
        System.assertEquals(getExpectedCountryLabel('DE'), markers[0].countryLabel);
    }

    @IsTest
    static void keepsRawCountryTextWhenProvided() {
        CustomerMapController.AccountMapMarker marker = new CustomerMapController.AccountMapMarker(
            new Account(
                Name = 'Raw Country',
                BillingStreet = '1 Route Example',
                BillingCity = 'Paris',
                BillingCountry = '  Customland  '
            )
        );

        System.assertEquals('Customland', marker.countryLabel);
        System.assertEquals('1 Route Example', marker.street);
        System.assert(marker.hasUsableLocation());
    }

    @IsTest
    static void fallsBackToCountryCodeWhenMetadataHasNoLabel() {
        CustomerMapController.AccountMapMarker firstMarker = new CustomerMapController.AccountMapMarker(
            new Account(
                Name = 'Known Code',
                BillingCity = 'Toronto',
                BillingCountryCode = 'CA'
            )
        );
        CustomerMapController.AccountMapMarker unknownCodeMarker = new CustomerMapController.AccountMapMarker(
            new Account(
                Name = 'Unknown Code',
                BillingCity = 'Nowhere',
                BillingCountryCode = 'ZZ'
            )
        );

        System.assertEquals(getExpectedCountryLabel('CA'), firstMarker.countryLabel);
        System.assertEquals('ZZ', unknownCodeMarker.countryLabel);
        System.assert(unknownCodeMarker.hasUsableLocation());
    }

    @IsTest
    static void markerWithoutCountryDoesNotQualifyAsUsableLocation() {
        CustomerMapController.AccountMapMarker marker = new CustomerMapController.AccountMapMarker(
            new Account(
                Name = 'Missing Country',
                BillingCity = 'Berlin'
            )
        );

        System.assertEquals(null, marker.countryLabel);
        System.assertEquals('Berlin', marker.description);
        System.assertEquals(false, marker.hasUsableLocation());
    }

    private static String getExpectedCountryLabel(String countryCode) {
        for (Schema.PicklistEntry entry : Account.BillingCountryCode.getDescribe().getPicklistValues()) {
            if (entry.getValue() == countryCode) {
                return entry.getLabel();
            }
        }

        return countryCode;
    }
}

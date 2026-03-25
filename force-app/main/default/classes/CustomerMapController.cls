public with sharing class CustomerMapController {
    private static Map<String, String> countryCodeToLabel;

    public class AccountMapMarker {
        @AuraEnabled public Id recordId;
        @AuraEnabled public String accountName;
        @AuraEnabled public String segmentation;
        @AuraEnabled public String street;
        @AuraEnabled public String city;
        @AuraEnabled public String state;
        @AuraEnabled public String postalCode;
        @AuraEnabled public String country;
        @AuraEnabled public String countryCode;
        @AuraEnabled public String countryLabel;
        @AuraEnabled public String description;

        public AccountMapMarker(Account accountRecord) {
            recordId = accountRecord.Id;
            accountName = accountRecord.Name;
            segmentation = (String)accountRecord.get('Segmentation__c');
            street = firstNonBlank(accountRecord.BillingStreet, accountRecord.ShippingStreet);
            city = firstNonBlank(accountRecord.BillingCity, accountRecord.ShippingCity);
            state = firstNonBlank(accountRecord.BillingState, accountRecord.ShippingState);
            postalCode = firstNonBlank(accountRecord.BillingPostalCode, accountRecord.ShippingPostalCode);
            country = firstNonBlank(accountRecord.BillingCountry, accountRecord.ShippingCountry);
            countryCode = firstNonBlank(accountRecord.BillingCountryCode, accountRecord.ShippingCountryCode);
            countryLabel = CustomerMapController.resolveCountryLabel(country, countryCode);
            description = CustomerMapController.formatAddress(street, city, state, postalCode, countryLabel);
        }

        public Boolean hasUsableLocation() {
            return String.isNotBlank(countryLabel)
                && (
                    String.isNotBlank(street)
                    || String.isNotBlank(city)
                    || String.isNotBlank(state)
                    || String.isNotBlank(postalCode)
                );
        }
    }

    private static String resolveCountryLabel(String country, String countryCode) {
        if (String.isNotBlank(country)) {
            return country.trim();
        }

        String normalizedCode = String.isNotBlank(countryCode) ? countryCode.trim().toUpperCase() : null;
        if (String.isBlank(normalizedCode)) {
            return null;
        }

        Map<String, String> codeToLabel = getCountryCodeToLabel();
        if (codeToLabel.containsKey(normalizedCode)) {
            return codeToLabel.get(normalizedCode);
        }

        return normalizedCode;
    }

    private static Map<String, String> getCountryCodeToLabel() {
        if (countryCodeToLabel != null) {
            return countryCodeToLabel;
        }

        countryCodeToLabel = new Map<String, String>();
        Schema.DescribeFieldResult describeResult = Account.BillingCountryCode.getDescribe();
        for (Schema.PicklistEntry entry : describeResult.getPicklistValues()) {
            String value = entry.getValue();
            if (String.isNotBlank(value)) {
                countryCodeToLabel.put(value.trim().toUpperCase(), entry.getLabel());
            }
        }

        return countryCodeToLabel;
    }

    private static String formatAddress(String street, String city, String state, String postalCode, String countryLabel) {
        List<String> lines = new List<String>();
        if (String.isNotBlank(street)) {
            lines.add(street);
        }

        List<String> cityLineParts = new List<String>();
        if (String.isNotBlank(city)) {
            cityLineParts.add(city);
        }
        if (String.isNotBlank(state)) {
            cityLineParts.add(state);
        }
        if (String.isNotBlank(postalCode)) {
            cityLineParts.add(postalCode);
        }
        if (!cityLineParts.isEmpty()) {
            lines.add(String.join(cityLineParts, ', '));
        }

        if (String.isNotBlank(countryLabel)) {
            lines.add(countryLabel);
        }

        return String.join(lines, '\n');
    }

    private static String firstNonBlank(String firstValue, String secondValue) {
        if (String.isNotBlank(firstValue)) {
            return firstValue;
        }
        return secondValue;
    }

    @AuraEnabled(cacheable=true)
    public static List<AccountMapMarker> getCustomerLocations() {
        List<Account> accounts = [
            SELECT Id, Name, Segmentation__c,
                BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, BillingCountryCode,
                ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry, ShippingCountryCode
            FROM Account
            WHERE BillingStreet != NULL
                OR BillingCity != NULL
                OR BillingState != NULL
                OR BillingPostalCode != NULL
                OR BillingCountry != NULL
                OR BillingCountryCode != NULL
                OR ShippingStreet != NULL
                OR ShippingCity != NULL
                OR ShippingState != NULL
                OR ShippingPostalCode != NULL
                OR ShippingCountry != NULL
                OR ShippingCountryCode != NULL
            ORDER BY Name
            LIMIT 2000
        ];

        List<AccountMapMarker> markers = new List<AccountMapMarker>();
        for (Account accountRecord : accounts) {
            AccountMapMarker marker = new AccountMapMarker(accountRecord);
            if (marker.hasUsableLocation()) {
                markers.add(marker);
            }
        }
        return markers;
    }
}

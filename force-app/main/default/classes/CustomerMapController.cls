public with sharing class CustomerMapController {
    private static final Map<String, String> COUNTRY_CODE_TO_LABEL = new Map<String, String>{
        'US' => 'United States',
        'GB' => 'United Kingdom',
        'UK' => 'United Kingdom',
        'FR' => 'France',
        'AE' => 'United Arab Emirates'
    };

    private static final Map<String, String> COUNTRY_ALIAS_TO_LABEL = new Map<String, String>{
        'UNITED STATES' => 'United States',
        'UNITED STATES OF AMERICA' => 'United States',
        'USA' => 'United States',
        'US' => 'United States',
        'U.S.' => 'United States',
        'U.S.A.' => 'United States',
        'UNBITED STATES' => 'United States',
        'UNITED KINGDOM' => 'United Kingdom',
        'UK' => 'United Kingdom',
        'GREAT BRITAIN' => 'United Kingdom',
        'ENGLAND' => 'United Kingdom',
        'SINGAPORE' => 'Singapore',
        'FRANCE' => 'France',
        'UAE' => 'United Arab Emirates',
        'UNITED ARAB EMIRATES' => 'United Arab Emirates'
    };

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
            countryLabel = CustomerMapController.normalizeCountry(
                country,
                countryCode,
                state,
                street
            );
            description = CustomerMapController.formatAddress(street, city, state, postalCode, countryLabel);
        }
    }

    private static String normalizeCountry(String country, String countryCode, String state, String street) {
        String normalizedCode = String.isNotBlank(countryCode) ? countryCode.trim().toUpperCase() : null;
        if (String.isNotBlank(normalizedCode) && COUNTRY_CODE_TO_LABEL.containsKey(normalizedCode)) {
            return COUNTRY_CODE_TO_LABEL.get(normalizedCode);
        }

        String normalizedCountry = String.isNotBlank(country) ? country.trim().toUpperCase() : null;
        if (String.isNotBlank(normalizedCountry) && COUNTRY_ALIAS_TO_LABEL.containsKey(normalizedCountry)) {
            return COUNTRY_ALIAS_TO_LABEL.get(normalizedCountry);
        }

        if (String.isNotBlank(country)) {
            return country.trim();
        }

        String normalizedState = String.isNotBlank(state) ? state.trim().toUpperCase() : null;
        if (String.isNotBlank(normalizedState) && COUNTRY_ALIAS_TO_LABEL.containsKey(normalizedState)) {
            return COUNTRY_ALIAS_TO_LABEL.get(normalizedState);
        }

        String lastStreetLine = getLastMeaningfulLine(street);
        String upperStreet = String.isNotBlank(lastStreetLine) ? lastStreetLine.toUpperCase() : null;
        if (String.isNotBlank(upperStreet)) {
            if (COUNTRY_ALIAS_TO_LABEL.containsKey(upperStreet)) {
                return COUNTRY_ALIAS_TO_LABEL.get(upperStreet);
            }
            for (String alias : COUNTRY_ALIAS_TO_LABEL.keySet()) {
                if (upperStreet.contains(alias)) {
                    return COUNTRY_ALIAS_TO_LABEL.get(alias);
                }
            }
        }

        return countryCode;
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

    private static String getLastMeaningfulLine(String multilineValue) {
        if (String.isBlank(multilineValue)) {
            return null;
        }

        List<String> lines = multilineValue.replace('\r', '\n').split('\n');
        for (Integer index = lines.size() - 1; index >= 0; index--) {
            if (String.isNotBlank(lines[index])) {
                return lines[index].trim();
            }
        }

        return null;
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
            markers.add(new AccountMapMarker(accountRecord));
        }
        return markers;
    }
}

public with sharing class AccountIdVService {
    public class Request {
        @InvocableVariable(required=true)
        public Id accountId;

        @InvocableVariable
        public String customerNumber;

        @InvocableVariable
        public String phoneNumber;

        @InvocableVariable
        public String email;
    }

    public class Response {
        @InvocableVariable
        public Boolean customerNumberMatched;

        @InvocableVariable
        public Boolean phoneMatched;

        @InvocableVariable
        public Boolean emailMatched;

        @InvocableVariable
        public Integer matchedCount;

        @InvocableVariable
        public Boolean passed;

        @InvocableVariable
        public String resultMessage;
    }

    @InvocableMethod(label='Evaluate Account ID&V' description='Checks whether two of the supplied customer number, phone, and email values match the selected account.')
    public static List<Response> evaluate(List<Request> requests) {
        List<Response> responses = new List<Response>();
        if (requests == null || requests.isEmpty()) {
            return responses;
        }

        Set<Id> accountIds = new Set<Id>();
        for (Request requestItem : requests) {
            if (requestItem != null && requestItem.accountId != null) {
                accountIds.add(requestItem.accountId);
            }
        }

        Map<Id, Account> accountsById = new Map<Id, Account>();
        if (!accountIds.isEmpty()) {
            accountsById = new Map<Id, Account>([
                SELECT Id, AccountNumber, Phone
                FROM Account
                WHERE Id IN :accountIds
            ]);
        }

        Map<Id, List<Contact>> contactsByAccountId = new Map<Id, List<Contact>>();
        if (!accountIds.isEmpty()) {
            for (Contact contactRecord : [
                SELECT Id, AccountId, Email, Phone, MobilePhone
                FROM Contact
                WHERE AccountId IN :accountIds
            ]) {
                if (!contactsByAccountId.containsKey(contactRecord.AccountId)) {
                    contactsByAccountId.put(contactRecord.AccountId, new List<Contact>());
                }
                contactsByAccountId.get(contactRecord.AccountId).add(contactRecord);
            }
        }

        for (Request requestItem : requests) {
            Response responseItem = new Response();
            responseItem.customerNumberMatched = false;
            responseItem.phoneMatched = false;
            responseItem.emailMatched = false;
            responseItem.matchedCount = 0;
            responseItem.passed = false;

            if (requestItem == null || requestItem.accountId == null || !accountsById.containsKey(requestItem.accountId)) {
                responseItem.resultMessage = 'The selected account could not be found.';
                responses.add(responseItem);
                continue;
            }

            Account accountRecord = accountsById.get(requestItem.accountId);
            List<Contact> relatedContacts = contactsByAccountId.containsKey(requestItem.accountId)
                ? contactsByAccountId.get(requestItem.accountId)
                : new List<Contact>();

            String normalizedCustomerNumber = normalizeText(requestItem.customerNumber);
            String normalizedEmail = normalizeText(requestItem.email);
            String normalizedPhone = normalizePhone(requestItem.phoneNumber);

            if (!String.isBlank(normalizedCustomerNumber) &&
                normalizedCustomerNumber == normalizeText(accountRecord.AccountNumber)) {
                responseItem.customerNumberMatched = true;
            }

            if (!String.isBlank(normalizedPhone)) {
                if (normalizedPhone == normalizePhone(accountRecord.Phone)) {
                    responseItem.phoneMatched = true;
                } else {
                    for (Contact contactRecord : relatedContacts) {
                        if (normalizedPhone == normalizePhone(contactRecord.Phone) ||
                            normalizedPhone == normalizePhone(contactRecord.MobilePhone)) {
                            responseItem.phoneMatched = true;
                            break;
                        }
                    }
                }
            }

            if (!String.isBlank(normalizedEmail)) {
                for (Contact contactRecord : relatedContacts) {
                    if (normalizedEmail == normalizeText(contactRecord.Email)) {
                        responseItem.emailMatched = true;
                        break;
                    }
                }
            }

            Integer suppliedValueCount = 0;
            if (!String.isBlank(normalizedCustomerNumber)) {
                suppliedValueCount++;
            }
            if (!String.isBlank(normalizedPhone)) {
                suppliedValueCount++;
            }
            if (!String.isBlank(normalizedEmail)) {
                suppliedValueCount++;
            }

            Integer matchCount = 0;
            if (responseItem.customerNumberMatched) {
                matchCount++;
            }
            if (responseItem.phoneMatched) {
                matchCount++;
            }
            if (responseItem.emailMatched) {
                matchCount++;
            }

            responseItem.matchedCount = matchCount;
            responseItem.passed = suppliedValueCount >= 2 && matchCount >= 2;
            responseItem.resultMessage = buildResultMessage(responseItem, suppliedValueCount);
            responses.add(responseItem);
        }

        return responses;
    }

    private static String buildResultMessage(Response responseItem, Integer suppliedValueCount) {
        if (suppliedValueCount < 2) {
            return 'Enter at least two values to complete verification.';
        }
        if (responseItem.passed) {
            return 'Verification passed with ' + responseItem.matchedCount + ' matching values.';
        }
        return 'Verification failed. Only ' + responseItem.matchedCount + ' value(s) matched.';
    }

    private static String normalizeText(String rawValue) {
        return String.isBlank(rawValue) ? null : rawValue.trim().toLowerCase();
    }

    private static String normalizePhone(String rawValue) {
        if (String.isBlank(rawValue)) {
            return null;
        }

        String normalizedValue = '';
        for (Integer index = 0; index < rawValue.length(); index++) {
            String nextCharacter = rawValue.substring(index, index + 1);
            if (nextCharacter >= '0' && nextCharacter <= '9') {
                normalizedValue += nextCharacter;
            }
        }
        return String.isBlank(normalizedValue) ? null : normalizedValue;
    }
}

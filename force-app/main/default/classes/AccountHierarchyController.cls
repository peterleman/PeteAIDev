public with sharing class AccountHierarchyController {
    public class ParentAccountSummary {
        @AuraEnabled public Id recordId;
        @AuraEnabled public String name;
        @AuraEnabled public Integer directChildCount;
        @AuraEnabled public Integer totalContactCount;

        public ParentAccountSummary(Account accountRecord, Integer directChildren, Integer contacts) {
            recordId = accountRecord.Id;
            name = accountRecord.Name;
            directChildCount = directChildren;
            totalContactCount = contacts;
        }
    }

    public class ContactNode {
        @AuraEnabled public Id recordId;
        @AuraEnabled public String name;
        @AuraEnabled public String title;
        @AuraEnabled public String email;
        @AuraEnabled public String phone;

        public ContactNode(Contact contactRecord) {
            recordId = contactRecord.Id;
            name = contactRecord.Name;
            title = contactRecord.Title;
            email = contactRecord.Email;
            phone = contactRecord.Phone;
        }
    }

    public class AccountTreeNode {
        @AuraEnabled public Id recordId;
        @AuraEnabled public String name;
        @AuraEnabled public Boolean isGlobalAccount;
        @AuraEnabled public Integer directChildCount;
        @AuraEnabled public Integer totalDescendantCount;
        @AuraEnabled public Integer contactCount;
        @AuraEnabled public Integer totalContactCount;
        @AuraEnabled public List<ContactNode> contacts;
        @AuraEnabled public List<AccountTreeNode> children;

        public AccountTreeNode(Account accountRecord) {
            recordId = accountRecord.Id;
            name = accountRecord.Name;
            isGlobalAccount = (Boolean)accountRecord.get('Global_Account__c');
            directChildCount = 0;
            totalDescendantCount = 0;
            contactCount = 0;
            totalContactCount = 0;
            contacts = new List<ContactNode>();
            children = new List<AccountTreeNode>();
        }
    }

    private class TreeMetrics {
        Integer descendantCount;
        Integer totalContactCount;

        TreeMetrics(Integer descendants, Integer contacts) {
            descendantCount = descendants;
            totalContactCount = contacts;
        }
    }

    private static final Integer DEFAULT_MAX_RESULTS = 50;
    private static final Integer MAX_ALLOWED_RESULTS = 200;

    @AuraEnabled(cacheable=true)
    public static List<ParentAccountSummary> getCorporateParents(String searchKey, Integer maxResults) {
        Integer cappedResults = sanitizeLimit(maxResults);
        String likeClause = buildLikeClause(searchKey);
        List<Account> globalAccounts = [
            SELECT Id, Name, Global_Account__c
            FROM Account
            WHERE Global_Account__c = true
                AND Name LIKE :likeClause
            ORDER BY Name
            LIMIT :cappedResults
        ];

        if (globalAccounts.isEmpty()) {
            return new List<ParentAccountSummary>();
        }

        Set<Id> globalIds = new Map<Id, Account>(globalAccounts).keySet();
        Map<Id, Integer> directChildCountByParentId = getDirectChildCountByParentId(globalIds);
        Map<Id, Integer> directContactCountByParentId = getDirectContactCountByParentId(globalIds);

        List<ParentAccountSummary> summaries = new List<ParentAccountSummary>();
        for (Account globalAccount : globalAccounts) {
            summaries.add(
                new ParentAccountSummary(
                    globalAccount,
                    directChildCountByParentId.containsKey(globalAccount.Id)
                        ? directChildCountByParentId.get(globalAccount.Id)
                        : 0,
                    directContactCountByParentId.containsKey(globalAccount.Id)
                        ? directContactCountByParentId.get(globalAccount.Id)
                        : 0
                )
            );
        }

        return summaries;
    }

    @AuraEnabled(cacheable=true)
    public static AccountTreeNode getParentHierarchy(Id parentAccountId) {
        if (parentAccountId == null) {
            return null;
        }

        Map<Id, Account> accountById = new Map<Id, Account>([
            SELECT Id, Name, ParentId, Global_Account__c
            FROM Account
            WHERE Id = :parentAccountId
        ]);
        if (!accountById.containsKey(parentAccountId)) {
            return null;
        }

        Set<Id> frontierIds = new Set<Id>{ parentAccountId };
        while (!frontierIds.isEmpty()) {
            List<Account> nextLevelAccounts = [
                SELECT Id, Name, ParentId, Global_Account__c
                FROM Account
                WHERE ParentId IN :frontierIds
                ORDER BY Name
            ];

            frontierIds = new Set<Id>();
            for (Account childAccount : nextLevelAccounts) {
                accountById.put(childAccount.Id, childAccount);
                frontierIds.add(childAccount.Id);
            }
        }

        Set<Id> accountIds = accountById.keySet();
        Map<Id, List<Contact>> contactsByAccountId = getContactsByAccountId(accountIds);
        Map<Id, AccountTreeNode> nodeById = new Map<Id, AccountTreeNode>();
        Map<Id, List<Id>> childIdsByParentId = new Map<Id, List<Id>>();

        for (Account accountRecord : accountById.values()) {
            AccountTreeNode node = new AccountTreeNode(accountRecord);
            if (contactsByAccountId.containsKey(accountRecord.Id)) {
                for (Contact contactRecord : contactsByAccountId.get(accountRecord.Id)) {
                    node.contacts.add(new ContactNode(contactRecord));
                }
            }
            node.contactCount = node.contacts.size();
            node.totalContactCount = node.contactCount;
            nodeById.put(accountRecord.Id, node);
        }

        for (Account accountRecord : accountById.values()) {
            if (accountRecord.ParentId == null || !nodeById.containsKey(accountRecord.ParentId)) {
                continue;
            }

            if (!childIdsByParentId.containsKey(accountRecord.ParentId)) {
                childIdsByParentId.put(accountRecord.ParentId, new List<Id>());
            }
            childIdsByParentId.get(accountRecord.ParentId).add(accountRecord.Id);
        }

        for (Id parentId : childIdsByParentId.keySet()) {
            for (Id childId : childIdsByParentId.get(parentId)) {
                nodeById.get(parentId).children.add(nodeById.get(childId));
            }
            nodeById.get(parentId).directChildCount = nodeById.get(parentId).children.size();
        }

        rollupTreeMetrics(nodeById.get(parentAccountId));
        return nodeById.get(parentAccountId);
    }

    private static Integer sanitizeLimit(Integer requestedLimit) {
        Integer limitSize = requestedLimit == null ? DEFAULT_MAX_RESULTS : requestedLimit;
        if (limitSize < 1) {
            return DEFAULT_MAX_RESULTS;
        }
        return Math.min(limitSize, MAX_ALLOWED_RESULTS);
    }

    private static String buildLikeClause(String searchKey) {
        if (String.isBlank(searchKey)) {
            return '%';
        }

        return '%' + String.escapeSingleQuotes(searchKey.trim()) + '%';
    }

    private static Map<Id, Integer> getDirectChildCountByParentId(Set<Id> parentIds) {
        Map<Id, Integer> directChildCountByParentId = new Map<Id, Integer>();
        if (parentIds.isEmpty()) {
            return directChildCountByParentId;
        }

        for (AggregateResult result : [
            SELECT ParentId parentId, COUNT(Id) childCount
            FROM Account
            WHERE ParentId IN :parentIds
            GROUP BY ParentId
        ]) {
            directChildCountByParentId.put(
                (Id)result.get('parentId'),
                (Integer)result.get('childCount')
            );
        }
        return directChildCountByParentId;
    }

    private static Map<Id, Integer> getDirectContactCountByParentId(Set<Id> parentIds) {
        Map<Id, Integer> directContactCountByParentId = new Map<Id, Integer>();
        if (parentIds.isEmpty()) {
            return directContactCountByParentId;
        }

        for (AggregateResult result : [
            SELECT Account.ParentId parentId, COUNT(Id) contactCount
            FROM Contact
            WHERE Account.ParentId IN :parentIds
            GROUP BY Account.ParentId
        ]) {
            directContactCountByParentId.put(
                (Id)result.get('parentId'),
                (Integer)result.get('contactCount')
            );
        }

        return directContactCountByParentId;
    }

    private static Map<Id, List<Contact>> getContactsByAccountId(Set<Id> accountIds) {
        Map<Id, List<Contact>> contactsByAccountId = new Map<Id, List<Contact>>();
        if (accountIds.isEmpty()) {
            return contactsByAccountId;
        }

        for (Contact contactRecord : [
            SELECT Id, Name, Title, Email, Phone, AccountId
            FROM Contact
            WHERE AccountId IN :accountIds
            ORDER BY Name
        ]) {
            if (!contactsByAccountId.containsKey(contactRecord.AccountId)) {
                contactsByAccountId.put(contactRecord.AccountId, new List<Contact>());
            }
            contactsByAccountId.get(contactRecord.AccountId).add(contactRecord);
        }

        return contactsByAccountId;
    }

    private static TreeMetrics rollupTreeMetrics(AccountTreeNode node) {
        Integer descendants = node.children.size();
        Integer contacts = node.contactCount;

        for (AccountTreeNode childNode : node.children) {
            TreeMetrics childMetrics = rollupTreeMetrics(childNode);
            descendants += childMetrics.descendantCount;
            contacts += childMetrics.totalContactCount;
        }

        node.directChildCount = node.children.size();
        node.totalDescendantCount = descendants;
        node.totalContactCount = contacts;
        return new TreeMetrics(descendants, contacts);
    }
}

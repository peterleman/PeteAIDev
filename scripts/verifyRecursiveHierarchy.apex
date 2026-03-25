List<AccountHierarchyController.ParentAccountSummary> parents =
    AccountHierarchyController.getCorporateParents(null, 10);
System.debug(LoggingLevel.INFO, 'globalParents=' + parents.size());
if (parents.size() > 0) {
    AccountHierarchyController.AccountTreeNode root =
        AccountHierarchyController.getParentHierarchy(parents[0].recordId);
    System.debug(
        LoggingLevel.INFO,
        'root=' + root.name
        + ' directChildren=' + root.directChildCount
        + ' totalDescendants=' + root.totalDescendantCount
        + ' totalContacts=' + root.totalContactCount
    );

    for (AccountHierarchyController.AccountTreeNode childNode : root.children) {
        if (!childNode.children.isEmpty()) {
            System.debug(
                LoggingLevel.INFO,
                'nestedParent=' + childNode.name
                + ' nestedChildren=' + childNode.children.size()
                + ' directContacts=' + childNode.contactCount
            );
            if (!childNode.children[0].contacts.isEmpty()) {
                System.debug(
                    LoggingLevel.INFO,
                    'grandchildContact=' + childNode.children[0].contacts[0].name
                );
            }
            break;
        }
    }
}

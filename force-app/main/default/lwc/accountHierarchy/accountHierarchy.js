import { LightningElement } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getCorporateParents from '@salesforce/apex/AccountHierarchyController.getCorporateParents';
import getParentHierarchy from '@salesforce/apex/AccountHierarchyController.getParentHierarchy';

const SEARCH_DELAY = 250;
const DEFAULT_RESULT_SIZE = 75;

export default class AccountHierarchy extends NavigationMixin(LightningElement) {
    parentAccounts = [];
    selectedHierarchy;
    searchKey = '';
    detailSearchKey = '';
    selectedParentId;
    errorMessage;
    isLoadingParents = true;
    isLoadingHierarchy = false;
    allContactsExpanded = false;
    allBranchesExpanded = true;
    contactToggleSignal = 0;
    branchToggleSignal = 0;
    searchTimer;

    connectedCallback() {
        this.loadParentAccounts();
    }

    get hasParents() {
        return this.parentAccounts.length > 0;
    }

    get hasSelectedHierarchy() {
        return !!this.selectedHierarchy;
    }

    get displayedHierarchy() {
        if (!this.selectedHierarchy) {
            return undefined;
        }

        if (!this.detailSearchKey?.trim()) {
            return this.selectedHierarchy;
        }

        const filteredChildren = this.selectedHierarchy.children
            .map((childNode) => this.filterNode(childNode, this.detailSearchKey))
            .filter((childNode) => childNode);

        return {
            ...this.selectedHierarchy,
            children: filteredChildren,
            directChildCount: filteredChildren.length,
            totalDescendantCount: this.countDescendants(filteredChildren),
            totalContactCount: this.countContacts(filteredChildren)
        };
    }

    get showEmptyState() {
        return !this.isLoadingParents && !this.errorMessage && !this.hasParents;
    }

    get summary() {
        if (!this.hasParents) {
            return 'Search global accounts and open a hierarchy tree.';
        }

        const totalDirectChildren = this.parentAccounts.reduce(
            (sum, parent) => sum + parent.directChildCount,
            0
        );
        return `${this.parentAccounts.length} global accounts loaded, ${totalDirectChildren} direct child accounts in view`;
    }

    get parentOptions() {
        return this.parentAccounts.map((parent) => ({
            ...parent,
            itemClass:
                parent.recordId === this.selectedParentId
                    ? 'parent-item parent-item_selected'
                    : 'parent-item'
        }));
    }

    get selectedSummary() {
        if (!this.selectedHierarchy) {
            return 'Select a global account to inspect its hierarchy.';
        }

        const activeHierarchy = this.displayedHierarchy;
        const descendantLabel =
            activeHierarchy.totalDescendantCount === 1
                ? '1 descendant account'
                : `${activeHierarchy.totalDescendantCount} descendant accounts`;
        const contactLabel =
            activeHierarchy.totalContactCount === 1
                ? '1 contact'
                : `${activeHierarchy.totalContactCount} contacts`;
        return `${descendantLabel}, ${contactLabel}`;
    }

    get toggleAllContactsLabel() {
        return this.allContactsExpanded ? 'Collapse All Contacts' : 'Expand All Contacts';
    }

    get toggleAllBranchesLabel() {
        return this.allBranchesExpanded ? 'Collapse All Accounts' : 'Expand All Accounts';
    }

    handleSearchChange(event) {
        this.searchKey = event.target.value;
        window.clearTimeout(this.searchTimer);
        this.searchTimer = window.setTimeout(() => {
            this.loadParentAccounts();
        }, SEARCH_DELAY);
    }

    handleDetailSearchChange(event) {
        this.detailSearchKey = event.target.value;
    }

    async loadParentAccounts() {
        this.isLoadingParents = true;
        this.errorMessage = undefined;

        try {
            const data = await getCorporateParents({
                searchKey: this.searchKey,
                maxResults: DEFAULT_RESULT_SIZE
            });

            this.parentAccounts = data;

            if (!data.length) {
                this.selectedParentId = undefined;
                this.selectedHierarchy = undefined;
                this.detailSearchKey = '';
                this.resetTreeControls();
                return;
            }

            const nextParentId = data.some((parent) => parent.recordId === this.selectedParentId)
                ? this.selectedParentId
                : data[0].recordId;

            await this.loadHierarchy(nextParentId);
        } catch (error) {
            this.parentAccounts = [];
            this.selectedParentId = undefined;
            this.selectedHierarchy = undefined;
            this.detailSearchKey = '';
            this.resetTreeControls();
            this.errorMessage = 'Unable to load the global account list.';
        } finally {
            this.isLoadingParents = false;
        }
    }

    async loadHierarchy(parentId) {
        if (!parentId) {
            this.selectedParentId = undefined;
            this.selectedHierarchy = undefined;
            this.detailSearchKey = '';
            this.resetTreeControls();
            return;
        }

        this.selectedParentId = parentId;
        this.isLoadingHierarchy = true;
        this.errorMessage = undefined;
        this.detailSearchKey = '';
        this.resetTreeControls();

        try {
            this.selectedHierarchy = await getParentHierarchy({ parentAccountId: parentId });
        } catch (error) {
            this.selectedHierarchy = undefined;
            this.errorMessage = 'Unable to load the selected account hierarchy.';
        } finally {
            this.isLoadingHierarchy = false;
        }
    }

    handleSelectParent(event) {
        const { recordId } = event.currentTarget.dataset;
        if (recordId === this.selectedParentId) {
            return;
        }

        this.loadHierarchy(recordId);
    }

    handleToggleAllContacts() {
        this.allContactsExpanded = !this.allContactsExpanded;
        this.contactToggleSignal += 1;
    }

    handleToggleAllBranches() {
        this.allBranchesExpanded = !this.allBranchesExpanded;
        this.branchToggleSignal += 1;
    }

    handleNavigate(event) {
        const navigationSource =
            event.currentTarget?.dataset?.recordId
                ? event.currentTarget.dataset
                : event.detail;
        const { recordId, objectApiName } = navigationSource || {};

        if (!recordId || !objectApiName) {
            return;
        }

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId,
                objectApiName,
                actionName: 'view'
            }
        });
    }

    resetTreeControls() {
        this.allContactsExpanded = false;
        this.allBranchesExpanded = true;
        this.contactToggleSignal += 1;
        this.branchToggleSignal += 1;
    }

    filterNode(node, rawSearchKey) {
        const searchKey = rawSearchKey.trim().toLowerCase();
        const accountMatches = node.name?.toLowerCase().includes(searchKey);
        const matchingContacts = (node.contacts || []).filter((contact) =>
            contact.name?.toLowerCase().includes(searchKey)
        );
        const contactMatches = matchingContacts.length > 0;
        const matchingChildren = (node.children || [])
            .map((childNode) => this.filterNode(childNode, searchKey))
            .filter((childNode) => childNode);
        const childMatches = matchingChildren.length > 0;

        if (!accountMatches && !contactMatches && !childMatches) {
            return null;
        }

        const visibleChildren = accountMatches ? node.children || [] : matchingChildren;
        const visibleContacts = accountMatches ? node.contacts || [] : matchingContacts;

        return {
            ...node,
            contacts: visibleContacts,
            children: visibleChildren,
            forceExpandBranch: accountMatches || childMatches || contactMatches,
            forceShowContacts: contactMatches,
            directChildCount: visibleChildren.length,
            totalDescendantCount: this.countDescendants(visibleChildren),
            totalContactCount:
                (visibleContacts || []).length + this.countContacts(visibleChildren)
        };
    }

    countDescendants(children) {
        return (children || []).reduce(
            (total, childNode) => total + 1 + this.countDescendants(childNode.children || []),
            0
        );
    }

    countContacts(children) {
        return (children || []).reduce(
            (total, childNode) =>
                total +
                (childNode.contacts?.length || 0) +
                this.countContacts(childNode.children || []),
            0
        );
    }
}

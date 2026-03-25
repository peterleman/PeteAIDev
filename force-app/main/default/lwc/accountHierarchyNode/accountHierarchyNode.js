import { LightningElement, api } from 'lwc';

export default class AccountHierarchyNode extends LightningElement {
    @api node;
    @api isRoot = false;

    branchExpanded = true;
    contactsExpanded = false;
    _expandAllContacts = false;
    _contactToggleSignal = 0;
    _expandAllBranches = true;
    _branchToggleSignal = 0;

    @api
    get expandAllContacts() {
        return this._expandAllContacts;
    }

    set expandAllContacts(value) {
        this._expandAllContacts = value;
    }

    @api
    get contactToggleSignal() {
        return this._contactToggleSignal;
    }

    set contactToggleSignal(value) {
        this._contactToggleSignal = value;
        this.contactsExpanded = this._expandAllContacts;
    }

    @api
    get expandAllBranches() {
        return this._expandAllBranches;
    }

    set expandAllBranches(value) {
        this._expandAllBranches = value;
    }

    @api
    get branchToggleSignal() {
        return this._branchToggleSignal;
    }

    set branchToggleSignal(value) {
        this._branchToggleSignal = value;
        if (!this.isRoot) {
            this.branchExpanded = this._expandAllBranches;
        }
    }

    get hasChildren() {
        return !!this.node?.children?.length;
    }

    get hasContacts() {
        return !!this.node?.contactCount;
    }

    get showChildren() {
        return this.hasChildren && (this.isRoot || this.branchExpanded || this.node?.forceExpandBranch);
    }

    get showContacts() {
        return (
            this.hasContacts &&
            (this.expandAllContacts || this.contactsExpanded || this.node?.forceShowContacts)
        );
    }

    get branchIconName() {
        return this.showChildren ? 'utility:chevrondown' : 'utility:chevronright';
    }

    get contactToggleLabel() {
        return this.showContacts ? 'Collapse contacts' : 'Expand contacts';
    }

    get nodeClass() {
        return this.isRoot ? 'node node_root' : 'node';
    }

    get nodeBadgeClass() {
        return this.node?.isGlobalAccount ? 'node-badge node-badge_global' : 'node-badge';
    }

    handleToggleBranch() {
        this.branchExpanded = !this.branchExpanded;
    }

    handleToggleContacts() {
        this.contactsExpanded = !this.contactsExpanded;
    }

    handleNavigate(event) {
        this.dispatchEvent(
            new CustomEvent('navigate', {
                bubbles: true,
                composed: true,
                detail: {
                    recordId: event.currentTarget.dataset.recordId,
                    objectApiName: event.currentTarget.dataset.objectApiName
                }
            })
        );
    }
}

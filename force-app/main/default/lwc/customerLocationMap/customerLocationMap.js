import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import getCustomerLocations from '@salesforce/apex/CustomerMapController.getCustomerLocations';

const DEFAULT_MARKER_PATH =
    'M12 2C8.134 2 5 5.134 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.866-3.134-7-7-7zm0 9.5A2.5 2.5 0 1 1 12 6.5a2.5 2.5 0 0 1 0 5z';

const SEGMENTATION_STYLES = {
    Gold: { color: '#c79a00', label: 'Gold' },
    Silver: { color: '#8f99a3', label: 'Silver' },
    Bronze: { color: '#a05a2c', label: 'Bronze' },
    Default: { color: '#1b96ff', label: 'Unassigned' }
};

const EUROPE_CENTER = {
    location: {
        Latitude: 48.5,
        Longitude: 11.5
    }
};
const EUROPE_ZOOM_LEVEL = 3;

const MAX_RENDERED_ACCOUNTS = 200;
const MIN_LIST_HEIGHT = 220;
const VIEWPORT_BOTTOM_GAP = 24;

export default class CustomerLocationMap extends NavigationMixin(LightningElement) {
    accounts = [];
    errorMessage;
    selectedMarkerValue;
    selectedCountry = '';
    hasRendered = false;
    wiredLocationsResult;
    resizeHandler = () => this.updateListHeight();

    @wire(getCustomerLocations)
    wiredCustomerLocations(result) {
        this.wiredLocationsResult = result;
        const { data, error } = result;
        if (data) {
            this.accounts = data;
            this.errorMessage = undefined;
            if (!this.displayedAccounts.some((account) => account.recordId === this.selectedMarkerValue)) {
                this.selectedMarkerValue = undefined;
            }
            requestAnimationFrame(() => this.updateListHeight());
        } else if (error) {
            this.accounts = [];
            this.errorMessage =
                'Unable to load customer locations. Check access to the Apex controller and Account address fields.';
            this.selectedMarkerValue = undefined;
            // Keep the error detail in the console for admins investigating runtime failures.
            // eslint-disable-next-line no-console
            console.error('customerLocationMap wire error', error);
        }
    }

    renderedCallback() {
        if (this.hasRendered) {
            return;
        }

        this.hasRendered = true;
        window.addEventListener('resize', this.resizeHandler);
        requestAnimationFrame(() => this.updateListHeight());
    }

    disconnectedCallback() {
        window.removeEventListener('resize', this.resizeHandler);
    }

    get hasMarkers() {
        return this.mapMarkers.length > 0;
    }

    get showEmptyState() {
        return !this.errorMessage && !this.hasMarkers;
    }

    get filteredAccounts() {
        return this.accounts.filter((account) => {
            const matchesCountry = !this.selectedCountry || account.countryLabel === this.selectedCountry;
            return matchesCountry;
        });
    }

    get displayedAccounts() {
        return this.filteredAccounts.slice(0, MAX_RENDERED_ACCOUNTS);
    }

    get countryOptions() {
        return this.buildOptions(this.accounts.map((account) => account.countryLabel));
    }

    get resultSummary() {
        const visible = this.filteredAccounts.length;
        const total = this.accounts.length;
        return this.selectedCountry ? `${visible} customers in ${this.selectedCountry}` : `${total} customers`;
    }

    get visibleListAccounts() {
        return this.displayedAccounts.map((account) => ({
            ...account,
            accessibleLabel: this.buildAccessibleLabel(account),
            itemClass:
                account.recordId === this.selectedMarkerValue
                    ? 'customer-item customer-item_selected slds-button_reset slds-size_full slds-text-align_left slds-p-around_small slds-border_bottom slds-theme_default'
                    : 'customer-item slds-button_reset slds-size_full slds-text-align_left slds-p-around_small slds-border_bottom slds-theme_default'
        }));
    }

    get listSummary() {
        const visibleCount = this.displayedAccounts.length;
        if (this.filteredAccounts.length > MAX_RENDERED_ACCOUNTS) {
            return `Showing first ${visibleCount} of ${this.filteredAccounts.length} on the map and list`;
        }
        return `${visibleCount} customers`;
    }

    get mapMarkers() {
        return this.displayedAccounts.map((account) => ({
            value: account.recordId,
            title: account.accountName,
            mapIcon: this.buildMarkerIcon(account.segmentation),
            location: this.buildMarkerLocation(account)
        }));
    }

    get mapOptions() {
        return {
            draggable: true,
            scrollwheel: true
        };
    }

    get mapCenter() {
        if (this.selectedCountry) {
            return undefined;
        }
        return EUROPE_CENTER;
    }

    get mapZoomLevel() {
        if (this.selectedCountry) {
            return undefined;
        }
        return EUROPE_ZOOM_LEVEL;
    }

    get showDefaultMap() {
        return !this.selectedCountry;
    }

    get showFilteredMap() {
        return !!this.selectedCountry;
    }

    handleCountryChange(event) {
        this.selectedCountry = event.detail.value;
        this.selectedMarkerValue = undefined;
    }

    handleMarkerSelect(event) {
        const recordId = event.target.selectedMarkerValue || event.detail.selectedMarkerValue;
        this.selectedMarkerValue = recordId;
        if (recordId) {
            this.navigateToAccount(recordId);
        }
    }

    handleListItemClick(event) {
        const { recordId } = event.currentTarget.dataset;
        this.selectedMarkerValue = recordId;
        this.navigateToAccount(recordId);
    }

    handleRetry() {
        this.errorMessage = undefined;
        this.selectedMarkerValue = undefined;
        if (this.wiredLocationsResult) {
            refreshApex(this.wiredLocationsResult);
        }
    }

    navigateToAccount(recordId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId,
                objectApiName: 'Account',
                actionName: 'view'
            }
        });
    }

    get segmentationLegend() {
        return ['Gold', 'Silver', 'Bronze', 'Default'].map((name) => ({
            key: name,
            label: SEGMENTATION_STYLES[name].label,
            swatchClass: `legend-swatch legend-swatch_${name.toLowerCase()} slds-var-m-right_xx-small slds-shrink-none`
        }));
    }

    buildMarkerIcon(segmentation) {
        const style = SEGMENTATION_STYLES[segmentation] || SEGMENTATION_STYLES.Default;
        return {
            path: DEFAULT_MARKER_PATH,
            fillColor: style.color,
            fillOpacity: 1,
            strokeColor: '#16325c',
            strokeWeight: 1,
            scale: 1.35,
            anchor: { x: 12, y: 24 }
        };
    }

    buildMarkerLocation(account) {
        return {
            Street: account.street,
            City: account.city,
            State: account.state,
            PostalCode: account.postalCode,
            Country: account.countryLabel
        };
    }

    buildOptions(values) {
        const uniqueValues = [...new Set(values.filter((value) => value))].sort((left, right) =>
            left.localeCompare(right)
        );

        return [{ label: 'All', value: '' }, ...uniqueValues.map((value) => ({ label: value, value }))];
    }

    buildAccessibleLabel(account) {
        return [account.accountName, account.countryLabel, account.description].filter((value) => value).join(', ');
    }

    updateListHeight() {
        const listPanel = this.template.querySelector('.list-panel');
        if (!listPanel) {
            return;
        }

        const { top } = listPanel.getBoundingClientRect();
        const availableHeight = Math.max(MIN_LIST_HEIGHT, Math.floor(window.innerHeight - top - VIEWPORT_BOTTOM_GAP));
        this.template.host.style.setProperty('--customer-list-height', `${availableHeight}px`);
    }
}
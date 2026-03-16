import { LightningElement, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getCustomerLocations from '@salesforce/apex/CustomerMapController.getCustomerLocations';

const DEFAULT_MARKER_PATH =
    'M12 2C8.134 2 5 5.134 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.866-3.134-7-7-7zm0 9.5A2.5 2.5 0 1 1 12 6.5a2.5 2.5 0 0 1 0 5z';

const SEGMENTATION_STYLES = {
    Gold: { color: '#c79a00', label: 'Gold' },
    Silver: { color: '#8f99a3', label: 'Silver' },
    Bronze: { color: '#a05a2c', label: 'Bronze' },
    Default: { color: '#1b96ff', label: 'Unassigned' }
};

const COUNTRY_VIEWPORTS = {
    Australia: { latitude: -25.2744, longitude: 133.7751, zoom: 4 },
    Brazil: { latitude: -14.235, longitude: -51.9253, zoom: 4 },
    Canada: { latitude: 56.1304, longitude: -106.3468, zoom: 4 },
    France: { latitude: 46.2276, longitude: 2.2137, zoom: 5 },
    Germany: { latitude: 51.1657, longitude: 10.4515, zoom: 5 },
    India: { latitude: 20.5937, longitude: 78.9629, zoom: 4 },
    Italy: { latitude: 41.8719, longitude: 12.5674, zoom: 5 },
    Japan: { latitude: 36.2048, longitude: 138.2529, zoom: 5 },
    Netherlands: { latitude: 52.1326, longitude: 5.2913, zoom: 6 },
    Singapore: { latitude: 1.3521, longitude: 103.8198, zoom: 9 },
    'South Africa': { latitude: -30.5595, longitude: 22.9375, zoom: 5 },
    Spain: { latitude: 40.4637, longitude: -3.7492, zoom: 5 },
    'United Arab Emirates': { latitude: 23.4241, longitude: 53.8478, zoom: 6 },
    'United Kingdom': { latitude: 54.5, longitude: -2.5, zoom: 6 },
    'United States': { latitude: 39.8283, longitude: -98.5795, zoom: 4 }
};

const MAX_LIST_ITEMS = 200;
const MIN_LIST_HEIGHT = 220;
const VIEWPORT_BOTTOM_GAP = 24;

export default class CustomerLocationMap extends NavigationMixin(LightningElement) {
    accounts = [];
    errorMessage;
    selectedMarkerValue;
    selectedCountry = '';
    hasRendered = false;
    resizeHandler = () => this.updateListHeight();

    @wire(getCustomerLocations)
    wiredCustomerLocations({ data, error }) {
        if (data) {
            this.accounts = data;
            this.errorMessage = undefined;
            this.selectedMarkerValue = undefined;
            requestAnimationFrame(() => this.updateListHeight());
        } else if (error) {
            this.accounts = [];
            this.errorMessage = 'Unable to load customer locations.';
            this.selectedMarkerValue = undefined;
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

    get countryOptions() {
        return this.buildOptions(this.accounts.map((account) => account.countryLabel));
    }

    get resultSummary() {
        const visible = this.filteredAccounts.length;
        const total = this.accounts.length;
        return this.selectedCountry ? `${visible} customers in ${this.selectedCountry}` : `${total} customers`;
    }

    get visibleListAccounts() {
        return this.filteredAccounts.slice(0, MAX_LIST_ITEMS).map((account) => ({
            ...account,
            itemClass:
                account.recordId === this.selectedMarkerValue ? 'customer-item customer-item_selected' : 'customer-item'
        }));
    }

    get listSummary() {
        const visibleCount = Math.min(this.filteredAccounts.length, MAX_LIST_ITEMS);
        if (this.filteredAccounts.length > MAX_LIST_ITEMS) {
            return `Showing first ${visibleCount} of ${this.filteredAccounts.length}`;
        }
        return `${visibleCount} customers`;
    }

    get mapMarkers() {
        return this.filteredAccounts.map((account) => ({
            value: account.recordId,
            title: account.accountName,
            description: account.description,
            mapIcon: this.buildMarkerIcon(account.segmentation),
            location: this.buildMarkerLocation(account)
        }));
    }

    get mapCenter() {
        const centeredAccounts = this.filteredAccounts
            .map((account) => ({
                account,
                viewport: COUNTRY_VIEWPORTS[account.countryLabel]
            }))
            .filter((item) => item.viewport);

        if (!centeredAccounts.length) {
            return undefined;
        }

        if (this.selectedCountry && centeredAccounts.length) {
            const countryViewport = COUNTRY_VIEWPORTS[this.selectedCountry];
            if (countryViewport) {
                return {
                    Latitude: countryViewport.latitude,
                    Longitude: countryViewport.longitude
                };
            }
        }

        const total = centeredAccounts.length;
        const latitude =
            centeredAccounts.reduce((sum, item) => sum + item.viewport.latitude, 0) / total;
        const longitude =
            centeredAccounts.reduce((sum, item) => sum + item.viewport.longitude, 0) / total;

        return {
            Latitude: Number(latitude.toFixed(4)),
            Longitude: Number(longitude.toFixed(4))
        };
    }

    get zoomLevel() {
        if (this.selectedCountry && COUNTRY_VIEWPORTS[this.selectedCountry]) {
            return COUNTRY_VIEWPORTS[this.selectedCountry].zoom;
        }

        const distinctCountries = new Set(
            this.filteredAccounts.map((account) => account.countryLabel).filter((value) => value)
        ).size;

        if (distinctCountries > 8) {
            return 2;
        }
        if (distinctCountries > 3) {
            return 3;
        }
        if (distinctCountries > 1) {
            return 4;
        }
        return 5;
    }

    handleCountryChange(event) {
        this.selectedCountry = event.detail.value;
        this.selectedMarkerValue = undefined;
    }

    handleMarkerSelect(event) {
        const recordId = event.target.selectedMarkerValue || event.detail.selectedMarkerValue;
        this.selectedMarkerValue = recordId;
        if (!recordId) {
            return;
        }

        this.navigateToAccount(recordId);
    }

    handleListItemClick(event) {
        const { recordId } = event.currentTarget.dataset;
        this.selectedMarkerValue = recordId;
        this.navigateToAccount(recordId);
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
        return ['Gold', 'Silver', 'Bronze'].map((name) => ({
            key: name,
            label: name,
            style: `background-color: ${SEGMENTATION_STYLES[name].color};`
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

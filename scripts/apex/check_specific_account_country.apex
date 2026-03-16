List<CustomerMapController.AccountMapMarker> markers = CustomerMapController.getCustomerLocations();
for (CustomerMapController.AccountMapMarker marker : markers) {
    if (marker.recordId == '001dL00001xgRB9QAM') {
        System.debug('ACCOUNT_COUNTRY=' + marker.countryLabel);
        System.debug('ACCOUNT_STREET=' + marker.street);
    }
}

List<CustomerMapController.AccountMapMarker> markers = CustomerMapController.getCustomerLocations();
Set<String> labels = new Set<String>();
for (CustomerMapController.AccountMapMarker marker : markers) {
    labels.add(marker.countryLabel);
}
System.debug('COUNTRY_LABELS=' + labels);

abstract class AddressPickerEvent {}

class InitializeAddressPickerEvent extends AddressPickerEvent {}

class SearchAddressEvent extends AddressPickerEvent {
  final String query;

  SearchAddressEvent({required this.query});
}

class SelectAddressEvent extends AddressPickerEvent {
  final String address;
  final String subAddress;
  final double latitude;
  final double longitude;

  SelectAddressEvent({
    required this.address,
    required this.subAddress,
    required this.latitude,
    required this.longitude,
  });
}

class UseCurrentLocationEvent extends AddressPickerEvent {}

class ClearSearchEvent extends AddressPickerEvent {}

class CloseAddressPickerEvent extends AddressPickerEvent {}
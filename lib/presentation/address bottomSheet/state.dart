class AddressSuggestion {
  final String mainText;
  final String secondaryText;
  final double? latitude;
  final double? longitude;
  final String? placeId;

  AddressSuggestion({
    required this.mainText,
    required this.secondaryText,
    this.latitude,
    this.longitude,
    this.placeId,
  });
}

abstract class AddressPickerState {}

class AddressPickerInitial extends AddressPickerState {}

class AddressPickerLoading extends AddressPickerState {}

class AddressPickerLoadSuccess extends AddressPickerState {
  final List<AddressSuggestion> suggestions;
  final String searchQuery;

  AddressPickerLoadSuccess({
    required this.suggestions,
    this.searchQuery = '',
  });
}

class AddressPickerLoadFailure extends AddressPickerState {
  final String error;

  AddressPickerLoadFailure({required this.error});
}

class LocationDetecting extends AddressPickerState {}

class LocationDetected extends AddressPickerState {
  final String address;
  final String subAddress;
  final double latitude;
  final double longitude;

  LocationDetected({
    required this.address,
    required this.subAddress,
    required this.latitude,
    required this.longitude,
  });
}

class AddressSelected extends AddressPickerState {
  final String address;
  final String subAddress;
  final double latitude;
  final double longitude;

  AddressSelected({
    required this.address,
    required this.subAddress,
    required this.latitude,
    required this.longitude,
  });
}

class AddressPickerClosed extends AddressPickerState {}
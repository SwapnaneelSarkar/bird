abstract class AddressState {}

class AddressInitialState extends AddressState {}

class AddressLoadingState extends AddressState {}

class AddressSubmittedState extends AddressState {
  final String address;

  AddressSubmittedState({required this.address});
}

class LocationDetectedState extends AddressState {
  final String location;
  final double latitude;
  final double longitude;

  LocationDetectedState({
    required this.location,
    required this.latitude,
    required this.longitude,
  });
}

class AddressErrorState extends AddressState {
  final String error;

  AddressErrorState({required this.error});
}
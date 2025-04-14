abstract class AddressState {}

class AddressInitialState extends AddressState {}

class AddressLoadingState extends AddressState {}

class AddressSubmittedState extends AddressState {
  final String address;

  AddressSubmittedState({required this.address});
}

class LocationDetectedState extends AddressState {
  final String location;

  LocationDetectedState({required this.location});
}

class AddressErrorState extends AddressState {
  final String error;

  AddressErrorState({required this.error});
}

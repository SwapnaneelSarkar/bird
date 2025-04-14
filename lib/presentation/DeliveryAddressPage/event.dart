abstract class AddressEvent {}

class SubmitAddressEvent extends AddressEvent {
  final String address;

  SubmitAddressEvent({required this.address});
}

class DetectLocationEvent extends AddressEvent {}

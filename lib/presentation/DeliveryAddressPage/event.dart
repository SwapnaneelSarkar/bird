abstract class AddressEvent {}

class SubmitAddressEvent extends AddressEvent {
  final String address;
  final double latitude;
  final double longitude;

  SubmitAddressEvent({
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}

class DetectLocationEvent extends AddressEvent {}
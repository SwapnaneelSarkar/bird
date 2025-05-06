import 'package:equatable/equatable.dart';

abstract class AddressEvent extends Equatable {
  const AddressEvent();
  
  @override
  List<Object?> get props => [];
}

class SubmitAddressEvent extends AddressEvent {
  final String address;
  final double latitude;
  final double longitude;

  const SubmitAddressEvent({
    required this.address,
    required this.latitude,
    required this.longitude,
  });
  
  @override
  List<Object?> get props => [address, latitude, longitude];
}

class DetectLocationEvent extends AddressEvent {}

class SelectPlaceEvent extends AddressEvent {
  final String placeId;
  
  const SelectPlaceEvent(this.placeId);
  
  @override
  List<Object?> get props => [placeId];
}
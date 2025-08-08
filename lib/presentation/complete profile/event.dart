import 'package:equatable/equatable.dart';

abstract class CompleteProfileEvent extends Equatable {
  const CompleteProfileEvent();

  @override
  List<Object?> get props => [];
}

class SubmitProfile extends CompleteProfileEvent {
  final String name;
  final String? email;
  final String? address;
  final double? latitude;
  final double? longitude;

  const SubmitProfile({
    required this.name,
    this.email,
    this.address,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [name, email, address, latitude, longitude];
}

class SelectPlace extends CompleteProfileEvent {
  final String placeId;
  
  const SelectPlace(this.placeId);
  
  @override
  List<Object?> get props => [placeId];
}
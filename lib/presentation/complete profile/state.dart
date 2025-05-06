import 'package:equatable/equatable.dart';

abstract class CompleteProfileState extends Equatable {
  const CompleteProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends CompleteProfileState {}

class ProfileSubmitting extends CompleteProfileState {}

class ProfileSuccess extends CompleteProfileState {}

class ProfileFailure extends CompleteProfileState {
  final String error;
  const ProfileFailure(this.error);

  @override
  List<Object?> get props => [error];
}

class PlaceSelected extends CompleteProfileState {
  final String address;
  final double latitude;
  final double longitude;
  
  const PlaceSelected({
    required this.address,
    required this.latitude,
    required this.longitude,
  });
  
  @override
  List<Object?> get props => [address, latitude, longitude];
}
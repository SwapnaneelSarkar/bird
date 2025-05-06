import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class CompleteProfileEvent extends Equatable {
  const CompleteProfileEvent();

  @override
  List<Object?> get props => [];
}

class SubmitProfile extends CompleteProfileEvent {
  final String name;
  final String email;
  final File? avatar;
  final String? address;
  final double? latitude;
  final double? longitude;

  const SubmitProfile({
    required this.name,
    required this.email,
    this.avatar,
    this.address,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [name, email, avatar, address, latitude, longitude];
}

class SelectPlace extends CompleteProfileEvent {
  final String placeId;
  
  const SelectPlace(this.placeId);
  
  @override
  List<Object?> get props => [placeId];
}
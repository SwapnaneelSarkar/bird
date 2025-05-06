import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadHomeData extends HomeEvent {
  const LoadHomeData();
}

class ToggleVegOnly extends HomeEvent {
  final bool value;
  
  const ToggleVegOnly(this.value);
  
  @override
  List<Object?> get props => [value];
}

class UpdateUserAddress extends HomeEvent {
  final String address;
  final double latitude;
  final double longitude;
  
  const UpdateUserAddress({
    required this.address,
    required this.latitude,
    required this.longitude,
  });
  
  @override
  List<Object?> get props => [address, latitude, longitude];
}
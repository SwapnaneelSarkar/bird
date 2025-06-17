// lib/presentation/home page/event.dart - Complete version with address management
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

class FilterByCategory extends HomeEvent {
  final String? categoryName; // null means show all categories
  
  const FilterByCategory(this.categoryName);
  
  @override
  List<Object?> get props => [categoryName];
}

// Address management events
class LoadSavedAddresses extends HomeEvent {
  const LoadSavedAddresses();
}

class SaveNewAddress extends HomeEvent {
  final String addressLine1;
  final String addressName; // Home, Office, Friend's place, etc.
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final double latitude;
  final double longitude;
  final bool makeDefault;
  
  const SaveNewAddress({
    required this.addressLine1,
    required this.addressName,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    required this.latitude,
    required this.longitude,
    this.makeDefault = false,
  });
  
  @override
  List<Object?> get props => [
    addressLine1,
    addressName,
    city,
    state,
    postalCode,
    country,
    latitude,
    longitude,
    makeDefault,
  ];
}

class SelectSavedAddress extends HomeEvent {
  final Map<String, dynamic> address;
  
  const SelectSavedAddress(this.address);
  
  @override
  List<Object?> get props => [address];
}
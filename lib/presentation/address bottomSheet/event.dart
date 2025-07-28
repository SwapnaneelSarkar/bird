// lib/presentation/address bottomSheet/event.dart
import 'package:equatable/equatable.dart';
import 'state.dart';

abstract class AddressPickerEvent extends Equatable {
  const AddressPickerEvent();
  
  @override
  List<Object?> get props => [];
}

class InitializeAddressPickerEvent extends AddressPickerEvent {}

class SearchAddressEvent extends AddressPickerEvent {
  final String query;

  const SearchAddressEvent({required this.query});

  @override
  List<Object?> get props => [query];
}

class SelectAddressEvent extends AddressPickerEvent {
  final String address;
  final String subAddress;
  final double latitude;
  final double longitude;
  final String fullAddress;

  const SelectAddressEvent({
    required this.address,
    required this.subAddress,
    required this.latitude,
    required this.longitude,
    required this.fullAddress,
  });

  @override
  List<Object?> get props => [address, subAddress, latitude, longitude, fullAddress];
}

class UseCurrentLocationEvent extends AddressPickerEvent {}

class ClearSearchEvent extends AddressPickerEvent {}

class CloseAddressPickerEvent extends AddressPickerEvent {}

// Address saving events
class SaveAddressEvent extends AddressPickerEvent {
  final String address;
  final String subAddress;
  final String addressName;
  final double latitude;
  final double longitude;
  final String fullAddress;

  const SaveAddressEvent({
    required this.address,
    required this.subAddress,
    required this.addressName,
    required this.latitude,
    required this.longitude,
    required this.fullAddress,
  });

  @override
  List<Object?> get props => [address, subAddress, addressName, latitude, longitude, fullAddress];
}

// Saved addresses events
class LoadSavedAddressesEvent extends AddressPickerEvent {}

class SelectSavedAddressEvent extends AddressPickerEvent {
  final SavedAddress savedAddress;

  const SelectSavedAddressEvent({required this.savedAddress});

  @override
  List<Object?> get props => [savedAddress];
}

class DeleteSavedAddressEvent extends AddressPickerEvent {
  final String addressId;

  const DeleteSavedAddressEvent({required this.addressId});

  @override
  List<Object?> get props => [addressId];
}

// Edit address events
class EditAddressEvent extends AddressPickerEvent {
  final SavedAddress savedAddress;

  const EditAddressEvent({required this.savedAddress});

  @override
  List<Object?> get props => [savedAddress];
}

class UpdateAddressEvent extends AddressPickerEvent {
  final String addressId;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final double latitude;
  final double longitude;
  final bool isDefault;

  const UpdateAddressEvent({
    required this.addressId,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.isDefault,
  });

  @override
  List<Object?> get props => [
    addressId,
    addressLine1,
    addressLine2,
    city,
    state,
    postalCode,
    country,
    latitude,
    longitude,
    isDefault,
  ];
}

// Share address events
class ShareAddressEvent extends AddressPickerEvent {
  final SavedAddress savedAddress;

  const ShareAddressEvent({required this.savedAddress});

  @override
  List<Object?> get props => [savedAddress];
}
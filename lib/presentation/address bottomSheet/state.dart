// lib/presentation/address bottomSheet/state.dart
import 'package:equatable/equatable.dart';
import '../../utils/timezone_utils.dart';

class AddressSuggestion extends Equatable {
  final String mainText;
  final String secondaryText;
  final double latitude;
  final double longitude;
  final String? placeId;

  const AddressSuggestion({
    required this.mainText,
    required this.secondaryText,
    required this.latitude,
    required this.longitude,
    this.placeId,
  });

  @override
  List<Object?> get props => [mainText, secondaryText, latitude, longitude, placeId];
}

class SavedAddress extends Equatable {
  final String addressId;
  final String userId;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final bool isDefault;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SavedAddress({
    required this.addressId,
    required this.userId,
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    required this.isDefault,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SavedAddress.fromJson(Map<String, dynamic> json) {
    return SavedAddress(
      addressId: json['address_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      addressLine1: json['address_line1']?.toString() ?? '',
      addressLine2: json['address_line2']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      postalCode: json['postal_code']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      isDefault: json['is_default'] == 1 || json['is_default'] == true,
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      createdAt: TimezoneUtils.parseToIST(json['created_at']?.toString() ?? ''),
      updatedAt: TimezoneUtils.parseToIST(json['updated_at']?.toString() ?? ''),
    );
  }

  String get displayName => addressLine2.isNotEmpty ? addressLine2 : 'Other';
  
  String get fullAddress => '$addressLine1, $city, $state';

  @override
  List<Object?> get props => [
    addressId,
    userId,
    addressLine1,
    addressLine2,
    city,
    state,
    postalCode,
    country,
    isDefault,
    latitude,
    longitude,
    createdAt,
    updatedAt,
  ];
}

abstract class AddressPickerState extends Equatable {
  const AddressPickerState();
  
  @override
  List<Object?> get props => [];
}

class AddressPickerInitial extends AddressPickerState {}

class AddressPickerLoading extends AddressPickerState {}

class AddressPickerLoadSuccess extends AddressPickerState {
  final List<AddressSuggestion> suggestions;
  final String searchQuery;
  final List<SavedAddress> savedAddresses;

  const AddressPickerLoadSuccess({
    required this.suggestions,
    this.searchQuery = '',
    this.savedAddresses = const [],
  });

  @override
  List<Object?> get props => [suggestions, searchQuery, savedAddresses];
}

class AddressPickerLoadFailure extends AddressPickerState {
  final String error;

  const AddressPickerLoadFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

class LocationDetecting extends AddressPickerState {}

class LocationDetected extends AddressPickerState {
  final String address;
  final String subAddress;
  final double latitude;
  final double longitude;

  const LocationDetected({
    required this.address,
    required this.subAddress,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [address, subAddress, latitude, longitude];
}

class AddressSelected extends AddressPickerState {
  final String address;
  final String subAddress;
  final double latitude;
  final double longitude;

  const AddressSelected({
    required this.address,
    required this.subAddress,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [address, subAddress, latitude, longitude];
}

class AddressNameInputRequired extends AddressPickerState {
  final String address;
  final String subAddress;
  final double latitude;
  final double longitude;
  final String fullAddress;

  const AddressNameInputRequired({
    required this.address,
    required this.subAddress,
    required this.latitude,
    required this.longitude,
    required this.fullAddress,
  });

  @override
  List<Object?> get props => [address, subAddress, latitude, longitude, fullAddress];
}

class AddressPickerClosed extends AddressPickerState {}

// Address saving states
class AddressSaving extends AddressPickerState {}

class AddressSavedSuccessfully extends AddressPickerState {
  final String address;
  final String subAddress;
  final double latitude;
  final double longitude;
  final String addressName;
  final String addressId;

  const AddressSavedSuccessfully({
    required this.address,
    required this.subAddress,
    required this.latitude,
    required this.longitude,
    required this.addressName,
    required this.addressId,
  });

  @override
  List<Object?> get props => [address, subAddress, latitude, longitude, addressName, addressId];
}

// Saved addresses states
class SavedAddressesLoading extends AddressPickerState {}

class SavedAddressesLoaded extends AddressPickerState {
  final List<SavedAddress> savedAddresses;
  final List<AddressSuggestion> suggestions;

  const SavedAddressesLoaded({
    required this.savedAddresses,
    required this.suggestions,
  });

  @override
  List<Object?> get props => [savedAddresses, suggestions];
}

class SavedAddressesLoadFailure extends AddressPickerState {
  final String error;

  const SavedAddressesLoadFailure({required this.error});

  @override
  List<Object?> get props => [error];
}

class SavedAddressSelected extends AddressPickerState {
  final SavedAddress savedAddress;

  const SavedAddressSelected({required this.savedAddress});

  @override
  List<Object?> get props => [savedAddress];
}

// Address deletion states
class AddressDeleting extends AddressPickerState {}

class AddressDeletedSuccessfully extends AddressPickerState {
  final String deletedAddressId;

  const AddressDeletedSuccessfully({required this.deletedAddressId});

  @override
  List<Object?> get props => [deletedAddressId];
}

// Address editing states
class AddressEditing extends AddressPickerState {
  final SavedAddress savedAddress;

  const AddressEditing({required this.savedAddress});

  @override
  List<Object?> get props => [savedAddress];
}

class AddressUpdating extends AddressPickerState {}

class AddressUpdatedSuccessfully extends AddressPickerState {
  final SavedAddress updatedAddress;

  const AddressUpdatedSuccessfully({required this.updatedAddress});

  @override
  List<Object?> get props => [updatedAddress];
}

// Address sharing states
class AddressSharing extends AddressPickerState {}

class AddressSharedSuccessfully extends AddressPickerState {
  final SavedAddress sharedAddress;

  const AddressSharedSuccessfully({required this.sharedAddress});

  @override
  List<Object?> get props => [sharedAddress];
}
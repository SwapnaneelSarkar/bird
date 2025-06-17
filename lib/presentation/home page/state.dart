// lib/presentation/home page/state.dart - Complete version with address management
import 'package:equatable/equatable.dart';

abstract class HomeState extends Equatable {
  const HomeState();
  
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final String userAddress;
  final bool vegOnly;
  final List<dynamic> restaurants;
  final List<dynamic> categories;
  final double? userLatitude;
  final double? userLongitude;
  final String? selectedCategory;
  final List<dynamic> allRestaurants;
  final List<Map<String, dynamic>> savedAddresses;
  final String? errorMessage;
  
  const HomeLoaded({
    required this.userAddress,
    required this.vegOnly,
    required this.restaurants,
    required this.categories,
    this.userLatitude,
    this.userLongitude,
    this.selectedCategory,
    required this.allRestaurants,
    this.savedAddresses = const [],
    this.errorMessage,
  });
  
  @override
  List<Object?> get props => [
    userAddress, 
    vegOnly, 
    restaurants, 
    categories, 
    userLatitude, 
    userLongitude, 
    selectedCategory,
    allRestaurants,
    savedAddresses,
    errorMessage,
  ];
  
  HomeLoaded copyWith({
    String? userAddress,
    bool? vegOnly,
    List<dynamic>? restaurants,
    List<dynamic>? categories,
    double? userLatitude,
    double? userLongitude,
    String? selectedCategory,
    List<dynamic>? allRestaurants,
    List<Map<String, dynamic>>? savedAddresses,
    String? errorMessage,
  }) {
    return HomeLoaded(
      userAddress: userAddress ?? this.userAddress,
      vegOnly: vegOnly ?? this.vegOnly,
      restaurants: restaurants ?? this.restaurants,
      categories: categories ?? this.categories,
      userLatitude: userLatitude ?? this.userLatitude,
      userLongitude: userLongitude ?? this.userLongitude,
      selectedCategory: selectedCategory,
      allRestaurants: allRestaurants ?? this.allRestaurants,
      savedAddresses: savedAddresses ?? this.savedAddresses,
      errorMessage: errorMessage,
    );
  }
}

class HomeError extends HomeState {
  final String message;
  
  const HomeError(this.message);
  
  @override
  List<Object> get props => [message];
}

// Address-related states
class AddressUpdateSuccess extends HomeState {
  final String address;
  
  const AddressUpdateSuccess(this.address);
  
  @override
  List<Object> get props => [address];
}

class AddressUpdateFailure extends HomeState {
  final String error;
  
  const AddressUpdateFailure(this.error);
  
  @override
  List<Object> get props => [error];
}

class AddressSaveSuccess extends HomeState {
  final String message;
  
  const AddressSaveSuccess(this.message);
  
  @override
  List<Object> get props => [message];
}

class AddressSaveFailure extends HomeState {
  final String error;
  
  const AddressSaveFailure(this.error);
  
  @override
  List<Object> get props => [error];
}
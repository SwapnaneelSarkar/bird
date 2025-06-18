// lib/presentation/home page/state.dart - COMPLETELY FIXED VERSION
import 'package:equatable/equatable.dart';
import '../../models/restaurant_model.dart';

abstract class HomeState extends Equatable {
  const HomeState();
  
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final List<Restaurant> restaurants;
  final List<Map<String, dynamic>> categories;
  final String userAddress;
  final double? userLatitude;
  final double? userLongitude;
  final bool vegOnly;
  final String? selectedCategory;
  final List<Map<String, dynamic>> savedAddresses;
  
  const HomeLoaded({
    required this.restaurants,
    required this.categories,
    required this.userAddress,
    this.userLatitude,
    this.userLongitude,
    this.vegOnly = false,
    this.selectedCategory,
    this.savedAddresses = const [],
  });
  
  // Helper method to get filtered restaurants
  List<Restaurant> get filteredRestaurants {
    var filtered = restaurants;
    
    // Filter by veg only if enabled
    if (vegOnly) {
      filtered = filtered.where((restaurant) => restaurant.isVeg == true).toList();
    }
    
    // Filter by category if selected
    if (selectedCategory != null) {
      filtered = filtered.where((restaurant) {
        return restaurant.cuisine.toLowerCase().contains(selectedCategory!.toLowerCase()) ||
               restaurant.name.toLowerCase().contains(selectedCategory!.toLowerCase());
      }).toList();
    }
    
    return filtered;
  }
  
  // Copy with method for state updates
  HomeLoaded copyWith({
    List<Restaurant>? restaurants,
    List<Map<String, dynamic>>? categories,
    String? userAddress,
    double? userLatitude,
    double? userLongitude,
    bool? vegOnly,
    String? selectedCategory,
    List<Map<String, dynamic>>? savedAddresses,
  }) {
    return HomeLoaded(
      restaurants: restaurants ?? this.restaurants,
      categories: categories ?? this.categories,
      userAddress: userAddress ?? this.userAddress,
      userLatitude: userLatitude ?? this.userLatitude,
      userLongitude: userLongitude ?? this.userLongitude,
      vegOnly: vegOnly ?? this.vegOnly,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      savedAddresses: savedAddresses ?? this.savedAddresses,
    );
  }
  
  @override
  List<Object?> get props => [
    restaurants, 
    categories, 
    userAddress, 
    userLatitude, 
    userLongitude, 
    vegOnly, 
    selectedCategory,
    savedAddresses,
  ];
}

class HomeError extends HomeState {
  final String message;
  
  const HomeError(this.message);
  
  @override
  List<Object> get props => [message];
}

// Address-related states
class AddressUpdating extends HomeState {}

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
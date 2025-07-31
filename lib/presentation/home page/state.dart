// lib/presentation/home page/state.dart - COMPLETELY FIXED VERSION
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
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
  final List<Map<String, dynamic>> foodTypes;
  final String userAddress;
  final double? userLatitude;
  final double? userLongitude;
  final bool vegOnly;
  final String? selectedCategoryId;
  final String? selectedFoodTypeId;
  final List<Map<String, dynamic>> savedAddresses;
  
  const HomeLoaded({
    required this.restaurants,
    required this.categories,
    required this.foodTypes,
    required this.userAddress,
    this.userLatitude,
    this.userLongitude,
    this.vegOnly = false,
    this.selectedCategoryId,
    this.selectedFoodTypeId,
    this.savedAddresses = const [],
  });
  
  // Helper method to get filtered restaurants
  List<Restaurant> get filteredRestaurants {
    var filtered = restaurants;
    
    debugPrint('HomeState: Starting filtering with ${filtered.length} restaurants');
    debugPrint('HomeState: Current filters - vegOnly: $vegOnly, selectedCategoryId: $selectedCategoryId, selectedFoodTypeId: $selectedFoodTypeId');
    
    // Filter by veg only if enabled
    if (vegOnly) {
      filtered = filtered.where((restaurant) => restaurant.isVeg == true).toList();
      debugPrint('HomeState: After veg filter: ${filtered.length} restaurants');
    }
    
    // Filter by category if selected
    if (selectedCategoryId != null) {
      filtered = filtered.where((restaurant) {
        // Match category id in availableCategories
        final contains = restaurant.availableCategories.contains(selectedCategoryId);
        debugPrint('HomeState: Restaurant ${restaurant.name} - availableCategories: ${restaurant.availableCategories}, contains $selectedCategoryId: $contains');
        return contains;
      }).toList();
      debugPrint('HomeState: After category filter: ${filtered.length} restaurants');
    }
    
    // Filter by food type if selected
    if (selectedFoodTypeId != null) {
      filtered = filtered.where((restaurant) {
        // Check if restaurant has the selected food type in availableFoodTypes
        final hasFoodType = restaurant.availableFoodTypes.contains(selectedFoodTypeId);
        debugPrint('HomeState: Restaurant ${restaurant.name} - availableFoodTypes: ${restaurant.availableFoodTypes}, contains $selectedFoodTypeId: $hasFoodType');
        
        // Only show restaurants that have the selected food type
        if (hasFoodType) {
          debugPrint('HomeState: Restaurant ${restaurant.name} has the selected food type, showing it');
          return true;
        }
        
        // If restaurant doesn't have the selected food type, don't show it
        debugPrint('HomeState: Restaurant ${restaurant.name} does not have the selected food type, hiding it');
        return false;
      }).toList();
      debugPrint('HomeState: After food type filter: ${filtered.length} restaurants');
    }
    
    debugPrint('HomeState: Final filtered results: ${filtered.length} restaurants');
    return filtered;
  }
  
  static const _noValue = Object();

  // Copy with method for state updates
  HomeLoaded copyWith({
    List<Restaurant>? restaurants,
    List<Map<String, dynamic>>? categories,
    List<Map<String, dynamic>>? foodTypes,
    String? userAddress,
    double? userLatitude,
    double? userLongitude,
    bool? vegOnly,
    Object? selectedCategoryId = _noValue,
    Object? selectedFoodTypeId = _noValue,
    List<Map<String, dynamic>>? savedAddresses,
  }) {
    return HomeLoaded(
      restaurants: restaurants ?? this.restaurants,
      categories: categories ?? this.categories,
      foodTypes: foodTypes ?? this.foodTypes,
      userAddress: userAddress ?? this.userAddress,
      userLatitude: userLatitude ?? this.userLatitude,
      userLongitude: userLongitude ?? this.userLongitude,
      vegOnly: vegOnly ?? this.vegOnly,
      selectedCategoryId: selectedCategoryId == _noValue ? this.selectedCategoryId : selectedCategoryId as String?,
      selectedFoodTypeId: selectedFoodTypeId == _noValue ? this.selectedFoodTypeId : selectedFoodTypeId as String?,
      savedAddresses: savedAddresses ?? this.savedAddresses,
    );
  }
  
    @override
  List<Object?> get props => [
    restaurants,
    categories,
    foodTypes,
    userAddress,
    userLatitude,
    userLongitude,
    vegOnly,
    selectedCategoryId,
    selectedFoodTypeId,
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
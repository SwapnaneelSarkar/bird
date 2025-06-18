// lib/presentation/home page/bloc.dart - Updated version with Profile API priority
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../service/token_service.dart';
import '../../../service/profile_get_service.dart';
import '../../../service/address_service.dart';
import '../../../service/update_user_service.dart';
import '../../../constants/api_constant.dart';
import '../../models/restaurant_model.dart';
import 'event.dart';
import 'state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final ProfileApiService _profileApiService = ProfileApiService();
  final UpdateUserService _updateUserService = UpdateUserService();
  
  HomeBloc() : super(HomeInitial()) {
    on<LoadHomeData>(_onLoadHomeData);
    on<ToggleVegOnly>(_onToggleVegOnly);
    on<UpdateUserAddress>(_onUpdateUserAddress);
    on<FilterByCategory>(_onFilterByCategory);
    on<LoadSavedAddresses>(_onLoadSavedAddresses);
    on<SaveNewAddress>(_onSaveNewAddress);
    on<SelectSavedAddress>(_onSelectSavedAddress);
  }
  
  Future<void> _onLoadHomeData(LoadHomeData event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    
    try {
      final userId = await TokenService.getUserId();
      final token = await TokenService.getToken();
      
      debugPrint('HomeBloc: Loading home data with token: ${token != null ? 'Found' : 'Not found'}');
      
      String userAddress = 'Add delivery address';
      double? latitude;
      double? longitude;
      List<Map<String, dynamic>> savedAddresses = [];
      
      if (userId != null && token != null) {
        // PRIORITY 1: Fetch user profile data from API first
        debugPrint('HomeBloc: Fetching user profile from API...');
        final profileResult = await _profileApiService.getUserProfile(
          token: token,
          userId: userId,
        );
        
        if (profileResult['success'] == true) {
          final userData = profileResult['data'] as Map<String, dynamic>;
          
          // Use profile address as primary address
          if (userData['address'] != null && userData['address'].toString().isNotEmpty) {
            userAddress = userData['address'].toString();
            debugPrint('HomeBloc: Using profile address: $userAddress');
            
            // Get coordinates from profile
            if (userData['latitude'] != null && userData['longitude'] != null) {
              latitude = double.tryParse(userData['latitude'].toString());
              longitude = double.tryParse(userData['longitude'].toString());
              debugPrint('HomeBloc: Profile coordinates - Lat: $latitude, Long: $longitude');
            }
          }
        }
        
        // PRIORITY 2: Load saved addresses for the address picker
        debugPrint('HomeBloc: Loading saved addresses...');
        final addressResult = await AddressService.getAllAddresses();
        if (addressResult['success'] == true && addressResult['data'] != null) {
          savedAddresses = List<Map<String, dynamic>>.from(addressResult['data']);
          debugPrint('HomeBloc: Loaded ${savedAddresses.length} saved addresses');
        }
        
        // PRIORITY 3: If no profile address, fallback to saved addresses
        if (userAddress == 'Add delivery address' && savedAddresses.isNotEmpty) {
          debugPrint('HomeBloc: No profile address, using saved address as fallback');
          final firstAddress = savedAddresses.first;
          userAddress = firstAddress['address_line1'] ?? 'Add delivery address';
          latitude = double.tryParse(firstAddress['latitude']?.toString() ?? '');
          longitude = double.tryParse(firstAddress['longitude']?.toString() ?? '');
          debugPrint('HomeBloc: Fallback address: $userAddress');
        }
      }
      
      // Fetch restaurants and categories in parallel
      final restaurantsFuture = (latitude != null && longitude != null) 
          ? _fetchRestaurants(latitude, longitude)
          : _fetchRestaurantsWithoutLocation();
      final categoriesFuture = _fetchCategories();
      
      final results = await Future.wait([restaurantsFuture, categoriesFuture]);
      final restaurants = results[0];
      final categories = results[1];
      
      debugPrint('HomeBloc: Fetched ${restaurants.length} restaurants and ${categories.length} categories');
      
      emit(HomeLoaded(
        userAddress: userAddress,
        vegOnly: false,
        restaurants: restaurants,
        categories: categories,
        userLatitude: latitude,
        userLongitude: longitude,
        allRestaurants: restaurants,
        savedAddresses: savedAddresses,
      ));
      
    } catch (e) {
      debugPrint('HomeBloc: Error loading home data: $e');
      emit(HomeError('Failed to load data. Please try again.'));
    }
  }

  Future<void> _onUpdateUserAddress(UpdateUserAddress event, Emitter<HomeState> emit) async {
    try {
      debugPrint('HomeBloc: Updating user address to: ${event.address}');
      debugPrint('HomeBloc: New coordinates - Lat: ${event.latitude}, Long: ${event.longitude}');
      
      final currentState = state;
      if (currentState is! HomeLoaded) return;
      
      // Get token and user ID
      final token = await TokenService.getToken();
      final userId = await TokenService.getUserId();
      
      if (token == null || userId == null) {
        debugPrint('HomeBloc: No token or user ID for address update');
        emit(AddressUpdateFailure('Please login again'));
        return;
      }
      
      // Update address in profile via API
      debugPrint('HomeBloc: Updating address via Profile API...');
      final updateResult = await _updateUserService.updateUserProfileWithId(
        token: token,
        userId: userId,
        address: event.address,
        latitude: event.latitude,
        longitude: event.longitude,
      );
      
      if (updateResult['success'] == true) {
        debugPrint('HomeBloc: Address updated successfully in profile');
        
        // Fetch updated restaurants based on new location
        final restaurants = await _fetchRestaurants(event.latitude, event.longitude);
        
        // Update state with new address and restaurants
        emit(currentState.copyWith(
          userAddress: event.address,
          userLatitude: event.latitude,
          userLongitude: event.longitude,
          restaurants: restaurants,
          allRestaurants: restaurants,
        ));
        
        // Emit success message
        emit(AddressUpdateSuccess(event.address));
        
        // Restore to main state
        emit(currentState.copyWith(
          userAddress: event.address,
          userLatitude: event.latitude,
          userLongitude: event.longitude,
          restaurants: restaurants,
          allRestaurants: restaurants,
        ));
        
      } else {
        debugPrint('HomeBloc: Failed to update address: ${updateResult['message']}');
        emit(AddressUpdateFailure(updateResult['message'] ?? 'Failed to update address'));
      }
      
    } catch (e) {
      debugPrint('HomeBloc: Error updating address: $e');
      emit(AddressUpdateFailure('Error updating address. Please try again.'));
    }
  }

  Future<void> _onLoadSavedAddresses(LoadSavedAddresses event, Emitter<HomeState> emit) async {
    try {
      debugPrint('HomeBloc: Loading saved addresses...');
      final currentState = state;
      if (currentState is! HomeLoaded) return;
      
      final addressResult = await AddressService.getAllAddresses();
      if (addressResult['success'] == true && addressResult['data'] != null) {
        final savedAddresses = List<Map<String, dynamic>>.from(addressResult['data']);
        debugPrint('HomeBloc: Reloaded ${savedAddresses.length} saved addresses');
        
        emit(currentState.copyWith(savedAddresses: savedAddresses));
      }
    } catch (e) {
      debugPrint('HomeBloc: Error loading saved addresses: $e');
    }
  }

  Future<void> _onSaveNewAddress(SaveNewAddress event, Emitter<HomeState> emit) async {
    try {
      debugPrint('HomeBloc: Saving new address: ${event.addressLine1}');
      
      final currentState = state;
      if (currentState is! HomeLoaded) return;
      
      // Save address via AddressService
      final result = await AddressService.saveAddress(
        addressLine1: event.addressLine1,
        addressLine2: event.addressName,
        city: event.city,
        state: event.state,
        postalCode: event.postalCode,
        country: event.country,
        latitude: event.latitude,
        longitude: event.longitude,
        isDefault: event.makeDefault,
      );
      
      if (result['success'] == true) {
        debugPrint('HomeBloc: Address saved successfully');
        
        // If this is set as default or user wants to use it, update profile
        if (event.makeDefault) {
          // Update user profile with this address
          add(UpdateUserAddress(
            address: event.addressLine1,
            latitude: event.latitude,
            longitude: event.longitude,
          ));
        }
        
        // Reload saved addresses to show the new one
        add(const LoadSavedAddresses());
        
        emit(AddressSaveSuccess('Address saved successfully'));
      } else {
        debugPrint('HomeBloc: Failed to save address: ${result['message']}');
        emit(AddressSaveFailure(result['message'] ?? 'Failed to save address'));
      }
    } catch (e) {
      debugPrint('HomeBloc: Error saving address: $e');
      emit(AddressSaveFailure('Error saving address. Please try again.'));
    }
  }

  Future<void> _onSelectSavedAddress(SelectSavedAddress event, Emitter<HomeState> emit) async {
    try {
      debugPrint('HomeBloc: Selecting saved address: ${event.address}');
      
      final address = event.address;
      final addressLine = address['address_line1']?.toString() ?? '';
      final latitude = double.tryParse(address['latitude']?.toString() ?? '') ?? 0.0;
      final longitude = double.tryParse(address['longitude']?.toString() ?? '') ?? 0.0;
      
      if (addressLine.isNotEmpty && latitude != 0.0 && longitude != 0.0) {
        // Update the user's current address in profile
        add(UpdateUserAddress(
          address: addressLine,
          latitude: latitude,
          longitude: longitude,
        ));
      }
    } catch (e) {
      debugPrint('HomeBloc: Error selecting saved address: $e');
    }
  }

  Future<void> _onToggleVegOnly(ToggleVegOnly event, Emitter<HomeState> emit) async {
    final currentState = state;
    if (currentState is HomeLoaded) {
      List<dynamic> filteredRestaurants = currentState.allRestaurants;
      
      if (event.value) {
        filteredRestaurants = currentState.allRestaurants.where((restaurant) {
          return restaurant['isVegetarian'] == true || restaurant['veg_nonveg'] == 'veg';
        }).toList();
      }
      
      emit(currentState.copyWith(
        vegOnly: event.value,
        restaurants: filteredRestaurants,
      ));
    }
  }

  Future<void> _onFilterByCategory(FilterByCategory event, Emitter<HomeState> emit) async {
    final currentState = state;
    if (currentState is HomeLoaded) {
      List<dynamic> filteredRestaurants = currentState.allRestaurants;
      
      // Apply category filter if specified
      if (event.categoryName != null) {
        filteredRestaurants = currentState.allRestaurants.where((restaurant) {
          final cuisine = restaurant['cuisine']?.toString().toLowerCase() ?? '';
          final category = restaurant['category']?.toString().toLowerCase() ?? '';
          final targetCategory = event.categoryName!.toLowerCase();
          
          return cuisine.contains(targetCategory) || category.contains(targetCategory);
        }).toList();
      }
      
      // Apply veg filter if active
      if (currentState.vegOnly) {
        filteredRestaurants = filteredRestaurants.where((restaurant) {
          return restaurant['isVegetarian'] == true || restaurant['veg_nonveg'] == 'veg';
        }).toList();
      }
      
      emit(currentState.copyWith(
        selectedCategory: event.categoryName,
        restaurants: filteredRestaurants,
      ));
    }
  }

  // Helper methods
  Future<List<dynamic>> _fetchRestaurants(double latitude, double longitude) async {
    try {
      debugPrint('HomeBloc: Fetching restaurants with coordinates - Lat: $latitude, Long: $longitude');
      
      final token = await TokenService.getToken();
      if (token == null) {
        debugPrint('HomeBloc: No token available for restaurant fetch');
        return [];
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/api/restaurants?latitude=$latitude&longitude=$longitude');
      debugPrint('HomeBloc: Restaurant API URL: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('HomeBloc: Restaurant API response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true && data['data'] != null) {
          final List<dynamic> restaurantsData = data['data'];
          debugPrint('HomeBloc: Successfully fetched ${restaurantsData.length} restaurants');
          
          return restaurantsData.map((restaurantJson) {
            final restaurant = Restaurant.fromJson(restaurantJson);
            return restaurant.toMap();
          }).toList();
        }
      }
      
      debugPrint('HomeBloc: Restaurant API failed or returned no data');
      return [];
    } catch (e) {
      debugPrint('HomeBloc: Error fetching restaurants: $e');
      return [];
    }
  }

  Future<List<dynamic>> _fetchRestaurantsWithoutLocation() async {
    try {
      debugPrint('HomeBloc: Fetching restaurants without location');
      
      final token = await TokenService.getToken();
      if (token == null) return [];

      final url = Uri.parse('${ApiConstants.baseUrl}/api/restaurants');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true && data['data'] != null) {
          final List<dynamic> restaurantsData = data['data'];
          return restaurantsData.map((restaurantJson) {
            final restaurant = Restaurant.fromJson(restaurantJson);
            return restaurant.toMap();
          }).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('HomeBloc: Error fetching restaurants without location: $e');
      return [];
    }
  }

  Future<List<dynamic>> _fetchCategories() async {
    try {
      debugPrint('HomeBloc: Fetching categories');
      return [
        {'name': 'Pizza', 'icon': 'local_pizza', 'color': 'red'},
        {'name': 'Burger', 'icon': 'lunch_dining', 'color': 'amber'},
        {'name': 'Sushi', 'icon': 'set_meal', 'color': 'blue'},
        {'name': 'Dessert', 'icon': 'icecream', 'color': 'pink'},
        {'name': 'Drinks', 'icon': 'local_drink', 'color': 'teal'},
      ];
    } catch (e) {
      debugPrint('HomeBloc: Error fetching categories: $e');
      return [];
    }
  }
}
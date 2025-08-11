// lib/presentation/home page/bloc.dart - REWRITTEN WITH SUPERCATEGORY FILTER
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../service/token_service.dart';
import '../../../service/profile_get_service.dart';
import '../../../service/address_service.dart';
import '../../../service/update_user_service.dart';
import '../../../service/category_recommendation_service.dart';
import '../../../service/food_type_service.dart';
import '../../../service/location_validation_service.dart';
import '../../../constants/api_constant.dart';
import '../../models/restaurant_model.dart';
import '../../models/recent_order_model.dart';
import 'event.dart';
import 'state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final ProfileApiService _profileApiService = ProfileApiService();
  final UpdateUserService _updateUserService = UpdateUserService();
  
  // Store the selected supercategory ID for filtering
  String? _selectedSupercategoryId;
  
  // Add a public getter for selectedSupercategoryId
  String? get selectedSupercategoryId => _selectedSupercategoryId;
  
  HomeBloc({String? selectedSupercategoryId}) : super(HomeInitial()) {
    _selectedSupercategoryId = selectedSupercategoryId;
    debugPrint('HomeBloc: Constructor called with selectedSupercategoryId: $_selectedSupercategoryId');
    
    on<LoadHomeData>(_onLoadHomeData);
    on<ToggleVegOnly>(_onToggleVegOnly);
    on<UpdateUserAddress>(_onUpdateUserAddress);
    on<FilterByCategory>(_onFilterByCategory);
    on<FilterByFoodType>(_onFilterByFoodType);
    on<LoadSavedAddresses>(_onLoadSavedAddresses);
    on<SaveNewAddress>(_onSaveNewAddress);
    on<SelectSavedAddress>(_onSelectSavedAddress);
    on<ResetFilters>((event, emit) {
      debugPrint('HomeBloc: ResetFilters event received');
      final currentState = state;
      if (currentState is HomeLoaded) {
        debugPrint('HomeBloc: Resetting all filters - vegOnly: false, selectedCategoryId: null, selectedFoodTypeId: null');
        emit(currentState.copyWith(vegOnly: false, selectedCategoryId: null, selectedFoodTypeId: null));
        debugPrint('HomeBloc: All filters reset successfully');
      } else {
        debugPrint('HomeBloc: Current state is not HomeLoaded, cannot reset filters');
      }
    });
  }
  
  Future<void> _onLoadHomeData(LoadHomeData event, Emitter<HomeState> emit) async {
    emit(HomeLoading());
    
    try {
      final userId = await TokenService.getUserId();
      final token = await TokenService.getToken();
      
      debugPrint('🏠 HomeBloc: Loading home data with token: ${token != null ? 'Found' : 'Not found'}');
      debugPrint('🏠 HomeBloc: Selected supercategory ID: $_selectedSupercategoryId');
      debugPrint('🏠 HomeBloc: User ID: $userId');
      
      String userAddress = 'Add delivery address';
      double? latitude;
      double? longitude;
      List<Map<String, dynamic>> savedAddresses = [];
      
      if (userId != null && token != null) {
        // Always fetch fresh location data when home page loads
        debugPrint('🏠 HomeBloc: Fetching fresh location data for home page...');
        
        // Force refresh user profile data from API to get latest location
        debugPrint('🏠 HomeBloc: Force refreshing user profile from API...');
        
        // Add a small delay to ensure any pending location updates are completed
        await Future.delayed(const Duration(milliseconds: 100));
        
        final profileResult = await _profileApiService.getUserProfile(
          token: token,
          userId: userId,
        );
        
        if (profileResult['success'] == true) {
          final userData = profileResult['data'] as Map<String, dynamic>;
          
          debugPrint('🏠 HomeBloc: Fresh profile data received:');
          debugPrint('  📍 Address: ${userData['address']}');
          debugPrint('  📍 Latitude: ${userData['latitude']}');
          debugPrint('  📍 Longitude: ${userData['longitude']}');
          debugPrint('  📍 Updated At: ${userData['updated_at']}');
          
          // Update user data in TokenService to ensure consistency
          await TokenService.saveUserData(userData);
          debugPrint('🏠 HomeBloc: Updated user data in TokenService');
          
          // Use profile address as primary address
          if (userData['address'] != null && userData['address'].toString().isNotEmpty) {
            userAddress = userData['address'].toString();
            debugPrint('🏠 HomeBloc: Using fresh profile address: $userAddress');
            
            // Get coordinates from profile
            if (userData['latitude'] != null && userData['longitude'] != null) {
              latitude = double.tryParse(userData['latitude'].toString());
              longitude = double.tryParse(userData['longitude'].toString());
              debugPrint('🏠 HomeBloc: Fresh profile coordinates - Lat: $latitude, Long: $longitude');
            }
          }
        } else {
          debugPrint('🏠 HomeBloc: Failed to fetch fresh profile data, using cached data');
        }
        
        // Load saved addresses for the address picker
        debugPrint('HomeBloc: Loading saved addresses...');
        final addressResult = await AddressService.getAllAddresses();
        if (addressResult['success'] == true && addressResult['data'] != null) {
          savedAddresses = List<Map<String, dynamic>>.from(addressResult['data']);
          debugPrint('HomeBloc: Loaded ${savedAddresses.length} saved addresses');
        }
        
        // If no profile address, fallback to saved addresses
        if (userAddress == 'Add delivery address' && savedAddresses.isNotEmpty) {
          debugPrint('HomeBloc: No profile address, using saved address as fallback');
          final firstAddress = savedAddresses.first;
          userAddress = firstAddress['address_line1'] ?? 'Add delivery address';
          latitude = double.tryParse(firstAddress['latitude']?.toString() ?? '');
          longitude = double.tryParse(firstAddress['longitude']?.toString() ?? '');
          debugPrint('HomeBloc: Fallback address: $userAddress');
        }
      }
      
      debugPrint('🏠 HomeBloc: Final fresh location data for restaurant fetching:');
      debugPrint('  📍 Address: $userAddress');
      debugPrint('  📍 Latitude: $latitude');
      debugPrint('  📍 Longitude: $longitude');
      
      // Fetch restaurants, categories, food types, and recent orders in parallel
      final restaurantsFuture = (latitude != null && longitude != null) 
          ? _fetchRestaurants(latitude, longitude)
          : _fetchRestaurantsWithoutLocation();
      final categoriesFuture = _fetchCategories();
      final foodTypesFuture = FoodTypeService.fetchFoodTypes();
      final recentOrdersFuture = _fetchRecentOrders(token, userId);
      
      final results = await Future.wait([restaurantsFuture, categoriesFuture, foodTypesFuture, recentOrdersFuture]);
      final allRestaurants = results[0] as List<Restaurant>;
      final categories = results[1] as List<Map<String, dynamic>>;
      final foodTypes = results[2] as List<Map<String, dynamic>>;
      final recentOrders = results[3] as List<RecentOrderModel>;
      
      // Use all restaurants since filtering is now handled by the API
      List<Restaurant> filteredRestaurants = allRestaurants;
      debugPrint('🏠 HomeBloc: Fetched ${allRestaurants.length} restaurants from API with fresh location');
      debugPrint('🏠 HomeBloc: Fetched ${categories.length} categories, and ${foodTypes.length} food types');
      
      // Check location serviceability if we have coordinates and no restaurants
      bool isLocationServiceable = true;
      String? locationServiceabilityMessage;
      
      if (latitude != null && longitude != null && userAddress != 'Add delivery address' && allRestaurants.isEmpty) {
        debugPrint('🏠 HomeBloc: No restaurants found, checking location serviceability...');
        
        final serviceabilityResult = await LocationValidationService.checkLocationServiceabilityWithDetails(
          latitude: latitude,
          longitude: longitude,
          address: userAddress,
        );
        
        isLocationServiceable = serviceabilityResult['isServiceable'] ?? true;
        locationServiceabilityMessage = serviceabilityResult['detailedMessage'];
        
        debugPrint('🏠 HomeBloc: Location serviceability check result:');
        debugPrint('  📍 Is serviceable: $isLocationServiceable');
        debugPrint('  📍 Message: $locationServiceabilityMessage');
      }
      
      debugPrint('🏠 HomeBloc: === FRESH LOCATION FLOW SUMMARY ===');
      debugPrint('🏠 HomeBloc: Final address: $userAddress');
      debugPrint('🏠 HomeBloc: Final coordinates: ($latitude, $longitude)');
      debugPrint('🏠 HomeBloc: Restaurants found: ${filteredRestaurants.length}');
      debugPrint('🏠 HomeBloc: Categories found: ${categories.length}');
      debugPrint('🏠 HomeBloc: Location serviceable: $isLocationServiceable');
      debugPrint('🏠 HomeBloc: === END FRESH LOCATION FLOW SUMMARY ===');
      
      emit(HomeLoaded(
        restaurants: filteredRestaurants,
        categories: categories,
        foodTypes: foodTypes,
        userAddress: userAddress,
        userLatitude: latitude,
        userLongitude: longitude,
        savedAddresses: savedAddresses,
        recentOrders: recentOrders,
        isLocationServiceable: isLocationServiceable,
        locationServiceabilityMessage: locationServiceabilityMessage,
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
      
      // OPTIMISTIC UPDATE: reflect address change immediately in UI
      final optimisticState = currentState.copyWith(
        userAddress: event.address,
        userLatitude: event.latitude,
        userLongitude: event.longitude,
      );
      emit(optimisticState);
      debugPrint('HomeBloc: Emitted optimistic address update');

      // Load saved addresses first
      debugPrint('HomeBloc: Loading saved addresses...');
      final addressResult = await AddressService.getAllAddresses();
      List<Map<String, dynamic>> savedAddresses = [];
      if (addressResult['success'] == true && addressResult['data'] != null) {
        savedAddresses = List<Map<String, dynamic>>.from(addressResult['data']);
        debugPrint('HomeBloc: Reloaded ${savedAddresses.length} saved addresses');
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
        final allRestaurants = await _fetchRestaurants(event.latitude, event.longitude);
        
        // Apply supercategory filter if set
        List<Restaurant> filteredRestaurants = allRestaurants;
        if (_selectedSupercategoryId != null && _selectedSupercategoryId!.isNotEmpty) {
          filteredRestaurants = allRestaurants.where((restaurant) {
            final restaurantSupercategory = restaurant.supercategory?.toString() ?? '';
            return restaurantSupercategory == _selectedSupercategoryId;
          }).toList();
          debugPrint('HomeBloc: Re-filtered restaurants after address update: ${filteredRestaurants.length}');
        }
        
        // Finalize by updating restaurants and saved addresses
        emit(optimisticState.copyWith(
          restaurants: filteredRestaurants,
          savedAddresses: savedAddresses,
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
    debugPrint('HomeBloc: ToggleVegOnly event received with value: ${event.value}');
    final currentState = state;
    if (currentState is HomeLoaded) {
      debugPrint('HomeBloc: Previous vegOnly: ${currentState.vegOnly}, new vegOnly: ${event.value}');
      emit(currentState.copyWith(vegOnly: event.value));
      debugPrint('HomeBloc: VegOnly state updated');
    } else {
      debugPrint('HomeBloc: Current state is not HomeLoaded, cannot update vegOnly');
    }
  }

  Future<void> _onFilterByCategory(FilterByCategory event, Emitter<HomeState> emit) async {
    debugPrint('HomeBloc: FilterByCategory event received with categoryId: ${event.categoryId}');
    final currentState = state;
    if (currentState is HomeLoaded) {
      debugPrint('HomeBloc: Previous selectedCategoryId: ${currentState.selectedCategoryId}');
      debugPrint('HomeBloc: New selectedCategoryId to set: ${event.categoryId}');
      
      // Create new state with updated category
      final newState = currentState.copyWith(selectedCategoryId: event.categoryId);
      debugPrint('HomeBloc: New state selectedCategoryId: ${newState.selectedCategoryId}');
      debugPrint('HomeBloc: New state selectedFoodTypeId: ${newState.selectedFoodTypeId}');
      debugPrint('HomeBloc: New state vegOnly: ${newState.vegOnly}');
      
      emit(newState);
      debugPrint('HomeBloc: Category filter state updated');
    } else {
      debugPrint('HomeBloc: Current state is not HomeLoaded, cannot update category');
    }
  }

  Future<void> _onFilterByFoodType(FilterByFoodType event, Emitter<HomeState> emit) async {
    debugPrint('HomeBloc: FilterByFoodType event received with foodTypeId: ${event.foodTypeId}');
    final currentState = state;
    if (currentState is HomeLoaded) {
      debugPrint('HomeBloc: Previous selectedFoodTypeId: ${currentState.selectedFoodTypeId}');
      debugPrint('HomeBloc: New selectedFoodTypeId to set: ${event.foodTypeId}');
      
      // Create new state with updated food type filter
      final newState = currentState.copyWith(selectedFoodTypeId: event.foodTypeId);
      debugPrint('HomeBloc: New state selectedFoodTypeId: ${newState.selectedFoodTypeId}');
      
      emit(newState);
      debugPrint('HomeBloc: Food type filter state updated - filtering will be applied by state logic');
    } else {
      debugPrint('HomeBloc: Current state is not HomeLoaded, cannot update food type');
    }
  }

  Future<List<Restaurant>> _fetchRestaurants(double latitude, double longitude) async {
    try {
      debugPrint('🏠 HomeBloc: Fetching restaurants with coordinates - Lat: $latitude, Long: $longitude');
      
      final token = await TokenService.getToken();
      if (token == null) {
        debugPrint('HomeBloc: No token available for restaurant fetch');
        return [];
      }

      // Build URL with supercategory filter only
      String urlString = '${ApiConstants.baseUrl}/api/partner/restaurants?latitude=$latitude&longitude=$longitude&radius=30';
      if (_selectedSupercategoryId != null && _selectedSupercategoryId!.isNotEmpty) {
        urlString += '&supercategory=$_selectedSupercategoryId';
      }
      final url = Uri.parse(urlString);
      debugPrint('🏠 HomeBloc: Restaurant API URL: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('HomeBloc: Restaurant API response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        debugPrint('HomeBloc: Restaurant API response body: ${response.body}');
        final data = json.decode(response.body);
        
        if (data['status'] == true || data['status'] == 'SUCCESS') {
          final dynamic restaurantsData = data['data'];
          
          List<dynamic> restaurantsList = [];
          if (restaurantsData == null) {
            debugPrint('HomeBloc: No restaurant data in response');
            return [];
          } else if (restaurantsData is List) {
            restaurantsList = restaurantsData;
          } else if (restaurantsData is Map && restaurantsData['restaurants'] != null) {
            restaurantsList = restaurantsData['restaurants'] as List;
          } else {
            debugPrint('HomeBloc: Unexpected data structure: ${restaurantsData.runtimeType}');
            return [];
          }
          
          debugPrint('HomeBloc: Successfully parsed ${restaurantsList.length} restaurants from endpoint');
          
          if (restaurantsList.isEmpty) {
            debugPrint('HomeBloc: No restaurants found in response data');
            return [];
          }
          
          // Parse restaurants with error handling
          final List<Restaurant> restaurants = [];
          for (var restaurantJson in restaurantsList) {
            try {
              final restaurant = Restaurant.fromJson(restaurantJson as Map<String, dynamic>);
              restaurants.add(restaurant);
              debugPrint('HomeBloc: Parsed restaurant ${restaurant.name} with supercategory: ${restaurant.supercategory}');
            } catch (e) {
              debugPrint('HomeBloc: Error parsing individual restaurant: $e');
              debugPrint('HomeBloc: Restaurant data: $restaurantJson');
            }
          }
          
          if (restaurants.isNotEmpty) {
            debugPrint('HomeBloc: Successfully parsed ${restaurants.length} restaurants');
            return restaurants;
          }
        } else {
          debugPrint('HomeBloc: API returned error status: ${data['status']}');
          debugPrint('HomeBloc: Error message: ${data['message']}');
        }
      } else {
        debugPrint('HomeBloc: HTTP error ${response.statusCode}');
      }
      
      debugPrint('HomeBloc: Restaurant endpoint failed or returned no data');
      return [];
    } catch (e) {
      debugPrint('HomeBloc: Error fetching restaurants: $e');
      return [];
    }
  }

  Future<List<Restaurant>> _fetchRestaurantsWithoutLocation() async {
    try {
      debugPrint('HomeBloc: Fetching restaurants without location');
      
      final token = await TokenService.getToken();
      if (token == null) return [];

      final url = Uri.parse('${ApiConstants.baseUrl}/api/partner/restaurants');
      debugPrint('HomeBloc: Trying no-location endpoint: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('HomeBloc: No-location endpoint response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == true || data['status'] == 'SUCCESS') {
          final dynamic restaurantsData = data['data'];
          
          List<dynamic> restaurantsList = [];
          if (restaurantsData is List) {
            restaurantsList = restaurantsData;
          } else if (restaurantsData is Map && restaurantsData['restaurants'] != null) {
            restaurantsList = restaurantsData['restaurants'] as List;
          }
          
          if (restaurantsList.isNotEmpty) {
            final List<Restaurant> restaurants = [];
            for (var restaurantJson in restaurantsList) {
              try {
                final restaurant = Restaurant.fromJson(restaurantJson as Map<String, dynamic>);
                restaurants.add(restaurant);
              } catch (e) {
                debugPrint('HomeBloc: Error parsing restaurant without location: $e');
              }
            }
            
            if (restaurants.isNotEmpty) {
              debugPrint('HomeBloc: Successfully fetched ${restaurants.length} restaurants without location');
              return restaurants;
            }
          }
        }
      }
      
      return [];
    } catch (e) {
      debugPrint('HomeBloc: Error fetching restaurants without location: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchCategories() async {
    try {
      debugPrint('HomeBloc: Fetching recommended categories...');
      
      final categories = await CategoryRecommendationService.fetchRecommendedCategories(supercategoryId: _selectedSupercategoryId);
      
      debugPrint('HomeBloc: Fetched ${categories.length} recommended categories');
      return categories;
      
    } catch (e) {
      debugPrint('HomeBloc: Error fetching recommended categories: $e');
      return _getStaticCategories();
    }
  }

  List<Map<String, dynamic>> _getStaticCategories() {
    debugPrint('HomeBloc: Using static categories as fallback');
    return [
      {'name': 'Pizza', 'icon': 'local_pizza', 'color': 'red'},
      {'name': 'Burger', 'icon': 'lunch_dining', 'color': 'amber'},
      {'name': 'Sushi', 'icon': 'set_meal', 'color': 'blue'},
      {'name': 'Dessert', 'icon': 'icecream', 'color': 'pink'},
      {'name': 'Drinks', 'icon': 'local_drink', 'color': 'teal'},
    ];
  }

  Future<List<RecentOrderModel>> _fetchRecentOrders(String? token, String? userId) async {
    try {
      if (token == null || userId == null) {
        debugPrint('HomeBloc: No token or user ID for recent orders');
        return [];
      }

      debugPrint('HomeBloc: Fetching recent orders for user: $userId');
      
      final url = Uri.parse('${ApiConstants.baseUrl}/api/user/orders/recent?count=10&user_id=$userId');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('HomeBloc: Recent orders response status: ${response.statusCode}');
      debugPrint('HomeBloc: Recent orders response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['status'] == true && responseData['data'] != null) {
          final List<dynamic> ordersData = responseData['data'];
          
          return ordersData.map((json) => RecentOrderModel.fromJson(json)).toList();
        } else {
          debugPrint('HomeBloc: API returned error: ${responseData['message'] ?? 'Unknown error'}');
          return [];
        }
      } else {
        debugPrint('HomeBloc: HTTP error ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('HomeBloc: Error fetching recent orders: $e');
      return [];
    }
  }
}
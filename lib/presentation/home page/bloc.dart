// lib/presentation/home page/bloc.dart - Complete integrated version
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../service/token_service.dart';
import '../../../service/profile_get_service.dart';
import '../../../service/update_user_service.dart';
import '../../../service/address_service.dart';
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
        // Fetch saved addresses first
        final addressResult = await AddressService.getAllAddresses();
        if (addressResult['success'] == true && addressResult['data'] != null) {
          savedAddresses = List<Map<String, dynamic>>.from(addressResult['data']);
          debugPrint('HomeBloc: Loaded ${savedAddresses.length} saved addresses');
          
          // Find default address or use the first one
          if (savedAddresses.isNotEmpty) {
            final defaultAddress = savedAddresses.firstWhere(
              (addr) => addr['is_default'] == 1,
              orElse: () => savedAddresses.first,
            );
            
            userAddress = defaultAddress['address_line1'] ?? 'Add delivery address';
            latitude = double.tryParse(defaultAddress['latitude']?.toString() ?? '');
            longitude = double.tryParse(defaultAddress['longitude']?.toString() ?? '');
            
            debugPrint('HomeBloc: Using saved address: $userAddress');
            debugPrint('HomeBloc: Address coordinates - Lat: $latitude, Long: $longitude');
          }
        }
        
        // If no saved addresses, try to get from user profile
        if (latitude == null || longitude == null) {
          final result = await _profileApiService.getUserProfile(
            token: token,
            userId: userId,
          );
          
          if (result['success'] == true) {
            final userData = result['data'] as Map<String, dynamic>;
            userAddress = userData['address'] ?? userAddress;
            
            if (userData['latitude'] != null && userData['longitude'] != null) {
              latitude = double.tryParse(userData['latitude'].toString());
              longitude = double.tryParse(userData['longitude'].toString());
              debugPrint('HomeBloc: Using profile coordinates - Lat: $latitude, Long: $longitude');
            }
          }
        }
        
        // Fetch restaurants and categories in parallel
        final restaurantsFuture = (latitude != null && longitude != null) 
            ? _fetchRestaurantsByLocation(token, latitude, longitude)
            : _fetchAllRestaurants(token);
        
        final categoriesFuture = _fetchCategories(token);
        
        final results = await Future.wait([restaurantsFuture, categoriesFuture]);
        final restaurants = results[0] as List<dynamic>;
        final categories = results[1] as List<dynamic>;
        
        debugPrint('HomeBloc: Loaded ${restaurants.length} restaurants from API');
        debugPrint('HomeBloc: Loaded ${categories.length} categories from API');
        
        // Load user preferences
        final prefs = await SharedPreferences.getInstance();
        final vegOnly = prefs.getBool('veg_only') ?? false;
        
        // Apply veg filter if needed
        final filteredRestaurants = vegOnly 
            ? restaurants.where((r) => r['isVegetarian'] == true).toList()
            : restaurants;
        
        emit(HomeLoaded(
          userAddress: userAddress,
          vegOnly: vegOnly,
          restaurants: filteredRestaurants,
          categories: categories,
          userLatitude: latitude,
          userLongitude: longitude,
          selectedCategory: null,
          allRestaurants: restaurants,
          savedAddresses: savedAddresses,
        ));
      } else {
        debugPrint('HomeBloc: User ID or token is null');
        emit(HomeError('Please login to continue'));
      }
      
    } catch (e) {
      debugPrint('HomeBloc: Error loading home data: $e');
      emit(HomeError('Failed to load data. Please try again.'));
    }
  }

  Future<void> _onUpdateUserAddress(UpdateUserAddress event, Emitter<HomeState> emit) async {
    if (state is! HomeLoaded) return;
    
    final currentState = state as HomeLoaded;
    
    try {
      debugPrint('HomeBloc: Updating user address to: ${event.address}');
      debugPrint('HomeBloc: New coordinates - Lat: ${event.latitude}, Long: ${event.longitude}');
      
      // Get token and user ID
      final token = await TokenService.getToken();
      final userId = await TokenService.getUserId();
      
      if (token == null || userId == null) {
        debugPrint('HomeBloc: Missing token or user ID');
        emit(currentState.copyWith(errorMessage: 'Please login again to update your address.'));
        return;
      }
      
      // Validate coordinates
      if (event.latitude.isNaN || event.longitude.isNaN ||
          event.latitude.isInfinite || event.longitude.isInfinite) {
        debugPrint('HomeBloc: Invalid coordinates detected');
        emit(currentState.copyWith(errorMessage: 'Invalid coordinates. Please try again.'));
        return;
      }
      
      debugPrint('HomeBloc: Making API call to update address');
      
      // Update user profile with new address
      var result = await _updateUserService.updateUserProfileWithId(
        token: token,
        userId: userId,
        address: event.address,
        latitude: event.latitude,
        longitude: event.longitude,
      );
    
      if (result['success'] == true) {
        debugPrint('HomeBloc: Address updated successfully');
        
        // Fetch restaurants for the new location
        final restaurants = await _fetchRestaurantsByLocation(token, event.latitude, event.longitude);
        
        final prefs = await SharedPreferences.getInstance();
        final vegOnly = prefs.getBool('veg_only') ?? false;
        
        // Start with all restaurants
        List<dynamic> baseRestaurants = List.from(restaurants);
        
        // Apply category filter if there was one selected
        if (currentState.selectedCategory != null && currentState.selectedCategory!.isNotEmpty) {
          baseRestaurants = baseRestaurants.where((restaurant) {
            String restaurantCategories = '';
            
            if (restaurant['category'] != null) {
              restaurantCategories = restaurant['category'].toString().toLowerCase();
            } else if (restaurant['cuisine'] != null) {
              restaurantCategories = restaurant['cuisine'].toString().toLowerCase();
            }
            
            final selectedCategory = currentState.selectedCategory!.toLowerCase();
            return restaurantCategories.contains(selectedCategory);
          }).toList();
        }
        
        // Apply veg filter if enabled
        final filteredRestaurants = vegOnly 
            ? baseRestaurants.where((r) => r['isVegetarian'] == true).toList()
            : baseRestaurants;
        
        debugPrint('HomeBloc: Emitting HomeLoaded after address update');
        emit(HomeLoaded(
          userAddress: event.address,
          vegOnly: vegOnly,
          restaurants: filteredRestaurants,
          categories: currentState.categories,
          userLatitude: event.latitude,
          userLongitude: event.longitude,
          selectedCategory: currentState.selectedCategory,
          allRestaurants: restaurants,
          savedAddresses: currentState.savedAddresses,
          errorMessage: null,
        ));
        debugPrint('HomeBloc: Emitted HomeLoaded after address update');
      } else {
        debugPrint('HomeBloc: Failed to update address: ${result['message']}');
        final errorMsg = result['message'] ?? 'Server error occurred. Please try again.';
        // On failure, keep previous address/lat/lng, but clear restaurants and set errorMessage
        emit(currentState.copyWith(
          restaurants: [],
          errorMessage: errorMsg,
        ));
      }
    } catch (e, stack) {
      debugPrint('HomeBloc: Error updating address: $e');
      debugPrint('HomeBloc: Stack trace: $stack');
      emit(currentState.copyWith(errorMessage: 'An error occurred while updating your address.'));
    }
  }

  Future<void> _onLoadSavedAddresses(LoadSavedAddresses event, Emitter<HomeState> emit) async {
    try {
      debugPrint('HomeBloc: Loading saved addresses...');
      
      final result = await AddressService.getAllAddresses();
      
      if (result['success'] == true && result['data'] != null) {
        final savedAddresses = List<Map<String, dynamic>>.from(result['data']);
        
        if (state is HomeLoaded) {
          final currentState = state as HomeLoaded;
          emit(currentState.copyWith(
            savedAddresses: savedAddresses,
            errorMessage: currentState.errorMessage,
          ));
          debugPrint('HomeBloc: Updated existing HomeLoaded state with ${savedAddresses.length} saved addresses');
        }
        
        debugPrint('HomeBloc: Loaded ${savedAddresses.length} saved addresses');
      } else {
        debugPrint('HomeBloc: Failed to load saved addresses: ${result['message']}');
      }
    } catch (e) {
      debugPrint('HomeBloc: Error loading saved addresses: $e');
    }
  }

  Future<void> _onSaveNewAddress(SaveNewAddress event, Emitter<HomeState> emit) async {
    try {
      debugPrint('HomeBloc: Saving new address...');
      
      final result = await AddressService.saveAddress(
        addressLine1: event.addressLine1,
        addressLine2: event.addressName.isNotEmpty ? event.addressName : 'Other',
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
        
        // If this is set as default, update the current address
        if (event.makeDefault && state is HomeLoaded) {
          final currentState = state as HomeLoaded;
          emit(currentState.copyWith(
            userAddress: event.addressLine1,
            userLatitude: event.latitude,
            userLongitude: event.longitude,
          ));
        }
        
        // Reload saved addresses
        add(const LoadSavedAddresses());
        
        emit(AddressSaveSuccess(result['message'] ?? 'Address saved successfully'));
      } else {
        debugPrint('HomeBloc: Failed to save address: ${result['message']}');
        emit(AddressSaveFailure(result['message'] ?? 'Failed to save address'));
      }
    } catch (e) {
      debugPrint('HomeBloc: Error saving address: $e');
      emit(AddressSaveFailure('Network error occurred. Please try again.'));
    }
  }

  Future<void> _onSelectSavedAddress(SelectSavedAddress event, Emitter<HomeState> emit) async {
    try {
      debugPrint('HomeBloc: Selecting saved address...');
      
      if (state is HomeLoaded) {
        final currentState = state as HomeLoaded;
        final address = event.address;
        
        final addressLine1 = address['address_line1']?.toString() ?? '';
        final latitude = double.tryParse(address['latitude']?.toString() ?? '');
        final longitude = double.tryParse(address['longitude']?.toString() ?? '');
        
        emit(currentState.copyWith(
          userAddress: addressLine1,
          userLatitude: latitude,
          userLongitude: longitude,
        ));
      }
    } catch (e) {
      debugPrint('HomeBloc: Error selecting saved address: $e');
      emit(HomeError('Failed to select address'));
    }
  }
  
  Future<List<dynamic>> _fetchRestaurantsByLocation(String token, double latitude, double longitude) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/partner/restaurants?latitude=$latitude&longitude=$longitude');
      
      debugPrint('Fetching restaurants from: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      debugPrint('Restaurant API Response Status: ${response.statusCode}');
      debugPrint('Restaurant API Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['status'] == 'SUCCESS') {
          final List<dynamic> restaurantsList = responseData['data'] ?? [];
          
          // CRITICAL FIX: Safer restaurant parsing
          return restaurantsList.map((data) {
            try {
              // Create Restaurant object and convert to map
              final restaurant = Restaurant.fromJson(data);
              return restaurant.toMap();
            } catch (e) {
              debugPrint('HomeBloc: Error parsing restaurant: $e');
              debugPrint('HomeBloc: Restaurant data: $data');
              // Return a safe fallback
              return {
                'id': data['partner_id'] ?? '',
                'name': data['restaurant_name'] ?? 'Unknown Restaurant',
                'imageUrl': _getFirstPhoto(data['restaurant_photos']).isNotEmpty
                    ? _getFirstPhoto(data['restaurant_photos'])
                    : 'assets/images/placeholder.jpg',
                'cuisine': data['category'] ?? data['cuisine'] ?? '',
                'rating': double.tryParse(data['rating']?.toString() ?? '0') ?? 0.0,
                'price': data['price'] ?? '₹200 for two',
                'deliveryTime': data['deliveryTime'] ?? data['cooking_time'] ?? '30-40 min',
                'isVegetarian': (data['veg_nonveg']?.toString().toLowerCase() == 'veg') || (data['veg_nonveg'] == true),
                'distance': data['distance'] ?? 1.2,
                'address': data['address'] ?? '',
                'latitude': double.tryParse(data['latitude']?.toString() ?? '0') ?? 0.0,
                'longitude': double.tryParse(data['longitude']?.toString() ?? '0') ?? 0.0,
                'restaurantType': data['restaurant_type'] ?? 'Restaurant',
                'category': data['category'] ?? '',
              };
            }
          }).toList();
        } else {
          debugPrint('HomeBloc: API returned non-success status: ${responseData['message']}');
          return [];
        }
      } else {
        debugPrint('HomeBloc: Restaurant API Error: Status ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('HomeBloc: Error fetching restaurants: $e');
      return [];
    }
  }

  // Helper method to safely extract first photo
  String _getFirstPhoto(dynamic photos) {
    try {
      if (photos == null) return '';
      
      if (photos is String) {
        if (photos.isEmpty || photos == '[]') return '';
        
        // Handle JSON string format
        if (photos.startsWith('[') && photos.endsWith(']')) {
          final parsed = jsonDecode(photos) as List;
          return parsed.isNotEmpty ? parsed.first.toString() : '';
        }
        
        return photos;
      }
      
      if (photos is List) {
        return photos.isNotEmpty ? photos.first.toString() : '';
      }
      
      return '';
    } catch (e) {
      debugPrint('HomeBloc: Error parsing photos: $e');
      return '';
    }
  }
  
  Future<List<dynamic>> _fetchAllRestaurants(String token) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/partner/restaurants');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['status'] == 'SUCCESS') {
          final List<dynamic> restaurantsList = responseData['data'] ?? [];
          
          return restaurantsList.map((data) {
            try {
              final restaurant = Restaurant.fromJson(data);
              return restaurant.toMap();
            } catch (e) {
              debugPrint('HomeBloc: Error parsing restaurant: $e');
              return {
                'id': data['partner_id'] ?? '',
                'name': data['restaurant_name'] ?? 'Unknown Restaurant',
                'imageUrl': _getFirstPhoto(data['restaurant_photos']).isNotEmpty
                    ? _getFirstPhoto(data['restaurant_photos'])
                    : 'assets/images/placeholder.jpg',
                'cuisine': data['category'] ?? data['cuisine'] ?? '',
                'rating': double.tryParse(data['rating']?.toString() ?? '0') ?? 0.0,
                'price': data['price'] ?? '₹200 for two',
                'deliveryTime': data['deliveryTime'] ?? data['cooking_time'] ?? '30-40 min',
                'isVegetarian': (data['veg_nonveg']?.toString().toLowerCase() == 'veg') || (data['veg_nonveg'] == true),
                'distance': data['distance'] ?? 1.2,
                'address': data['address'] ?? '',
                'latitude': double.tryParse(data['latitude']?.toString() ?? '0') ?? 0.0,
                'longitude': double.tryParse(data['longitude']?.toString() ?? '0') ?? 0.0,
                'restaurantType': data['restaurant_type'] ?? 'Restaurant',
                'category': data['category'] ?? '',
              };
            }
          }).toList();
        }
      }
      
      return [];
    } catch (e) {
      debugPrint('HomeBloc: Error fetching all restaurants: $e');
      return [];
    }
  }
  
  Future<void> _onFilterByCategory(FilterByCategory event, Emitter<HomeState> emit) async {
    try {
      if (state is HomeLoaded) {
        final currentState = state as HomeLoaded;
        
        debugPrint('HomeBloc: Filtering by category: ${event.categoryName}');
        
        List<dynamic> filteredRestaurants = List.from(currentState.allRestaurants);
        
        // Apply category filter if specified
        if (event.categoryName != null && event.categoryName!.isNotEmpty) {
          filteredRestaurants = filteredRestaurants.where((restaurant) {
            String restaurantCategories = '';
            
            if (restaurant['category'] != null) {
              restaurantCategories = restaurant['category'].toString().toLowerCase();
            } else if (restaurant['cuisine'] != null) {
              restaurantCategories = restaurant['cuisine'].toString().toLowerCase();
            }
            
            final selectedCategory = event.categoryName!.toLowerCase();
            return restaurantCategories.contains(selectedCategory);
          }).toList();
        }
        
        // Apply veg filter if enabled
        if (currentState.vegOnly) {
          filteredRestaurants = filteredRestaurants.where((restaurant) {
            final isVeg = restaurant['isVegetarian'] as bool? ?? false;
            return isVeg;
          }).toList();
        }
        
        emit(currentState.copyWith(
          restaurants: filteredRestaurants,
          selectedCategory: event.categoryName,
        ));
      }
    } catch (e) {
      debugPrint('HomeBloc: Error filtering by category: $e');
    }
  }
  
  Future<void> _onToggleVegOnly(ToggleVegOnly event, Emitter<HomeState> emit) async {
    try {
      if (state is HomeLoaded) {
        final currentState = state as HomeLoaded;
        
        // Save preference
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('veg_only', event.value);
        
        if (event.value != currentState.vegOnly) {
          List<dynamic> baseRestaurants = List.from(currentState.allRestaurants);
          
          // Apply category filter first if there's a selected category
          if (currentState.selectedCategory != null && currentState.selectedCategory!.isNotEmpty) {
            baseRestaurants = baseRestaurants.where((restaurant) {
              String restaurantCategories = '';
              
              if (restaurant['category'] != null) {
                restaurantCategories = restaurant['category'].toString().toLowerCase();
              } else if (restaurant['cuisine'] != null) {
                restaurantCategories = restaurant['cuisine'].toString().toLowerCase();
              }
              
              final selectedCategory = currentState.selectedCategory!.toLowerCase();
              return restaurantCategories.contains(selectedCategory);
            }).toList();
          }
          
          // Apply veg filter if toggled on
          final filteredRestaurants = event.value 
              ? baseRestaurants.where((restaurant) {
                  final isVeg = restaurant['isVegetarian'] as bool? ?? false;
                  return isVeg;
                }).toList()
              : baseRestaurants;
          
          emit(currentState.copyWith(
            vegOnly: event.value,
            restaurants: filteredRestaurants,
          ));
        }
        
        debugPrint('HomeBloc: Veg only toggled to: ${event.value}');
      }
    } catch (e) {
      debugPrint('HomeBloc: Error toggling veg only: $e');
    }
  }
  
  Future<List<dynamic>> _fetchCategories(String token) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/partner/categories');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['status'] == 'SUCCESS' && responseData['data'] != null) {
          final List<dynamic> categoriesList = responseData['data'];
          
          return categoriesList.map((category) {
            return {
              'id': category['id'],
              'name': category['name'],
              'display_order': category['display_order'] ?? 0,
              'active': category['active'] ?? 1,
              'icon': _getCategoryIcon(category['name']),
              'color': _getCategoryColor(category['name']),
            };
          }).toList();
        } else {
          return _getDefaultCategories();
        }
      } else {
        return _getDefaultCategories();
      }
    } catch (e) {
      debugPrint('HomeBloc: Error fetching categories: $e');
      return _getDefaultCategories();
    }
  }

  List<dynamic> _getDefaultCategories() {
    return [
      {'name': 'Pizza', 'icon': 'local_pizza', 'color': 'red'},
      {'name': 'Burger', 'icon': 'lunch_dining', 'color': 'amber'},
      {'name': 'Sushi', 'icon': 'set_meal', 'color': 'blue'},
      {'name': 'Desserts', 'icon': 'icecream', 'color': 'pink'},
      {'name': 'Drinks', 'icon': 'local_drink', 'color': 'teal'},
    ];
  }

  String _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    
    if (name.contains('pizza')) return 'local_pizza';
    if (name.contains('burger')) return 'lunch_dining';
    if (name.contains('sushi') || name.contains('seafood')) return 'set_meal';
    if (name.contains('dessert') || name.contains('cake') || name.contains('sweet')) return 'icecream';
    if (name.contains('drink') || name.contains('beverage')) return 'local_drink';
    if (name.contains('bakery') || name.contains('bread')) return 'bakery_dining';
    if (name.contains('breakfast')) return 'free_breakfast';
    if (name.contains('healthy') || name.contains('salad')) return 'spa';
    if (name.contains('indian')) return 'restaurant';
    if (name.contains('chicken')) return 'egg';
    if (name.contains('chinese')) return 'ramen_dining';
    
    return 'restaurant';
  }

  String _getCategoryColor(String categoryName) {
    final name = categoryName.toLowerCase();
    
    if (name.contains('pizza')) return 'red';
    if (name.contains('burger')) return 'amber';
    if (name.contains('sushi') || name.contains('seafood')) return 'blue';
    if (name.contains('dessert') || name.contains('cake')) return 'pink';
    if (name.contains('drink') || name.contains('beverage')) return 'teal';
    if (name.contains('bakery') || name.contains('bread')) return 'brown';
    if (name.contains('breakfast')) return 'orange';
    if (name.contains('healthy') || name.contains('salad')) return 'green';
    if (name.contains('indian')) return 'deepOrange';
    if (name.contains('chicken')) return 'amber';
    
    final colors = ['red', 'amber', 'blue', 'pink', 'teal', 'purple', 'green', 'orange'];
    final hash = name.hashCode.abs() % colors.length;
    return colors[hash];
  }
}
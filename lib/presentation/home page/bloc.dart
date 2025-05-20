// bloc.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../service/token_service.dart';
import '../../../service/profile_get_service.dart';
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
  }
  
  Future<void> _onLoadHomeData(LoadHomeData event, Emitter<HomeState> emit) async {
  emit(HomeLoading());
  
  try {
    // Get user ID and token
    final userId = await TokenService.getUserId();
    final token = await TokenService.getToken();
    
    debugPrint('HomeBloc: Loading home data with token: ${token != null ? 'Found' : 'Not found'}');
    
    String userAddress = 'Add delivery address';
    double? latitude;
    double? longitude;
    
    if (userId != null && token != null) {
      // Fetch user profile data
      final result = await _profileApiService.getUserProfile(
        token: token,
        userId: userId,
      );
      
      debugPrint('Profile API Response: $result');
      
      if (result['success'] == true) {
        final userData = result['data'] as Map<String, dynamic>;
        userAddress = userData['address'] ?? 'Add delivery address';
        
        // Get latitude and longitude
        if (userData['latitude'] != null && userData['longitude'] != null) {
          latitude = double.tryParse(userData['latitude'].toString());
          longitude = double.tryParse(userData['longitude'].toString());
          
          debugPrint('HomeBloc: User coordinates loaded - Lat: $latitude, Long: $longitude');
        }
        
        debugPrint('HomeBloc: User address loaded: $userAddress');
      } else {
        debugPrint('HomeBloc: Failed to load address: ${result['message']}');
      }
      
      // Now fetch restaurants and categories in parallel for better performance
      final restaurantsFuture = (latitude != null && longitude != null) 
          ? _fetchRestaurantsByLocation(token, latitude, longitude)
          : Future.value(<Map<String, dynamic>>[]);
      
      final categoriesFuture = _fetchCategories(token);
      
      final results = await Future.wait([restaurantsFuture, categoriesFuture]);
      
      final List<Map<String, dynamic>> restaurants = results[0];
      final List<Map<String, dynamic>> categories = results[1];
      
      debugPrint('HomeBloc: Loaded ${restaurants.length} restaurants from API');
      debugPrint('HomeBloc: Loaded ${categories.length} categories from API');
      
      // Load user preferences
      final prefs = await SharedPreferences.getInstance();
      final vegOnly = prefs.getBool('veg_only') ?? false;
      
      // If vegOnly is true, filter restaurants
      final filteredRestaurants = vegOnly 
          ? restaurants.where((r) => r['isVeg'] == true).toList()
          : restaurants;
      
      emit(HomeLoaded(
        userAddress: userAddress,
        vegOnly: vegOnly,
        restaurants: filteredRestaurants,
        categories: categories,
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
  
  Future<List<Map<String, dynamic>>> _fetchRestaurantsByLocation(String token, double latitude, double longitude) async {
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
          final List<dynamic> restaurantsList = responseData['restaurants'];
          
          // Convert API response to our model and then to Map for state
          List<Restaurant> restaurants = restaurantsList
              .map((data) => Restaurant.fromJson(data))
              .toList();
          
          // Convert to map format expected by UI
          return restaurants.map((restaurant) => restaurant.toMap()).toList();
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
  
  Future<void> _onToggleVegOnly(ToggleVegOnly event, Emitter<HomeState> emit) async {
    try {
      if (state is HomeLoaded) {
        final currentState = state as HomeLoaded;
        
        // Save preference
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('veg_only', event.value);
        
        // If vegOnly is toggled on, we need to filter restaurants
        if (event.value != currentState.vegOnly) {
          emit(HomeLoading());
          
          final allRestaurants = currentState.restaurants;
          
          // Filter if vegOnly is true
          final filteredRestaurants = event.value 
              ? allRestaurants.where((r) => r['isVeg'] == true).toList()
              : allRestaurants;
          
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
  
  Future<void> _onUpdateUserAddress(UpdateUserAddress event, Emitter<HomeState> emit) async {
  try {
    debugPrint('HomeBloc: Updating user address...');
    debugPrint('HomeBloc: Address: ${event.address}');
    debugPrint('HomeBloc: Latitude: ${event.latitude}');
    debugPrint('HomeBloc: Longitude: ${event.longitude}');
    
    // If already in a HomeLoaded state, keep current state data
    HomeLoaded? currentLoadedState;
    if (state is HomeLoaded) {
      currentLoadedState = state as HomeLoaded;
    }
    
    emit(AddressUpdating());
    
    // Get token and user ID (instead of mobile number)
    final token = await TokenService.getToken();
    final userId = await TokenService.getUserId(); // Change to userId
    
    if (token == null || userId == null) {
      debugPrint('HomeBloc: Missing token or user ID');
      emit(const AddressUpdateFailure('Please login again to update your address.'));
      
      // Restore previous state if it was HomeLoaded
      if (currentLoadedState != null) {
        emit(currentLoadedState);
      }
      return;
    }
    
    // Verify the coordinates are valid numbers
    if (event.latitude.isNaN || event.longitude.isNaN ||
        event.latitude.isInfinite || event.longitude.isInfinite) {
      debugPrint('HomeBloc: Invalid coordinates detected');
      emit(const AddressUpdateFailure('Invalid coordinates. Please try again.'));
      
      // Restore previous state if it was HomeLoaded
      if (currentLoadedState != null) {
        emit(currentLoadedState);
      }
      return;
    }
    
    debugPrint('HomeBloc: Making API call to update address with:');
    debugPrint('HomeBloc: User ID: $userId'); // Update log message
    debugPrint('HomeBloc: Address: ${event.address}');
    debugPrint('HomeBloc: Latitude: ${event.latitude}');
    debugPrint('HomeBloc: Longitude: ${event.longitude}');
    
    // Use updateUserProfileWithId instead of updateUserProfile
    var result = await _updateUserService.updateUserProfileWithId(
      token: token,
      userId: userId, // Use userId parameter
      address: event.address,
      latitude: event.latitude,
      longitude: event.longitude,
    );
  
      
      if (result['success'] == true) {
        debugPrint('HomeBloc: Address updated successfully');
        emit(AddressUpdateSuccess(event.address));
        
        // Now fetch restaurants for this new location
        final restaurants = await _fetchRestaurantsByLocation(token, event.latitude, event.longitude);
        
        // If we had a HomeLoaded state before, restore it with the new address and restaurants
        if (currentLoadedState != null) {
          final prefs = await SharedPreferences.getInstance();
          final vegOnly = prefs.getBool('veg_only') ?? false;
          
          // If vegOnly is true, filter restaurants
          final filteredRestaurants = vegOnly 
              ? restaurants.where((r) => r['isVeg'] == true).toList()
              : restaurants;
          
          emit(currentLoadedState.copyWith(
            userAddress: event.address,
            restaurants: filteredRestaurants,
          ));
        } else {
          // Reload home data
          add(const LoadHomeData());
        }
      } else {
        debugPrint('HomeBloc: Failed to update address: ${result['message']}');
        emit(AddressUpdateFailure(result['message'] ?? 'Failed to update address'));
        
        // Restore previous state if it was HomeLoaded
        if (currentLoadedState != null) {
          emit(currentLoadedState);
        }
      }
    } catch (e) {
      debugPrint('HomeBloc: Error updating address: $e');
      emit(AddressUpdateFailure('An error occurred while updating your address.'));
      
      // If we had a HomeLoaded state before, restore it
      if (state is HomeLoaded) {
        emit(state);
      }
    }
  }
  // Add this method in HomeBloc class to fetch categories from API
Future<List<Map<String, dynamic>>> _fetchCategories(String token) async {
  try {
    final url = Uri.parse('${ApiConstants.baseUrl}/api/partner/categories');
    
    debugPrint('Fetching categories from: $url');
    
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    
    debugPrint('Categories API Response Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      debugPrint('Categories API Response Body: ${response.body}');
      
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      
      if (responseData['status'] == 'SUCCESS' && responseData['data'] != null) {
        final List<dynamic> categoriesList = responseData['data'];
        
        // Convert to map format expected by UI
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
        debugPrint('HomeBloc: API returned non-success status: ${responseData['message']}');
        return _getDefaultCategories();
      }
    } else {
      debugPrint('HomeBloc: Categories API Error: Status ${response.statusCode}');
      return _getDefaultCategories();
    }
  } catch (e) {
    debugPrint('HomeBloc: Error fetching categories: $e');
    return _getDefaultCategories();
  }
}

// Helper method to get default categories if API fails
List<Map<String, dynamic>> _getDefaultCategories() {
  return [
    {'name': 'Pizza', 'icon': 'local_pizza', 'color': 'red'},
    {'name': 'Burger', 'icon': 'lunch_dining', 'color': 'amber'},
    {'name': 'Sushi', 'icon': 'set_meal', 'color': 'blue'},
    {'name': 'Desserts', 'icon': 'icecream', 'color': 'pink'},
    {'name': 'Drinks', 'icon': 'local_drink', 'color': 'teal'},
  ];
}

// Helper method to assign icons to categories based on name
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
  
  // Default icon for other categories
  return 'restaurant';
}

// Helper method to assign colors to categories based on name
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
  
  // Generate a random but consistent color based on category name
  final colors = ['red', 'amber', 'blue', 'pink', 'teal', 'purple', 'green', 'orange'];
  final hash = name.hashCode.abs() % colors.length;
  return colors[hash];
}
}
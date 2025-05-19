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
        
        // Now fetch restaurants based on location
        List<Map<String, dynamic>> restaurants = [];
        
        if (latitude != null && longitude != null) {
          restaurants = await _fetchRestaurantsByLocation(token, latitude, longitude);
          debugPrint('HomeBloc: Loaded ${restaurants.length} restaurants from API');
        } else {
          debugPrint('HomeBloc: No coordinates available, could not fetch restaurants');
        }
        
        // For categories, we'll keep the static data for now
        final categories = [
          {'name': 'Pizza', 'icon': 'local_pizza', 'color': 'red'},
          {'name': 'Burger', 'icon': 'lunch_dining', 'color': 'amber'},
          {'name': 'Sushi', 'icon': 'set_meal', 'color': 'blue'},
          {'name': 'Desserts', 'icon': 'icecream', 'color': 'pink'},
          {'name': 'Drinks', 'icon': 'local_drink', 'color': 'teal'},
        ];
        
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
      
      // Get token and mobile number
      final token = await TokenService.getToken();
      final mobile = await TokenService.getMobileNumber();
      
      if (token == null || mobile == null) {
        debugPrint('HomeBloc: Missing token or mobile number');
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
      debugPrint('HomeBloc: Mobile: $mobile');
      debugPrint('HomeBloc: Address: ${event.address}');
      debugPrint('HomeBloc: Latitude: ${event.latitude}');
      debugPrint('HomeBloc: Longitude: ${event.longitude}');
      
      // Use the UpdateUserService to update the user's address
      var result = await _updateUserService.updateUserProfile(
        token: token,
        mobile: mobile,
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
}
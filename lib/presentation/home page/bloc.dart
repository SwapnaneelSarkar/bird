import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../service/token_service.dart';
import '../../../service/profile_get_service.dart';
import '../../../service/update_user_service.dart';
import '../../../service/update_address_service.dart';
import 'event.dart';
import 'state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final ProfileApiService _profileApiService = ProfileApiService();
  final UpdateUserService _updateUserService = UpdateUserService();
  final UpdateAddressService _updateAddressService = UpdateAddressService();
  
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
      
      if (userId != null && token != null) {
        // Fetch user profile data
        final result = await _profileApiService.getUserProfile(
          token: token,
          userId: userId,
        );
        
        if (result['success'] == true) {
          final userData = result['data'] as Map<String, dynamic>;
          userAddress = userData['address'] ?? 'Add delivery address';
          debugPrint('HomeBloc: User address loaded: $userAddress');
        } else {
          debugPrint('HomeBloc: Failed to load address: ${result['message']}');
        }
      } else {
        debugPrint('HomeBloc: User ID or token is null');
      }
      
      // Load restaurant data from JSON file
      final restaurants = await _loadRestaurantData();
      debugPrint('HomeBloc: Loaded ${restaurants.length} restaurants from JSON file');
      
      // For categories, we'll keep the static data for now, but this could also be moved to JSON
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
      
    } catch (e) {
      debugPrint('HomeBloc: Error loading home data: $e');
      emit(HomeError('Failed to load data. Please try again.'));
    }
  }
  
  Future<List<Map<String, dynamic>>> _loadRestaurantData() async {
    try {
      // Load data from the JSON file
      final String data = await rootBundle.loadString('assets/data/restaurant.json');
      final Map<String, dynamic> jsonData = json.decode(data);
      
      // Extract and return restaurants as List<Map<String, dynamic>>
      final List<dynamic> restaurants = jsonData['restaurants'];
      
      // Convert each restaurant item to a Map<String, dynamic>
      return List<Map<String, dynamic>>.from(restaurants);
    } catch (e) {
      debugPrint('HomeBloc: Error loading restaurant data from JSON: $e');
      
      // Return fallback data in case of error
      return [
        {
          'id': 'rest001',
          'name': 'The Gourmet Kitchen',
          'imageUrl': 'assets/images/restaurant1.jpg',
          'cuisine': 'Italian, Continental',
          'rating': 4.8,
          'price': '₹200 for two',
          'deliveryTime': '20-25 mins',
          'isVeg': false,
        },
        {
          'id': 'rest002',
          'name': 'Cafe Bistro',
          'imageUrl': 'assets/images/restaurant2.jpg',
          'cuisine': 'Cafe, Continental',
          'rating': 4.5,
          'price': '₹150 for two',
          'deliveryTime': '15-20 mins',
          'isVeg': true,
        },
      ];
    }
  }
  
  Future<void> _onToggleVegOnly(ToggleVegOnly event, Emitter<HomeState> emit) async {
    try {
      if (state is HomeLoaded) {
        final currentState = state as HomeLoaded;
        
        // Save preference
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('veg_only', event.value);
        
        // If vegOnly is toggled on, we need to filter restaurants to show only veg
        // If toggled off, we need to reload all restaurants
        if (event.value != currentState.vegOnly) {
          emit(HomeLoading());
          
          // Reload restaurant data
          final allRestaurants = await _loadRestaurantData();
          
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
      final prefs = await SharedPreferences.getInstance();
      final mobile = prefs.getString('user_phone');
      
      if (token == null || mobile == null) {
        debugPrint('HomeBloc: Missing token or mobile number');
        emit(const AddressUpdateFailure('Please login again to update your address.'));
        
        // Restore previous state if it was HomeLoaded
        if (currentLoadedState != null) {
          emit(currentLoadedState);
        }
        return;
      }
      
      // Clean up mobile number (remove country code if present)
      String cleanMobile = mobile;
      if (cleanMobile.startsWith('+91')) {
        cleanMobile = cleanMobile.substring(3);
      } else if (cleanMobile.startsWith('+')) {
        // Remove any country code
        cleanMobile = cleanMobile.substring(cleanMobile.length - 10);
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
      debugPrint('HomeBloc: Mobile: $cleanMobile');
      debugPrint('HomeBloc: Address: ${event.address}');
      debugPrint('HomeBloc: Latitude: ${event.latitude}');
      debugPrint('HomeBloc: Longitude: ${event.longitude}');
      
      // Use the UpdateUserService directly to ensure coordinates are properly sent
      // This matches the API usage in other parts of the app
      var result = await _updateUserService.updateUserProfile(
        token: token,
        mobile: cleanMobile,
        address: event.address,
        latitude: event.latitude,
        longitude: event.longitude,
      );
      
      if (result['success'] == true) {
        debugPrint('HomeBloc: Address updated successfully');
        emit(AddressUpdateSuccess(event.address));
        
        // If we had a HomeLoaded state before, restore it with the new address
        if (currentLoadedState != null) {
          emit(currentLoadedState.copyWith(userAddress: event.address));
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
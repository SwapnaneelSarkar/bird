// lib/presentation/home page/bloc.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../service/token_service.dart';
import '../../../service/profile_get_service.dart';
import '../../../service/address_service.dart';
import '../../../constants/api_constant.dart';
import '../../models/restaurant_model.dart';
import 'event.dart';
import 'state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final ProfileApiService _profileApiService = ProfileApiService();
  
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
        } else {
          debugPrint('HomeBloc: No saved addresses found, falling back to profile address');
          
          // Fallback to profile address if no saved addresses
          final result = await _profileApiService.getUserProfile(
            token: token,
            userId: userId,
          );
          
          if (result['success'] == true) {
            final userData = result['data'] as Map<String, dynamic>;
            userAddress = userData['address'] ?? 'Add delivery address';
            
            if (userData['latitude'] != null && userData['longitude'] != null) {
              latitude = double.tryParse(userData['latitude'].toString());
              longitude = double.tryParse(userData['longitude'].toString());
            }
          }
        }
        
        // Fetch restaurants and categories in parallel
        final restaurantsFuture = (latitude != null && longitude != null) 
            ? _fetchNearbyRestaurants(token, latitude, longitude)
            : _fetchAllRestaurants(token);
        
        final categoriesFuture = _fetchCategories(token);
        
        final results = await Future.wait([restaurantsFuture, categoriesFuture]);
        final restaurants = results[0] as List<Restaurant>;
        final categories = results[1] as List<Map<String, dynamic>>;
        
        emit(HomeLoaded(
          restaurants: restaurants,
          categories: categories,
          userAddress: userAddress,
          userLatitude: latitude,
          userLongitude: longitude,
          savedAddresses: savedAddresses,
        ));
      } else {
        debugPrint('HomeBloc: No user credentials found');
        
        // Load basic data without user-specific content
        final categoriesFuture = _fetchCategories(null);
        final restaurantsFuture = _fetchAllRestaurants(null);
        
        final results = await Future.wait([restaurantsFuture, categoriesFuture]);
        final restaurants = results[0] as List<Restaurant>;
        final categories = results[1] as List<Map<String, dynamic>>;
        
        emit(HomeLoaded(
          restaurants: restaurants,
          categories: categories,
          userAddress: userAddress,
          savedAddresses: savedAddresses,
        ));
      }
    } catch (e) {
      debugPrint('HomeBloc: Error loading home data: $e');
      emit(HomeError(e.toString()));
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
          emit(currentState.copyWith(savedAddresses: savedAddresses));
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
        
        emit(AddressUpdateSuccess(addressLine1));
      }
    } catch (e) {
      debugPrint('HomeBloc: Error selecting saved address: $e');
      emit(AddressUpdateFailure('Failed to select address'));
    }
  }
  
  Future<void> _onUpdateUserAddress(UpdateUserAddress event, Emitter<HomeState> emit) async {
    if (state is! HomeLoaded) return;
    
    final currentState = state as HomeLoaded;
    emit(AddressUpdating());
    
    try {
      debugPrint('HomeBloc: Updating user address to: ${event.address}');
      debugPrint('HomeBloc: New coordinates - Lat: ${event.latitude}, Long: ${event.longitude}');
      
      // Update the home state with new address immediately for better UX
      emit(currentState.copyWith(
        userAddress: event.address,
        userLatitude: event.latitude,
        userLongitude: event.longitude,
      ));
      
      emit(AddressUpdateSuccess(event.address));
    } catch (e) {
      debugPrint('HomeBloc: Error updating address: $e');
      emit(AddressUpdateFailure(e.toString()));
    }
  }
  
  Future<void> _onToggleVegOnly(ToggleVegOnly event, Emitter<HomeState> emit) async {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      emit(currentState.copyWith(vegOnly: event.value));
    }
  }

  Future<void> _onFilterByCategory(FilterByCategory event, Emitter<HomeState> emit) async {
    if (state is HomeLoaded) {
      final currentState = state as HomeLoaded;
      emit(currentState.copyWith(selectedCategory: event.categoryName));
    }
  }

  Future<List<Restaurant>> _fetchNearbyRestaurants(String token, double latitude, double longitude) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/partner/restaurants?latitude=$latitude&longitude=$longitude');
      
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
          final List<dynamic> restaurantList = responseData['data'];
          return restaurantList.map((json) => Restaurant.fromJson(json)).toList();
        }
      }
      
      debugPrint('HomeBloc: Failed to fetch nearby restaurants');
      return [];
    } catch (e) {
      debugPrint('HomeBloc: Error fetching nearby restaurants: $e');
      return [];
    }
  }

  Future<List<Restaurant>> _fetchAllRestaurants(String? token) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/partner/restaurants');
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['status'] == 'SUCCESS' && responseData['data'] != null) {
          final List<dynamic> restaurantList = responseData['data'];
          return restaurantList.map((json) => Restaurant.fromJson(json)).toList();
        }
      }
      
      debugPrint('HomeBloc: Failed to fetch restaurants');
      return [];
    } catch (e) {
      debugPrint('HomeBloc: Error fetching restaurants: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchCategories(String? token) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/partner/categories');
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['status'] == 'SUCCESS' && responseData['data'] != null) {
          final List<dynamic> categoryList = responseData['data'];
          return categoryList.cast<Map<String, dynamic>>();
        }
      }
      
      debugPrint('HomeBloc: Failed to fetch categories');
      return [];
    } catch (e) {
      debugPrint('HomeBloc: Error fetching categories: $e');
      return [];
    }
  }
}
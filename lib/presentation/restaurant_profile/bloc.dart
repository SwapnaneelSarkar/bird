// presentation/restaurant_profile/bloc.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import '../../../service/token_service.dart';
import '../../../constants/api_constant.dart';
import '../../../models/restaurant_model.dart';
import 'event.dart';
import 'state.dart';

class RestaurantProfileBloc extends Bloc<RestaurantProfileEvent, RestaurantProfileState> {
  RestaurantProfileBloc() : super(RestaurantProfileInitial()) {
    on<LoadRestaurantProfile>(_onLoadRestaurantProfile);
  }

  Future<void> _onLoadRestaurantProfile(
    LoadRestaurantProfile event,
    Emitter<RestaurantProfileState> emit,
  ) async {
    try {
      emit(RestaurantProfileLoading());
      
      debugPrint('RestaurantProfileBloc: Loading restaurant with ID: ${event.restaurantId}');
      
      // Get auth token
      final token = await TokenService.getToken();
      if (token == null) {
        debugPrint('RestaurantProfileBloc: No authentication token available');
        emit(const RestaurantProfileError(message: 'Please login to view restaurant details'));
        return;
      }
      
      // Fetch restaurant data from API
      final url = Uri.parse('${ApiConstants.baseUrl}/api/partner/restaurant/${event.restaurantId}');
      
      debugPrint('RestaurantProfileBloc: Fetching restaurant from: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      debugPrint('RestaurantProfileBloc: API Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        debugPrint('RestaurantProfileBloc: API Response Body: ${response.body}');
        
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['status'] == 'SUCCESS' && responseData['data'] != null) {
          final restaurantData = responseData['data'];
          
          // Convert API response to Restaurant model
          final restaurant = Restaurant.fromJson(restaurantData);
          
          debugPrint('RestaurantProfileBloc: Restaurant loaded successfully: ${restaurant.name}');
          
          emit(RestaurantProfileLoaded(restaurant: restaurant));
        } else {
          debugPrint('RestaurantProfileBloc: API returned non-success status: ${responseData['message']}');
          emit(RestaurantProfileError(message: responseData['message'] ?? 'Failed to load restaurant details'));
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        // Authentication error
        debugPrint('RestaurantProfileBloc: Authentication error: ${response.statusCode}');
        emit(const RestaurantProfileError(message: 'Your session has expired. Please login again'));
      } else {
        debugPrint('RestaurantProfileBloc: Restaurant API Error: Status ${response.statusCode}');
        emit(const RestaurantProfileError(message: 'Server error. Please try again later.'));
      }
    } catch (e) {
      debugPrint('RestaurantProfileBloc: Error loading restaurant data: $e');
      emit(const RestaurantProfileError(message: 'Failed to load restaurant data. Please check your connection.'));
    }
  }
}
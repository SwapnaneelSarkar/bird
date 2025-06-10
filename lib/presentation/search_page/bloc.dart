// lib/presentation/screens/search/bloc.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:bird/constants/api_constant.dart';
import '../../../service/token_service.dart';
import 'event.dart';
import 'state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  Timer? _debounceTimer;
  
  SearchBloc() : super(SearchInitialState()) {
    on<SearchInitialEvent>(_onSearchInitial);
    on<SearchQueryChangedEvent>(_onSearchQueryChanged);
    on<SearchClearEvent>(_onSearchClear);
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }

  Future<void> _onSearchInitial(
    SearchInitialEvent event,
    Emitter<SearchState> emit,
  ) async {
    debugPrint('SearchBloc: Initialized with coordinates - Lat: ${event.latitude}, Long: ${event.longitude}');
    emit(SearchEmptyState(query: ''));
  }

  Future<void> _onSearchQueryChanged(
    SearchQueryChangedEvent event,
    Emitter<SearchState> emit,
  ) async {
    debugPrint('SearchBloc: Query changed to: "${event.query}"');
    
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    // If query is empty, show empty state
    if (event.query.trim().isEmpty) {
      emit(SearchEmptyState(query: ''));
      return;
    }

    // Show loading state immediately
    emit(SearchLoadingState());

    // Use simple delay without Timer to avoid BLoC issues
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Check if a newer search was triggered during the delay
    if (state is! SearchLoadingState) {
      return; // A newer search has been started
    }
    
    debugPrint('SearchBloc: Performing search after delay for query: "${event.query}"');
    await _performSearch(event, emit);
  }

  Future<void> _onSearchClear(
    SearchClearEvent event,
    Emitter<SearchState> emit,
  ) async {
    _debounceTimer?.cancel();
    emit(SearchEmptyState(query: ''));
  }

  Future<void> _performSearch(
    SearchQueryChangedEvent event,
    Emitter<SearchState> emit,
  ) async {
    try {
      debugPrint('SearchBloc: Performing search with query: "${event.query}"');
      
      // Get auth token
      final token = await TokenService.getToken();
      if (token == null) {
        debugPrint('SearchBloc: No authentication token available');
        emit(SearchErrorState(error: 'Please login to search restaurants'));
        return;
      }
      
      // Construct the API URL - using the working endpoint
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/user/search').replace(
        queryParameters: {
          'latitude': event.latitude?.toString() ?? '0',
          'longitude': event.longitude?.toString() ?? '0',
          'searchQuery': event.query.trim(),
          'radius': event.radius.toString(),
        },
      );

      debugPrint('SearchBloc: API URL - $uri');

      // Make API call with auth token - using POST since you mentioned it's a POST API
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'latitude': event.latitude?.toString() ?? '0',
          'longitude': event.longitude?.toString() ?? '0',
          'searchQuery': event.query.trim(),
          'radius': event.radius.toString(),
        }),
      );

      debugPrint('SearchBloc: API Response Status Code - ${response.statusCode}');
      debugPrint('SearchBloc: API Response Body - ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        
        if (jsonResponse['status'] == true) {
          await _processSuccessfulResponse(jsonResponse, event.query, emit);
        } else {
          final errorMessage = jsonResponse['message'] ?? 'Search failed';
          debugPrint('SearchBloc: API returned error - $errorMessage');
          emit(SearchErrorState(error: errorMessage));
        }
      } else if (response.statusCode == 401) {
        debugPrint('SearchBloc: Authentication failed');
        emit(SearchErrorState(error: 'Session expired. Please login again.'));
      } else {
        debugPrint('SearchBloc: API call failed with status code ${response.statusCode}');
        emit(SearchErrorState(error: 'Failed to search. Please try again.'));
      }
    } catch (e) {
      debugPrint('SearchBloc: Exception occurred - $e');
      emit(SearchErrorState(error: 'An error occurred. Please check your connection.'));
    }
  }
  
  Future<void> _processSuccessfulResponse(
    Map<String, dynamic> jsonResponse,
    String query,
    Emitter<SearchState> emit,
  ) async {
    final data = jsonResponse['data'] as Map<String, dynamic>;
    
    // Parse direct restaurants from restaurants array
    final List<SearchRestaurant> directRestaurants = [];
    if (data['restaurants'] != null) {
      final restaurantsList = data['restaurants'] as List;
      directRestaurants.addAll(
        restaurantsList.map((restaurant) => SearchRestaurant.fromJson(restaurant))
      );
    }

    // Parse menu items
    final List<SearchMenuItem> menuItems = [];
    if (data['menu_items'] != null) {
      final menuItemsList = data['menu_items'] as List;
      menuItems.addAll(
        menuItemsList.map((menuItem) => SearchMenuItem.fromJson(menuItem))
      );
    }

    // Extract restaurants from menu items and convert to SearchRestaurant format
    final List<SearchRestaurant> restaurantsFromMenuItems = [];
    final Set<String> addedRestaurantIds = {}; // To avoid duplicates
    
    for (final menuItem in menuItems) {
      final restaurantInfo = menuItem.restaurant;
      
      // Skip if we already added this restaurant
      if (addedRestaurantIds.contains(restaurantInfo.id)) {
        continue;
      }
      
      // Convert SearchRestaurantInfo to SearchRestaurant format
      final restaurantFromMenuItem = SearchRestaurant(
        partnerId: restaurantInfo.id,
        restaurantName: restaurantInfo.name,
        address: restaurantInfo.address,
        rating: restaurantInfo.rating,
        category: restaurantInfo.cuisineType,
        latitude: restaurantInfo.latitude,
        longitude: restaurantInfo.longitude,
        restaurantPhotos: restaurantInfo.restaurantPhotos,
        distance: restaurantInfo.distance,
      );
      
      restaurantsFromMenuItems.add(restaurantFromMenuItem);
      addedRestaurantIds.add(restaurantInfo.id);
    }

    // Combine both restaurant lists and remove duplicates
    final Map<String, SearchRestaurant> uniqueRestaurants = {};
    
    // Add direct restaurants
    for (final restaurant in directRestaurants) {
      uniqueRestaurants[restaurant.partnerId] = restaurant;
    }
    
    // Add restaurants from menu items (only if not already present)
    for (final restaurant in restaurantsFromMenuItems) {
      if (!uniqueRestaurants.containsKey(restaurant.partnerId)) {
        uniqueRestaurants[restaurant.partnerId] = restaurant;
      }
    }
    
    // Convert back to list
    final List<SearchRestaurant> allRestaurants = uniqueRestaurants.values.toList();
    
    // Sort by distance (closest first)
    allRestaurants.sort((a, b) => a.distance.compareTo(b.distance));

    debugPrint('SearchBloc: Found ${directRestaurants.length} direct restaurants');
    debugPrint('SearchBloc: Found ${restaurantsFromMenuItems.length} restaurants from menu items');
    debugPrint('SearchBloc: Total unique restaurants: ${allRestaurants.length}');
    debugPrint('SearchBloc: Found ${menuItems.length} menu items');

    // Check if results are empty
    if (allRestaurants.isEmpty && menuItems.isEmpty) {
      debugPrint('SearchBloc: Emitting empty state');
      emit(SearchEmptyState(query: query));
    } else {
      debugPrint('SearchBloc: Emitting loaded state');
      emit(SearchLoadedState(
        restaurants: allRestaurants,
        menuItems: menuItems,
        query: query,
      ));
    }
  }
}
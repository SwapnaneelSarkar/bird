// bloc.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../service/token_service.dart';
import '../../../constants/api_constant.dart';
import 'event.dart';
import 'state.dart';

class RestaurantDetailsBloc extends Bloc<RestaurantDetailsEvent, RestaurantDetailsState> {
  RestaurantDetailsBloc() : super(RestaurantDetailsInitial()) {
    on<LoadRestaurantDetails>(_onLoadRestaurantDetails);
    on<AddItemToCart>(_onAddItemToCart);
    on<ToggleFavorite>(_onToggleFavorite);
  }
  
  Future<void> _onLoadRestaurantDetails(
    LoadRestaurantDetails event, 
    Emitter<RestaurantDetailsState> emit
  ) async {
    emit(RestaurantDetailsLoading());
    
    try {
      // Process restaurant data
      final restaurant = event.restaurant;
      
      // Check if restaurant data is valid
      if (restaurant == null || restaurant.isEmpty) {
        debugPrint('RestaurantDetailsBloc: Restaurant data is null or empty');
        emit(RestaurantDetailsError('Restaurant data is not available. Please try again.'));
        return;
      }
      
      // Extract restaurant ID using different possible key names
      final partnerId = restaurant['partnerId'] ?? 
                         restaurant['partner_id'] ?? 
                         restaurant['id'];
      
      final restaurantName = restaurant['restaurantName'] ?? 
                              restaurant['restaurant_name'] ?? 
                              restaurant['name'];
      
      debugPrint('RestaurantDetailsBloc: Loading details for restaurant ID: ${partnerId ?? 'unknown'}, name: ${restaurantName ?? 'unknown'}');
      
      if (partnerId == null) {
        debugPrint('RestaurantDetailsBloc: Restaurant ID is missing');
        emit(RestaurantDetailsError('Restaurant information is incomplete. Please try again.'));
        return;
      }
      
      // Get auth token
      final token = await TokenService.getToken();
      if (token == null) {
        debugPrint('RestaurantDetailsBloc: No authentication token available');
        emit(RestaurantDetailsError('Please login to view restaurant details.'));
        return;
      }
      
      // Fetch menu items from the API
      List<Map<String, dynamic>> menuItems = [];
      bool needsLogin = false;
      String errorMessage = '';
      
      try {
        final url = Uri.parse('${ApiConstants.baseUrl}/api/partner/restaurant/$partnerId');
        
        debugPrint('RestaurantDetailsBloc: Fetching menu from: $url');
        
        final response = await http.get(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        
        debugPrint('RestaurantDetailsBloc: API Response Status: ${response.statusCode}');
        if (response.statusCode == 200) {
          debugPrint('RestaurantDetailsBloc: API Response Body: ${response.body}');
          
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          
          if (responseData['status'] == 'SUCCESS' && responseData['data'] != null) {
            final data = responseData['data'];
            
            // Format menu items from API response
            if (data['menu_items'] != null && data['menu_items'] is List) {
              final List<dynamic> menuItemsList = data['menu_items'];
              
              // Convert to map format expected by UI
              menuItems = menuItemsList.map((item) {
                // Parse price (handling string or numeric values)
                double price = 0.0;
                if (item['price'] != null) {
                  if (item['price'] is String) {
                    price = double.tryParse(item['price'].toString()) ?? 0.0;
                  } else if (item['price'] is num) {
                    price = (item['price'] as num).toDouble();
                  }
                }
                
                return {
                  'id': item['menu_id'] ?? '',
                  'name': item['name'] ?? '',
                  'price': price,
                  'description': item['description'] ?? '',
                  'imageUrl': item['image_url'],
                  'isVeg': item['isVeg'] ?? false,
                  'category': item['category'] ?? '',
                };
              }).toList();
              
              debugPrint('RestaurantDetailsBloc: Processed ${menuItems.length} menu items');
              
              // Log one menu item for debugging
              if (menuItems.isNotEmpty) {
                debugPrint('RestaurantDetailsBloc: Sample menu item: ${menuItems[0]}');
              }
            }
          } else {
            debugPrint('RestaurantDetailsBloc: API returned non-success status: ${responseData['message']}');
            errorMessage = responseData['message'] ?? 'Failed to load restaurant menu';
          }
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          // Authentication error
          debugPrint('RestaurantDetailsBloc: Authentication error: ${response.statusCode}');
          needsLogin = true;
          errorMessage = 'Your session has expired. Please login again.';
        } else {
          debugPrint('RestaurantDetailsBloc: Restaurant API Error: Status ${response.statusCode}');
          errorMessage = 'Server error. Please try again later.';
        }
      } catch (e) {
        debugPrint('RestaurantDetailsBloc: Error fetching restaurant menu: $e');
        errorMessage = 'Network error. Please check your connection.';
      }
      
      // Check for authentication errors
      if (needsLogin) {
        await TokenService.clearAll(); // Clear invalid tokens
        emit(RestaurantDetailsError(errorMessage, needsLogin: true));
        return;
      }
      
      // Check if we have an error message but no menu items
      if (errorMessage.isNotEmpty && menuItems.isEmpty) {
        emit(RestaurantDetailsError(errorMessage));
        return;
      }
      
      // Check if the restaurant is in favorites
      final prefs = await SharedPreferences.getInstance();
      final favoriteRestaurants = prefs.getStringList('favorite_restaurants') ?? [];
      final isFavorite = favoriteRestaurants.contains(restaurantName);
      
      emit(RestaurantDetailsLoaded(
        restaurant: restaurant,
        menu: menuItems,
        cartItems: [],
        isFavorite: isFavorite,
      ));
      
    } catch (e) {
      debugPrint('RestaurantDetailsBloc: Error loading details: $e');
      emit(RestaurantDetailsError('Failed to load restaurant details. Please try again.'));
    }
  }
  
  Future<void> _onAddItemToCart(
    AddItemToCart event, 
    Emitter<RestaurantDetailsState> emit
  ) async {
    try {
      if (state is RestaurantDetailsLoaded) {
        final currentState = state as RestaurantDetailsLoaded;
        
        // Check if item already in cart
        final existingItemIndex = currentState.cartItems.indexWhere(
          (item) => item['id'] == event.item['id']
        );
        
        List<Map<String, dynamic>> updatedCart = List.from(currentState.cartItems);
        
        if (existingItemIndex >= 0) {
          // Update quantity
          final existingItem = updatedCart[existingItemIndex];
          final updatedItem = {...existingItem};
          updatedItem['quantity'] = event.quantity;
          
          if (event.quantity > 0) {
            updatedCart[existingItemIndex] = updatedItem;
          } else {
            // Remove item if quantity is 0
            updatedCart.removeAt(existingItemIndex);
          }
        } else if (event.quantity > 0) {
          // Add new item
          updatedCart.add({
            ...event.item,
            'quantity': event.quantity,
          });
        }
        
        // First emit success message for the snackbar
        emit(CartUpdateSuccess('Item added to cart'));
        
        // Then emit updated state
        emit(currentState.copyWith(cartItems: updatedCart));
      }
    } catch (e) {
      debugPrint('RestaurantDetailsBloc: Error updating cart: $e');
    }
  }
  
  Future<void> _onToggleFavorite(
    ToggleFavorite event, 
    Emitter<RestaurantDetailsState> emit
  ) async {
    try {
      if (state is RestaurantDetailsLoaded) {
        final currentState = state as RestaurantDetailsLoaded;
        final restaurant = currentState.restaurant;
        
        // Get restaurant name using different possible keys
        final restaurantName = restaurant['restaurantName'] ?? 
                               restaurant['restaurant_name'] ?? 
                               restaurant['name'];
        
        // Update SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final favoriteRestaurants = prefs.getStringList('favorite_restaurants') ?? [];
        
        List<String> updatedFavorites = List.from(favoriteRestaurants);
        
        if (currentState.isFavorite) {
          updatedFavorites.remove(restaurantName);
        } else {
          updatedFavorites.add(restaurantName);
        }
        
        await prefs.setStringList('favorite_restaurants', updatedFavorites);
        
        // Update state
        emit(currentState.copyWith(isFavorite: !currentState.isFavorite));
      }
    } catch (e) {
      debugPrint('RestaurantDetailsBloc: Error toggling favorite: $e');
    }
  }
}
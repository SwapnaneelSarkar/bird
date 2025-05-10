import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      
      final restaurantId = restaurant['id'] as String?;
      final restaurantName = restaurant['name'] as String?;
      
      debugPrint('RestaurantDetailsBloc: Loading details for restaurant ID: ${restaurantId ?? 'unknown'}, name: ${restaurantName ?? 'unknown'}');
      
      if (restaurantName == null) {
        debugPrint('RestaurantDetailsBloc: Restaurant name is missing');
        emit(RestaurantDetailsError('Restaurant information is incomplete. Please try again.'));
        return;
      };
      
      // Load menu items from the JSON file (if not already present in the restaurant data)
      final List<Map<String, dynamic>> menuItems = 
          await _loadRestaurantMenu(restaurant['name'], restaurantId);
      
      debugPrint('RestaurantDetailsBloc: Loaded ${menuItems.length} menu items');
      
      // Check if the restaurant is in favorites
      final prefs = await SharedPreferences.getInstance();
      final favoriteRestaurants = prefs.getStringList('favorite_restaurants') ?? [];
      final isFavorite = favoriteRestaurants.contains(restaurant['name']);
      
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
          updatedItem['quantity'] = event.quantity as int;
          
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
            'quantity': event.quantity as int,
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
        
        // Update SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final favoriteRestaurants = prefs.getStringList('favorite_restaurants') ?? [];
        
        List<String> updatedFavorites = List.from(favoriteRestaurants);
        
        if (currentState.isFavorite) {
          updatedFavorites.remove(restaurant['name']);
        } else {
          updatedFavorites.add(restaurant['name']);
        }
        
        await prefs.setStringList('favorite_restaurants', updatedFavorites);
        
        // Update state
        emit(currentState.copyWith(isFavorite: !currentState.isFavorite));
      }
    } catch (e) {
      debugPrint('RestaurantDetailsBloc: Error toggling favorite: $e');
    }
  }
  
  // Helper method to load restaurant menu from the JSON file
  Future<List<Map<String, dynamic>>> _loadRestaurantMenu(String restaurantName, String? restaurantId) async {
    try {
      // Load data from the JSON file
      final String data = await rootBundle.loadString('assets/data/restaurant.json');
      final Map<String, dynamic> jsonData = json.decode(data);
      
      // Extract restaurants list
      final List<dynamic> restaurants = jsonData['restaurants'];
      
      // Find the restaurant - first try by ID if available, then by name
      Map<String, dynamic>? restaurant;
      
      if (restaurantId != null) {
        // Try to find by ID first
        restaurant = restaurants.firstWhere(
          (r) => r['id'] == restaurantId,
          orElse: () => null,
        );
      }
      
      // If not found by ID or ID was null, try to find by name
      if (restaurant == null) {
        restaurant = restaurants.firstWhere(
          (r) => r['name'] == restaurantName,
          orElse: () => null,
        );
      }
      
      // If restaurant is found and has menu items
      if (restaurant != null && restaurant.containsKey('menu')) {
        debugPrint('RestaurantDetailsBloc: Found restaurant ${restaurant['name']} with ${restaurant['menu'].length} menu items');
        return List<Map<String, dynamic>>.from(restaurant['menu']);
      }
      
      debugPrint('RestaurantDetailsBloc: Restaurant menu not found, using fallback menu');
      // Fallback menu items if not found
      return [
        {
          'id': 'default1',
          'name': 'House Special',
          'price': 299,
          'description': 'Chef\'s special preparation',
          'imageUrl': 'assets/images/food1.jpg',
          'isVeg': false,
          'category': 'Specials',
          'cookTime': '15 mins',
          'isPopular': true
        },
        {
          'id': 'default2',
          'name': 'Vegetarian Platter',
          'price': 249,
          'description': 'Assorted vegetarian delicacies',
          'imageUrl': 'assets/images/food2.jpg',
          'isVeg': true,
          'category': 'Main Course',
          'cookTime': '10 mins',
          'isPopular': false
        }
      ];
      
      debugPrint('RestaurantDetailsBloc: Restaurant data not found in JSON, using fallback menu');
      // Fallback to hardcoded menu for demo purposes
      return [
        {
          'id': 'default1',
          'name': 'House Special',
          'price': 299,
          'description': 'Chef\'s special preparation',
          'imageUrl': 'assets/images/food1.jpg',
          'isVeg': false,
          'category': 'Specials',
          'cookTime': '15 mins',
          'isPopular': true
        },
        {
          'id': 'default2',
          'name': 'Vegetarian Platter',
          'price': 249,
          'description': 'Assorted vegetarian delicacies',
          'imageUrl': 'assets/images/food2.jpg',
          'isVeg': true,
          'category': 'Main Course',
          'cookTime': '10 mins',
          'isPopular': false
        },
      ];
    } catch (e) {
      debugPrint('RestaurantDetailsBloc: Error loading menu: $e');
      
      // Return fallback menu in case of error
      return [
        {
          'id': 'error1',
          'name': 'Classic Dish',
          'price': 299,
          'description': 'A delicious option from our menu',
          'imageUrl': 'assets/images/food1.jpg',
          'isVeg': true,
          'category': 'Main Course',
          'cookTime': '15 mins',
          'isPopular': true
        }
      ];
    }
  }
}
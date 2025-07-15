import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../service/token_service.dart';
import '../../../service/cart_service.dart';
import '../../../constants/api_constant.dart';
import '../../../utils/distance_util.dart';
import 'event.dart';
import 'state.dart';

class RestaurantDetailsBloc extends Bloc<RestaurantDetailsEvent, RestaurantDetailsState> {
  RestaurantDetailsBloc() : super(RestaurantDetailsInitial()) {
    on<LoadRestaurantDetails>(_onLoadRestaurantDetails);
    on<AddItemToCart>(_onAddItemToCart);
    on<ReplaceCartWithNewRestaurant>(_onReplaceCartWithNewRestaurant);
    on<ToggleFavorite>(_onToggleFavorite);
    on<LoadCartData>(_onLoadCartData);
    on<DismissCartConflict>(_onDismissCartConflict);
    on<ClearCart>(_onClearCart);
  }
  
  Future<void> _onLoadRestaurantDetails(
    LoadRestaurantDetails event, 
    Emitter<RestaurantDetailsState> emit
  ) async {
    emit(RestaurantDetailsLoading());
    
    try {
      // Process restaurant data
      final restaurant = Map<String, dynamic>.from(event.restaurant);
      
      // Check if restaurant data is valid
      if (restaurant.isEmpty) {
        debugPrint('RestaurantDetailsBloc: Restaurant data is null or empty');
        emit(RestaurantDetailsError('Restaurant data is not available. Please try again.'));
        return;
      }
      
      // Calculate distance if coordinates are available
      if (event.userLatitude != null && event.userLongitude != null) {
        final restaurantLat = restaurant['latitude'] != null 
            ? double.tryParse(restaurant['latitude'].toString())
            : null;
        final restaurantLng = restaurant['longitude'] != null 
            ? double.tryParse(restaurant['longitude'].toString())
            : null;
            
        debugPrint('RestaurantDetailsBloc: User coordinates - Lat: ${event.userLatitude}, Long: ${event.userLongitude}');
        debugPrint('RestaurantDetailsBloc: Restaurant coordinates - Lat: $restaurantLat, Long: $restaurantLng');
            
        if (restaurantLat != null && restaurantLng != null) {
          try {
            final distance = DistanceUtil.calculateDistance(
              event.userLatitude!,
              event.userLongitude!,
              restaurantLat,
              restaurantLng
            );
            
            // Format the distance
            final formattedDistance = DistanceUtil.formatDistance(distance);
            debugPrint('RestaurantDetailsBloc: Calculated distance: $formattedDistance');
            
            // Update the restaurant data with the calculated distance
            restaurant['calculatedDistance'] = formattedDistance;
          } catch (e) {
            debugPrint('RestaurantDetailsBloc: Error calculating distance: $e');
          }
        }
      }
      
      // Extract restaurant ID using different possible key names
      final partnerId = restaurant['partnerId'] ?? 
                         restaurant['partner_id'] ?? 
                         restaurant['id'];
      
      final restaurantName = restaurant['restaurantName'] ?? 
                              restaurant['restaurant_name'] ?? 
                              restaurant['name'];
      
      debugPrint('RestaurantDetailsBloc: Loading details for restaurant ID: ${partnerId ?? 'unknown'}, name: ${restaurantName ?? 'unknown'}');
      
      if (partnerId == null || partnerId.toString().trim().isEmpty) {
        debugPrint('RestaurantDetailsBloc: Restaurant ID is missing or empty');
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
            
            // Update restaurant information with API response data
            final apiRestaurant = data as Map<String, dynamic>;
            
            // Update restaurant with any new information from API
            if (apiRestaurant['partner_id'] != null) restaurant['id'] = apiRestaurant['partner_id'];
            if (apiRestaurant['restaurant_name'] != null) restaurant['name'] = apiRestaurant['restaurant_name'];
            if (apiRestaurant['category'] != null) restaurant['cuisine'] = apiRestaurant['category'];
            if (apiRestaurant['address'] != null) restaurant['address'] = apiRestaurant['address'];
            if (apiRestaurant['latitude'] != null) restaurant['latitude'] = apiRestaurant['latitude'];
            if (apiRestaurant['longitude'] != null) restaurant['longitude'] = apiRestaurant['longitude'];
            if (apiRestaurant['veg_nonveg'] != null) restaurant['isVeg'] = apiRestaurant['veg_nonveg'] == 'veg';
            if (apiRestaurant['operational_hours'] != null) restaurant['openTimings'] = apiRestaurant['operational_hours'];
            if (apiRestaurant['owner_name'] != null) restaurant['ownerName'] = apiRestaurant['owner_name'];
            if (apiRestaurant['description'] != null) restaurant['description'] = apiRestaurant['description'];
            if (apiRestaurant['rating'] != null) restaurant['rating'] = apiRestaurant['rating'];
            if (apiRestaurant['restaurant_type'] != null) restaurant['restaurantType'] = apiRestaurant['restaurant_type'];
            if (apiRestaurant['isAcceptingOrder'] != null) restaurant['isAcceptingOrder'] = apiRestaurant['isAcceptingOrder'] == 1;
            
            // Format menu items from API response
            if (data['menu'] != null && data['menu'] is List) {
              final List<dynamic> menuItemsList = data['menu'];
              
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
                  'isVeg': item['isVeg'] == 1,
                  'category': item['category'],
                  'available': item['available'] == 1,
                  'isTaxIncluded': item['isTaxIncluded'] == 1,
                  'isCancellable': item['isCancellable'] == 1,
                  'tags': item['tags'],
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
      
      // Load cart data to show current quantities
      final cart = await CartService.getCart();
      Map<String, int> cartQuantities = {};
      
      if (cart != null && cart['partner_id'] == partnerId) {
        final items = cart['items'] as List<dynamic>? ?? [];
        for (var item in items) {
          cartQuantities[item['menu_id']] = item['quantity'] ?? 0;
        }
        debugPrint('RestaurantDetailsBloc: Loaded cart with ${items.length} items');
      }
      
      emit(RestaurantDetailsLoaded(
        restaurant: restaurant,
        menu: menuItems,
        cartQuantities: cartQuantities,
        isFavorite: isFavorite,
        cartItemCount: await CartService.getCartItemCount(),
        cartTotal: await CartService.getCartTotal(),
      ));
      
    } catch (e) {
      debugPrint('RestaurantDetailsBloc: Error loading details: $e');
      emit(RestaurantDetailsError('Failed to load restaurant details. Please try again.'));
    }
  }
  
  Future<void> _onAddItemToCart(
    AddItemToCart event,
    Emitter<RestaurantDetailsState> emit,
  ) async {
    try {
      debugPrint('=== RESTAURANT MENU BLOC: ADD ITEM TO CART START (SILENT MODE) ===');

      final currentState = state;
      if (currentState is! RestaurantDetailsLoaded) {
        debugPrint('RESTAURANT MENU BLOC: Invalid state for adding item');
        return;
      }

      final restaurant = currentState.restaurant;
      final partnerId = restaurant['id']?.toString() ?? '';
      final restaurantName = restaurant['name']?.toString() ?? '';

      // Add item to cart silently in background
      final result = await CartService.addItemToCart(
        partnerId: partnerId,
        restaurantName: restaurantName,
        menuId: event.item['id']?.toString() ?? '',
        itemName: event.item['name']?.toString() ?? '',
        price: (event.item['price'] as num?)?.toDouble() ?? 0.0,
        quantity: event.quantity,
        imageUrl: event.item['imageUrl']?.toString(),
        attributes: event.attributes,
      );

      if (result['success'] == true) {
        final cart = result['cart'] as Map<String, dynamic>;
        
        // Update ONLY the cart quantities - no success/error emissions
        Map<String, int> updatedQuantities = <String, int>{};
        final cartItems = cart['items'] as List<dynamic>;
        
        // Set quantities based on cart items
        for (var cartItem in cartItems) {
          final menuId = cartItem['menu_id']?.toString() ?? '';
          final quantity = cartItem['quantity'] as int? ?? 0;
          updatedQuantities[menuId] = quantity;
        }

        // SILENT UPDATE - Only emit updated quantities
        emit(currentState.copyWith(
          cartQuantities: updatedQuantities,
          cartItemCount: result['total_items'] as int? ?? 0,
          cartTotal: (cart['total_price'] as num?)?.toDouble() ?? 0.0,
        ));
        
        debugPrint('RESTAURANT MENU BLOC: Cart updated silently');
        
      } else if (result['message'] == 'different_restaurant') {
        debugPrint('RESTAURANT MENU BLOC: Different restaurant detected');
        emit(CartConflictDetected(
          currentRestaurant: result['current_restaurant'] as String? ?? 'Previous Restaurant',
          newRestaurant: result['new_restaurant'] as String? ?? 'New Restaurant',
          pendingItem: event.item,
          pendingQuantity: event.quantity,
          previousState: currentState,
        ));
      } else {
        debugPrint('RESTAURANT MENU BLOC: Cart operation failed silently');
      }
      
      debugPrint('=== RESTAURANT MENU BLOC: ADD ITEM TO CART END (SILENT MODE) ===');
      
    } catch (e) {
      debugPrint('RESTAURANT MENU BLOC: Error in _onAddItemToCart: $e');
    }
  }
  
  Future<void> _onReplaceCartWithNewRestaurant(
    ReplaceCartWithNewRestaurant event, 
    Emitter<RestaurantDetailsState> emit
  ) async {
    try {
      debugPrint('RestaurantDetailsBloc: Replacing cart with new restaurant');
      
      RestaurantDetailsLoaded? currentState;
      
      if (state is RestaurantDetailsLoaded) {
        currentState = state as RestaurantDetailsLoaded;
      } else if (state is CartConflictDetected) {
        currentState = (state as CartConflictDetected).previousState;
      }
      
      if (currentState == null) {
        debugPrint('RestaurantDetailsBloc: No valid current state found');
        return;
      }
      
      final restaurant = currentState.restaurant;
      
      final partnerId = restaurant['partnerId'] ?? 
                       restaurant['partner_id'] ?? 
                       restaurant['id'] ?? '';
      
      final restaurantName = restaurant['restaurantName'] ?? 
                            restaurant['restaurant_name'] ?? 
                            restaurant['name'] ?? '';
      
      final result = await CartService.replaceCartWithNewRestaurant(
        partnerId: partnerId,
        restaurantName: restaurantName,
        menuId: event.item['id'] ?? '',
        itemName: event.item['name'] ?? '',
        price: (event.item['price'] as num?)?.toDouble() ?? 0.0,
        quantity: event.quantity,
        imageUrl: event.item['imageUrl'],
      );
      
      if (result['success'] == true) {
        Map<String, int> updatedQuantities = {
          event.item['id']: event.quantity,
        };
        
        emit(currentState.copyWith(
          cartQuantities: updatedQuantities,
          cartItemCount: result['total_items'] ?? 0,
          cartTotal: result['cart']?['total_price']?.toDouble() ?? 0.0,
        ));
      } else {
        emit(currentState);
      }
    } catch (e) {
      debugPrint('RestaurantDetailsBloc: Error replacing cart: $e');
    }
  }
  
  Future<void> _onLoadCartData(
    LoadCartData event, 
    Emitter<RestaurantDetailsState> emit
  ) async {
    try {
      if (state is RestaurantDetailsLoaded) {
        final currentState = state as RestaurantDetailsLoaded;
        final restaurant = currentState.restaurant;
        
        final partnerId = restaurant['partnerId'] ?? 
                         restaurant['partner_id'] ?? 
                         restaurant['id'] ?? '';
        
        final cart = await CartService.getCart();
        Map<String, int> cartQuantities = {};
        
        if (cart != null && cart['partner_id'] == partnerId) {
          final items = cart['items'] as List<dynamic>? ?? [];
          for (var item in items) {
            cartQuantities[item['menu_id']] = item['quantity'] ?? 0;
          }
        }
        
        emit(currentState.copyWith(
          cartQuantities: cartQuantities,
          cartItemCount: await CartService.getCartItemCount(),
          cartTotal: await CartService.getCartTotal(),
        ));
      }
    } catch (e) {
      debugPrint('RestaurantDetailsBloc: Error loading cart data: $e');
    }
  }
  
  Future<void> _onDismissCartConflict(
    DismissCartConflict event, 
    Emitter<RestaurantDetailsState> emit
  ) async {
    try {
      if (state is CartConflictDetected) {
        final conflictState = state as CartConflictDetected;
        
        final cart = await CartService.getCart();
        final restaurant = conflictState.previousState.restaurant;
        
        final partnerId = restaurant['partnerId'] ?? 
                         restaurant['partner_id'] ?? 
                         restaurant['id'] ?? '';
        
        Map<String, int> cartQuantities = {};
        
        if (cart != null && cart['partner_id'] == partnerId) {
          final items = cart['items'] as List<dynamic>? ?? [];
          for (var item in items) {
            cartQuantities[item['menu_id']] = item['quantity'] ?? 0;
          }
        }
        
        emit(conflictState.previousState.copyWith(
          cartQuantities: cartQuantities,
          cartItemCount: await CartService.getCartItemCount(),
          cartTotal: await CartService.getCartTotal(),
        ));
      }
    } catch (e) {
      debugPrint('RestaurantDetailsBloc: Error dismissing cart conflict: $e');
      add(const LoadCartData());
    }
  }
  
  Future<void> _onClearCart(
    ClearCart event,
    Emitter<RestaurantDetailsState> emit,
  ) async {
    try {
      if (state is RestaurantDetailsLoaded) {
        final currentState = state as RestaurantDetailsLoaded;
        await CartService.clearCart();
        emit(currentState.copyWith(
          cartQuantities: {},
          cartItemCount: 0,
          cartTotal: 0.0,
        ));
      }
    } catch (e) {
      debugPrint('RestaurantDetailsBloc: Error clearing cart: $e');
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
        
        final restaurantName = restaurant['restaurantName'] ?? 
                               restaurant['restaurant_name'] ?? 
                               restaurant['name'];
        
        final prefs = await SharedPreferences.getInstance();
        final favoriteRestaurants = prefs.getStringList('favorite_restaurants') ?? [];
        
        List<String> updatedFavorites = List.from(favoriteRestaurants);
        
        if (currentState.isFavorite) {
          updatedFavorites.remove(restaurantName);
        } else {
          updatedFavorites.add(restaurantName);
        }
        
        await prefs.setStringList('favorite_restaurants', updatedFavorites);
        
        emit(currentState.copyWith(isFavorite: !currentState.isFavorite));
      }
    } catch (e) {
      debugPrint('RestaurantDetailsBloc: Error toggling favorite: $e');
    }
  }
}
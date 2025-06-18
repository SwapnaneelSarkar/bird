import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/token_service.dart';

class CartService {
  static const String _cartKey = 'user_cart';
  
  // Get current cart
  static Future<Map<String, dynamic>?> getCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartString = prefs.getString(_cartKey);
      
      if (cartString != null) {
        final cart = jsonDecode(cartString) as Map<String, dynamic>;
        debugPrint('CartService: Retrieved cart with ${cart['items']?.length ?? 0} items');
        return cart;
      }
      
      debugPrint('CartService: No cart found');
      return null;
    } catch (e) {
      debugPrint('CartService: Error getting cart: $e');
      return null;
    }
  }
  
  // Save cart to storage
  static Future<bool> saveCart(Map<String, dynamic> cart) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartString = jsonEncode(cart);
      final result = await prefs.setString(_cartKey, cartString);
      
      debugPrint('CartService: Cart saved with ${cart['items']?.length ?? 0} items');
      debugPrint('CartService: Total price: ₹${cart['total_price']}');
      
      return result;
    } catch (e) {
      debugPrint('CartService: Error saving cart: $e');
      return false;
    }
  }
  
  // Clear cart
  static Future<bool> clearCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.remove(_cartKey);
      
      debugPrint('CartService: Cart cleared');
      return result;
    } catch (e) {
      debugPrint('CartService: Error clearing cart: $e');
      return false;
    }
  }
  
  // Add item to cart
  static Future<Map<String, dynamic>> addItemToCart({
    required String partnerId,
    required String restaurantName,
    required String menuId,
    required String itemName,
    required double price,
    required int quantity,
    String? imageUrl,
    Map<String, dynamic>? attributes,
  }) async {
    try {
      final userId = await TokenService.getUserId();
      if (userId == null) {
        return {
          'success': false,
          'message': 'Please login to add items to cart',
        };
      }
      
      // Get current cart
      Map<String, dynamic>? currentCart = await getCart();
      
      // Check if cart exists and has different restaurant
      if (currentCart != null && currentCart['partner_id'] != partnerId) {
        debugPrint('CartService: Different restaurant detected');
        debugPrint('CartService: Current: ${currentCart['partner_id']}, New: $partnerId');
        
        return {
          'success': false,
          'message': 'different_restaurant',
          'current_restaurant': currentCart['restaurant_name'] ?? 'Previous Restaurant',
          'new_restaurant': restaurantName,
        };
      }
      
      // Create new cart or use existing
      Map<String, dynamic> cart = currentCart ?? {
        'partner_id': partnerId,
        'restaurant_name': restaurantName,
        'user_id': userId,
        'items': <Map<String, dynamic>>[],
        'total_price': 0.0,
        'subtotal': 0.0,
        'delivery_fees': 50.0, // Default delivery fee
        'address': '', // Will be updated when placing order
      };
      
      // Find existing item
      List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(cart['items']);
      int existingIndex = items.indexWhere((item) => 
        item['menu_id'] == menuId && 
        mapEquals(item['attributes'], attributes)
      );
      
      if (quantity <= 0) {
        // Remove item if quantity is 0 or less
        if (existingIndex >= 0) {
          items.removeAt(existingIndex);
          debugPrint('CartService: Removed item $itemName from cart');
        }
      } else {
        // Add or update item
        Map<String, dynamic> cartItem = {
          'menu_id': menuId,
          'name': itemName,
          'quantity': quantity,
          'price': price,
          'total_price': price * quantity,
          'image_url': imageUrl,
          'attributes': attributes,
        };
        
        if (existingIndex >= 0) {
          items[existingIndex] = cartItem;
          debugPrint('CartService: Updated item $itemName quantity to $quantity');
        } else {
          items.add(cartItem);
          debugPrint('CartService: Added new item $itemName to cart');
        }
      }
      
      // Update cart
      cart['items'] = items;
      
      // Calculate totals
      double subtotal = 0.0;
      for (var item in items) {
        subtotal += (item['total_price'] as num).toDouble();
      }
      
      cart['subtotal'] = subtotal;
      cart['total_price'] = subtotal + (cart['delivery_fees'] as num).toDouble();
      
      // Save cart (or clear if empty)
      if (items.isEmpty) {
        await clearCart();
        debugPrint('CartService: Cart is empty, cleared from storage');
      } else {
        await saveCart(cart);
      }
      
      return {
        'success': true,
        'message': quantity <= 0 ? 'Item removed from cart' : 'Item added to cart',
        'cart': cart,
        'item_count': items.length,
        'total_items': items.fold<int>(0, (sum, item) => sum + (item['quantity'] as int)),
      };
      
    } catch (e) {
      debugPrint('CartService: Error adding item to cart: $e');
      return {
        'success': false,
        'message': 'Error adding item to cart',
      };
    }
  }
  
  // Helper function to compare maps
  static bool mapEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    
    return a.entries.every((entry) {
      final value = b[entry.key];
      if (value is Map) {
        return mapEquals(entry.value as Map<String, dynamic>?, value as Map<String, dynamic>?);
      }
      return value == entry.value;
    });
  }
  
  // Replace cart with new restaurant items
  static Future<Map<String, dynamic>> replaceCartWithNewRestaurant({
    required String partnerId,
    required String restaurantName,
    required String menuId,
    required String itemName,
    required double price,
    required int quantity,
    String? imageUrl,
  }) async {
    try {
      debugPrint('CartService: Replacing cart with new restaurant: $restaurantName');
      debugPrint('CartService: Partner ID: $partnerId');
      debugPrint('CartService: Item: $itemName, Quantity: $quantity, Price: $price');
      
      // Clear existing cart first
      await clearCart();
      debugPrint('CartService: Existing cart cleared');
      
      // Add new item from the new restaurant
      final result = await addItemToCart(
        partnerId: partnerId,
        restaurantName: restaurantName,
        menuId: menuId,
        itemName: itemName,
        price: price,
        quantity: quantity,
        imageUrl: imageUrl,
      );
      
      debugPrint('CartService: Add item result after clearing: $result');
      
      if (result['success'] == true) {
        debugPrint('CartService: Cart successfully replaced with new restaurant');
        return {
          'success': true,
          'message': 'Cart updated with items from $restaurantName',
          'cart': result['cart'],
          'item_count': result['item_count'],
          'total_items': result['total_items'],
        };
      } else {
        debugPrint('CartService: Failed to add item after clearing cart: ${result['message']}');
        return {
          'success': false,
          'message': result['message'] ?? 'Failed to replace cart',
        };
      }
      
    } catch (e) {
      debugPrint('CartService: Error replacing cart: $e');
      return {
        'success': false,
        'message': 'Error updating cart',
      };
    }
  }
  
  // Get cart item count
  static Future<int> getCartItemCount() async {
    try {
      final cart = await getCart();
      if (cart == null) return 0;
      
      final items = cart['items'] as List<dynamic>? ?? [];
      return items.fold<int>(0, (sum, item) => sum + (item['quantity'] as int));
    } catch (e) {
      debugPrint('CartService: Error getting cart count: $e');
      return 0;
    }
  }
  
  // Get cart total
  static Future<double> getCartTotal() async {
    try {
      final cart = await getCart();
      return cart?['total_price']?.toDouble() ?? 0.0;
    } catch (e) {
      debugPrint('CartService: Error getting cart total: $e');
      return 0.0;
    }
  }
  
  // Update cart address
  static Future<bool> updateCartAddress(String address) async {
    try {
      final cart = await getCart();
      if (cart == null) return false;
      
      cart['address'] = address;
      return await saveCart(cart);
    } catch (e) {
      debugPrint('CartService: Error updating cart address: $e');
      return false;
    }
  }
}
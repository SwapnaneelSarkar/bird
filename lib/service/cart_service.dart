import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/token_service.dart';
import '../models/attribute_model.dart';
import '../utils/timezone_utils.dart';

class CartService {
  static const String _cartKey = 'user_cart';
  static DateTime? _lastCartOperation;
  static const Duration _debounceDelay = Duration(milliseconds: 300);
  
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
  
  // Add item to cart with debouncing
  static Future<Map<String, dynamic>> addItemToCart({
    required String partnerId,
    required String restaurantName,
    required String menuId,
    required String itemName,
    required double price,
    required int quantity,
    String? imageUrl,
    List<SelectedAttribute>? attributes,
  }) async {
    final now = TimezoneUtils.getCurrentTimeIST();
    
    // Debounce rapid operations
    if (_lastCartOperation != null &&
        now.difference(_lastCartOperation!) < _debounceDelay) {
      debugPrint('CartService: Debouncing cart operation');
      return {
        'success': false,
        'message': 'Please wait before making another change',
      };
    }
    
    _lastCartOperation = now;

    try {
      debugPrint('=== CART SERVICE: ADD ITEM OPERATION START ===');
      debugPrint('CART SERVICE: Input parameters:');
      debugPrint('  - Partner ID: $partnerId');
      debugPrint('  - Restaurant: $restaurantName');
      debugPrint('  - Menu ID: $menuId');
      debugPrint('  - Item Name: $itemName');
      debugPrint('  - Base Price: ₹$price');
      debugPrint('  - Quantity: $quantity');
      debugPrint('  - Image URL: $imageUrl');
      debugPrint('  - Attributes count: ${attributes?.length ?? 0}');
      
      if (attributes != null && attributes.isNotEmpty) {
        for (var attr in attributes) {
          debugPrint('    - ${attr.attributeName}: ${attr.valueName} (+₹${attr.priceAdjustment})');
        }
      }

      final userId = await TokenService.getUserId();
      if (userId == null) {
        debugPrint('CART SERVICE: No user ID found - authentication required');
        _lastCartOperation = null; // Reset on error
        return {
          'success': false,
          'message': 'Please login to add items to cart',
        };
      }
      
      // Get current cart
      Map<String, dynamic>? currentCart = await getCart();
      debugPrint('CART SERVICE: Current cart before operation:');
      if (currentCart != null) {
        debugPrint('  - Partner ID: ${currentCart['partner_id']}');
        debugPrint('  - Restaurant: ${currentCart['restaurant_name']}');
        debugPrint('  - Items count: ${(currentCart['items'] as List?)?.length ?? 0}');
        debugPrint('  - Subtotal: ₹${currentCart['subtotal']}');
        debugPrint('  - Total: ₹${currentCart['total_price']}');
        
        if (currentCart['items'] != null) {
          final items = currentCart['items'] as List;
          for (int i = 0; i < items.length; i++) {
            final item = items[i];
            debugPrint('    Item $i: ${item['name']} - Qty: ${item['quantity']}, Base: ₹${item['price']}, Total: ₹${item['total_price']}');
          }
        }
      } else {
        debugPrint('  - No existing cart found');
      }
      
      // Check if cart exists and has different restaurant
      if (currentCart != null && currentCart['partner_id'] != partnerId) {
        debugPrint('CART SERVICE: Different restaurant detected');
        debugPrint('CART SERVICE: Current: ${currentCart['partner_id']}, New: $partnerId');
        
        _lastCartOperation = null; // Reset for conflict handling
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
        'delivery_fees': 0.0, // Default delivery fee
        'address': '', // Will be updated when placing order
      };
      
      // Calculate attributes price
      double attributesPrice = 0.0;
      List<Map<String, dynamic>> attributesData = [];
      if (attributes != null && attributes.isNotEmpty) {
        for (var attr in attributes) {
          attributesPrice += attr.priceAdjustment;
          attributesData.add(attr.toJson());
        }
      }
      
      debugPrint('CART SERVICE: Price calculations:');
      debugPrint('  - Base price: ₹$price');
      debugPrint('  - Attributes price: ₹$attributesPrice');
      debugPrint('  - Total price per item: ₹${price + attributesPrice}');
      debugPrint('  - Total price for quantity: ₹${(price + attributesPrice) * quantity}');
      
      // Calculate total price per item (base price + attributes)
      double totalPricePerItem = price + attributesPrice;
      
      // Find existing item with same attributes
      List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(cart['items']);
      int existingIndex = -1;
      
      if (quantity <= 0) {
        // When removing, first find by menu ID only
        existingIndex = items.indexWhere((item) => item['menu_id'] == menuId);
        
        // If multiple items with same menu ID, try to match attributes if provided
        if (existingIndex >= 0 && attributesData.isNotEmpty) {
          // Look for exact attribute match
          for (int i = 0; i < items.length; i++) {
            if (items[i]['menu_id'] == menuId && _compareAttributes(items[i]['attributes'], attributesData)) {
              existingIndex = i;
              break;
            }
          }
        }
      } else {
        // When adding/updating, find by menu ID and attributes
        existingIndex = items.indexWhere((item) => 
          item['menu_id'] == menuId && 
          _compareAttributes(item['attributes'], attributesData)
        );
      }
      
      debugPrint('CART SERVICE: Item search:');
      debugPrint('  - Looking for menu ID: $menuId');
      debugPrint('  - Quantity: $quantity (${quantity <= 0 ? 'removing' : 'adding/updating'})');
      debugPrint('  - Attributes provided: ${attributesData.isNotEmpty ? 'yes' : 'no'}');
      debugPrint('  - Existing item found at index: $existingIndex');
      
      if (quantity <= 0) {
        // Remove item if quantity is 0 or less
        debugPrint('CART SERVICE: Removing item (quantity <= 0)');
        if (existingIndex >= 0) {
          final removedItem = items[existingIndex];
          debugPrint('  - Removing: ${removedItem['name']} (Qty: ${removedItem['quantity']}, Total: ₹${removedItem['total_price']})');
          items.removeAt(existingIndex);
          debugPrint('CART SERVICE: Item removed from cart');
        }
      } else {
        // Add or update item
        Map<String, dynamic> cartItem = {
          'menu_id': menuId,
          'name': itemName,
          'quantity': quantity,
          'price': price, // Base price
          'attributes_price': attributesPrice, // Total attributes price
          'total_price_per_item': totalPricePerItem, // Price per item including attributes
          'total_price': totalPricePerItem * quantity, // Total price for this item
          'image_url': imageUrl,
          'attributes': attributesData,
        };
        
        debugPrint('CART SERVICE: Cart item data:');
        debugPrint('  - Menu ID: ${cartItem['menu_id']}');
        debugPrint('  - Name: ${cartItem['name']}');
        debugPrint('  - Quantity: ${cartItem['quantity']}');
        debugPrint('  - Base Price: ₹${cartItem['price']}');
        debugPrint('  - Attributes Price: ₹${cartItem['attributes_price']}');
        debugPrint('  - Total Price Per Item: ₹${cartItem['total_price_per_item']}');
        debugPrint('  - Total Price: ₹${cartItem['total_price']}');
        debugPrint('  - Attributes: ${cartItem['attributes']}');
        
        if (existingIndex >= 0) {
          final oldItem = items[existingIndex];
          debugPrint('CART SERVICE: Updating existing item:');
          debugPrint('  - Old: ${oldItem['name']} (Qty: ${oldItem['quantity']}, Total: ₹${oldItem['total_price']})');
          debugPrint('  - New: ${cartItem['name']} (Qty: ${cartItem['quantity']}, Total: ₹${cartItem['total_price']})');
          items[existingIndex] = cartItem;
          debugPrint('CART SERVICE: Item updated in cart');
        } else {
          debugPrint('CART SERVICE: Adding new item to cart');
          items.add(cartItem);
          debugPrint('CART SERVICE: New item added to cart');
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
      
      debugPrint('CART SERVICE: Final cart calculations:');
      debugPrint('  - Items count: ${items.length}');
      debugPrint('  - Subtotal: ₹$subtotal');
      debugPrint('  - Delivery fees: ₹${cart['delivery_fees']}');
      debugPrint('  - Total price: ₹${cart['total_price']}');
      
      debugPrint('CART SERVICE: Final items in cart:');
      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        debugPrint('  Item $i: ${item['name']} - Qty: ${item['quantity']}, Base: ₹${item['price']}, Attr: ₹${item['attributes_price']}, Total: ₹${item['total_price']}');
      }
      
      // Save cart (or clear if empty)
      if (items.isEmpty) {
        await clearCart();
        debugPrint('CART SERVICE: Cart is empty, cleared from storage');
      } else {
        await saveCart(cart);
      }
      
      debugPrint('=== CART SERVICE: ADD ITEM OPERATION END ===');
      
      return {
        'success': true,
        'message': quantity <= 0 ? 'Item removed from cart' : 'Item added to cart',
        'cart': cart,
        'item_count': items.length,
        'total_items': items.fold<int>(0, (sum, item) => sum + (item['quantity'] as int)),
      };
      
    } catch (e) {
      debugPrint('CART SERVICE: Error adding item to cart: $e');
      _lastCartOperation = null; // Reset on error
      return {
        'success': false,
        'message': 'Error adding item to cart',
      };
    }
  }
  
  // Helper function to compare attributes
  static bool _compareAttributes(dynamic a, dynamic b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      
      // If both lists are empty, they match
      if (a.isEmpty && b.isEmpty) return true;
      
      // Sort both lists by attribute_id for consistent comparison
      final sortedA = List<Map<String, dynamic>>.from(a)
        ..sort((x, y) => (x['attribute_id'] ?? '').compareTo(y['attribute_id'] ?? ''));
      final sortedB = List<Map<String, dynamic>>.from(b)
        ..sort((x, y) => (x['attribute_id'] ?? '').compareTo(y['attribute_id'] ?? ''));
      
      for (int i = 0; i < sortedA.length; i++) {
        if (sortedA[i]['attribute_id'] != sortedB[i]['attribute_id'] ||
            sortedA[i]['value_id'] != sortedB[i]['value_id']) {
          return false;
        }
      }
      return true;
    }
    
    return false;
  }
  
  // Helper function to compare maps (keeping for backward compatibility)
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
      
      // Reset debounce timer for new operation
      _lastCartOperation = null;
      
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
      _lastCartOperation = null; // Reset on error
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
// lib/service/reorder_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constant.dart';
import '../service/token_service.dart';
import '../service/cart_service.dart';
import '../models/attribute_model.dart';

class ReorderService {
  // Reorder functionality - copy items from a previous order to cart using partner orders API
  static Future<Map<String, dynamic>> reorderFromHistory({
    required String orderId,
    required String partnerId,
  }) async {
    try {
      debugPrint('ReorderService: Reordering from order: $orderId, partner: $partnerId');
      
      final token = await TokenService.getToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication required. Please login again.',
        };
      }
      
      // Use the partner orders API to get detailed order information
      final orderDetailsUrl = Uri.parse('${ApiConstants.baseUrl}/api/partner/orders/$partnerId/$orderId');
      
      debugPrint('ReorderService: Fetching order details from: $orderDetailsUrl');
      
      final orderResponse = await http.get(
        orderDetailsUrl,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (orderResponse.statusCode == 200) {
        final orderData = json.decode(orderResponse.body);
        
        if (orderData['status'] == 'SUCCESS' && orderData['data'] != null) {
          final order = orderData['data'] as Map<String, dynamic>;
          final items = order['items'] as List<dynamic>;
          
          debugPrint('ReorderService: Found ${items.length} items to reorder');
          
          // Clear current cart first
          await CartService.clearCart();
          
          // Add each item to cart with attributes
          for (var item in items) {
            final menuId = item['menu_id']?.toString() ?? '';
            final quantity = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
            final itemPrice = double.tryParse(item['item_price']?.toString() ?? '0') ?? 0.0;
            final attributes = item['attributes'] as Map<String, dynamic>?;
            
            if (menuId.isNotEmpty) {
              debugPrint('ReorderService: Adding item $menuId with quantity $quantity to cart');
              
                             // Convert attributes to SelectedAttribute format if needed
               List<SelectedAttribute>? selectedAttributes;
               if (attributes != null && attributes.isNotEmpty) {
                 selectedAttributes = attributes.entries.map((entry) {
                   return SelectedAttribute(
                     attributeId: entry.key,
                     valueId: entry.value.toString(),
                     attributeName: 'Custom Option', // We don't have attribute names from this API
                     valueName: entry.value.toString(),
                     priceAdjustment: 0.0, // We don't have price adjustments from this API
                   );
                 }).toList();
               }
              
              final addToCartResult = await CartService.addItemToCart(
                partnerId: partnerId,
                restaurantName: 'Restaurant', // We'll get this from order data
                menuId: menuId,
                itemName: 'Item', // We don't have item names from this API
                price: itemPrice,
                quantity: quantity,
                imageUrl: null, // We don't have image URLs from this API
                attributes: selectedAttributes,
              );
              
              if (!addToCartResult['success']) {
                debugPrint('ReorderService: Failed to add item $menuId to cart: ${addToCartResult['message']}');
                return {
                  'success': false,
                  'message': 'Failed to add some items to cart: ${addToCartResult['message']}',
                };
              }
            }
          }
          
          debugPrint('ReorderService: Reorder completed successfully');
          
          return {
            'success': true,
            'message': 'Items added to cart successfully. You can now proceed to checkout.',
            'data': {
              'items_count': items.length,
              'partner_id': partnerId,
            },
          };
        } else {
          return {
            'success': false,
            'message': orderData['message'] ?? 'Failed to fetch order details',
          };
        }
      } else if (orderResponse.statusCode == 404) {
        return {
          'success': false,
          'message': 'Order not found',
        };
      } else if (orderResponse.statusCode == 401) {
        return {
          'success': false,
          'message': 'Session expired. Please login again.',
        };
      } else {
        return {
          'success': false,
          'message': 'Server error occurred. Please try again.',
        };
      }
    } catch (e) {
      debugPrint('ReorderService: Exception in reorder: $e');
      return {
        'success': false,
        'message': 'Network error occurred. Please check your connection.',
      };
    }
  }

  // Alternative reorder method using order history data directly
  static Future<Map<String, dynamic>> reorderFromOrderData({
    required List<Map<String, dynamic>> items,
    required String partnerId,
  }) async {
    try {
      debugPrint('ReorderService: Reordering ${items.length} items for partner: $partnerId');
      
      // Clear current cart first
      await CartService.clearCart();
      
      // Add each item to cart
      for (var item in items) {
        final menuId = item['menu_id']?.toString() ?? '';
        final quantity = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
        
        if (menuId.isNotEmpty) {
          debugPrint('ReorderService: Adding item $menuId with quantity $quantity to cart');
          
          final addToCartResult = await CartService.addItemToCart(
            partnerId: partnerId,
            restaurantName: 'Restaurant', // We'll get this from order data
            menuId: menuId,
            itemName: item['item_name']?.toString() ?? 'Item',
            price: double.tryParse(item['item_price']?.toString() ?? '0') ?? 0.0,
            quantity: quantity,
            imageUrl: item['item_picture']?.toString(),
          );
          
          if (!addToCartResult['success']) {
            debugPrint('ReorderService: Failed to add item $menuId to cart: ${addToCartResult['message']}');
            return {
              'success': false,
              'message': 'Failed to add some items to cart: ${addToCartResult['message']}',
            };
          }
        }
      }
      
      debugPrint('ReorderService: Reorder completed successfully');
      
      return {
        'success': true,
        'message': 'Items added to cart successfully. You can now proceed to checkout.',
        'data': {
          'items_count': items.length,
          'partner_id': partnerId,
        },
      };
    } catch (e) {
      debugPrint('ReorderService: Exception in reorder from data: $e');
      return {
        'success': false,
        'message': 'Network error occurred. Please check your connection.',
      };
    }
  }
} 
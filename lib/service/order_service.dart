import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constant.dart';
import '../service/token_service.dart';

class OrderService {
  // Place order API
  static Future<Map<String, dynamic>> placeOrder({
    required String partnerId,
    required String userId,
    required List<Map<String, dynamic>> items,
    required double totalPrice,
    required String address,
    required double deliveryFees,
    required double subtotal,
  }) async {
    try {
      debugPrint('OrderService: Placing order...');
      debugPrint('OrderService: Partner ID: $partnerId');
      debugPrint('OrderService: User ID: $userId');
      debugPrint('OrderService: Items: ${items.length}');
      debugPrint('OrderService: Total Price: ₹$totalPrice');
      debugPrint('OrderService: Address: $address');
      
      final token = await TokenService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found. Please login again.',
        };
      }
      
      final url = Uri.parse('${ApiConstants.baseUrl}/api/user/place-order');
      
      final body = {
        'partner_id': partnerId,
        'user_id': userId,
        'items': items,
        'total_price': totalPrice,
        'address': address,
        'delivery_fees': deliveryFees,
        'subtotal': subtotal,
      };
      
      debugPrint('OrderService: Request URL: $url');
      debugPrint('OrderService: Request Body: ${jsonEncode(body)}');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      
      debugPrint('OrderService: Response Status: ${response.statusCode}');
      debugPrint('OrderService: Response Body: ${response.body}');
      
      // Fix: Accept both 200 and 201 status codes as successful
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['status'] == true) {
          debugPrint('OrderService: Order placed successfully');
          debugPrint('OrderService: Order ID: ${responseData['data']['order_id']}');
          
          return {
            'success': true,
            'message': responseData['message'] ?? 'Order placed successfully',
            'data': responseData['data'],
          };
        } else {
          debugPrint('OrderService: Order placement failed: ${responseData['message']}');
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to place order',
          };
        }
      } else {
        debugPrint('OrderService: Server error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server error occurred. Please try again.',
        };
      }
    } catch (e) {
      debugPrint('OrderService: Exception: $e');
      return {
        'success': false,
        'message': 'Network error occurred. Please check your connection.',
      };
    }
  }
  
  // Create chat room API
  static Future<Map<String, dynamic>> createChatRoom(String orderId) async {
    try {
      debugPrint('OrderService: Creating chat room for order: $orderId');
      
      final token = await TokenService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found. Please login again.',
        };
      }
      
      final url = Uri.parse('${ApiConstants.baseUrl}/api/chat/rooms/$orderId');
      
      debugPrint('OrderService: Chat room URL: $url');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      debugPrint('OrderService: Chat room response status: ${response.statusCode}');
      debugPrint('OrderService: Chat room response body: ${response.body}');
      
      // Fix: Accept both 200 and 201 status codes as successful
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['status'] == 'SUCCESS' || responseData['status'] == true) {
          debugPrint('OrderService: Chat room created successfully');
          debugPrint('OrderService: Room ID: ${responseData['data']['roomId']}');
          
          return {
            'success': true,
            'message': responseData['message'] ?? 'Chat room created successfully',
            'data': responseData['data'],
          };
        } else {
          debugPrint('OrderService: Chat room creation failed: ${responseData['message']}');
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to create chat room',
          };
        }
      } else {
        debugPrint('OrderService: Chat room server error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server error occurred. Please try again.',
        };
      }
    } catch (e) {
      debugPrint('OrderService: Chat room exception: $e');
      return {
        'success': false,
        'message': 'Network error occurred. Please check your connection.',
      };
    }
  }
}
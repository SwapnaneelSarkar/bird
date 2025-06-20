import 'dart:convert';
import 'dart:developer';
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
    double? latitude,
    double? longitude,
  }) async {
    try {
      debugPrint('OrderService: Placing order...');
      debugPrint('OrderService: Partner ID: $partnerId');
      debugPrint('OrderService: User ID: $userId');
      debugPrint('OrderService: Items: ${items.length}');
      debugPrint('OrderService: Total Price: ₹$totalPrice');
      debugPrint('OrderService: Address: $address');
      debugPrint('OrderService: Latitude: $latitude');
      debugPrint('OrderService: Longitude: $longitude');
      
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
      
      // Add coordinates if available
      if (latitude != null && longitude != null) {
        body['latitude'] = latitude;
        body['longitude'] = longitude;
      }
      
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
      
      // Parse response data
      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(response.body);
      } catch (jsonError) {
        debugPrint('OrderService: Failed to parse JSON response: $jsonError');
        return {
          'success': false,
          'message': 'Invalid response from server. Please try again.',
        };
      }
      
      // Fix: Accept both 200 and 201 status codes as successful
      if (response.statusCode == 200 || response.statusCode == 201) {
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
      } else if (response.statusCode == 400) {
        // Handle 400 error - extract actual message from API
        final message = responseData['message'] ?? 'Invalid request';
        debugPrint('OrderService: Bad request - $message');
        return {
          'success': false,
          'message': message,
        };
      } else if (response.statusCode == 401) {
        debugPrint('OrderService: Unauthorized request');
        return {
          'success': false,
          'message': 'Your session has expired. Please login again.',
        };
      } else if (response.statusCode == 403) {
        debugPrint('OrderService: Forbidden request');
        return {
          'success': false,
          'message': 'You are not authorized to place this order.',
        };
      } else if (response.statusCode >= 500) {
        debugPrint('OrderService: Server error');
        return {
          'success': false,
          'message': 'Server error. Please try again later.',
        };
      } else {
        debugPrint('OrderService: Unexpected status code: ${response.statusCode}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to place order. Please try again.',
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
    static Future<Map<String, dynamic>> cancelOrder(String orderId) async {
    try {
      // Get user ID from token service
      final userId = await TokenService.getUserId();
      if (userId == null) {
        return {
          'success': false,
          'message': 'User not authenticated'
        };
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/api/user/cancel-order/$orderId');
      
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await TokenService.getToken()}',
      };

      final body = json.encode({
        'user_id': userId,
      });

      log('OrderService: Cancelling order - URL: $url');
      log('OrderService: User ID: $userId');
      log('OrderService: Request body: $body');

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      log('OrderService: Cancel order response status: ${response.statusCode}');
      log('OrderService: Cancel order response body: ${response.body}');

      // Check if response is HTML (404 error page)
      if (response.body.trim().startsWith('<!DOCTYPE html>') || 
          response.body.contains('<html>')) {
        log('OrderService: Received HTML response - API endpoint not found');
        return {
          'success': false,
          'message': 'Cancel order service is currently unavailable. Please contact support.',
        };
      }

      Map<String, dynamic> responseData;
      try {
        responseData = json.decode(response.body);
      } catch (jsonError) {
        log('OrderService: Failed to parse JSON response: $jsonError');
        return {
          'success': false,
          'message': 'Invalid response from server. Please try again.',
        };
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        log('OrderService: Order cancelled successfully');
        return {
          'success': true,
          'message': responseData['message'] ?? 'Order cancelled successfully',
          'data': responseData['data'],
        };
      } else if (response.statusCode == 400) {
        // Handle specific 400 error cases
        final message = responseData['message'] ?? 'Invalid request';
        log('OrderService: Bad request - $message');
        
        if (message.toLowerCase().contains('cancelled state')) {
          return {
            'success': false,
            'message': 'This order has already been cancelled.',
          };
        } else if (message.toLowerCase().contains('cannot be cancelled')) {
          return {
            'success': false,
            'message': 'This order cannot be cancelled at this time. It may be in preparation or out for delivery.',
          };
        } else {
          return {
            'success': false,
            'message': message,
          };
        }
      } else if (response.statusCode == 401) {
        log('OrderService: Unauthorized request');
        return {
          'success': false,
          'message': 'Your session has expired. Please login again.',
        };
      } else if (response.statusCode == 403) {
        log('OrderService: Forbidden request');
        return {
          'success': false,
          'message': 'You are not authorized to cancel this order.',
        };
      } else if (response.statusCode == 404) {
        log('OrderService: Order not found');
        return {
          'success': false,
          'message': 'Order not found. Please check the order ID.',
        };
      } else if (response.statusCode >= 500) {
        log('OrderService: Server error');
        return {
          'success': false,
          'message': 'Server error. Please try again later.',
        };
      } else {
        log('OrderService: Unexpected status code: ${response.statusCode}');
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to cancel order. Please try again.',
        };
      }

    } catch (e) {
      log('OrderService: Exception occurred: $e');
      if (e.toString().contains('SocketException')) {
        return {
          'success': false,
          'message': 'No internet connection. Please check your network and try again.',
        };
      } else if (e.toString().contains('TimeoutException')) {
        return {
          'success': false,
          'message': 'Request timed out. Please try again.',
        };
      } else {
        return {
          'success': false,
          'message': 'Network error. Please try again.',
        };
      }
    }
  }

  // Method to check if an order can be cancelled
  static Future<Map<String, dynamic>> checkOrderCancellable(String orderId) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}api//user/orders/$orderId');
      
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${await TokenService.getToken()}',
      };

      log('OrderService: Checking if order can be cancelled - URL: $url');

      final response = await http.get(url, headers: headers);

      log('OrderService: Order check response status: ${response.statusCode}');
      log('OrderService: Order check response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final orderData = responseData['data'];
        final status = orderData['status']?.toString().toUpperCase();
        
        // Define cancellable statuses
        final cancellableStatuses = ['PENDING', 'CONFIRMED', 'PREPARING'];
        final nonCancellableStatuses = ['CANCELLED', 'DELIVERED', 'OUT_FOR_DELIVERY', 'PICKED_UP'];
        
        if (nonCancellableStatuses.contains(status)) {
          return {
            'success': false,
            'canCancel': false,
            'message': _getStatusMessage(status),
            'status': status,
          };
        } else if (cancellableStatuses.contains(status)) {
          return {
            'success': true,
            'canCancel': true,
            'message': 'Order can be cancelled',
            'status': status,
          };
        } else {
          return {
            'success': false,
            'canCancel': false,
            'message': 'Order status unknown. Please contact support.',
            'status': status,
          };
        }
      } else {
        return {
          'success': false,
          'canCancel': false,
          'message': 'Unable to check order status',
        };
      }
    } catch (e) {
      log('OrderService: Error checking order status: $e');
      return {
        'success': false,
        'canCancel': true, // Default to true to allow user to try
        'message': 'Unable to verify order status',
      };
    }
  }

  static String _getStatusMessage(String? status) {
    switch (status?.toUpperCase()) {
      case 'CANCELLED':
        return 'This order has already been cancelled.';
      case 'DELIVERED':
        return 'This order has already been delivered and cannot be cancelled.';
      case 'OUT_FOR_DELIVERY':
        return 'This order is out for delivery and cannot be cancelled.';
      case 'PICKED_UP':
        return 'This order has been picked up and cannot be cancelled.';
      default:
        return 'This order cannot be cancelled at this time.';
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
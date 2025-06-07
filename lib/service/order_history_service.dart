// lib/service/order_history_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constant.dart';
import '../service/token_service.dart';

class OrderHistoryService {
  // Fetch order history for a user
  static Future<Map<String, dynamic>> fetchOrderHistory() async {
    try {
      debugPrint('OrderHistoryService: Fetching order history...');
      
      final token = await TokenService.getToken();
      final userId = await TokenService.getUserId();
      
      if (token == null || userId == null) {
        return {
          'success': false,
          'message': 'Authentication required. Please login again.',
        };
      }
      
      debugPrint('OrderHistoryService: User ID: $userId');
      
      final url = Uri.parse('${ApiConstants.baseUrl}/api/user/orders/$userId');
      
      debugPrint('OrderHistoryService: Request URL: $url');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('OrderHistoryService: Response status: ${response.statusCode}');
      debugPrint('OrderHistoryService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['status'] == true && responseData['data'] != null) {
          final data = responseData['data'] as Map<String, dynamic>;
          
          // Combine all orders from different categories
          List<Map<String, dynamic>> allOrders = [];
          
          // Process Ongoing orders
          if (data['Ongoing'] != null) {
            final ongoingOrders = List<Map<String, dynamic>>.from(data['Ongoing']);
            for (var order in ongoingOrders) {
              order['status'] = 'Ongoing';
            }
            allOrders.addAll(ongoingOrders);
            debugPrint('OrderHistoryService: Found ${ongoingOrders.length} ongoing orders');
          }
          
          // Process Completed orders
          if (data['Completed'] != null) {
            final completedOrders = List<Map<String, dynamic>>.from(data['Completed']);
            for (var order in completedOrders) {
              order['status'] = 'Delivered';
            }
            allOrders.addAll(completedOrders);
            debugPrint('OrderHistoryService: Found ${completedOrders.length} completed orders');
          }
          
          // Process Cancelled orders
          if (data['Cancelled'] != null) {
            final cancelledOrders = List<Map<String, dynamic>>.from(data['Cancelled']);
            for (var order in cancelledOrders) {
              order['status'] = 'Cancelled';
            }
            allOrders.addAll(cancelledOrders);
            debugPrint('OrderHistoryService: Found ${cancelledOrders.length} cancelled orders');
          }
          
          // Sort by datetime (newest first)
          allOrders.sort((a, b) {
            try {
              final dateA = DateTime.parse(a['datetime'] ?? '');
              final dateB = DateTime.parse(b['datetime'] ?? '');
              return dateB.compareTo(dateA);
            } catch (e) {
              debugPrint('OrderHistoryService: Error parsing date: $e');
              return 0;
            }
          });
          
          debugPrint('OrderHistoryService: Total orders fetched: ${allOrders.length}');
          
          return {
            'success': true,
            'data': allOrders,
            'message': 'Order history fetched successfully',
          };
        } else {
          debugPrint('OrderHistoryService: Invalid response format');
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to fetch order history',
          };
        }
      } else if (response.statusCode == 401) {
        debugPrint('OrderHistoryService: Unauthorized access');
        return {
          'success': false,
          'message': 'Session expired. Please login again.',
        };
      } else {
        debugPrint('OrderHistoryService: Server error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server error occurred. Please try again.',
        };
      }
    } catch (e) {
      debugPrint('OrderHistoryService: Exception: $e');
      return {
        'success': false,
        'message': 'Network error occurred. Please check your connection.',
      };
    }
  }
  
  // Get order details by ID
  static Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    try {
      debugPrint('OrderHistoryService: Fetching order details for: $orderId');
      
      final token = await TokenService.getToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication required. Please login again.',
        };
      }
      
      final url = Uri.parse('${ApiConstants.baseUrl}/api/user/order/$orderId');
      
      debugPrint('OrderHistoryService: Order details URL: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('OrderHistoryService: Order details response status: ${response.statusCode}');
      debugPrint('OrderHistoryService: Order details response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['status'] == true && responseData['data'] != null) {
          debugPrint('OrderHistoryService: Order details fetched successfully');
          
          return {
            'success': true,
            'data': responseData['data'],
            'message': 'Order details fetched successfully',
          };
        } else {
          debugPrint('OrderHistoryService: Invalid order details response');
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to fetch order details',
          };
        }
      } else if (response.statusCode == 404) {
        debugPrint('OrderHistoryService: Order not found');
        return {
          'success': false,
          'message': 'Order not found',
        };
      } else if (response.statusCode == 401) {
        debugPrint('OrderHistoryService: Unauthorized access');
        return {
          'success': false,
          'message': 'Session expired. Please login again.',
        };
      } else {
        debugPrint('OrderHistoryService: Server error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server error occurred. Please try again.',
        };
      }
    } catch (e) {
      debugPrint('OrderHistoryService: Exception in order details: $e');
      return {
        'success': false,
        'message': 'Network error occurred. Please check your connection.',
      };
    }
  }
  
  // Cancel an order
  static Future<Map<String, dynamic>> cancelOrder(String orderId) async {
    try {
      debugPrint('OrderHistoryService: Cancelling order: $orderId');
      
      final token = await TokenService.getToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication required. Please login again.',
        };
      }
      
      final url = Uri.parse('${ApiConstants.baseUrl}/api/user/cancel-order');
      
      final payload = {
        'order_id': orderId,
      };
      
      debugPrint('OrderHistoryService: Cancel order URL: $url');
      debugPrint('OrderHistoryService: Cancel order payload: $payload');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      debugPrint('OrderHistoryService: Cancel order response status: ${response.statusCode}');
      debugPrint('OrderHistoryService: Cancel order response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['status'] == true) {
          debugPrint('OrderHistoryService: Order cancelled successfully');
          
          return {
            'success': true,
            'data': responseData['data'],
            'message': responseData['message'] ?? 'Order cancelled successfully',
          };
        } else {
          debugPrint('OrderHistoryService: Failed to cancel order');
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to cancel order',
          };
        }
      } else if (response.statusCode == 401) {
        debugPrint('OrderHistoryService: Unauthorized access');
        return {
          'success': false,
          'message': 'Session expired. Please login again.',
        };
      } else {
        debugPrint('OrderHistoryService: Server error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server error occurred. Please try again.',
        };
      }
    } catch (e) {
      debugPrint('OrderHistoryService: Exception in cancel order: $e');
      return {
        'success': false,
        'message': 'Network error occurred. Please check your connection.',
      };
    }
  }
  
  // Rate an order
  static Future<Map<String, dynamic>> rateOrder({
    required String orderId,
    required double rating,
    String? review,
  }) async {
    try {
      debugPrint('OrderHistoryService: Rating order: $orderId with rating: $rating');
      
      final token = await TokenService.getToken();
      final userId = await TokenService.getUserId();
      
      if (token == null || userId == null) {
        return {
          'success': false,
          'message': 'Authentication required. Please login again.',
        };
      }
      
      final url = Uri.parse('${ApiConstants.baseUrl}/api/user/rate-order');
      
      final payload = {
        'order_id': orderId,
        'user_id': userId,
        'rating': rating,
        if (review != null && review.isNotEmpty) 'review': review,
      };
      
      debugPrint('OrderHistoryService: Rate order URL: $url');
      debugPrint('OrderHistoryService: Rate order payload: $payload');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      debugPrint('OrderHistoryService: Rate order response status: ${response.statusCode}');
      debugPrint('OrderHistoryService: Rate order response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['status'] == true) {
          debugPrint('OrderHistoryService: Order rated successfully');
          
          return {
            'success': true,
            'data': responseData['data'],
            'message': responseData['message'] ?? 'Order rated successfully',
          };
        } else {
          debugPrint('OrderHistoryService: Failed to rate order');
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to rate order',
          };
        }
      } else if (response.statusCode == 401) {
        debugPrint('OrderHistoryService: Unauthorized access');
        return {
          'success': false,
          'message': 'Session expired. Please login again.',
        };
      } else {
        debugPrint('OrderHistoryService: Server error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server error occurred. Please try again.',
        };
      }
    } catch (e) {
      debugPrint('OrderHistoryService: Exception in rate order: $e');
      return {
        'success': false,
        'message': 'Network error occurred. Please check your connection.',
      };
    }
  }
}
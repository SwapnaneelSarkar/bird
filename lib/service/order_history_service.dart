// lib/service/order_history_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constant.dart';
import '../service/token_service.dart';
import '../utils/custom_cache_manager.dart';

class OrderHistoryService {
  // Cache for order details to improve performance
  static final Map<String, Map<String, dynamic>> _orderDetailsCache = {};
  static const Duration _cacheDuration = Duration(minutes: 5);
  static final Map<String, DateTime> _cacheTimestamps = {};
  
  // Cache for restaurant details to improve performance
  static final Map<String, Map<String, dynamic>> _restaurantDetailsCache = {};
  static const Duration _restaurantCacheDuration = Duration(minutes: 15);
  static final Map<String, DateTime> _restaurantCacheTimestamps = {};
  
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
            // Keep original status from API
            allOrders.addAll(ongoingOrders);
            debugPrint('OrderHistoryService: Found ${ongoingOrders.length} ongoing orders');
          }
          
          // Process Completed orders
          if (data['Completed'] != null) {
            final completedOrders = List<Map<String, dynamic>>.from(data['Completed']);
            // Keep original status from API
            allOrders.addAll(completedOrders);
            debugPrint('OrderHistoryService: Found ${completedOrders.length} completed orders');
          }
          
          // Process Cancelled orders
          if (data['Cancelled'] != null) {
            final cancelledOrders = List<Map<String, dynamic>>.from(data['Cancelled']);
            // Keep original status from API
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

  // ADDED: Fetch restaurant details by partner ID
  static Future<Map<String, dynamic>> fetchRestaurantDetails(String partnerId) async {
    // Check cache first
    if (_restaurantDetailsCache.containsKey(partnerId)) {
      final timestamp = _restaurantCacheTimestamps[partnerId];
      if (timestamp != null && DateTime.now().difference(timestamp) < _restaurantCacheDuration) {
        debugPrint('OrderHistoryService: ✅ Returning cached restaurant details for: $partnerId');
        return _restaurantDetailsCache[partnerId]!;
      } else {
        // Cache expired, remove it
        _restaurantDetailsCache.remove(partnerId);
        _restaurantCacheTimestamps.remove(partnerId);
        debugPrint('OrderHistoryService: 🗑️ Removed expired restaurant cache for: $partnerId');
      }
    }
    
    try {
      debugPrint('OrderHistoryService: Fetching restaurant details for partner: $partnerId');
      
      final token = await TokenService.getToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication required. Please login again.',
        };
      }
      
      final url = Uri.parse('${ApiConstants.baseUrl}/api/partner/restaurant/$partnerId');
      
      debugPrint('OrderHistoryService: Restaurant details URL: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('OrderHistoryService: Restaurant details response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['status'] == 'SUCCESS' && responseData['data'] != null) {
          final data = responseData['data'] as Map<String, dynamic>;
          
          final result = {
            'success': true,
            'data': {
              'address': data['address'] ?? '',
              'rating': data['rating'] ?? '0.0',
            },
            'message': 'Restaurant details fetched successfully',
          };
          
          // Cache the successful result
          _restaurantDetailsCache[partnerId] = result;
          _restaurantCacheTimestamps[partnerId] = DateTime.now();
          debugPrint('OrderHistoryService: 💾 Cached restaurant details for: $partnerId');
          
          return result;
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to fetch restaurant details',
          };
        }
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Restaurant not found',
        };
      } else if (response.statusCode == 401) {
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
      debugPrint('OrderHistoryService: Exception in restaurant details: $e');
      return {
        'success': false,
        'message': 'Network error occurred. Please check your connection.',
      };
    }
  }

  // ADDED: Fetch order review/rating
  static Future<Map<String, dynamic>> fetchOrderReview(String orderId, String partnerId) async {
    try {
      debugPrint('OrderHistoryService: Fetching review for order: $orderId, partner: $partnerId');
      
      final token = await TokenService.getToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication required. Please login again.',
        };
      }
      
      final url = Uri.parse('${ApiConstants.baseUrl}/api/partner/reviews/order/$orderId?partner_id=$partnerId');
      
      debugPrint('OrderHistoryService: Review URL: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('OrderHistoryService: Review response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['status'] == 'SUCCESS' && responseData['data'] != null) {
          final data = responseData['data'] as Map<String, dynamic>;
          
          return {
            'success': true,
            'data': {
              'rating': data['rating'] ?? 0,
              'review_text': data['review_text'] ?? '',
            },
            'message': 'Review fetched successfully',
          };
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to fetch review',
          };
        }
      } else if (response.statusCode == 404) {
        // No review found for this order
        return {
          'success': true,
          'data': {
            'rating': null,
            'review_text': null,
          },
          'message': 'No review found for this order',
        };
      } else if (response.statusCode == 401) {
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
      debugPrint('OrderHistoryService: Exception in review fetch: $e');
      return {
        'success': false,
        'message': 'Network error occurred. Please check your connection.',
      };
    }
  }
  
  // Get order details by ID
  static Future<Map<String, dynamic>> getOrderDetails(String orderId) async {
    debugPrint('OrderHistoryService: 🚩 getOrderDetails called for: $orderId');
    
    // Check cache first
    if (_orderDetailsCache.containsKey(orderId)) {
      final timestamp = _cacheTimestamps[orderId];
      if (timestamp != null && DateTime.now().difference(timestamp) < _cacheDuration) {
        debugPrint('OrderHistoryService: ✅ Returning cached order details for: $orderId');
        return _orderDetailsCache[orderId]!;
      } else {
        // Cache expired, remove it
        _orderDetailsCache.remove(orderId);
        _cacheTimestamps.remove(orderId);
        debugPrint('OrderHistoryService: 🗑️ Removed expired cache for: $orderId');
      }
    }
    
    try {
      debugPrint('OrderHistoryService: 🔍 Fetching order details for: $orderId');
      debugPrint('OrderHistoryService: 🔍 Order ID type: ${orderId.runtimeType}');
      debugPrint('OrderHistoryService: 🔍 Order ID length: ${orderId.length}');
      
      final token = await TokenService.getToken();
      
      if (token == null) {
        debugPrint('OrderHistoryService: ❌ No token available');
        return {
          'success': false,
          'message': 'Authentication required. Please login again.',
        };
      }
      
      debugPrint('OrderHistoryService: ✅ Token available');
      
      final url = Uri.parse('${ApiConstants.baseUrl}/api/user/order/$orderId');
      
      debugPrint('OrderHistoryService: 🌐 Order details URL: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('OrderHistoryService: 📡 Response status: ${response.statusCode}');
      debugPrint('OrderHistoryService: 📡 Response body: ${response.body}');
      debugPrint('OrderHistoryService: 📡 Response headers: ${response.headers}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        debugPrint('OrderHistoryService: 🔍 Response data status: ${responseData['status']}');
        debugPrint('OrderHistoryService: 🔍 Response data has data: ${responseData['data'] != null}');
        
        // Check for both "SUCCESS" string and true boolean status (like order details page)
        if ((responseData['status'] == 'SUCCESS' || responseData['status'] == true) && responseData['data'] != null) {
          debugPrint('OrderHistoryService: ✅ Order details fetched successfully');
          debugPrint('OrderHistoryService: 📋 Order data: ${responseData['data']}');
          debugPrint('OrderHistoryService: 📋 Order data type: ${responseData['data'].runtimeType}');
          
          final result = {
            'success': true,
            'data': responseData['data'],
            'message': 'Order details fetched successfully',
          };
          
          // Cache the successful result
          _orderDetailsCache[orderId] = result;
          _cacheTimestamps[orderId] = DateTime.now();
          debugPrint('OrderHistoryService: 💾 Cached order details for: $orderId');
          
          return result;
        } else {
          debugPrint('OrderHistoryService: ❌ Invalid order details response');
          debugPrint('OrderHistoryService: ❌ Response status: ${responseData['status']}');
          debugPrint('OrderHistoryService: ❌ Response message: ${responseData['message']}');
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to fetch order details',
          };
        }
      } else if (response.statusCode == 404) {
        debugPrint('OrderHistoryService: ❌ Order not found (404)');
        return {
          'success': false,
          'message': 'Order not found',
        };
      } else if (response.statusCode == 401) {
        debugPrint('OrderHistoryService: ❌ Unauthorized access (401)');
        return {
          'success': false,
          'message': 'Session expired. Please login again.',
        };
      } else {
        debugPrint('OrderHistoryService: ❌ Server error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server error occurred. Please try again.',
        };
      }
    } catch (e, stackTrace) {
      debugPrint('OrderHistoryService: ❌ Exception in order details: $e');
      debugPrint('OrderHistoryService: ❌ Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Network error occurred. Please check your connection.',
      };
    }
  }
  
  // Clear order details cache
  static void clearOrderDetailsCache() {
    _orderDetailsCache.clear();
    _cacheTimestamps.clear();
    debugPrint('OrderHistoryService: 🗑️ Cleared all order details cache');
  }
  
  // Clear cache for specific order
  static void clearOrderDetailsCacheForOrder(String orderId) {
    _orderDetailsCache.remove(orderId);
    _cacheTimestamps.remove(orderId);
    debugPrint('OrderHistoryService: 🗑️ Cleared cache for order: $orderId');
  }
  
  // Clear restaurant details cache
  static void clearRestaurantDetailsCache() {
    _restaurantDetailsCache.clear();
    _restaurantCacheTimestamps.clear();
    debugPrint('OrderHistoryService: 🗑️ Cleared all restaurant details cache');
  }
  
  // Clear cache for specific restaurant
  static void clearRestaurantDetailsCacheForRestaurant(String partnerId) {
    _restaurantDetailsCache.remove(partnerId);
    _restaurantCacheTimestamps.remove(partnerId);
    debugPrint('OrderHistoryService: 🗑️ Cleared cache for restaurant: $partnerId');
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
// lib/presentation/order_details/bloc.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/api_constant.dart';
import '../../service/token_service.dart';
import '../../service/order_history_service.dart';
import '../../models/order_details_model.dart';
import '../../models/menu_model.dart';
import '../../utils/performance_monitor.dart';
import 'event.dart';
import 'state.dart';

class OrderDetailsBloc extends Bloc<OrderDetailsEvent, OrderDetailsState> {
  OrderDetailsBloc() : super(OrderDetailsInitial()) {
    debugPrint('OrderDetailsBloc: Constructor called');
    on<LoadOrderDetails>(_onLoadOrderDetails);
    on<RefreshOrderDetails>(_onRefreshOrderDetails);
    on<CancelOrder>(_onCancelOrder);
    on<TrackOrder>(_onTrackOrder);
    on<LoadMenuItemDetails>(_onLoadMenuItemDetails);
    debugPrint('OrderDetailsBloc: Event handlers registered');
  }

  Future<void> _onLoadOrderDetails(
    LoadOrderDetails event,
    Emitter<OrderDetailsState> emit,
  ) async {
    PerformanceMonitor.startTimer('OrderDetailsLoading');
    emit(OrderDetailsLoading());
    
    try {
      debugPrint('OrderDetailsBloc: Loading order details for: ${event.orderId}');
      
      final orderDetails = await _fetchOrderDetails(event.orderId);
      
      if (orderDetails != null) {
        debugPrint('OrderDetailsBloc: Order details loaded successfully');
        debugPrint('OrderDetailsBloc: Order ID: ${orderDetails.orderId}');
        debugPrint('OrderDetailsBloc: Status: ${orderDetails.orderStatus}');
        debugPrint('OrderDetailsBloc: Total Amount: ${orderDetails.totalAmount}');
        debugPrint('OrderDetailsBloc: Items Count: ${orderDetails.items.length}');
        
        // Fetch menu items in parallel for better performance
        Map<String, MenuItem> menuItems = {};
        final uniqueMenuIds = orderDetails.items
            .where((item) => item.menuId != null && item.menuId!.isNotEmpty)
            .map((item) => item.menuId!)
            .toSet()
            .toList();
        
        if (uniqueMenuIds.isNotEmpty) {
          debugPrint('OrderDetailsBloc: Fetching menu details for ${uniqueMenuIds.length} unique items in parallel');
          
          // Fetch all menu items in parallel
          final menuItemFutures = uniqueMenuIds.map((menuId) => _fetchMenuItemDetails(menuId)).toList();
          final menuItemResults = await Future.wait(menuItemFutures);
          
          for (int i = 0; i < uniqueMenuIds.length; i++) {
            final menuItem = menuItemResults[i];
            if (menuItem != null) {
              menuItems[uniqueMenuIds[i]] = menuItem;
            }
          }
          
          debugPrint('OrderDetailsBloc: Successfully loaded ${menuItems.length} menu items');
        }
        
        emit(OrderDetailsLoaded(orderDetails, menuItems));
        
        // Fetch additional data (restaurant details and rating) if we have partner ID
        if (orderDetails.partnerId != null && orderDetails.partnerId!.isNotEmpty) {
          _fetchAdditionalData(orderDetails.partnerId!, orderDetails.orderId, orderDetails.orderStatus);
        }
        
        // Log performance statistics
        PerformanceMonitor.endTimer('OrderDetailsLoading');
        PerformanceMonitor.logAllStatistics();
      } else {
        debugPrint('OrderDetailsBloc: Failed to load order details');
        PerformanceMonitor.endTimer('OrderDetailsLoading');
        emit(const OrderDetailsError('Failed to load order details. Please try again.'));
      }
    } catch (e) {
      debugPrint('OrderDetailsBloc: Error loading order details: $e');
      PerformanceMonitor.endTimer('OrderDetailsLoading');
      emit(const OrderDetailsError('An error occurred while loading order details.'));
    }
  }

  Future<void> _onLoadMenuItemDetails(
    LoadMenuItemDetails event,
    Emitter<OrderDetailsState> emit,
  ) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        debugPrint('OrderDetailsBloc: No auth token available for menu item fetch');
        return;
      }
      
      debugPrint('OrderDetailsBloc: Fetching menu item details for menuId: ${event.menuId}');
      
      final url = '${ApiConstants.baseUrl}/api/partner/menu_item/${event.menuId}';
      debugPrint('OrderDetailsBloc: Menu item API URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      debugPrint('OrderDetailsBloc: Menu item API response status: ${response.statusCode}');
      debugPrint('OrderDetailsBloc: Menu item API response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['status'] == 'SUCCESS') {
          final menuItemData = responseData['data'];
          final menuItem = MenuItem.fromJson({
            'menu_id': event.menuId,
            'name': menuItemData['name'],
            'price': menuItemData['price'],
            'description': menuItemData['description'],
            'available': true,
            'category': '',
            'isVeg': false,
            'isTaxIncluded': true,
            'isCancellable': true,
            'tags': [],
          });
          
          debugPrint('OrderDetailsBloc: Menu item loaded successfully: ${menuItem.name}');
          debugPrint('OrderDetailsBloc: Current menu item price: ₹${menuItem.price}');
          debugPrint('OrderDetailsBloc: Note: This is the current price, which may differ from the order price');
          
          // Update state with new menu item
          if (state is OrderDetailsLoaded) {
            final currentState = state as OrderDetailsLoaded;
            final updatedMenuItems = Map<String, MenuItem>.from(currentState.menuItems);
            updatedMenuItems[event.menuId] = menuItem;
            
            emit(OrderDetailsLoaded(currentState.orderDetails, updatedMenuItems));
          }
        } else {
          debugPrint('OrderDetailsBloc: Failed to load menu item: ${responseData['message']}');
        }
      } else {
        debugPrint('OrderDetailsBloc: Failed to fetch menu item. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('OrderDetailsBloc: Error loading menu item details: $e');
    }
  }

  Future<void> _onRefreshOrderDetails(
    RefreshOrderDetails event,
    Emitter<OrderDetailsState> emit,
  ) async {
    try {
      debugPrint('OrderDetailsBloc: Refreshing order details for: ${event.orderId}');
      
      final orderDetails = await _fetchOrderDetails(event.orderId);
      
      if (orderDetails != null) {
        debugPrint('OrderDetailsBloc: Order details refreshed successfully');
        emit(OrderDetailsLoaded(orderDetails, {}));
        
        // Fetch menu item details for each item that has a menuId
        for (var item in orderDetails.items) {
          if (item.menuId != null && item.menuId!.isNotEmpty) {
            add(LoadMenuItemDetails(item.menuId!));
          }
        }
      } else {
        debugPrint('OrderDetailsBloc: Failed to refresh order details');
        emit(const OrderDetailsError('Failed to refresh order details.'));
      }
    } catch (e) {
      debugPrint('OrderDetailsBloc: Error refreshing order details: $e');
      emit(const OrderDetailsError('An error occurred while refreshing order details.'));
    }
  }

  Future<void> _onCancelOrder(
    CancelOrder event,
    Emitter<OrderDetailsState> emit,
  ) async {
    if (state is OrderDetailsLoaded) {
      final currentState = state as OrderDetailsLoaded;
      
      emit(OrderCancelling());
      
      try {
        debugPrint('OrderDetailsBloc: Cancelling order: ${event.orderId}');
        
        final result = await _cancelOrder(event.orderId);
        
        if (result['success'] == true) {
          debugPrint('OrderDetailsBloc: Order cancelled successfully');
          emit(OrderCancelled(result['message'] ?? 'Order cancelled successfully'));
          
          // Refresh order details to show updated status
          add(RefreshOrderDetails(event.orderId));
        } else {
          debugPrint('OrderDetailsBloc: Failed to cancel order: ${result['message']}');
          emit(OrderDetailsError(result['message'] ?? 'Failed to cancel order'));
          
          // Return to loaded state
          emit(currentState);
        }
      } catch (e) {
        debugPrint('OrderDetailsBloc: Error cancelling order: $e');
        emit(const OrderDetailsError('An error occurred while cancelling the order.'));
        
        // Return to loaded state
        emit(currentState);
      }
    }
  }

  Future<void> _onTrackOrder(
    TrackOrder event,
    Emitter<OrderDetailsState> emit,
  ) async {
    try {
      debugPrint('OrderDetailsBloc: Tracking order: ${event.orderId}');
      
      // Refresh order details to get latest status
      add(RefreshOrderDetails(event.orderId));
    } catch (e) {
      debugPrint('OrderDetailsBloc: Error tracking order: $e');
    }
  }

  Future<OrderDetails?> _fetchOrderDetails(String orderId) async {
    try {
      debugPrint('OrderDetailsBloc: Fetching order details for: $orderId');
      
      final token = await TokenService.getToken();
      
      if (token == null) {
        debugPrint('OrderDetailsBloc: No token available');
        return null;
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/api/user/order/$orderId');
      
      debugPrint('OrderDetailsBloc: Order details URL: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('OrderDetailsBloc: Order details response status: ${response.statusCode}');
      debugPrint('OrderDetailsBloc: Order details response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Check for both "SUCCESS" string and true boolean status
        if ((responseData['status'] == 'SUCCESS' || responseData['status'] == true) && 
            responseData['data'] != null) {
          debugPrint('OrderDetailsBloc: Order details fetched successfully');
          
          // Note: Order details contain the price at the time of ordering
          // This may differ from the current menu item price if prices have changed
          final orderDetails = OrderDetails.fromJson(responseData['data']);
          debugPrint('OrderDetailsBloc: Order price details:');
          debugPrint('  - API total_amount: ₹${orderDetails.totalAmount} (this is actually subtotal)');
          debugPrint('  - Delivery fees: ₹${orderDetails.deliveryFees}');
          debugPrint('  - Calculated grand total: ₹${orderDetails.grandTotal}');
          for (var item in orderDetails.items) {
            debugPrint('    - Item ${item.menuId}: ₹${item.itemPrice} (ordered price)');
          }
          
          return orderDetails;
        } else {
          debugPrint('OrderDetailsBloc: Invalid order details response format');
          debugPrint('OrderDetailsBloc: Response status: ${responseData['status']}');
          debugPrint('OrderDetailsBloc: Response message: ${responseData['message']}');
          return null;
        }
      } else if (response.statusCode == 404) {
        debugPrint('OrderDetailsBloc: Order not found');
        return null;
      } else if (response.statusCode == 401) {
        debugPrint('OrderDetailsBloc: Unauthorized access');
        return null;
      } else {
        debugPrint('OrderDetailsBloc: Server error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('OrderDetailsBloc: Exception in order details fetch: $e');
      return null;
    }
  }

  Future<MenuItem?> _fetchMenuItemDetails(String menuId) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        debugPrint('OrderDetailsBloc: No auth token available for menu item fetch');
        return null;
      }
      
      debugPrint('OrderDetailsBloc: Fetching menu item details for menuId: $menuId');
      
      final url = '${ApiConstants.baseUrl}/api/partner/menu_item/$menuId';
      debugPrint('OrderDetailsBloc: Menu item API URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      debugPrint('OrderDetailsBloc: Menu item API response status: ${response.statusCode}');
      debugPrint('OrderDetailsBloc: Menu item API response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['status'] == 'SUCCESS' && responseData['data'] != null) {
          final menuItemData = responseData['data'];
          final menuItem = MenuItem.fromJson({
            'menu_id': menuId,
            'name': menuItemData['name'],
            'price': menuItemData['price'],
            'description': menuItemData['description'],
            'available': true,
            'category': '',
            'isVeg': false,
            'isTaxIncluded': true,
            'isCancellable': true,
            'tags': [],
          });
          
          debugPrint('OrderDetailsBloc: Menu item loaded successfully: ${menuItem.name}');
          debugPrint('OrderDetailsBloc: Current menu item price: ₹${menuItem.price}');
          debugPrint('OrderDetailsBloc: Note: This is the current price, which may differ from the order price');
          
          return menuItem;
        } else {
          debugPrint('OrderDetailsBloc: Failed to load menu item: ${responseData['message']}');
          return null;
        }
      } else {
        debugPrint('OrderDetailsBloc: Failed to fetch menu item. Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('OrderDetailsBloc: Error loading menu item details: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> _cancelOrder(String orderId) async {
    try {
      debugPrint('OrderDetailsBloc: Cancelling order: $orderId');
      
      final token = await TokenService.getToken();
      final userId = await TokenService.getUserId();
      
      if (token == null || userId == null) {
        return {
          'success': false,
          'message': 'Authentication required. Please login again.',
        };
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/api/user/cancel-order');
      
      final payload = {
        'order_id': orderId,
        'user_id': userId,
      };

      debugPrint('OrderDetailsBloc: Cancel order URL: $url');
      debugPrint('OrderDetailsBloc: Cancel order payload: $payload');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      debugPrint('OrderDetailsBloc: Cancel order response status: ${response.statusCode}');
      debugPrint('OrderDetailsBloc: Cancel order response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['status'] == 'SUCCESS' || responseData['status'] == true) {
          debugPrint('OrderDetailsBloc: Order cancelled successfully');
          
          return {
            'success': true,
            'message': responseData['message'] ?? 'Order cancelled successfully',
          };
        } else {
          debugPrint('OrderDetailsBloc: Failed to cancel order');
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to cancel order',
          };
        }
      } else if (response.statusCode == 401) {
        debugPrint('OrderDetailsBloc: Unauthorized access');
        return {
          'success': false,
          'message': 'Session expired. Please login again.',
        };
      } else {
        debugPrint('OrderDetailsBloc: Server error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server error occurred. Please try again.',
        };
      }
    } catch (e) {
      debugPrint('OrderDetailsBloc: Exception in cancel order: $e');
      return {
        'success': false,
        'message': 'Network error occurred. Please check your connection.',
      };
    }
  }

  // ADDED: Fetch additional data (restaurant details and rating)
  Future<void> _fetchAdditionalData(String partnerId, String orderId, String orderStatus) async {
    try {
      debugPrint('OrderDetailsBloc: Fetching additional data for partner: $partnerId, order: $orderId');
      
      // Fetch restaurant details
      final restaurantResult = await OrderHistoryService.fetchRestaurantDetails(partnerId);
      if (restaurantResult['success']) {
        final restaurantData = restaurantResult['data'] as Map<String, dynamic>;
        final address = restaurantData['address']?.toString();
        
        if (address != null && address.isNotEmpty) {
          // Update the current state with restaurant address
          if (state is OrderDetailsLoaded) {
            final currentState = state as OrderDetailsLoaded;
            final updatedOrderDetails = currentState.orderDetails.copyWithRestaurantAddress(address);
            emit(OrderDetailsLoaded(updatedOrderDetails, currentState.menuItems));
          }
        }
      }
      
      // Fetch order review/rating if order is completed/delivered
      if (orderStatus.toUpperCase() == 'DELIVERED' || orderStatus.toUpperCase() == 'COMPLETED') {
        final reviewResult = await OrderHistoryService.fetchOrderReview(orderId, partnerId);
        if (reviewResult['success']) {
          final reviewData = reviewResult['data'] as Map<String, dynamic>;
          final rating = reviewData['rating'];
          final reviewText = reviewData['review_text']?.toString();
          
          if (rating != null) {
            final ratingValue = rating is int ? rating.toDouble() : double.tryParse(rating.toString());
            if (ratingValue != null) {
              // Update the current state with rating
              if (state is OrderDetailsLoaded) {
                final currentState = state as OrderDetailsLoaded;
                final updatedOrderDetails = currentState.orderDetails.copyWithRating(ratingValue, reviewText);
                emit(OrderDetailsLoaded(updatedOrderDetails, currentState.menuItems));
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('OrderDetailsBloc: Error fetching additional data: $e');
      // Don't emit error state, just log the error
    }
  }
}
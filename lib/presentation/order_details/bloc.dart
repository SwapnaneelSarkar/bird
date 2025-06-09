// lib/presentation/order_details/bloc.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../constants/api_constant.dart';
import '../../service/token_service.dart';
import '../../models/order_details_model.dart';
import 'event.dart';
import 'state.dart';

class OrderDetailsBloc extends Bloc<OrderDetailsEvent, OrderDetailsState> {
  OrderDetailsBloc() : super(OrderDetailsInitial()) {
    debugPrint('OrderDetailsBloc: Constructor called');
    on<LoadOrderDetails>(_onLoadOrderDetails);
    on<RefreshOrderDetails>(_onRefreshOrderDetails);
    on<CancelOrder>(_onCancelOrder);
    on<TrackOrder>(_onTrackOrder);
    debugPrint('OrderDetailsBloc: Event handlers registered');
  }

  Future<void> _onLoadOrderDetails(
    LoadOrderDetails event,
    Emitter<OrderDetailsState> emit,
  ) async {
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
        
        emit(OrderDetailsLoaded(orderDetails));
      } else {
        debugPrint('OrderDetailsBloc: Failed to load order details');
        emit(const OrderDetailsError('Failed to load order details. Please try again.'));
      }
    } catch (e) {
      debugPrint('OrderDetailsBloc: Error loading order details: $e');
      emit(const OrderDetailsError('An error occurred while loading order details.'));
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
        emit(OrderDetailsLoaded(orderDetails));
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
      
      // For now, just refresh the order details
      // In a real app, this could open a tracking screen or show live updates
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
          
          return OrderDetails.fromJson(responseData['data']);
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
}
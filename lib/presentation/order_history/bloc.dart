// lib/presentation/order_history/bloc.dart - Updated to use order_id correctly
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../constants/api_constant.dart';
import '../../service/token_service.dart';
import 'event.dart';
import 'state.dart';

class OrderHistoryBloc extends Bloc<OrderHistoryEvent, OrderHistoryState> {
  OrderHistoryBloc() : super(OrderHistoryInitial()) {
    on<LoadOrderHistory>(_onLoadOrderHistory);
    on<FilterOrdersByStatus>(_onFilterOrdersByStatus);
    on<ViewOrderDetails>(_onViewOrderDetails);
    on<OpenChatForOrder>(_onOpenChatForOrder);
  }
  
  Future<void> _onLoadOrderHistory(LoadOrderHistory event, Emitter<OrderHistoryState> emit) async {
    emit(OrderHistoryLoading());
    
    try {
      debugPrint('OrderHistoryBloc: Loading order history...');
      
      // Get token and user ID
      final token = await TokenService.getToken();
      final userId = await TokenService.getUserId();
      
      if (token == null || userId == null) {
        emit(const OrderHistoryError('Please login again to view order history.'));
        return;
      }
      
      // Fetch order history from API
      final orders = await _fetchOrderHistory(token, userId);
      
      const filterTabs = ['All Orders', 'Preparing', 'Completed', 'Cancelled'];
      const selectedFilter = 'All Orders';
      
      emit(OrderHistoryLoaded(
        allOrders: orders,
        filteredOrders: orders, // Initially show all orders
        selectedFilter: selectedFilter,
        filterTabs: filterTabs,
      ));
      
      debugPrint('OrderHistoryBloc: Order history loaded successfully with ${orders.length} orders');
    } catch (e) {
      debugPrint('OrderHistoryBloc: Error loading order history: $e');
      emit(const OrderHistoryError('Failed to load order history. Please try again.'));
    }
  }
  
  Future<List<OrderItem>> _fetchOrderHistory(String token, String userId) async {
    try {
      debugPrint('OrderHistoryBloc: Fetching order history for user: $userId');
      
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/user/orders/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('OrderHistoryBloc: Order history response status: ${response.statusCode}');
      debugPrint('OrderHistoryBloc: Order history response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == true && responseData['data'] != null) {
          final data = responseData['data'] as Map<String, dynamic>;
          
          // Combine all orders from different categories
          List<Map<String, dynamic>> allOrdersData = [];
          
          if (data['Ongoing'] != null) {
            final ongoingOrders = List<Map<String, dynamic>>.from(data['Ongoing']);
            debugPrint('OrderHistoryBloc: Processing ${ongoingOrders.length} ongoing orders');
            for (var order in ongoingOrders) {
              order['status'] = 'Preparing';
              debugPrint('OrderHistoryBloc: Ongoing order ID: ${order['order_id']}');
            }
            allOrdersData.addAll(ongoingOrders);
          }
          
          if (data['Completed'] != null) {
            final completedOrders = List<Map<String, dynamic>>.from(data['Completed']);
            debugPrint('OrderHistoryBloc: Processing ${completedOrders.length} completed orders');
            for (var order in completedOrders) {
              order['status'] = 'Delivered';
              debugPrint('OrderHistoryBloc: Completed order ID: ${order['order_id']}');
            }
            allOrdersData.addAll(completedOrders);
          }
          
          if (data['Cancelled'] != null) {
            final cancelledOrders = List<Map<String, dynamic>>.from(data['Cancelled']);
            debugPrint('OrderHistoryBloc: Processing ${cancelledOrders.length} cancelled orders');
            for (var order in cancelledOrders) {
              order['status'] = 'Cancelled';
              debugPrint('OrderHistoryBloc: Cancelled order ID: ${order['order_id']}');
            }
            allOrdersData.addAll(cancelledOrders);
          }
          
          // Convert to OrderItem objects
          List<OrderItem> orders = allOrdersData
              .map((orderData) {
                final orderItem = OrderItem.fromJson(orderData);
                debugPrint('OrderHistoryBloc: Created OrderItem with ID: ${orderItem.id}');
                return orderItem;
              })
              .toList();
          
          // Sort by datetime (newest first)
          orders.sort((a, b) => b.dateTime.compareTo(a.dateTime));
          
          debugPrint('OrderHistoryBloc: Found ${orders.length} orders');
          
          // Log all order IDs for debugging
          for (var order in orders) {
            debugPrint('OrderHistoryBloc: Final order - ID: ${order.id}, Restaurant: ${order.restaurantName}');
          }
          
          return orders;
        }
      }
      
      debugPrint('OrderHistoryBloc: Failed to fetch order history or no orders found');
      return [];
    } catch (e) {
      debugPrint('OrderHistoryBloc: Error fetching order history: $e');
      return [];
    }
  }
  
  Future<void> _onFilterOrdersByStatus(FilterOrdersByStatus event, Emitter<OrderHistoryState> emit) async {
    if (state is OrderHistoryLoaded) {
      final currentState = state as OrderHistoryLoaded;
      
      try {
        debugPrint('OrderHistoryBloc: Filtering orders by status: ${event.status}');
        
        List<OrderItem> filteredOrders;
        
        switch (event.status) {
          case 'All Orders':
            filteredOrders = currentState.allOrders;
            break;
          case 'Preparing':
            filteredOrders = currentState.allOrders
                .where((order) => order.status == 'Preparing')
                .toList();
            break;
          case 'Completed':
            filteredOrders = currentState.allOrders
                .where((order) => order.status == 'Delivered' || order.status == 'Completed')
                .toList();
            break;
          case 'Cancelled':
            filteredOrders = currentState.allOrders
                .where((order) => order.status == 'Cancelled')
                .toList();
            break;
          default:
            filteredOrders = currentState.allOrders;
        }
        
        emit(currentState.copyWith(
          filteredOrders: filteredOrders,
          selectedFilter: event.status,
        ));
        
        debugPrint('OrderHistoryBloc: Filtered to ${filteredOrders.length} orders');
      } catch (e) {
        debugPrint('OrderHistoryBloc: Error filtering orders: $e');
        // Don't emit error, just keep current state
      }
    }
  }
  
  Future<void> _onViewOrderDetails(ViewOrderDetails event, Emitter<OrderHistoryState> emit) async {
    try {
      debugPrint('OrderHistoryBloc: Viewing order details for: ${event.orderId}');
      
      // In a real app, you would navigate to order details page here
      // For now, we'll just log the action
      debugPrint('OrderHistoryBloc: Navigate to order details page for order ${event.orderId}');
      
    } catch (e) {
      debugPrint('OrderHistoryBloc: Error viewing order details: $e');
    }
  }
  
  Future<void> _onOpenChatForOrder(OpenChatForOrder event, Emitter<OrderHistoryState> emit) async {
    try {
      debugPrint('OrderHistoryBloc: Opening chat for order: ${event.orderId}');
      
      // The navigation will be handled in the view layer
      // This event can be used for any additional logic if needed
      
    } catch (e) {
      debugPrint('OrderHistoryBloc: Error opening chat: $e');
      emit(const OrderHistoryError('Failed to open chat. Please try again.'));
    }
  }
}
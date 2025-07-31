// lib/presentation/order_history/bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../service/order_history_service.dart';
import 'event.dart';
import 'state.dart';

class OrderHistoryBloc extends Bloc<OrderHistoryEvent, OrderHistoryState> {
  OrderHistoryBloc() : super(OrderHistoryInitial()) {
    on<LoadOrderHistory>(_onLoadOrderHistory);
    on<RefreshOrderHistory>(_onRefreshOrderHistory);
    on<FilterOrdersByStatus>(_onFilterOrdersByStatus);
    on<ViewOrderDetails>(_onViewOrderDetails);
    on<LoadOrderAdditionalData>(_onLoadOrderAdditionalData); // ADDED: New event
  }

  Future<void> _onLoadOrderHistory(
    LoadOrderHistory event,
    Emitter<OrderHistoryState> emit,
  ) async {
    emit(OrderHistoryLoading());

    try {
      final result = await OrderHistoryService.fetchOrderHistory();

      if (result['success']) {
        final ordersData = result['data'] as List<Map<String, dynamic>>;
        final orders = ordersData.map((json) => OrderItem.fromJson(json)).toList();

        // Get unique filter tabs from order statuses
        final statuses = orders.map((order) => order.status).toSet().toList();
        final filterTabs = ['All', ...statuses];

        emit(OrderHistoryLoaded(
          allOrders: orders,
          filteredOrders: orders,
          selectedFilter: 'All',
          filterTabs: filterTabs,
        ));

        // ADDED: Load additional data for each order
        add(LoadOrderAdditionalData(orders: orders));
      } else {
        emit(OrderHistoryError(result['message'] ?? 'Failed to load order history'));
      }
    } catch (e) {
      emit(OrderHistoryError('An error occurred while loading order history'));
    }
  }

  Future<void> _onRefreshOrderHistory(
    RefreshOrderHistory event,
    Emitter<OrderHistoryState> emit,
  ) async {
    if (state is OrderHistoryLoaded) {
      final currentState = state as OrderHistoryLoaded;
      emit(OrderHistoryLoaded(
        allOrders: currentState.allOrders,
        filteredOrders: currentState.filteredOrders,
        selectedFilter: currentState.selectedFilter,
        filterTabs: currentState.filterTabs,
      ));
    }

    add(const LoadOrderHistory());
  }

  void _onFilterOrdersByStatus(
    FilterOrdersByStatus event,
    Emitter<OrderHistoryState> emit,
  ) {
    if (state is OrderHistoryLoaded) {
      final currentState = state as OrderHistoryLoaded;
      final filteredOrders = event.status == 'All'
          ? currentState.allOrders
          : currentState.allOrders.where((order) => order.status == event.status).toList();

      emit(currentState.copyWith(
        filteredOrders: filteredOrders,
        selectedFilter: event.status,
      ));
    }
  }

  void _onViewOrderDetails(
    ViewOrderDetails event,
    Emitter<OrderHistoryState> emit,
  ) {
    // This event is handled in the UI for navigation
    // No state changes needed here
  }

  // Optimized: Load additional data (restaurant address and ratings) for orders
  Future<void> _onLoadOrderAdditionalData(
    LoadOrderAdditionalData event,
    Emitter<OrderHistoryState> emit,
  ) async {
    if (state is OrderHistoryLoaded) {
      final currentState = state as OrderHistoryLoaded;
      final updatedOrders = List<OrderItem>.from(currentState.allOrders);

      // Process orders concurrently for better performance
      await Future.wait(
        updatedOrders.asMap().entries.map((entry) async {
          final index = entry.key;
          final order = entry.value;
          
          if (order.restaurantId.isEmpty) return;

          try {
            // Fetch restaurant details and review data concurrently
            final results = await Future.wait([
              _fetchRestaurantDetails(order),
              _fetchOrderReview(order),
            ]);

            final restaurantAddress = results[0] as String?;
            final reviewData = results[1] as Map<String, dynamic>?;

            if (restaurantAddress != null) {
              updatedOrders[index] = order.copyWithRestaurantAddress(restaurantAddress);
            }

            if (reviewData != null) {
              updatedOrders[index] = updatedOrders[index].copyWithRating(
                reviewData['rating'],
                reviewData['reviewText'],
              );
            }
          } catch (e) {
            // Log error but continue processing other orders
            print('Failed to fetch additional data for order ${order.id}: $e');
          }
        }),
      );

      // Update state with enhanced order data
      final filteredOrders = currentState.selectedFilter == 'All'
          ? updatedOrders
          : updatedOrders.where((order) => order.status == currentState.selectedFilter).toList();

      emit(OrderHistoryLoaded(
        allOrders: updatedOrders,
        filteredOrders: filteredOrders,
        selectedFilter: currentState.selectedFilter,
        filterTabs: currentState.filterTabs,
      ));
    }
  }

  // Helper method to fetch restaurant details
  Future<String?> _fetchRestaurantDetails(OrderItem order) async {
    try {
      final result = await OrderHistoryService.fetchRestaurantDetails(order.restaurantId);
      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>;
        final address = data['address']?.toString();
        return address?.isNotEmpty == true ? address : null;
      }
    } catch (e) {
      print('Failed to fetch restaurant details for order ${order.id}: $e');
    }
    return null;
  }

  // Helper method to fetch order review
  Future<Map<String, dynamic>?> _fetchOrderReview(OrderItem order) async {
    if (order.status.toUpperCase() != 'DELIVERED' && order.status.toUpperCase() != 'COMPLETED') {
      return null;
    }

    try {
      final result = await OrderHistoryService.fetchOrderReview(order.id, order.restaurantId);
      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>;
        final rating = data['rating'];
        final reviewText = data['review_text']?.toString();
        
        if (rating != null) {
          final ratingValue = rating is int ? rating.toDouble() : double.tryParse(rating.toString());
          if (ratingValue != null) {
            return {
              'rating': ratingValue,
              'reviewText': reviewText,
            };
          }
        }
      }
    } catch (e) {
      print('Failed to fetch review for order ${order.id}: $e');
    }
    return null;
  }
}
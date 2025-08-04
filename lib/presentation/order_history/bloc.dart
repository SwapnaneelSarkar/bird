// lib/presentation/order_history/bloc.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../service/order_history_service.dart';
import 'event.dart';
import 'state.dart';

class OrderHistoryBloc extends Bloc<OrderHistoryEvent, OrderHistoryState> {
  // Cache for restaurant details to avoid repeated API calls
  final Map<String, String> _restaurantAddressCache = {};
  
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

      // Get unique restaurant IDs to avoid duplicate API calls
      final uniqueRestaurantIds = updatedOrders
          .where((order) => order.restaurantId.isNotEmpty)
          .map((order) => order.restaurantId)
          .toSet()
          .toList();
      
      debugPrint('OrderHistoryBloc: Fetching data for ${uniqueRestaurantIds.length} unique restaurants');

      // Process orders concurrently for better performance
      await Future.wait(
        updatedOrders.asMap().entries.map((entry) async {
          final index = entry.key;
          final order = entry.value;
          
          if (order.restaurantId.isEmpty) return;

          try {
            // Check if we already have restaurant address cached
            String? restaurantAddress = _restaurantAddressCache[order.restaurantId];
            
            // Only fetch if not cached
            if (restaurantAddress == null) {
              final restaurantData = await _fetchRestaurantDetails(order);
              if (restaurantData != null) {
                restaurantAddress = restaurantData['address'];
                if (restaurantAddress != null) {
                  _restaurantAddressCache[order.restaurantId] = restaurantAddress;
                }
                
                // Update order with restaurant rating
                final restaurantRating = restaurantData['rating'];
                if (restaurantRating != null) {
                  updatedOrders[index] = order.copyWithRestaurantRating(restaurantRating);
                }
              }
            }
            
            // Fetch review data
            final reviewData = await _fetchOrderReview(order);

            if (restaurantAddress != null) {
              updatedOrders[index] = updatedOrders[index].copyWithRestaurantAddress(restaurantAddress);
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
  Future<Map<String, dynamic>?> _fetchRestaurantDetails(OrderItem order) async {
    try {
      final result = await OrderHistoryService.fetchRestaurantDetails(order.restaurantId);
      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>;
        final address = data['address']?.toString();
        final rating = data['rating']?.toString();
        
        return {
          'address': address?.isNotEmpty == true ? address : null,
          'rating': rating != null ? double.tryParse(rating) : null,
        };
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
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'event.dart';
import 'state.dart';

class OrderHistoryBloc extends Bloc<OrderHistoryEvent, OrderHistoryState> {
  OrderHistoryBloc() : super(OrderHistoryInitial()) {
    on<LoadOrderHistory>(_onLoadOrderHistory);
    on<FilterOrdersByStatus>(_onFilterOrdersByStatus);
    on<ViewOrderDetails>(_onViewOrderDetails);
  }
  
  Future<void> _onLoadOrderHistory(LoadOrderHistory event, Emitter<OrderHistoryState> emit) async {
    emit(OrderHistoryLoading());
    
    try {
      debugPrint('OrderHistoryBloc: Loading order history...');
      
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Mock order data matching the design
      final orders = [
        const OrderItem(
          id: 'order_001',
          name: 'Chicken Burger Combo',
          restaurantName: 'Bird Cafe',
          date: 'Apr 28, 2025',
          price: 18.99,
          status: 'Delivered',
          imageUrl: 'assets/images/chicken_burger.jpg',
        ),
        const OrderItem(
          id: 'order_002',
          name: 'Grilled Chicken Salad',
          restaurantName: 'Bird Cafe',
          date: 'Apr 27, 2025',
          price: 15.99,
          status: 'Delivered',
          imageUrl: 'assets/images/chicken_salad.jpg',
        ),
        const OrderItem(
          id: 'order_003',
          name: 'Pasta Carbonara',
          restaurantName: 'Bird Cafe',
          date: 'Apr 26, 2025',
          price: 16.99,
          status: 'Cancelled',
          imageUrl: 'assets/images/pasta_carbonara.jpg',
        ),
        const OrderItem(
          id: 'order_004',
          name: 'Margherita Pizza',
          restaurantName: 'Bird Cafe',
          date: 'Apr 25, 2025',
          price: 14.99,
          status: 'Delivered',
          imageUrl: 'assets/images/margherita_pizza.jpg',
        ),
        const OrderItem(
          id: 'order_005',
          name: 'Sushi Platter',
          restaurantName: 'Bird Cafe',
          date: 'Apr 24, 2025',
          price: 22.99,
          status: 'Delivered',
          imageUrl: 'assets/images/sushi_platter.jpg',
        ),
      ];
      
      const filterTabs = ['All Orders', 'Ongoing', 'Completed', 'Cancelled'];
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
          case 'Ongoing':
            filteredOrders = currentState.allOrders
                .where((order) => order.status == 'Ongoing' || order.status == 'Preparing')
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
}
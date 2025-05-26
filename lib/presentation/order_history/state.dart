import 'package:equatable/equatable.dart';

abstract class OrderHistoryState extends Equatable {
  const OrderHistoryState();
  
  @override
  List<Object?> get props => [];
}

class OrderItem {
  final String id;
  final String name;
  final String restaurantName;
  final String date;
  final double price;
  final String status;
  final String imageUrl;
  
  const OrderItem({
    required this.id,
    required this.name,
    required this.restaurantName,
    required this.date,
    required this.price,
    required this.status,
    required this.imageUrl,
  });
}

class OrderHistoryInitial extends OrderHistoryState {}

class OrderHistoryLoading extends OrderHistoryState {}

class OrderHistoryLoaded extends OrderHistoryState {
  final List<OrderItem> allOrders;
  final List<OrderItem> filteredOrders;
  final String selectedFilter;
  final List<String> filterTabs;
  
  const OrderHistoryLoaded({
    required this.allOrders,
    required this.filteredOrders,
    required this.selectedFilter,
    required this.filterTabs,
  });
  
  @override
  List<Object?> get props => [allOrders, filteredOrders, selectedFilter, filterTabs];
  
  OrderHistoryLoaded copyWith({
    List<OrderItem>? allOrders,
    List<OrderItem>? filteredOrders,
    String? selectedFilter,
    List<String>? filterTabs,
  }) {
    return OrderHistoryLoaded(
      allOrders: allOrders ?? this.allOrders,
      filteredOrders: filteredOrders ?? this.filteredOrders,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      filterTabs: filterTabs ?? this.filterTabs,
    );
  }
}

class OrderHistoryError extends OrderHistoryState {
  final String message;
  
  const OrderHistoryError(this.message);
  
  @override
  List<Object?> get props => [message];
}
// lib/presentation/order_history/event.dart
import 'package:equatable/equatable.dart';
import 'state.dart';

abstract class OrderHistoryEvent extends Equatable {
  const OrderHistoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadOrderHistory extends OrderHistoryEvent {
  const LoadOrderHistory();
}

class RefreshOrderHistory extends OrderHistoryEvent {
  const RefreshOrderHistory();
}

class FilterOrdersByStatus extends OrderHistoryEvent {
  final String status;

  const FilterOrdersByStatus(this.status);

  @override
  List<Object?> get props => [status];
}

class ViewOrderDetails extends OrderHistoryEvent {
  final String orderId;

  const ViewOrderDetails(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

// ADDED: Event to load additional data for orders
class LoadOrderAdditionalData extends OrderHistoryEvent {
  final List<OrderItem> orders;

  const LoadOrderAdditionalData({required this.orders});

  @override
  List<Object?> get props => [orders];
}

class OpenChatForOrder extends OrderHistoryEvent {
  final String orderId;

  const OpenChatForOrder(this.orderId);

  @override
  List<Object?> get props => [orderId];
}
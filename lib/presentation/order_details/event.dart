// lib/presentation/order_details/event.dart
import 'package:equatable/equatable.dart';

abstract class OrderDetailsEvent extends Equatable {
  const OrderDetailsEvent();

  @override
  List<Object?> get props => [];
}

class LoadOrderDetails extends OrderDetailsEvent {
  final String orderId;

  const LoadOrderDetails(this.orderId);

  @override
  List<Object?> get props => [orderId];
}

class LoadMenuItemDetails extends OrderDetailsEvent {
  final String menuId;

  const LoadMenuItemDetails(this.menuId);

  @override
  List<Object?> get props => [menuId];
}
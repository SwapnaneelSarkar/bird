// lib/presentation/order_details/state.dart
import '../../models/order_details_model.dart';
import '../../models/menu_model.dart';

abstract class OrderDetailsState {
  const OrderDetailsState();
}

class OrderDetailsInitial extends OrderDetailsState {}

class OrderDetailsLoading extends OrderDetailsState {}

class OrderDetailsLoaded extends OrderDetailsState {
  final OrderDetails orderDetails;
  final Map<String, MenuItem> menuItems; // Map menuId to MenuItem
  
  const OrderDetailsLoaded(this.orderDetails, this.menuItems);
}

class OrderDetailsError extends OrderDetailsState {
  final String message;
  
  const OrderDetailsError(this.message);
}

class OrderCancelling extends OrderDetailsState {}

class OrderCancelled extends OrderDetailsState {
  final String message;
  
  const OrderCancelled(this.message);
}
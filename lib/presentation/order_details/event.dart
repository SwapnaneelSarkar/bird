// lib/presentation/order_details/event.dart
abstract class OrderDetailsEvent {
  const OrderDetailsEvent();
}

class LoadOrderDetails extends OrderDetailsEvent {
  final String orderId;
  
  const LoadOrderDetails(this.orderId);
}

class RefreshOrderDetails extends OrderDetailsEvent {
  final String orderId;
  
  const RefreshOrderDetails(this.orderId);
}

class CancelOrder extends OrderDetailsEvent {
  final String orderId;
  
  const CancelOrder(this.orderId);
}

class TrackOrder extends OrderDetailsEvent {
  final String orderId;
  
  const TrackOrder(this.orderId);
}
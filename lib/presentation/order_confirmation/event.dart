import 'package:equatable/equatable.dart';

abstract class OrderConfirmationEvent extends Equatable {
  const OrderConfirmationEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadOrderConfirmationData extends OrderConfirmationEvent {
  final String? orderId;
  
  const LoadOrderConfirmationData({this.orderId});
  
  @override
  List<Object?> get props => [orderId];
}

class ProceedToChat extends OrderConfirmationEvent {
  const ProceedToChat();
}

class PlaceOrder extends OrderConfirmationEvent {
  final String? paymentMode;
  
  const PlaceOrder({this.paymentMode});
  
  @override
  List<Object?> get props => [paymentMode];
}

class SelectPaymentMode extends OrderConfirmationEvent {
  final String paymentMode;
  
  const SelectPaymentMode({required this.paymentMode});
  
  @override
  List<Object?> get props => [paymentMode];
}

class UpdateOrderQuantity extends OrderConfirmationEvent {
  final String itemId;
  final int newQuantity;
  
  const UpdateOrderQuantity({
    required this.itemId,
    required this.newQuantity,
  });
  
  @override
  List<Object?> get props => [itemId, newQuantity];
}

class RemoveOrderItem extends OrderConfirmationEvent {
  final String itemId;
  
  const RemoveOrderItem({required this.itemId});
  
  @override
  List<Object?> get props => [itemId];
}

class LoadPaymentMethods extends OrderConfirmationEvent {}

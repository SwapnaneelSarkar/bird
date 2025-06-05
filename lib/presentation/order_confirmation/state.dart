import 'package:equatable/equatable.dart';
import '../../../models/order_confirmation_model.dart';

abstract class OrderConfirmationState extends Equatable {
  const OrderConfirmationState();
  
  @override
  List<Object?> get props => [];
}

class OrderConfirmationInitial extends OrderConfirmationState {}

class OrderConfirmationLoading extends OrderConfirmationState {}

class OrderConfirmationLoaded extends OrderConfirmationState {
  final OrderSummary orderSummary;
  final Map<String, dynamic> cartMetadata;
  
  const OrderConfirmationLoaded({
    required this.orderSummary,
    required this.cartMetadata,
  });
  
  @override
  List<Object?> get props => [orderSummary, cartMetadata];
  
  OrderConfirmationLoaded copyWith({
    OrderSummary? orderSummary,
    Map<String, dynamic>? cartMetadata,
  }) {
    return OrderConfirmationLoaded(
      orderSummary: orderSummary ?? this.orderSummary,
      cartMetadata: cartMetadata ?? this.cartMetadata,
    );
  }
}

class OrderConfirmationError extends OrderConfirmationState {
  final String message;
  
  const OrderConfirmationError(this.message);
  
  @override
  List<Object?> get props => [message];
}

class OrderConfirmationProcessing extends OrderConfirmationState {}

class OrderConfirmationSuccess extends OrderConfirmationState {
  final String message;
  
  const OrderConfirmationSuccess(this.message);
  
  @override
  List<Object?> get props => [message];
}
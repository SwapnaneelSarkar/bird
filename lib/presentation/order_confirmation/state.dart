import 'package:bird/models/payment_mode.dart';
import 'package:equatable/equatable.dart';
import '../../../models/order_confirmation_model.dart';

abstract class OrderConfirmationState extends Equatable {
  const OrderConfirmationState();
  
  @override
  List<Object?> get props => [];
}
class PaymentMethodsLoaded extends OrderConfirmationState {
  final List<PaymentMethod> methods;
  final OrderSummary orderSummary;
  final Map<String, dynamic> cartMetadata;
  final String? selectedPaymentMode;
  
  PaymentMethodsLoaded(
    this.methods,
    this.orderSummary,
    this.cartMetadata,
    this.selectedPaymentMode,
  );
  
  @override
  List<Object?> get props => [methods, orderSummary, cartMetadata, selectedPaymentMode];
}


class OrderConfirmationInitial extends OrderConfirmationState {}

class OrderConfirmationLoading extends OrderConfirmationState {}

class OrderConfirmationLoaded extends OrderConfirmationState {
  final OrderSummary orderSummary;
  final Map<String, dynamic> cartMetadata;
  final String? selectedPaymentMode;
  
  const OrderConfirmationLoaded({
    required this.orderSummary,
    required this.cartMetadata,
    this.selectedPaymentMode,
  });
  
  @override
  List<Object?> get props => [orderSummary, cartMetadata, selectedPaymentMode];
  
  OrderConfirmationLoaded copyWith({
    OrderSummary? orderSummary,
    Map<String, dynamic>? cartMetadata,
    String? selectedPaymentMode,
  }) {
    return OrderConfirmationLoaded(
      orderSummary: orderSummary ?? this.orderSummary,
      cartMetadata: cartMetadata ?? this.cartMetadata,
      selectedPaymentMode: selectedPaymentMode ?? this.selectedPaymentMode,
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
  final String orderId;
  
  const OrderConfirmationSuccess(this.message, this.orderId);
  
  @override
  List<Object?> get props => [message, orderId];
}

class ChatRoomCreated extends OrderConfirmationState {
  final String orderId;
  final String roomId;
  
  const ChatRoomCreated(this.orderId, this.roomId);
  
  @override
  List<Object?> get props => [orderId, roomId];
}

class OrderConfirmationEmptyCart extends OrderConfirmationState {
  const OrderConfirmationEmptyCart();
}
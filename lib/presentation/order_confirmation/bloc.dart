import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/order_confirmation_model.dart';
import 'event.dart';
import 'state.dart';

class OrderConfirmationBloc extends Bloc<OrderConfirmationEvent, OrderConfirmationState> {
  OrderConfirmationBloc() : super(OrderConfirmationInitial()) {
    debugPrint('OrderConfirmationBloc: Constructor called');
    on<LoadOrderConfirmationData>(_onLoadOrderConfirmationData);
    on<ProceedToChat>(_onProceedToChat);
    on<UpdateOrderQuantity>(_onUpdateOrderQuantity);
    on<RemoveOrderItem>(_onRemoveOrderItem);
    debugPrint('OrderConfirmationBloc: Event handlers registered');
  }

  Future<void> _onLoadOrderConfirmationData(
    LoadOrderConfirmationData event,
    Emitter<OrderConfirmationState> emit,
  ) async {
    emit(OrderConfirmationLoading());
    
    try {
      debugPrint('OrderConfirmationBloc: Loading order confirmation data');
      debugPrint('OrderConfirmationBloc: Order ID: ${event.orderId}');
      
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Hardcoded data for now - this will be replaced with API call later
      final orderItems = [
        OrderItem(
          id: 'item_001',
          name: 'Classic Cheeseburger',
          imageUrl: 'assets/images/burger.png',
          quantity: 2,
          price: 12.99,
        ),
        OrderItem(
          id: 'item_002',
          name: 'Crispy French Fries',
          imageUrl: 'assets/images/fries.png',
          quantity: 2,
          price: 3.99,
        ),
        OrderItem(
          id: 'item_003',
          name: 'Chocolate Milkshake',
          imageUrl: 'assets/images/milkshake.png',
          quantity: 2,
          price: 5.99,
        ),
        OrderItem(
          id: 'item_004',
          name: 'Buffalo Chicken Wings',
          imageUrl: 'assets/images/wings.png',
          quantity: 1,
          price: 14.99,
        ),
        OrderItem(
          id: 'item_005',
          name: 'Fresh Garden Salad',
          imageUrl: 'assets/images/salad.png',
          quantity: 1,
          price: 9.99,
        ),
      ];
      
      debugPrint('OrderConfirmationBloc: Created ${orderItems.length} order items');
      
      // Print each item details for debugging
      for (var item in orderItems) {
        debugPrint('Item: ${item.name}, Price: \${item.price}, Qty: ${item.quantity}, Total: \${item.totalPrice}');
      }
      
      final orderSummary = OrderSummary(
        items: orderItems,
        deliveryFee: 3.99,
        taxAmount: 0.0,
        discountAmount: 0.0,
      );
      
      debugPrint('OrderConfirmationBloc: Order loaded successfully');
      debugPrint('OrderConfirmationBloc: Total items: ${orderSummary.items.length}');
      debugPrint('OrderConfirmationBloc: Subtotal: \${orderSummary.subtotal.toStringAsFixed(2)}');
      debugPrint('OrderConfirmationBloc: Delivery Fee: \${orderSummary.deliveryFee.toStringAsFixed(2)}');
      debugPrint('OrderConfirmationBloc: Total: \${orderSummary.total.toStringAsFixed(2)}');
      
      // Ensure we emit the loaded state
      emit(OrderConfirmationLoaded(orderSummary: orderSummary));
      
      debugPrint('OrderConfirmationBloc: Emitted OrderConfirmationLoaded state');
      
    } catch (e, stackTrace) {
      debugPrint('OrderConfirmationBloc: Error loading order data: $e');
      debugPrint('OrderConfirmationBloc: Stack trace: $stackTrace');
      emit(OrderConfirmationError('Failed to load order details. Please try again.'));
    }
  }

  Future<void> _onProceedToChat(
    ProceedToChat event,
    Emitter<OrderConfirmationState> emit,
  ) async {
    if (state is OrderConfirmationLoaded) {
      emit(OrderConfirmationProcessing());
      
      try {
        debugPrint('OrderConfirmationBloc: Processing order for chat...');
        
        // Simulate API call to proceed with order
        await Future.delayed(const Duration(milliseconds: 1500));
        
        debugPrint('OrderConfirmationBloc: Order processed successfully, proceeding to chat');
        emit(OrderConfirmationSuccess('Order confirmed! Proceeding to chat...'));
        
      } catch (e) {
        debugPrint('OrderConfirmationBloc: Error processing order: $e');
        emit(OrderConfirmationError('Failed to process order. Please try again.'));
        
        // Return to loaded state
        if (state is OrderConfirmationLoaded) {
          emit(state as OrderConfirmationLoaded);
        }
      }
    }
  }

  Future<void> _onUpdateOrderQuantity(
    UpdateOrderQuantity event,
    Emitter<OrderConfirmationState> emit,
  ) async {
    if (state is OrderConfirmationLoaded) {
      final currentState = state as OrderConfirmationLoaded;
      
      try {
        debugPrint('OrderConfirmationBloc: Updating quantity for item ${event.itemId} to ${event.newQuantity}');
        
        final updatedItems = currentState.orderSummary.items.map((item) {
          if (item.id == event.itemId) {
            return OrderItem(
              id: item.id,
              name: item.name,
              imageUrl: item.imageUrl,
              quantity: event.newQuantity,
              price: item.price,
            );
          }
          return item;
        }).toList();
        
        final updatedOrderSummary = OrderSummary(
          items: updatedItems,
          deliveryFee: currentState.orderSummary.deliveryFee,
          taxAmount: currentState.orderSummary.taxAmount,
          discountAmount: currentState.orderSummary.discountAmount,
        );
        
        debugPrint('OrderConfirmationBloc: Updated subtotal: \$${updatedOrderSummary.subtotal.toStringAsFixed(2)}');
        debugPrint('OrderConfirmationBloc: Updated total: \$${updatedOrderSummary.total.toStringAsFixed(2)}');
        
        emit(currentState.copyWith(orderSummary: updatedOrderSummary));
        
      } catch (e) {
        debugPrint('OrderConfirmationBloc: Error updating quantity: $e');
        emit(OrderConfirmationError('Failed to update item quantity.'));
      }
    }
  }

  Future<void> _onRemoveOrderItem(
    RemoveOrderItem event,
    Emitter<OrderConfirmationState> emit,
  ) async {
    if (state is OrderConfirmationLoaded) {
      final currentState = state as OrderConfirmationLoaded;
      
      try {
        debugPrint('OrderConfirmationBloc: Removing item ${event.itemId}');
        
        final updatedItems = currentState.orderSummary.items
            .where((item) => item.id != event.itemId)
            .toList();
        
        if (updatedItems.isEmpty) {
          debugPrint('OrderConfirmationBloc: No items remaining in order');
          emit(OrderConfirmationError('Your cart is empty. Please add items to continue.'));
          return;
        }
        
        final updatedOrderSummary = OrderSummary(
          items: updatedItems,
          deliveryFee: currentState.orderSummary.deliveryFee,
          taxAmount: currentState.orderSummary.taxAmount,
          discountAmount: currentState.orderSummary.discountAmount,
        );
        
        debugPrint('OrderConfirmationBloc: Item removed successfully');
        debugPrint('OrderConfirmationBloc: Remaining items: ${updatedItems.length}');
        debugPrint('OrderConfirmationBloc: Updated total: \$${updatedOrderSummary.total.toStringAsFixed(2)}');
        
        emit(currentState.copyWith(orderSummary: updatedOrderSummary));
        
      } catch (e) {
        debugPrint('OrderConfirmationBloc: Error removing item: $e');
        emit(OrderConfirmationError('Failed to remove item.'));
      }
    }
  }
}
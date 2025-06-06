import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/order_confirmation_model.dart';
import '../../../service/cart_service.dart';
import '../../../service/order_service.dart';
import '../../../service/token_service.dart';
import 'event.dart';
import 'state.dart';

class OrderConfirmationBloc extends Bloc<OrderConfirmationEvent, OrderConfirmationState> {
  OrderConfirmationBloc() : super(OrderConfirmationInitial()) {
    debugPrint('OrderConfirmationBloc: Constructor called');
    on<LoadOrderConfirmationData>(_onLoadOrderConfirmationData);
    on<ProceedToChat>(_onProceedToChat);
    on<PlaceOrder>(_onPlaceOrder);
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
      
      // Load cart data from CartService
      final cart = await CartService.getCart();
      
      if (cart == null || cart['items'] == null || (cart['items'] as List).isEmpty) {
        debugPrint('OrderConfirmationBloc: No cart data found or cart is empty');
        emit(OrderConfirmationError('Your cart is empty. Please add items to continue.'));
        return;
      }
      
      debugPrint('OrderConfirmationBloc: Cart loaded successfully');
      debugPrint('OrderConfirmationBloc: Partner ID: ${cart['partner_id']}');
      debugPrint('OrderConfirmationBloc: Restaurant: ${cart['restaurant_name']}');
      debugPrint('OrderConfirmationBloc: Items count: ${(cart['items'] as List).length}');
      
      // Convert cart items to OrderItem objects
      final cartItems = cart['items'] as List<dynamic>;
      final orderItems = cartItems.map((item) {
        debugPrint('Converting cart item: ${item['name']}, Price: ${item['price']}, Qty: ${item['quantity']}');
        
        return OrderItem(
          id: item['menu_id'] ?? '',
          name: item['name'] ?? '',
          imageUrl: item['image_url'] ?? 'assets/images/placeholder.png',
          quantity: item['quantity'] ?? 1,
          price: (item['price'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();
      
      debugPrint('OrderConfirmationBloc: Created ${orderItems.length} order items');
      
      // Print each item details for debugging
      for (var item in orderItems) {
        debugPrint('Item: ${item.name}, Price: ₹${item.price}, Qty: ${item.quantity}, Total: ₹${item.totalPrice}');
      }
      
      final orderSummary = OrderSummary(
        items: orderItems,
        deliveryFee: (cart['delivery_fees'] as num?)?.toDouble() ?? 50.0,
        taxAmount: 0.0,
        discountAmount: 0.0,
      );
      
      debugPrint('OrderConfirmationBloc: Order loaded successfully');
      debugPrint('OrderConfirmationBloc: Total items: ${orderSummary.items.length}');
      debugPrint('OrderConfirmationBloc: Subtotal: ₹${orderSummary.subtotal.toStringAsFixed(2)}');
      debugPrint('OrderConfirmationBloc: Delivery Fee: ₹${orderSummary.deliveryFee.toStringAsFixed(2)}');
      debugPrint('OrderConfirmationBloc: Total: ₹${orderSummary.total.toStringAsFixed(2)}');
      
      // Store cart metadata for order placement
      final cartMetadata = {
        'partner_id': cart['partner_id'],
        'restaurant_name': cart['restaurant_name'],
        'user_id': cart['user_id'],
        'address': cart['address'] ?? '',
      };
      
      // Ensure we emit the loaded state
      emit(OrderConfirmationLoaded(
        orderSummary: orderSummary,
        cartMetadata: cartMetadata,
      ));
      
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
      // Trigger order placement
      add(const PlaceOrder());
    }
  }

  Future<void> _onPlaceOrder(
    PlaceOrder event,
    Emitter<OrderConfirmationState> emit,
  ) async {
    if (state is OrderConfirmationLoaded) {
      final currentState = state as OrderConfirmationLoaded;
      
      emit(OrderConfirmationProcessing());
      
      try {
        debugPrint('OrderConfirmationBloc: Starting order placement process...');
        
        // Get user ID and address
        final userId = await TokenService.getUserId();
        if (userId == null) {
          emit(const OrderConfirmationError('User authentication required. Please login again.'));
          return;
        }
        
        final cartMetadata = currentState.cartMetadata;
        final partnerId = cartMetadata['partner_id']?.toString() ?? '';
        String address = cartMetadata['address']?.toString() ?? '';
        
        // If address is empty, try to get from user profile
        if (address.isEmpty) {
          final userData = await TokenService.getUserData();
          address = userData?['address']?.toString() ?? '';
        }
        
        if (address.isEmpty) {
          emit(const OrderConfirmationError('Delivery address is required. Please add your address.'));
          return;
        }
        
        // Prepare order items
        final orderItems = currentState.orderSummary.items.map((item) => {
          'menu_id': item.id,
          'quantity': item.quantity,
          'price': item.price,
        }).toList();
        
        debugPrint('OrderConfirmationBloc: Placing order with:');
        debugPrint('  Partner ID: $partnerId');
        debugPrint('  User ID: $userId');
        debugPrint('  Items: ${orderItems.length}');
        debugPrint('  Total: ₹${currentState.orderSummary.total}');
        debugPrint('  Address: $address');
        
        // Place order
        final orderResult = await OrderService.placeOrder(
          partnerId: partnerId,
          userId: userId,
          items: orderItems,
          totalPrice: currentState.orderSummary.total,
          address: address,
          deliveryFees: currentState.orderSummary.deliveryFee,
          subtotal: currentState.orderSummary.subtotal,
        );
        
        if (orderResult['success'] == true) {
          final orderData = orderResult['data'];
          final orderId = orderData['order_id'].toString();
          
          debugPrint('OrderConfirmationBloc: Order placed successfully - Order ID: $orderId');
          
          // Create chat room
          debugPrint('OrderConfirmationBloc: Creating chat room for order: $orderId');
          final chatResult = await OrderService.createChatRoom(orderId);
          
          if (chatResult['success'] == true) {
            final chatData = chatResult['data'];
            final roomId = chatData['roomId'].toString();
            
            debugPrint('OrderConfirmationBloc: Chat room created - Room ID: $roomId');
            
            // Clear cart after successful order
            await CartService.clearCart();
            debugPrint('OrderConfirmationBloc: Cart cleared after successful order');
            
            emit(ChatRoomCreated(orderId, roomId));
          } else {
            debugPrint('OrderConfirmationBloc: Chat room creation failed: ${chatResult['message']}');
            // Even if chat room creation fails, order was placed successfully
            await CartService.clearCart();
            emit(OrderConfirmationSuccess(
              'Order placed successfully! Order ID: $orderId',
              orderId,
            ));
          }
        } else {
          debugPrint('OrderConfirmationBloc: Order placement failed: ${orderResult['message']}');
          emit(OrderConfirmationError(orderResult['message'] ?? 'Failed to place order. Please try again.'));
          
          // Return to loaded state on error
          emit(currentState);
        }
        
      } catch (e, stackTrace) {
        debugPrint('OrderConfirmationBloc: Error during order placement: $e');
        debugPrint('OrderConfirmationBloc: Stack trace: $stackTrace');
        emit(const OrderConfirmationError('An error occurred while placing your order. Please try again.'));
        
        // Return to loaded state on error
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
        
        // Update cart in storage
        final cart = await CartService.getCart();
        if (cart != null) {
          final items = List<Map<String, dynamic>>.from(cart['items']);
          final itemIndex = items.indexWhere((item) => item['menu_id'] == event.itemId);
          
          if (itemIndex >= 0) {
            if (event.newQuantity <= 0) {
              items.removeAt(itemIndex);
              debugPrint('OrderConfirmationBloc: Removed item from cart');
            } else {
              items[itemIndex]['quantity'] = event.newQuantity;
              items[itemIndex]['total_price'] = items[itemIndex]['price'] * event.newQuantity;
              debugPrint('OrderConfirmationBloc: Updated item quantity in cart');
            }
            
            // Update cart totals
            cart['items'] = items;
            double subtotal = 0.0;
            for (var item in items) {
              subtotal += (item['total_price'] as num).toDouble();
            }
            cart['subtotal'] = subtotal;
            cart['total_price'] = subtotal + (cart['delivery_fees'] as num).toDouble();
            
            // Save updated cart or clear if empty
            if (items.isEmpty) {
              await CartService.clearCart();
              emit(OrderConfirmationError('Your cart is empty. Please add items to continue.'));
              return;
            } else {
              await CartService.saveCart(cart);
            }
          }
        }
        
        // Update UI state
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
        }).where((item) => item.quantity > 0).toList();
        
        if (updatedItems.isEmpty) {
          emit(OrderConfirmationError('Your cart is empty. Please add items to continue.'));
          return;
        }
        
        final updatedOrderSummary = OrderSummary(
          items: updatedItems,
          deliveryFee: currentState.orderSummary.deliveryFee,
          taxAmount: currentState.orderSummary.taxAmount,
          discountAmount: currentState.orderSummary.discountAmount,
        );
        
        debugPrint('OrderConfirmationBloc: Updated subtotal: ₹${updatedOrderSummary.subtotal.toStringAsFixed(2)}');
        debugPrint('OrderConfirmationBloc: Updated total: ₹${updatedOrderSummary.total.toStringAsFixed(2)}');
        
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
        
        // Update cart in storage
        final cart = await CartService.getCart();
        if (cart != null) {
          final items = List<Map<String, dynamic>>.from(cart['items']);
          items.removeWhere((item) => item['menu_id'] == event.itemId);
          
          if (items.isEmpty) {
            await CartService.clearCart();
            emit(OrderConfirmationError('Your cart is empty. Please add items to continue.'));
            return;
          } else {
            // Update cart totals
            cart['items'] = items;
            double subtotal = 0.0;
            for (var item in items) {
              subtotal += (item['total_price'] as num).toDouble();
            }
            cart['subtotal'] = subtotal;
            cart['total_price'] = subtotal + (cart['delivery_fees'] as num).toDouble();
            
            await CartService.saveCart(cart);
          }
        }
        
        // Update UI state
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
        debugPrint('OrderConfirmationBloc: Updated total: ₹${updatedOrderSummary.total.toStringAsFixed(2)}');
        
        emit(currentState.copyWith(orderSummary: updatedOrderSummary));
        
      } catch (e) {
        debugPrint('OrderConfirmationBloc: Error removing item: $e');
        emit(OrderConfirmationError('Failed to remove item.'));
      }
    }
  }
}
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:equatable/equatable.dart';
import '../../constants/api_constant.dart';
import '../../service/cart_service.dart';
import '../../service/order_service.dart';
import '../../service/token_service.dart';
import '../../models/order_confirmation_model.dart';
import '../../models/attribute_model.dart';
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
      debugPrint('=== ORDER CONFIRMATION BLOC: LOAD DATA START ===');
      debugPrint('ORDER CONFIRMATION BLOC: Order ID: ${event.orderId}');
      
      // Load cart data from CartService
      final cart = await CartService.getCart();
      
      debugPrint('ORDER CONFIRMATION BLOC: Cart data loaded:');
      if (cart != null) {
        debugPrint('  - Partner ID: ${cart['partner_id']}');
        debugPrint('  - Restaurant: ${cart['restaurant_name']}');
        debugPrint('  - Items count: ${(cart['items'] as List?)?.length ?? 0}');
        debugPrint('  - Subtotal: ₹${cart['subtotal']}');
        debugPrint('  - Total: ₹${cart['total_price']}');
        
        if (cart['items'] != null) {
          final items = cart['items'] as List;
          for (int i = 0; i < items.length; i++) {
            final item = items[i];
            debugPrint('    Item $i: ${item['name']} - Qty: ${item['quantity']}, Base: ₹${item['price']}, Attr: ₹${item['attributes_price']}, Total: ₹${item['total_price']}');
          }
        }
      } else {
        debugPrint('  - No cart data found');
      }
      
      if (cart == null || cart['items'] == null || (cart['items'] as List).isEmpty) {
        debugPrint('ORDER CONFIRMATION BLOC: No cart data found or cart is empty');
        emit(OrderConfirmationError('Your cart is empty. Please add items to continue.'));
        return;
      }
      
      debugPrint('ORDER CONFIRMATION BLOC: Converting cart items to OrderItem objects');
      
      // Convert cart items to OrderItem objects
      final cartItems = cart['items'] as List<dynamic>;
      final orderItems = cartItems.map((item) {
        debugPrint('ORDER CONFIRMATION BLOC: Converting item: ${item['name']}');
        debugPrint('  - Menu ID: ${item['menu_id']}');
        debugPrint('  - Base Price: ₹${item['price']}');
        debugPrint('  - Quantity: ${item['quantity']}');
        debugPrint('  - Attributes Price: ₹${item['attributes_price']}');
        debugPrint('  - Total Price: ₹${item['total_price']}');
        
        // Parse attributes from cart item
        List<SelectedAttribute> attributes = [];
        if (item['attributes'] != null && item['attributes'] is List) {
          attributes = (item['attributes'] as List)
              .map((attr) => SelectedAttribute.fromJson(attr))
              .toList();
          debugPrint('  - Attributes count: ${attributes.length}');
          for (var attr in attributes) {
            debugPrint('    - ${attr.attributeName}: ${attr.valueName} (+₹${attr.priceAdjustment})');
          }
        }
        
        final orderItem = OrderItem(
          id: item['menu_id'] ?? '',
          name: item['name'] ?? '',
          imageUrl: item['image_url'] ?? 'assets/images/placeholder.png',
          quantity: item['quantity'] ?? 1,
          price: (item['price'] as num?)?.toDouble() ?? 0.0,
          attributes: attributes,
        );
        
        debugPrint('ORDER CONFIRMATION BLOC: Created OrderItem:');
        debugPrint('  - ID: ${orderItem.id}');
        debugPrint('  - Name: ${orderItem.name}');
        debugPrint('  - Quantity: ${orderItem.quantity}');
        debugPrint('  - Base Price: ₹${orderItem.price}');
        debugPrint('  - Price Per Item: ₹${orderItem.pricePerItem}');
        debugPrint('  - Total Price: ₹${orderItem.totalPrice}');
        debugPrint('  - Attributes count: ${orderItem.attributes.length}');
        
        return orderItem;
      }).toList();
      
      debugPrint('ORDER CONFIRMATION BLOC: Created ${orderItems.length} order items');
      
      // Print each item details for debugging
      for (var item in orderItems) {
        debugPrint('ORDER CONFIRMATION BLOC: Final item: ${item.name}, Base: ₹${item.price}, Qty: ${item.quantity}, Total: ₹${item.totalPrice}');
      }
      
      final orderSummary = OrderSummary(
        items: orderItems,
        deliveryFee: (cart['delivery_fees'] as num?)?.toDouble() ?? 50.0,
        taxAmount: 0.0,
        discountAmount: 0.0,
      );
      
      debugPrint('ORDER CONFIRMATION BLOC: Order summary created:');
      debugPrint('  - Items count: ${orderSummary.items.length}');
      debugPrint('  - Subtotal: ₹${orderSummary.subtotal.toStringAsFixed(2)}');
      debugPrint('  - Delivery Fee: ₹${orderSummary.deliveryFee.toStringAsFixed(2)}');
      debugPrint('  - Total: ₹${orderSummary.total.toStringAsFixed(2)}');
      
      // Store cart metadata for order placement
      final cartMetadata = {
        'partner_id': cart['partner_id'],
        'restaurant_name': cart['restaurant_name'],
        'user_id': cart['user_id'],
        'address': cart['address'] ?? '',
      };
      
      debugPrint('ORDER CONFIRMATION BLOC: Cart metadata:');
      debugPrint('  - Partner ID: ${cartMetadata['partner_id']}');
      debugPrint('  - Restaurant: ${cartMetadata['restaurant_name']}');
      debugPrint('  - User ID: ${cartMetadata['user_id']}');
      debugPrint('  - Address: ${cartMetadata['address']}');
      
      // Ensure we emit the loaded state
      emit(OrderConfirmationLoaded(
        orderSummary: orderSummary,
        cartMetadata: cartMetadata,
      ));
      
      debugPrint('ORDER CONFIRMATION BLOC: Emitted OrderConfirmationLoaded state');
      debugPrint('=== ORDER CONFIRMATION BLOC: LOAD DATA END ===');
      
    } catch (e, stackTrace) {
      debugPrint('ORDER CONFIRMATION BLOC: Error loading order data: $e');
      debugPrint('ORDER CONFIRMATION BLOC: Stack trace: $stackTrace');
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
        
        // Prepare order items with attributes price included in the item price
        final orderItems = currentState.orderSummary.items.map((item) => {
          'menu_id': item.id,
          'quantity': item.quantity,
          'price': item.pricePerItem, // Base price + attribute prices
        }).toList();
        
        // Calculate total price as sum of (price × quantity) for all items
        double calculatedTotal = 0.0;
        for (var item in currentState.orderSummary.items) {
          calculatedTotal += item.pricePerItem * item.quantity;
        }
        
        debugPrint('OrderConfirmationBloc: Placing order with:');
        debugPrint('  Partner ID: $partnerId');
        debugPrint('  User ID: $userId');
        debugPrint('  Items: ${orderItems.length}');
        debugPrint('  Calculated Total: ₹$calculatedTotal');
        debugPrint('  Address: $address');
        
        // Place order
        final orderResult = await OrderService.placeOrder(
          partnerId: partnerId,
          userId: userId,
          items: orderItems,
          totalPrice: calculatedTotal,
          address: address,
          deliveryFees: currentState.orderSummary.deliveryFee,
          subtotal: calculatedTotal,
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
        debugPrint('=== ORDER CONFIRMATION BLOC: UPDATE QUANTITY START ===');
        debugPrint('ORDER CONFIRMATION BLOC: Update request:');
        debugPrint('  - Item ID: ${event.itemId}');
        debugPrint('  - New Quantity: ${event.newQuantity}');
        
        // Find the item in current state
        final currentItem = currentState.orderSummary.items.firstWhere(
          (item) => item.id == event.itemId,
          orElse: () => OrderItem(id: '', name: '', imageUrl: '', quantity: 0, price: 0.0),
        );
        
        debugPrint('ORDER CONFIRMATION BLOC: Current item in UI:');
        debugPrint('  - Name: ${currentItem.name}');
        debugPrint('  - Current Quantity: ${currentItem.quantity}');
        debugPrint('  - Base Price: ₹${currentItem.price}');
        debugPrint('  - Price Per Item: ₹${currentItem.pricePerItem}');
        debugPrint('  - Current Total: ₹${currentItem.totalPrice}');
        
        // Update cart in storage
        final cart = await CartService.getCart();
        debugPrint('ORDER CONFIRMATION BLOC: Cart data before update:');
        if (cart != null) {
          debugPrint('  - Items count: ${(cart['items'] as List?)?.length ?? 0}');
          debugPrint('  - Subtotal: ₹${cart['subtotal']}');
          debugPrint('  - Total: ₹${cart['total_price']}');
          
          if (cart['items'] != null) {
            final items = cart['items'] as List;
            for (int i = 0; i < items.length; i++) {
              final item = items[i];
              debugPrint('    Item $i: ${item['name']} - Qty: ${item['quantity']}, Base: ₹${item['price']}, Attr: ₹${item['attributes_price']}, Total: ₹${item['total_price']}');
            }
          }
        }
        
        if (cart != null) {
          final items = List<Map<String, dynamic>>.from(cart['items']);
          final itemIndex = items.indexWhere((item) => item['menu_id'] == event.itemId);
          
          debugPrint('ORDER CONFIRMATION BLOC: Cart item search:');
          debugPrint('  - Looking for menu ID: ${event.itemId}');
          debugPrint('  - Found at index: $itemIndex');
          
          if (itemIndex >= 0) {
            final cartItem = items[itemIndex];
            debugPrint('ORDER CONFIRMATION BLOC: Cart item before update:');
            debugPrint('  - Name: ${cartItem['name']}');
            debugPrint('  - Current Quantity: ${cartItem['quantity']}');
            debugPrint('  - Base Price: ₹${cartItem['price']}');
            debugPrint('  - Attributes Price: ₹${cartItem['attributes_price']}');
            debugPrint('  - Current Total: ₹${cartItem['total_price']}');
            
            if (event.newQuantity <= 0) {
              debugPrint('ORDER CONFIRMATION BLOC: Removing item from cart');
              items.removeAt(itemIndex);
              debugPrint('ORDER CONFIRMATION BLOC: Item removed from cart');
            } else {
              debugPrint('ORDER CONFIRMATION BLOC: Updating item quantity in cart');
              final oldQuantity = cartItem['quantity'] as int;
              final basePrice = (cartItem['price'] as num).toDouble();
              final attributesPrice = (cartItem['attributes_price'] as num?)?.toDouble() ?? 0.0;
              final totalPricePerItem = basePrice + attributesPrice;
              final newTotalPrice = totalPricePerItem * event.newQuantity;
              
              debugPrint('ORDER CONFIRMATION BLOC: Price calculations:');
              debugPrint('  - Old Quantity: $oldQuantity');
              debugPrint('  - New Quantity: ${event.newQuantity}');
              debugPrint('  - Base Price: ₹$basePrice');
              debugPrint('  - Attributes Price: ₹$attributesPrice');
              debugPrint('  - Total Price Per Item: ₹$totalPricePerItem');
              debugPrint('  - New Total Price: ₹$newTotalPrice');
              
              items[itemIndex]['quantity'] = event.newQuantity;
              items[itemIndex]['total_price'] = newTotalPrice;
              debugPrint('ORDER CONFIRMATION BLOC: Cart item updated');
            }
            
            // Update cart totals
            cart['items'] = items;
            double subtotal = 0.0;
            for (var item in items) {
              subtotal += (item['total_price'] as num).toDouble();
            }
            cart['subtotal'] = subtotal;
            cart['total_price'] = subtotal + (cart['delivery_fees'] as num).toDouble();
            
            debugPrint('ORDER CONFIRMATION BLOC: Updated cart totals:');
            debugPrint('  - Items count: ${items.length}');
            debugPrint('  - Subtotal: ₹$subtotal');
            debugPrint('  - Total: ₹${cart['total_price']}');
            
            // Save updated cart or clear if empty
            if (items.isEmpty) {
              await CartService.clearCart();
              debugPrint('ORDER CONFIRMATION BLOC: Cart is empty, cleared');
              emit(OrderConfirmationError('Your cart is empty. Please add items to continue.'));
              return;
            } else {
              await CartService.saveCart(cart);
              debugPrint('ORDER CONFIRMATION BLOC: Cart saved');
            }
          }
        }
        
        // Update UI state
        debugPrint('ORDER CONFIRMATION BLOC: Updating UI state');
        final updatedItems = currentState.orderSummary.items.map((item) {
          if (item.id == event.itemId) {
            debugPrint('ORDER CONFIRMATION BLOC: Updating UI item: ${item.name}');
            debugPrint('  - Old Quantity: ${item.quantity}');
            debugPrint('  - New Quantity: ${event.newQuantity}');
            debugPrint('  - Base Price: ₹${item.price}');
            debugPrint('  - Price Per Item: ₹${item.pricePerItem}');
            debugPrint('  - Old Total: ₹${item.totalPrice}');
            
            final newItem = OrderItem(
              id: item.id,
              name: item.name,
              imageUrl: item.imageUrl,
              quantity: event.newQuantity,
              price: item.price,
              attributes: item.attributes,
            );
            
            debugPrint('  - New Total: ₹${newItem.totalPrice}');
            return newItem;
          }
          return item;
        }).where((item) => item.quantity > 0).toList();
        
        debugPrint('ORDER CONFIRMATION BLOC: UI items after update:');
        for (var item in updatedItems) {
          debugPrint('  - ${item.name}: Qty ${item.quantity}, Base ₹${item.price}, Total ₹${item.totalPrice}');
        }
        
        if (updatedItems.isEmpty) {
          debugPrint('ORDER CONFIRMATION BLOC: No items remaining in UI');
          emit(OrderConfirmationError('Your cart is empty. Please add items to continue.'));
          return;
        }
        
        final updatedOrderSummary = OrderSummary(
          items: updatedItems,
          deliveryFee: currentState.orderSummary.deliveryFee,
          taxAmount: currentState.orderSummary.taxAmount,
          discountAmount: currentState.orderSummary.discountAmount,
        );
        
        debugPrint('ORDER CONFIRMATION BLOC: Updated order summary:');
        debugPrint('  - Items count: ${updatedOrderSummary.items.length}');
        debugPrint('  - Subtotal: ₹${updatedOrderSummary.subtotal.toStringAsFixed(2)}');
        debugPrint('  - Total: ₹${updatedOrderSummary.total.toStringAsFixed(2)}');
        
        emit(currentState.copyWith(orderSummary: updatedOrderSummary));
        debugPrint('ORDER CONFIRMATION BLOC: UI state updated');
        debugPrint('=== ORDER CONFIRMATION BLOC: UPDATE QUANTITY END ===');
        
      } catch (e) {
        debugPrint('ORDER CONFIRMATION BLOC: Error updating quantity: $e');
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
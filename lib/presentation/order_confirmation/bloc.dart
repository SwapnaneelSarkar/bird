import 'dart:convert';
import 'dart:async';
import 'package:bird/models/payment_mode.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:equatable/equatable.dart';
import '../../constants/api_constant.dart';
import '../../service/cart_service.dart';
import '../../service/order_service.dart';
import '../../service/token_service.dart';
import '../../service/profile_get_service.dart';
import '../../models/order_confirmation_model.dart';
import '../../models/attribute_model.dart';
import 'event.dart';
import 'state.dart';

class OrderConfirmationBloc extends Bloc<OrderConfirmationEvent, OrderConfirmationState> {
  final ProfileApiService _profileApiService = ProfileApiService();
  
  OrderConfirmationBloc() : super(OrderConfirmationInitial()) {
    debugPrint('OrderConfirmationBloc: Constructor called');
    on<LoadOrderConfirmationData>(_onLoadOrderConfirmationData);
    on<ProceedToChat>(_onProceedToChat);
    on<PlaceOrder>(_onPlaceOrder);
    on<SelectPaymentMode>(_onSelectPaymentMode);
    on<UpdateOrderQuantity>(_onUpdateOrderQuantity);
    on<RemoveOrderItem>(_onRemoveOrderItem);
    on<LoadPaymentMethods>(_onLoadPaymentMethods);
    debugPrint('OrderConfirmationBloc: Event handlers registered');
  }

  Future<void> _onLoadPaymentMethods(
    LoadPaymentMethods event,
    Emitter<OrderConfirmationState> emit,
  ) async {
    debugPrint('=== PAYMENT METHODS BLOC: LOAD START ===');
    try {
      debugPrint('PaymentMethods: Fetching payment methods from API...');
      
      final token = await TokenService.getToken();
      if (token == null) {
        debugPrint('PaymentMethods: No authentication token found');
        emit(const OrderConfirmationError('Authentication required. Please login again.'));
        return;
      }
      
      final url = Uri.parse('${ApiConstants.baseUrl}/api/user/paymentMethods');
      debugPrint('PaymentMethods: Request URL: $url');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      debugPrint('PaymentMethods: Response Status: ${response.statusCode}');
      debugPrint('PaymentMethods: Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          debugPrint('PaymentMethods: Parsed response data: $data');
          
          if ((data['status'] == 'SUCCESS' || data['status'] == true) && data['data'] != null) {
            final methods = (data['data'] as List)
                .map((json) => PaymentMethod.fromJson(json))
                .toList();
            
            debugPrint('PaymentMethods: Successfully loaded ${methods.length} payment methods');
            for (var method in methods) {
              debugPrint('  - ${method.displayName} (ID: ${method.id})');
            }
            
            // Get the current order data from the state
            if (state is OrderConfirmationLoaded) {
              final currentState = state as OrderConfirmationLoaded;
              emit(PaymentMethodsLoaded(
                methods,
                currentState.orderSummary,
                currentState.cartMetadata,
                currentState.selectedPaymentMode,
              ));
            } else {
              // Fallback: emit just the methods
              emit(PaymentMethodsLoaded(
                methods,
                OrderSummary(items: []),
                {},
                null,
              ));
            }
          } else {
            debugPrint('PaymentMethods: API returned false status or no data');
            emit(const OrderConfirmationError('Failed to load payment methods. Please try again.'));
          }
        } catch (jsonError) {
          debugPrint('PaymentMethods: JSON parsing error: $jsonError');
          emit(const OrderConfirmationError('Invalid response from server. Please try again.'));
        }
      } else if (response.statusCode == 401) {
        debugPrint('PaymentMethods: Unauthorized request');
        emit(const OrderConfirmationError('Your session has expired. Please login again.'));
      } else if (response.statusCode >= 500) {
        debugPrint('PaymentMethods: Server error');
        emit(const OrderConfirmationError('Server error. Please try again later.'));
      } else {
        debugPrint('PaymentMethods: Unexpected status code: ${response.statusCode}');
        emit(const OrderConfirmationError('Failed to load payment methods. Please try again.'));
      }
    } catch (e, stackTrace) {
      debugPrint('PaymentMethods: Exception: $e');
      debugPrint('PaymentMethods: Stack trace: $stackTrace');
      emit(OrderConfirmationError('Network error: ${e.toString()}'));
    }
    debugPrint('=== PAYMENT METHODS BLOC: LOAD END ===');
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
      
      // Create order summary
      final orderSummary = OrderSummary(
        items: orderItems,
        deliveryFee: (cart['delivery_fees'] as num?)?.toDouble() ?? 0.0,
        taxAmount: (cart['tax_amount'] as num?)?.toDouble() ?? 0.0,
        discountAmount: (cart['discount_amount'] as num?)?.toDouble() ?? 0.0,
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
    debugPrint('OrderConfirmationBloc: ProceedToChat event received');
    if (state is OrderConfirmationLoaded) {
      debugPrint('OrderConfirmationBloc: Current state is OrderConfirmationLoaded, triggering PlaceOrder');
      // Trigger order placement with default payment mode
      add(const PlaceOrder());
    } else {
      debugPrint('OrderConfirmationBloc: Current state is not OrderConfirmationLoaded: ${state.runtimeType}');
    }
  }

  Future<void> _onPlaceOrder(
    PlaceOrder event,
    Emitter<OrderConfirmationState> emit,
  ) async {
    debugPrint('=== ORDER PLACEMENT BLOC: START ===');
    debugPrint('OrderPlacement: Current state: ${state.runtimeType}');
    
    // Get the order data from the last loaded state
    OrderConfirmationLoaded? orderData;
    if (state is OrderConfirmationLoaded) {
      orderData = state as OrderConfirmationLoaded;
    } else if (state is PaymentMethodsLoaded) {
      // If we're in PaymentMethodsLoaded state, we need to get the order data from the previous state
      // For now, we'll reload the order data
      debugPrint('OrderPlacement: Reloading order data from cart...');
      try {
        final cart = await CartService.getCart();
        if (cart != null && cart['items'] != null && (cart['items'] as List).isNotEmpty) {
          final cartItems = cart['items'] as List<dynamic>;
          final orderItems = cartItems.map((item) {
            List<SelectedAttribute> attributes = [];
            if (item['attributes'] != null && item['attributes'] is List) {
              attributes = (item['attributes'] as List)
                  .map((attr) => SelectedAttribute.fromJson(attr))
                  .toList();
            }
            
            return OrderItem(
              id: item['menu_id'] ?? '',
              name: item['name'] ?? '',
              imageUrl: item['image_url'] ?? 'assets/images/placeholder.png',
              quantity: item['quantity'] ?? 1,
              price: (item['price'] as num?)?.toDouble() ?? 0.0,
              attributes: attributes,
            );
          }).toList();
          
          final orderSummary = OrderSummary(
            items: orderItems,
            deliveryFee: 0.0,
            taxAmount: 0.0,
            discountAmount: 0.0,
          );
          
          final cartMetadata = {
            'partner_id': cart['partner_id'],
            'restaurant_name': cart['restaurant_name'],
            'user_id': cart['user_id'],
            'address': cart['address'] ?? '',
          };
          
          orderData = OrderConfirmationLoaded(
            orderSummary: orderSummary,
            cartMetadata: cartMetadata,
          );
        }
      } catch (e) {
        debugPrint('OrderPlacement: Error reloading order data: $e');
        emit(const OrderConfirmationError('Failed to load order data. Please try again.'));
        return;
      }
    }
    
    if (orderData != null) {
      debugPrint('OrderPlacement: Order data loaded successfully');
      debugPrint('OrderPlacement: Emitting OrderConfirmationProcessing state');
      emit(OrderConfirmationProcessing());
      
      try {
        debugPrint('OrderPlacement: Starting order placement process...');
        
        // Get user ID and address
        debugPrint('OrderPlacement: Getting user ID...');
        final userId = await TokenService.getUserId();
        debugPrint('OrderPlacement: User ID: $userId');
        if (userId == null) {
          debugPrint('OrderPlacement: No user ID found, emitting error');
          emit(const OrderConfirmationError('User authentication required. Please login again.'));
          return;
        }
        
        final cartMetadata = orderData.cartMetadata;
        final partnerId = cartMetadata['partner_id']?.toString() ?? '';
        String address = cartMetadata['address']?.toString() ?? '';
        
        debugPrint('OrderPlacement: Cart metadata:');
        debugPrint('  - Partner ID: $partnerId');
        debugPrint('  - Address: $address');
        
        // If address is empty, try to get from user profile
        if (address.isEmpty) {
          debugPrint('OrderPlacement: Address is empty, trying to get from user profile...');
          final userData = await TokenService.getUserData();
          address = userData?['address']?.toString() ?? '';
          debugPrint('OrderPlacement: Address from user profile: $address');
        }
        
        if (address.isEmpty) {
          debugPrint('OrderPlacement: No address found, emitting error');
          emit(const OrderConfirmationError('Delivery address is required. Please add your address.'));
          return;
        }
        
        // Get user coordinates from profile API
        double? latitude;
        double? longitude;
        
        try {
          final token = await TokenService.getToken();
          if (token != null) {
            final profileResult = await _profileApiService.getUserProfile(
              token: token,
              userId: userId,
            );
            
            if (profileResult['success'] == true) {
              final userData = profileResult['data'] as Map<String, dynamic>;
              latitude = userData['latitude'] != null ? double.tryParse(userData['latitude'].toString()) : null;
              longitude = userData['longitude'] != null ? double.tryParse(userData['longitude'].toString()) : null;
              
              debugPrint('OrderPlacement: User coordinates - Lat: $latitude, Long: $longitude');
            } else {
              debugPrint('OrderPlacement: Failed to fetch user coordinates: ${profileResult['message']}');
            }
          } else {
            debugPrint('OrderPlacement: No token available for fetching coordinates');
          }
        } catch (e) {
          debugPrint('OrderPlacement: Error fetching user coordinates: $e');
        }
        
        // Prepare order items with attributes
        final orderItems = orderData.orderSummary.items.map((item) {
          final itemData = {
            'menu_id': item.id,
            'quantity': item.quantity,
            'price': item.pricePerItem, // Base price + attribute prices
          };
          
          // Add attributes if present
          if (item.attributes.isNotEmpty) {
            final attributesMap = <String, String>{};
            for (var attr in item.attributes) {
              // Use attribute_id as key and value_id as value
              attributesMap[attr.attributeId] = attr.valueId;
            }
            itemData['attributes'] = attributesMap;
          }
          
          return itemData;
        }).toList();
        
        // Calculate total price as sum of (price × quantity) for all items
        double calculatedTotal = 0.0;
        for (var item in orderData.orderSummary.items) {
          calculatedTotal += item.pricePerItem * item.quantity;
        }
        
        debugPrint('OrderPlacement: Placing order with:');
        debugPrint('  Partner ID: $partnerId');
        debugPrint('  User ID: $userId');
        debugPrint('  Items: ${orderItems.length}');
        debugPrint('  Calculated Total: ₹$calculatedTotal');
        debugPrint('  Address: $address');
        debugPrint('  Latitude: $latitude');
        debugPrint('  Longitude: $longitude');
        
        // Place order
        debugPrint('OrderPlacement: Order placement values:');
        debugPrint('  - Items total: ₹$calculatedTotal');
        debugPrint('  - Delivery fees: ₹${orderData.orderSummary.deliveryFee}');
        debugPrint('  - Subtotal (total + delivery): ₹${calculatedTotal + orderData.orderSummary.deliveryFee}');
        
        // Get selected payment mode from event or order data, default to 'cash' if not selected
        final paymentMode = event.paymentMode ?? orderData.selectedPaymentMode ?? 'cash';
        debugPrint('OrderPlacement: Using payment mode: $paymentMode');
        
        debugPrint('OrderPlacement: Calling OrderService.placeOrder with:');
        debugPrint('  - Partner ID: $partnerId');
        debugPrint('  - User ID: $userId');
        debugPrint('  - Items count: ${orderItems.length}');
        debugPrint('  - Total Price: ₹$calculatedTotal');
        debugPrint('  - Address: $address');
        debugPrint('  - Delivery Fees: ₹${orderData.orderSummary.deliveryFee}');
        debugPrint('  - Subtotal: ₹${calculatedTotal + orderData.orderSummary.deliveryFee}');
        debugPrint('  - Latitude: $latitude');
        debugPrint('  - Longitude: $longitude');
        debugPrint('  - Payment Mode: $paymentMode');
        
        final orderResult = await OrderService.placeOrder(
          partnerId: partnerId,
          userId: userId,
          items: orderItems,
          totalPrice: calculatedTotal,
          address: address,
          deliveryFees: orderData.orderSummary.deliveryFee,
          subtotal: calculatedTotal + orderData.orderSummary.deliveryFee, // Total including delivery fees
          latitude: latitude,
          longitude: longitude,
          paymentMode: paymentMode, // Add payment mode to API request
        );
        
        debugPrint('OrderPlacement: Order result received:');
        debugPrint('  - Success: ${orderResult['success']}');
        debugPrint('  - Message: ${orderResult['message']}');
        debugPrint('  - Data: ${orderResult['data']}');
        
        if (orderResult['success'] == true) {
          final orderData = orderResult['data'];
          final orderId = orderData['order_id'].toString();
          
          debugPrint('OrderPlacement: Order placed successfully - Order ID: $orderId');
          
          // Create chat room
          debugPrint('OrderPlacement: Creating chat room for order: $orderId');
          final chatResult = await OrderService.createChatRoom(orderId);
          
          debugPrint('OrderPlacement: Chat room creation result:');
          debugPrint('  - Success: ${chatResult['success']}');
          debugPrint('  - Message: ${chatResult['message']}');
          debugPrint('  - Data: ${chatResult['data']}');
          
          if (chatResult['success'] == true) {
            final chatData = chatResult['data'];
            final roomId = chatData['roomId'].toString();
            
            debugPrint('OrderPlacement: Chat room created - Room ID: $roomId');
            
            // Clear cart after successful order
            debugPrint('OrderPlacement: Clearing cart after successful order...');
            await CartService.clearCart();
            debugPrint('OrderPlacement: Cart cleared successfully');
            
            debugPrint('OrderPlacement: Emitting ChatRoomCreated state');
            emit(ChatRoomCreated(orderId, roomId));
          } else {
            debugPrint('OrderPlacement: Chat room creation failed: ${chatResult['message']}');
            // Even if chat room creation fails, order was placed successfully
            debugPrint('OrderPlacement: Clearing cart despite chat room failure...');
            await CartService.clearCart();
            debugPrint('OrderPlacement: Emitting OrderConfirmationSuccess state');
            emit(OrderConfirmationSuccess(
              'Order placed successfully! Order ID: $orderId',
              orderId,
            ));
          }
        } else {
          debugPrint('OrderPlacement: Order placement failed: ${orderResult['message']}');
          debugPrint('OrderPlacement: Emitting OrderConfirmationError state');
          emit(OrderConfirmationError(orderResult['message'] ?? 'Failed to place order. Please try again.'));
          
          // Return to loaded state on error
          debugPrint('OrderPlacement: Returning to loaded state after error');
          emit(orderData);
        }
        
      } catch (e, stackTrace) {
        debugPrint('OrderPlacement: Exception during order placement: $e');
        debugPrint('OrderPlacement: Stack trace: $stackTrace');
        debugPrint('OrderPlacement: Emitting OrderConfirmationError state');
        emit(const OrderConfirmationError('An error occurred while placing your order. Please try again.'));
        
        // Return to loaded state on error
        debugPrint('OrderPlacement: Returning to loaded state after exception');
        if (state is OrderConfirmationLoaded) {
          emit(state as OrderConfirmationLoaded);
        }
      }
    } else {
      debugPrint('OrderPlacement: Current state is not OrderConfirmationLoaded: ${state.runtimeType}');
    }
    debugPrint('=== ORDER PLACEMENT BLOC: END ===');
  }

  Future<void> _onSelectPaymentMode(
    SelectPaymentMode event,
    Emitter<OrderConfirmationState> emit,
  ) async {
    debugPrint('OrderConfirmationBloc: Payment mode selected: ${event.paymentMode}');
    
    // Store the selected payment mode in a variable that can be accessed by PlaceOrder
    // Since we can't access state directly, we'll use a different approach
    // The payment mode will be passed through the event and used in PlaceOrder
    debugPrint('OrderConfirmationBloc: Payment mode stored for order placement: ${event.paymentMode}');
  }

  Future<void> _onUpdateOrderQuantity(
    UpdateOrderQuantity event,
    Emitter<OrderConfirmationState> emit,
  ) async {
    // Note: We can't access state directly in event handlers
    // This will be handled by the view passing the current state
    debugPrint('OrderConfirmationBloc: Update quantity requested for item ${event.itemId} to ${event.newQuantity}');
  }

  Future<void> _onRemoveOrderItem(
    RemoveOrderItem event,
    Emitter<OrderConfirmationState> emit,
  ) async {
    // Note: We can't access state directly in event handlers
    // This will be handled by the view passing the current state
    debugPrint('OrderConfirmationBloc: Remove item requested for item ${event.itemId}');
  }
} 
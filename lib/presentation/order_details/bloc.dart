// lib/presentation/order_details/bloc.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import '../../constants/api_constant.dart';
import '../../service/token_service.dart';
import '../../service/order_history_service.dart';
import 'event.dart';
import 'state.dart';

class OrderDetailsBloc extends Bloc<OrderDetailsEvent, OrderDetailsState> {
  OrderDetailsBloc() : super(OrderDetailsInitial()) {
    debugPrint('OrderDetailsBloc: Constructor called');
    on<LoadOrderDetails>(_onLoadOrderDetails);
    on<LoadMenuItemDetails>(_onLoadMenuItemDetails);
    debugPrint('OrderDetailsBloc: Event handlers registered');
  }

  Future<void> _onLoadOrderDetails(
    LoadOrderDetails event,
    Emitter<OrderDetailsState> emit,
  ) async {
    emit(OrderDetailsLoading());

    try {
      debugPrint('OrderDetailsBloc: Loading order details for: ${event.orderId}');

      // Get order details from service
      final result = await OrderHistoryService.getOrderDetails(event.orderId);

      if (result['success'] == true && result['data'] != null) {
        // Handle the new payload structure
        final responseData = result['data'] as Map<String, dynamic>;
        
        // Check if the response has the expected structure with 'data' field
        Map<String, dynamic> orderDetails;
        if (responseData.containsKey('status') && responseData.containsKey('data')) {
          // New payload structure: {"status": "SUCCESS", "message": "...", "data": {...}}
          if (responseData['status'] == 'SUCCESS' && responseData['data'] != null) {
            orderDetails = responseData['data'] as Map<String, dynamic>;
          } else {
            debugPrint('OrderDetailsBloc: API returned non-success status: ${responseData['status']}');
            emit(OrderDetailsError(responseData['message'] ?? 'Failed to load order details'));
            return;
          }
        } else {
          // Legacy payload structure or direct data
          orderDetails = responseData;
        }
        
        debugPrint('OrderDetailsBloc: Order details loaded successfully');
        debugPrint('OrderDetailsBloc: Order payload: ${json.encode(orderDetails)}');

        // Initialize empty menu item details map
        Map<String, MenuItemDetail> menuItemDetails = {};

        // Load menu item details for each item in the order
        final items = orderDetails['items'] as List<dynamic>? ?? [];
        
        for (final item in items) {
          final menuId = item['menu_id'] as String?;
          if (menuId != null && menuId.isNotEmpty) {
            debugPrint('OrderDetailsBloc: Loading menu item details for: $menuId');
            final menuItemResult = await _fetchMenuItemDetails(menuId);
            if (menuItemResult != null) {
              menuItemDetails[menuId] = menuItemResult;
            }
          }
        }

        emit(OrderDetailsLoaded(
          orderDetails: orderDetails,
          menuItemDetails: menuItemDetails,
        ));
      } else {
        debugPrint('OrderDetailsBloc: Failed to load order details: ${result['message']}');
        emit(OrderDetailsError(result['message'] ?? 'Failed to load order details'));
      }
    } catch (e, stackTrace) {
      debugPrint('OrderDetailsBloc: Error loading order details: $e');
      debugPrint('OrderDetailsBloc: Stack trace: $stackTrace');
      emit(OrderDetailsError('An error occurred while loading order details'));
    }
  }

  Future<void> _onLoadMenuItemDetails(
    LoadMenuItemDetails event,
    Emitter<OrderDetailsState> emit,
  ) async {
    if (state is OrderDetailsLoaded) {
      final currentState = state as OrderDetailsLoaded;

      try {
        debugPrint('OrderDetailsBloc: Loading menu item details for: ${event.menuId}');

        final menuItemDetail = await _fetchMenuItemDetails(event.menuId);

        if (menuItemDetail != null) {
          final updatedMenuItemDetails = Map<String, MenuItemDetail>.from(
            currentState.menuItemDetails,
          );
          updatedMenuItemDetails[event.menuId] = menuItemDetail;

          emit(currentState.copyWith(
            menuItemDetails: updatedMenuItemDetails,
          ));
        }
      } catch (e) {
        debugPrint('OrderDetailsBloc: Error loading menu item details: $e');
        // Don't emit error, just keep current state
      }
    }
  }

  Future<MenuItemDetail?> _fetchMenuItemDetails(String menuId) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        debugPrint('OrderDetailsBloc: No authentication token available');
        return null;
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/api/partner/menu_item/$menuId');
      
      debugPrint('OrderDetailsBloc: Fetching menu item from: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('OrderDetailsBloc: Menu item API response status: ${response.statusCode}');
      debugPrint('OrderDetailsBloc: Menu item API response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['status'] == 'SUCCESS' && responseData['data'] != null) {
          debugPrint('OrderDetailsBloc: Menu item details fetched successfully');
          return MenuItemDetail.fromJson(responseData['data']);
        } else {
          debugPrint('OrderDetailsBloc: Menu item API returned non-success status');
          return null;
        }
      } else {
        debugPrint('OrderDetailsBloc: Menu item API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('OrderDetailsBloc: Error fetching menu item details: $e');
      return null;
    }
  }
}
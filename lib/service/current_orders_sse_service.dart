import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../constants/api_constant.dart';

class CurrentOrder {
  final String orderId;
  final String orderStatus;
  final String totalPrice;
  final String address;
  final double? latitude;
  final double? longitude;
  final String createdAt;
  final String updatedAt;
  final String paymentMode;
  final String supercategory;
  final String? deliveryPartnerId;
  final String restaurantName;
  final String restaurantMobile;

  CurrentOrder({
    required this.orderId,
    required this.orderStatus,
    required this.totalPrice,
    required this.address,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
    required this.paymentMode,
    required this.supercategory,
    this.deliveryPartnerId,
    required this.restaurantName,
    required this.restaurantMobile,
  });

  factory CurrentOrder.fromJson(Map<String, dynamic> json) {
    double? _toDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value);
        return parsed;
      }
      return null;
    }
    return CurrentOrder(
      orderId: json['order_id'] ?? '',
      orderStatus: json['order_status'] ?? '',
      totalPrice: json['total_price'] ?? '',
      address: json['address'] ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
      paymentMode: json['payment_mode'] ?? '',
      supercategory: json['supercategory'] ?? '',
      deliveryPartnerId: json['delivery_partner_id'],
      restaurantName: json['restaurant_name'] ?? '',
      restaurantMobile: json['restaurant_mobile'] ?? '',
    );
  }
}

class CurrentOrdersUpdate {
  final String type;
  final String userId;
  final bool hasCurrentOrders;
  final int ordersCount;
  final List<CurrentOrder> orders;
  final String timestamp;

  CurrentOrdersUpdate({
    required this.type,
    required this.userId,
    required this.hasCurrentOrders,
    required this.ordersCount,
    required this.orders,
    required this.timestamp,
  });

  factory CurrentOrdersUpdate.fromJson(Map<String, dynamic> json) {
    return CurrentOrdersUpdate(
      type: json['type'] ?? '',
      userId: json['user_id'] ?? '',
      hasCurrentOrders: json['has_current_orders'] ?? false,
      ordersCount: json['orders_count'] ?? 0,
      orders: (json['orders'] as List<dynamic>?)
          ?.map((order) => CurrentOrder.fromJson(order))
          .toList() ?? [],
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class CurrentOrdersSSEService {
  static const String _baseUrl = ApiConstants.baseUrl;
  StreamSubscription? _subscription;
  final StreamController<CurrentOrdersUpdate> _ordersController = StreamController<CurrentOrdersUpdate>.broadcast();
  bool _isConnected = false;

  Stream<CurrentOrdersUpdate> get ordersStream => _ordersController.stream;
  bool get isConnected => _isConnected;

  Future<void> connect(String token) async {
    debugPrint('🔗 CurrentOrdersSSEService: Attempting to connect to SSE stream');
    debugPrint('🔗 CurrentOrdersSSEService: Base URL: $_baseUrl');
    debugPrint('🔗 CurrentOrdersSSEService: Token provided: ${token.isNotEmpty ? 'Yes (${token.length} chars)' : 'No'}');
    
    if (_isConnected) {
      debugPrint('🔗 CurrentOrdersSSEService: Already connected, disconnecting first');
      await disconnect();
    }

    try {
      final url = ApiConstants.currentOrdersSSEUrl;
      debugPrint('🔗 CurrentOrdersSSEService: Connecting to URL: $url');
      
      final request = http.Request('GET', Uri.parse(url));
      
      // Add headers with debug logging
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
      };
      
      debugPrint('🔗 CurrentOrdersSSEService: Request headers:');
      headers.forEach((key, value) {
        if (key == 'Authorization') {
          debugPrint('  $key: Bearer ${token.substring(0, 10)}...${token.substring(token.length - 5)}');
        } else {
          debugPrint('  $key: $value');
        }
      });
      
      request.headers.addAll(headers);

      debugPrint('🔗 CurrentOrdersSSEService: Sending request...');
      final response = await http.Client().send(request);
      
      debugPrint('🔗 CurrentOrdersSSEService: Response status: ${response.statusCode}');
      debugPrint('🔗 CurrentOrdersSSEService: Response headers: ${response.headers}');
      
      if (response.statusCode == 200) {
        debugPrint('🔗 CurrentOrdersSSEService: Successfully connected to SSE stream');
        _isConnected = true;
        
        _subscription = response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(
              (String line) {
                debugPrint('📨 CurrentOrdersSSEService: Received SSE line: ${line.length} chars');
                if (line.isNotEmpty) {
                  debugPrint('📨 CurrentOrdersSSEService: Line content: $line');
                }
                _handleSSEMessage(line);
              },
              onError: (error) {
                debugPrint('❌ CurrentOrdersSSEService: SSE stream error: $error');
                _isConnected = false;
                _ordersController.addError(error);
              },
              onDone: () {
                debugPrint('🔗 CurrentOrdersSSEService: SSE stream closed');
                _isConnected = false;
              },
            );
            
        debugPrint('🔗 CurrentOrdersSSEService: SSE subscription created successfully');
      } else {
        final errorMsg = 'Failed to connect to SSE stream: ${response.statusCode}';
        debugPrint('❌ CurrentOrdersSSEService: $errorMsg');
        
        // Try to read response body for more details
        try {
          final responseBody = await response.stream.bytesToString();
          debugPrint('❌ CurrentOrdersSSEService: Response body: $responseBody');
        } catch (e) {
          debugPrint('❌ CurrentOrdersSSEService: Could not read response body: $e');
        }
        
        // Throw exception instead of using mock data
        throw Exception('SSE connection failed with status ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ CurrentOrdersSSEService: Connection error: $e');
      // Re-throw the exception instead of using mock data
      rethrow;
    }
  }



  void _handleSSEMessage(String line) {
    debugPrint('🔍 CurrentOrdersSSEService: Processing SSE line: ${line.length} chars');
    
    if (line.startsWith('data: ')) {
      final jsonData = line.substring(6); // Remove 'data: ' prefix
      debugPrint('🔍 CurrentOrdersSSEService: Extracted JSON data: ${jsonData.length} chars');
      debugPrint('🔍 CurrentOrdersSSEService: Raw JSON data: $jsonData');
      
      try {
        final Map<String, dynamic> data = json.decode(jsonData);
        debugPrint('🔍 CurrentOrdersSSEService: Successfully parsed JSON');
        debugPrint('🔍 CurrentOrdersSSEService: JSON keys: ${data.keys.toList()}');
        
        // Ignore non-order events like heartbeats
        if ((data['type'] as String?) != 'current_orders_update') {
          debugPrint('🔍 CurrentOrdersSSEService: Ignoring non-order event type: ${data['type']}');
          return;
        }
        
        final update = CurrentOrdersUpdate.fromJson(data);
        debugPrint('🔍 CurrentOrdersSSEService: Created CurrentOrdersUpdate object');
        debugPrint('🔍 CurrentOrdersSSEService: hasCurrentOrders: ${update.hasCurrentOrders}');
        debugPrint('🔍 CurrentOrdersSSEService: ordersCount: ${update.ordersCount}');
        debugPrint('🔍 CurrentOrdersSSEService: orders.length: ${update.orders.length}');
        
        // Debug print each order details from real SSE response
        for (int i = 0; i < update.orders.length; i++) {
          final order = update.orders[i];
          debugPrint('🔍 CurrentOrdersSSEService: Real SSE Order ${i + 1}:');
          debugPrint('  📋 Order ID: ${order.orderId}');
          debugPrint('  📊 Status: ${order.orderStatus}');
          debugPrint('  💰 Total Price: ${order.totalPrice}');
          debugPrint('  🏪 Restaurant: ${order.restaurantName}');
          debugPrint('  💳 Payment Mode: ${order.paymentMode}');
          debugPrint('  📍 Address: ${order.address}');
          debugPrint('  🚚 Delivery Partner: ${order.deliveryPartnerId ?? 'Not assigned'}');
          debugPrint('  📅 Created: ${order.createdAt}');
          debugPrint('  🔄 Updated: ${order.updatedAt}');
        }
        
        _ordersController.add(update);
        debugPrint('🔍 CurrentOrdersSSEService: Added update to stream controller');
      } catch (e) {
        debugPrint('❌ CurrentOrdersSSEService: Error parsing SSE message: $e');
        debugPrint('❌ CurrentOrdersSSEService: Raw JSON data: $jsonData');
      }
    } else if (line.isNotEmpty) {
      debugPrint('🔍 CurrentOrdersSSEService: Non-data line received: $line');
    }
  }

  Future<void> disconnect() async {
    debugPrint('🔗 CurrentOrdersSSEService: Disconnecting from SSE stream');
    _isConnected = false;
    await _subscription?.cancel();
    _subscription = null;
    debugPrint('🔗 CurrentOrdersSSEService: Disconnected successfully');
  }

  void dispose() {
    debugPrint('🔗 CurrentOrdersSSEService: Disposing SSE service');
    disconnect();
    _ordersController.close();
    debugPrint('🔗 CurrentOrdersSSEService: SSE service disposed');
  }
} 
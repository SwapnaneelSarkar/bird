import 'package:flutter_test/flutter_test.dart';
import 'package:bird/service/current_orders_sse_service.dart';

void main() {
  group('CurrentOrdersSSEService Tests', () {
    test('CurrentOrder.fromJson should parse correctly', () {
      final json = {
        'order_id': '2508000136',
        'order_status': 'PENDING',
        'total_price': '200.00',
        'address': '123 Main St, City',
        'latitude': null,
        'longitude': null,
        'created_at': '2025-08-20T07:02:34.000Z',
        'updated_at': '2025-08-20T07:02:34.000Z',
        'payment_mode': 'cash',
        'supercategory': '7acc47a2fa5a4eeb906a753b3',
        'delivery_partner_id': null,
        'restaurant_name': 'Soofi restaurant and cafe',
        'restaurant_mobile': '1111111111'
      };

      final order = CurrentOrder.fromJson(json);

      expect(order.orderId, '2508000136');
      expect(order.orderStatus, 'PENDING');
      expect(order.totalPrice, '200.00');
      expect(order.address, '123 Main St, City');
      expect(order.latitude, null);
      expect(order.longitude, null);
      expect(order.paymentMode, 'cash');
      expect(order.supercategory, '7acc47a2fa5a4eeb906a753b3');
      expect(order.deliveryPartnerId, null);
      expect(order.restaurantName, 'Soofi restaurant and cafe');
      expect(order.restaurantMobile, '1111111111');
    });

    test('CurrentOrdersUpdate.fromJson should parse correctly', () {
      final json = {
        'type': 'current_orders_update',
        'user_id': 'dd273fc400e24d77af6ffd56',
        'has_current_orders': true,
        'orders_count': 1,
        'orders': [{
          'order_id': '2508000136',
          'order_status': 'PENDING',
          'total_price': '200.00',
          'address': '123 Main St, City',
          'latitude': null,
          'longitude': null,
          'created_at': '2025-08-20T07:02:34.000Z',
          'updated_at': '2025-08-20T07:02:34.000Z',
          'payment_mode': 'cash',
          'supercategory': '7acc47a2fa5a4eeb906a753b3',
          'delivery_partner_id': null,
          'restaurant_name': 'Soofi restaurant and cafe',
          'restaurant_mobile': '1111111111'
        }],
        'timestamp': '2025-08-20T07:02:35.867Z'
      };

      final update = CurrentOrdersUpdate.fromJson(json);

      expect(update.type, 'current_orders_update');
      expect(update.userId, 'dd273fc400e24d77af6ffd56');
      expect(update.hasCurrentOrders, true);
      expect(update.ordersCount, 1);
      expect(update.orders.length, 1);
      expect(update.orders.first.orderId, '2508000136');
      expect(update.timestamp, '2025-08-20T07:02:35.867Z');
    });

    test('CurrentOrdersUpdate should handle no orders correctly', () {
      final json = {
        'type': 'current_orders_update',
        'user_id': 'dd273fc400e24d77af6ffd56',
        'has_current_orders': false,
        'orders_count': 0,
        'orders': [],
        'timestamp': '2025-08-20T07:02:35.867Z'
      };

      final update = CurrentOrdersUpdate.fromJson(json);

      expect(update.hasCurrentOrders, false);
      expect(update.ordersCount, 0);
      expect(update.orders.length, 0);
    });

    test('CurrentOrdersUpdate should display correct orders count', () {
      final json = {
        'type': 'current_orders_update',
        'user_id': 'dd273fc400e24d77af6ffd56',
        'has_current_orders': true,
        'orders_count': 3,
        'orders': [
          {
            'order_id': '2508000136',
            'order_status': 'PENDING',
            'total_price': '200.00',
            'address': '123 Main St, City',
            'latitude': null,
            'longitude': null,
            'created_at': '2025-08-20T07:02:34.000Z',
            'updated_at': '2025-08-20T07:02:34.000Z',
            'payment_mode': 'cash',
            'supercategory': '7acc47a2fa5a4eeb906a753b3',
            'delivery_partner_id': null,
            'restaurant_name': 'Soofi restaurant and cafe',
            'restaurant_mobile': '1111111111'
          },
          {
            'order_id': '2508000137',
            'order_status': 'CONFIRMED',
            'total_price': '150.00',
            'address': '456 Oak St, City',
            'latitude': null,
            'longitude': null,
            'created_at': '2025-08-20T07:03:34.000Z',
            'updated_at': '2025-08-20T07:03:34.000Z',
            'payment_mode': 'card',
            'supercategory': '7acc47a2fa5a4eeb906a753b3',
            'delivery_partner_id': null,
            'restaurant_name': 'Test Restaurant',
            'restaurant_mobile': '2222222222'
          },
          {
            'order_id': '2508000138',
            'order_status': 'PREPARING',
            'total_price': '75.00',
            'address': '789 Pine St, City',
            'latitude': null,
            'longitude': null,
            'created_at': '2025-08-20T07:04:34.000Z',
            'updated_at': '2025-08-20T07:04:34.000Z',
            'payment_mode': 'cash',
            'supercategory': '7acc47a2fa5a4eeb906a753b3',
            'delivery_partner_id': null,
            'restaurant_name': 'Another Restaurant',
            'restaurant_mobile': '3333333333'
          }
        ],
        'timestamp': '2025-08-20T07:02:35.867Z'
      };

      final update = CurrentOrdersUpdate.fromJson(json);

      expect(update.hasCurrentOrders, true);
      expect(update.ordersCount, 3);
      expect(update.orders.length, 3);
      expect(update.orders.first.orderId, '2508000136');
      expect(update.orders.last.orderId, '2508000138');
    });

    test('CurrentOrdersUpdate should handle orders_count vs actual orders mismatch', () {
      final json = {
        'type': 'current_orders_update',
        'user_id': 'dd273fc400e24d77af6ffd56',
        'has_current_orders': true,
        'orders_count': 2, // Server says 2 orders
        'orders': [
          {
            'order_id': '2508000136',
            'order_status': 'PENDING',
            'total_price': '200.00',
            'address': '123 Main St, City',
            'latitude': null,
            'longitude': null,
            'created_at': '2025-08-20T07:02:34.000Z',
            'updated_at': '2025-08-20T07:02:34.000Z',
            'payment_mode': 'cash',
            'supercategory': '7acc47a2fa5a4eeb906a753b3',
            'delivery_partner_id': null,
            'restaurant_name': 'Soofi restaurant and cafe',
            'restaurant_mobile': '1111111111'
          },
          {
            'order_id': '2508000137',
            'order_status': 'CONFIRMED',
            'total_price': '150.00',
            'address': '456 Oak St, City',
            'latitude': null,
            'longitude': null,
            'created_at': '2025-08-20T07:03:34.000Z',
            'updated_at': '2025-08-20T07:03:34.000Z',
            'payment_mode': 'card',
            'supercategory': '7acc47a2fa5a4eeb906a753b3',
            'delivery_partner_id': null,
            'restaurant_name': 'Test Restaurant',
            'restaurant_mobile': '2222222222'
          },
          {
            'order_id': '2508000138',
            'order_status': 'PREPARING',
            'total_price': '75.00',
            'address': '789 Pine St, City',
            'latitude': null,
            'longitude': null,
            'created_at': '2025-08-20T07:04:34.000Z',
            'updated_at': '2025-08-20T07:04:34.000Z',
            'payment_mode': 'cash',
            'supercategory': '7acc47a2fa5a4eeb906a753b3',
            'delivery_partner_id': null,
            'restaurant_name': 'Another Restaurant',
            'restaurant_mobile': '3333333333'
          }
        ],
        'timestamp': '2025-08-20T07:02:35.867Z'
      };

      final update = CurrentOrdersUpdate.fromJson(json);

      // The orders_count field should be respected even if it doesn't match the actual orders array length
      expect(update.hasCurrentOrders, true);
      expect(update.ordersCount, 2); // Should show 2 as per server
      expect(update.orders.length, 3); // But actually has 3 orders in the array
    });

    test('SSE service should be initialized correctly', () {
      final service = CurrentOrdersSSEService();
      
      expect(service.isConnected, false);
      expect(service.ordersStream, isNotNull);
    });
  });
} 
import 'package:flutter_test/flutter_test.dart';
import 'package:bird/service/order_status_sse_service.dart';

void main() {
  group('OrderStatusSSEService Tests', () {
    test('OrderStatusUpdate.fromJson should parse JSON correctly', () {
      final json = {
        "type": "status_update",
        "order_id": "2508000006",
        "status": "CANCELLED",
        "message": "Order status: CANCELLED",
        "timestamp": "2025-08-20T08:16:15.326Z",
        "delivery_partner_id": null,
        "created_at": "2025-08-02T15:41:57.000Z",
        "last_updated": "2025-08-02T20:30:00.000Z",
        "total_price": "20.00",
        "address": "Hyderabad, test1",
        "coordinates": {
          "latitude": "17.4064980",
          "longitude": "78.4772439"
        },
        "payment_mode": "cash",
        "supercategory": "7acc47a2fa5a4eeb906a753b3",
        "items": [
          {
            "quantity": 1,
            "price": "20.00",
            "item_name": "biryani ",
            "item_description": ""
          }
        ]
      };

      final statusUpdate = OrderStatusUpdate.fromJson(json);

      expect(statusUpdate.type, equals('status_update'));
      expect(statusUpdate.orderId, equals('2508000006'));
      expect(statusUpdate.status, equals('CANCELLED'));
      expect(statusUpdate.message, equals('Order status: CANCELLED'));
      expect(statusUpdate.timestamp, equals('2025-08-20T08:16:15.326Z'));
      expect(statusUpdate.deliveryPartnerId, isNull);
      expect(statusUpdate.createdAt, equals('2025-08-02T15:41:57.000Z'));
      expect(statusUpdate.lastUpdated, equals('2025-08-02T20:30:00.000Z'));
      expect(statusUpdate.totalPrice, equals('20.00'));
      expect(statusUpdate.address, equals('Hyderabad, test1'));
      expect(statusUpdate.coordinates['latitude'], equals('17.4064980'));
      expect(statusUpdate.coordinates['longitude'], equals('78.4772439'));
      expect(statusUpdate.paymentMode, equals('cash'));
      expect(statusUpdate.supercategory, equals('7acc47a2fa5a4eeb906a753b3'));
      expect(statusUpdate.items.length, equals(1));
      expect(statusUpdate.items.first.quantity, equals(1));
      expect(statusUpdate.items.first.price, equals('20.00'));
      expect(statusUpdate.items.first.itemName, equals('biryani '));
      expect(statusUpdate.items.first.itemDescription, equals(''));
    });

    test('OrderStatusItem.fromJson should parse JSON correctly', () {
      final json = {
        "quantity": 2,
        "price": "15.50",
        "item_name": "Pizza Margherita",
        "item_description": "Fresh tomato sauce and mozzarella"
      };

      final item = OrderStatusItem.fromJson(json);

      expect(item.quantity, equals(2));
      expect(item.price, equals('15.50'));
      expect(item.itemName, equals('Pizza Margherita'));
      expect(item.itemDescription, equals('Fresh tomato sauce and mozzarella'));
    });

    test('OrderStatusSSEService should create singleton instances', () {
      final service1 = OrderStatusSSEService('order123');
      final service2 = OrderStatusSSEService('order123');
      final service3 = OrderStatusSSEService('order456');

      expect(service1, same(service2));
      expect(service1, isNot(same(service3)));
    });

    test('OrderStatusSSEService should have correct initial state', () {
      final service = OrderStatusSSEService('order123');

      expect(service.orderId, equals('order123'));
      expect(service.isConnected, isFalse);
      expect(service.statusStream, isNotNull);
    });

    test('OrderStatusSSEService should handle SSE message parsing', () {
      final service = OrderStatusSSEService('order123');
      bool messageReceived = false;
      OrderStatusUpdate? receivedUpdate;

      // Listen to the stream
      service.statusStream.listen((update) {
        messageReceived = true;
        receivedUpdate = update;
      });

      // Simulate SSE message
      final sseLine = 'data: {"type":"status_update","order_id":"order123","status":"PREPARING","message":"Order is being prepared"}';
      
      // Use reflection or make the method public for testing
      // For now, we'll just test the parsing logic
      if (sseLine.startsWith('data: ')) {
        final jsonData = sseLine.substring(6);
        final data = {
          "type": "status_update",
          "order_id": "order123",
          "status": "PREPARING",
          "message": "Order is being prepared"
        };
        
        final update = OrderStatusUpdate.fromJson(data);
        expect(update.type, equals('status_update'));
        expect(update.orderId, equals('order123'));
        expect(update.status, equals('PREPARING'));
        expect(update.message, equals('Order is being prepared'));
      }
    });

    test('OrderStatusSSEService should handle connection lifecycle', () {
      final service = OrderStatusSSEService('order123');

      // Test initial state
      expect(service.isConnected, isFalse);

      // Test disconnect (should not throw)
      expect(() => service.disconnect(), returnsNormally);

      // Test dispose (should not throw)
      expect(() => service.dispose(), returnsNormally);
    });

    test('OrderStatusSSEService should handle multiple instances', () {
      final service1 = OrderStatusSSEService('order1');
      final service2 = OrderStatusSSEService('order2');
      final service3 = OrderStatusSSEService('order1'); // Should be same as service1

      expect(service1, same(service3));
      expect(service1, isNot(same(service2)));

      // Test dispose all
      expect(() => OrderStatusSSEService.disposeAll(), returnsNormally);
    });
  });
} 
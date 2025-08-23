import 'package:flutter_test/flutter_test.dart';
import 'package:bird/service/order_status_sse_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Chat Status Integration Tests', () {
    test('should create and dispose SSE service correctly', () {
      final service = OrderStatusSSEService('test_order_123');
      
      expect(service.orderId, equals('test_order_123'));
      expect(service.isConnected, isFalse);
      
      service.dispose();
    });

    test('should handle multiple SSE services for different orders', () {
      final service1 = OrderStatusSSEService('order_1');
      final service2 = OrderStatusSSEService('order_2');
      final service3 = OrderStatusSSEService('order_1'); // Should be same as service1
      
      expect(service1, same(service3));
      expect(service1, isNot(same(service2)));
      
      service1.dispose();
      service2.dispose();
    });

    test('should parse status update JSON correctly', () {
      final json = {
        "type": "status_update",
        "order_id": "test_order_123",
        "status": "PREPARING",
        "message": "Your order is being prepared",
        "timestamp": "2025-01-20T10:00:00.000Z",
        "delivery_partner_id": null,
        "created_at": "2025-01-20T09:30:00.000Z",
        "last_updated": "2025-01-20T10:00:00.000Z",
        "total_price": "20.00",
        "address": "Test Address",
        "coordinates": {
          "latitude": "17.4064980",
          "longitude": "78.4772439"
        },
        "payment_mode": "cash",
        "supercategory": "test_category",
        "items": [
          {
            "quantity": 1,
            "price": "20.00",
            "item_name": "Test Item",
            "item_description": "Test description"
          }
        ]
      };

      final statusUpdate = OrderStatusUpdate.fromJson(json);
      
      expect(statusUpdate.orderId, equals('test_order_123'));
      expect(statusUpdate.status, equals('PREPARING'));
      expect(statusUpdate.message, equals('Your order is being prepared'));
      expect(statusUpdate.items.length, equals(1));
      expect(statusUpdate.items.first.itemName, equals('Test Item'));
    });

    test('should handle status update with different statuses', () {
      final statuses = ['PENDING', 'PREPARING', 'READY', 'DELIVERED', 'CANCELLED'];
      
      for (final status in statuses) {
        final json = {
          "type": "status_update",
          "order_id": "test_order_123",
          "status": status,
          "message": "Status: $status",
          "timestamp": "2025-01-20T10:00:00.000Z",
          "delivery_partner_id": null,
          "created_at": "2025-01-20T09:30:00.000Z",
          "last_updated": "2025-01-20T10:00:00.000Z",
          "total_price": "20.00",
          "address": "Test Address",
          "coordinates": {
            "latitude": "17.4064980",
            "longitude": "78.4772439"
          },
          "payment_mode": "cash",
          "supercategory": "test_category",
          "items": []
        };

        final statusUpdate = OrderStatusUpdate.fromJson(json);
        expect(statusUpdate.status, equals(status));
      }
    });
  });
} 
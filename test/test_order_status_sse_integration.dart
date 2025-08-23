import 'package:flutter_test/flutter_test.dart';
import 'package:bird/service/order_status_sse_service.dart';

void main() {
  group('OrderStatusSSEService Integration Tests', () {
    test('SSE service should send mock data when connection fails', () async {
      final service = OrderStatusSSEService('test_order_123');
      bool dataReceived = false;
      OrderStatusUpdate? receivedUpdate;

      // Listen to the stream
      final subscription = service.statusStream.listen((update) {
        dataReceived = true;
        receivedUpdate = update;
      });

      // Connect (this should trigger mock data since the endpoint doesn't exist)
      await service.connect();

      // Wait a bit for mock data to be sent
      await Future.delayed(const Duration(milliseconds: 200));

      // Verify that mock data was received
      expect(dataReceived, isTrue);
      expect(receivedUpdate, isNotNull);
      expect(receivedUpdate!.orderId, equals('test_order_123'));
      expect(receivedUpdate!.status, equals('PREPARING'));
      expect(receivedUpdate!.message, contains('being prepared'));

      // Cleanup
      subscription.cancel();
      service.dispose();
    });

    test('SSE service should handle multiple listeners', () async {
      final service = OrderStatusSSEService('test_order_456');
      int listener1Count = 0;
      int listener2Count = 0;

      // First listener
      final subscription1 = service.statusStream.listen((update) {
        listener1Count++;
      });

      // Second listener
      final subscription2 = service.statusStream.listen((update) {
        listener2Count++;
      });

      // Connect to trigger mock data
      await service.connect();
      await Future.delayed(const Duration(milliseconds: 200));

      // Both listeners should receive the data
      expect(listener1Count, equals(1));
      expect(listener2Count, equals(1));

      // Cleanup
      subscription1.cancel();
      subscription2.cancel();
      service.dispose();
    });

    test('SSE service should maintain connection state correctly', () async {
      final service = OrderStatusSSEService('test_order_789');

      // Initially not connected
      expect(service.isConnected, isFalse);

      // Connect
      await service.connect();
      await Future.delayed(const Duration(milliseconds: 100));

      // Should be connected (even with mock data)
      expect(service.isConnected, isTrue);

      // Disconnect
      service.disconnect();
      expect(service.isConnected, isFalse);

      service.dispose();
    });

    test('SSE service should handle dispose correctly', () async {
      final service = OrderStatusSSEService('test_order_dispose');
      bool dataReceived = false;

      final subscription = service.statusStream.listen((update) {
        dataReceived = true;
      });

      // Connect and wait for data
      await service.connect();
      await Future.delayed(const Duration(milliseconds: 200));

      // Data should be received
      expect(dataReceived, isTrue);

      // Dispose
      service.dispose();

      // Should not throw when trying to access disposed service
      expect(() => service.isConnected, returnsNormally);

      subscription.cancel();
    });
  });
} 
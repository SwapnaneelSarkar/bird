import 'package:flutter_test/flutter_test.dart';
import 'package:bird/service/persistent_sse_service.dart';
import 'package:bird/service/current_orders_sse_service.dart';

void main() {
  group('PersistentSSEService Tests', () {
    late PersistentSSEService persistentSSEService;

    setUp(() {
      persistentSSEService = PersistentSSEService();
    });

    tearDown(() {
      persistentSSEService.dispose();
    });

    test('should be a singleton', () {
      final instance1 = PersistentSSEService();
      final instance2 = PersistentSSEService();
      expect(identical(instance1, instance2), true);
    });

    test('should initialize correctly', () async {
      expect(persistentSSEService.isInitialized, false);
      
      await persistentSSEService.initialize();
      
      expect(persistentSSEService.isInitialized, true);
    });

    test('should not initialize twice', () async {
      await persistentSSEService.initialize();
      expect(persistentSSEService.isInitialized, true);
      
      await persistentSSEService.initialize();
      expect(persistentSSEService.isInitialized, true);
    });

    test('should handle token validation', () {
      expect(persistentSSEService.hasValidToken, false);
      expect(persistentSSEService.currentToken, null);
    });

    test('should connect with valid token', () async {
      await persistentSSEService.initialize();
      
      const testToken = 'test_token_123';
      await persistentSSEService.connect(testToken);
      
      expect(persistentSSEService.hasValidToken, true);
      expect(persistentSSEService.currentToken, testToken);
    });

    test('should not connect with empty token', () async {
      await persistentSSEService.initialize();
      
      await persistentSSEService.connect('');
      
      expect(persistentSSEService.hasValidToken, false);
      expect(persistentSSEService.currentToken, '');
    });

    test('should update token correctly', () async {
      await persistentSSEService.initialize();
      
      const initialToken = 'initial_token';
      const newToken = 'new_token';
      
      await persistentSSEService.connect(initialToken);
      expect(persistentSSEService.currentToken, initialToken);
      
      await persistentSSEService.updateToken(newToken);
      expect(persistentSSEService.currentToken, newToken);
    });

    test('should not update token if same', () async {
      await persistentSSEService.initialize();
      
      const testToken = 'test_token';
      await persistentSSEService.connect(testToken);
      
      await persistentSSEService.updateToken(testToken);
      expect(persistentSSEService.currentToken, testToken);
    });

    test('should disconnect correctly', () async {
      await persistentSSEService.initialize();
      
      const testToken = 'test_token';
      await persistentSSEService.connect(testToken);
      expect(persistentSSEService.hasValidToken, true);
      
      await persistentSSEService.disconnect();
      expect(persistentSSEService.hasValidToken, false);
      expect(persistentSSEService.currentToken, null);
    });

    test('should provide access to current orders stream', () {
      expect(persistentSSEService.currentOrdersStream, isNotNull);
    });

    test('should provide connection status', () {
      expect(persistentSSEService.isConnected, false);
    });

    test('should handle multiple connect calls with same token', () async {
      await persistentSSEService.initialize();
      
      const testToken = 'test_token';
      await persistentSSEService.connect(testToken);
      expect(persistentSSEService.currentToken, testToken);
      
      // Second connect with same token should not change anything
      await persistentSSEService.connect(testToken);
      expect(persistentSSEService.currentToken, testToken);
    });

    test('should handle multiple connect calls with different tokens', () async {
      await persistentSSEService.initialize();
      
      const token1 = 'token_1';
      const token2 = 'token_2';
      
      await persistentSSEService.connect(token1);
      expect(persistentSSEService.currentToken, token1);
      
      await persistentSSEService.connect(token2);
      expect(persistentSSEService.currentToken, token2);
    });
  });
} 
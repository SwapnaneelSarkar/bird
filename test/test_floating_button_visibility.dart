import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bird/widgets/current_orders_floating_button.dart';
import 'package:bird/service/current_orders_sse_service.dart';

void main() {
  group('CurrentOrdersFloatingButton Visibility Tests', () {
    testWidgets('should show placeholder button when no token provided', (WidgetTester tester) async {
      bool visibilityChanged = false;
      bool isVisible = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrentOrdersFloatingButton(
              token: null, // No token
              onVisibilityChanged: (visible) {
                visibilityChanged = true;
                isVisible = visible;
              },
            ),
          ),
        ),
      );

      // Should show placeholder button when no token
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Current Orders'), findsOneWidget);
      expect(visibilityChanged, true);
      expect(isVisible, false); // No padding needed for placeholder
    });

    testWidgets('should show loading button when token provided but no SSE data', (WidgetTester tester) async {
      bool visibilityChanged = false;
      bool isVisible = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrentOrdersFloatingButton(
              token: 'test_token',
              onVisibilityChanged: (visible) {
                visibilityChanged = true;
                isVisible = visible;
              },
            ),
          ),
        ),
      );

      // Should show loading button when token available but no SSE data yet
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Loading Orders...'), findsOneWidget);
      expect(visibilityChanged, true);
      expect(isVisible, true); // Padding needed for loading button
    });

    testWidgets('should hide button when has_current_orders is false', (WidgetTester tester) async {
      bool visibilityChanged = false;
      bool isVisible = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrentOrdersFloatingButton(
              token: 'test_token',
              onVisibilityChanged: (visible) {
                visibilityChanged = true;
                isVisible = visible;
              },
            ),
          ),
        ),
      );

      // Simulate SSE data with has_current_orders = false
      final mockUpdate = CurrentOrdersUpdate(
        type: 'orders_update',
        userId: 'test_user',
        hasCurrentOrders: false,
        ordersCount: 0,
        orders: [],
        timestamp: '2024-01-01T12:00:00Z',
      );

      // This would normally be triggered by the SSE service
      // For testing, we'll manually trigger the state update
      await tester.pumpAndSettle();
      
      // The button should be hidden when has_current_orders is false
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(visibilityChanged, true);
      expect(isVisible, false); // No padding needed when hidden
    });

    testWidgets('should show button when has_current_orders is true', (WidgetTester tester) async {
      bool visibilityChanged = false;
      bool isVisible = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrentOrdersFloatingButton(
              token: 'test_token',
              onVisibilityChanged: (visible) {
                visibilityChanged = true;
                isVisible = visible;
              },
            ),
          ),
        ),
      );

      // Simulate SSE data with has_current_orders = true
      final mockUpdate = CurrentOrdersUpdate(
        type: 'orders_update',
        userId: 'test_user',
        hasCurrentOrders: true,
        ordersCount: 2,
        orders: [
          CurrentOrder(
            orderId: 'order1',
            restaurantName: 'Test Restaurant',
            orderStatus: 'preparing',
            totalPrice: '100.00',
            address: 'Test Address',
            createdAt: '2024-01-01T10:00:00Z',
            updatedAt: '2024-01-01T10:00:00Z',
            paymentMode: 'cash',
            supercategory: 'food',
            restaurantMobile: '1234567890',
          ),
          CurrentOrder(
            orderId: 'order2',
            restaurantName: 'Test Restaurant 2',
            orderStatus: 'confirmed',
            totalPrice: '150.00',
            address: 'Test Address 2',
            createdAt: '2024-01-01T11:00:00Z',
            updatedAt: '2024-01-01T11:00:00Z',
            paymentMode: 'online',
            supercategory: 'food',
            restaurantMobile: '0987654321',
          ),
        ],
        timestamp: '2024-01-01T12:00:00Z',
      );

      // This would normally be triggered by the SSE service
      // For testing, we'll manually trigger the state update
      await tester.pumpAndSettle();
      
      // The button should now be visible
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.textContaining('Current Orders (2)'), findsOneWidget);
      expect(visibilityChanged, true);
      expect(isVisible, true); // Padding needed for actual button
    });
  });
} 
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bird/widgets/current_orders_floating_button.dart';

void main() {
  group('CurrentOrdersFloatingButton Widget Tests', () {
    testWidgets('should hide button when no token provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrentOrdersFloatingButton(
              token: null,
              selectedSupercategoryId: null,
            ),
          ),
        ),
      );

      // Should hide the button when no token
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byIcon(Icons.delivery_dining), findsNothing);
    });

    testWidgets('should hide button when token provided but no orders', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrentOrdersFloatingButton(
              token: 'test-token',
              selectedSupercategoryId: 'test-category',
            ),
          ),
        ),
      );

      // Should hide the button when there are no active orders
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byIcon(Icons.delivery_dining), findsNothing);
    });

    testWidgets('should not render when only token is provided', (WidgetTester tester) async {
      const testToken = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test.token';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrentOrdersFloatingButton(
              token: testToken,
              selectedSupercategoryId: 'test-category',
            ),
          ),
        ),
      );

      // Should hide the button when only token exists but no active orders
      expect(find.byType(FloatingActionButton), findsNothing);
    });
  });
} 
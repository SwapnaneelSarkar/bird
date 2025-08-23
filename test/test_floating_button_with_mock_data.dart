import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bird/widgets/current_orders_floating_button.dart';

void main() {
  group('CurrentOrdersFloatingButton with Mock Data Tests', () {
    testWidgets('should show orders when mock data is received', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrentOrdersFloatingButton(
              token: 'test-token',
              selectedSupercategoryId: '7acc47a2fa5a4eeb906a753b3',
            ),
          ),
        ),
      );

      // Initially should show placeholder button
      expect(find.text('Check Current Orders'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);

      // Wait for mock data to be processed
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

          // Should now show the main button with orders
    expect(find.text('Current Orders (5)'), findsOneWidget);
    });

    testWidgets('should expand dropdown when button is pressed', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurrentOrdersFloatingButton(
              token: 'test-token',
              selectedSupercategoryId: '7acc47a2fa5a4eeb906a753b3',
            ),
          ),
        ),
      );

      // Wait for mock data to be processed
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

          // Tap the button to expand (find the first occurrence - the main button)
    await tester.tap(find.text('Current Orders (5)').first);
      await tester.pumpAndSettle();

      // Should show dropdown with order details (2 widgets: main button + dropdown header)
      expect(find.text('Current Orders (5)'), findsNWidgets(2));
      expect(find.text('Soofi restaurant and cafe'), findsAtLeastNWidgets(1));
      expect(find.text('Order #2508000151'), findsOneWidget); // Order ID
    });
  });
} 
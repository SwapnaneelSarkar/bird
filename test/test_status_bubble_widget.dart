import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bird/widgets/chat_order_status_bubble.dart';
import 'package:bird/models/order_details_model.dart';
import 'package:bird/service/order_status_sse_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChatOrderStatusBubble Widget Tests', () {
    testWidgets('should render status bubble widget', (WidgetTester tester) async {
      // Create mock order details
      final orderDetails = OrderDetails(
        orderId: 'test_order_123',
        userId: 'user_123',
        itemIds: ['item_1'],
        items: [
          OrderDetailsItem(
            menuId: 'item_1',
            quantity: 1,
            itemPrice: 20.0,
            itemName: 'Test Item',
          ),
        ],
        totalAmount: 20.0,
        deliveryFees: 5.0,
        orderStatus: 'PENDING',
        createdAt: DateTime.now(),
        restaurantName: 'Test Restaurant',
        deliveryAddress: 'Test Address',
        paymentMode: 'cash',
      );

      // Create mock status update
      final statusUpdate = OrderStatusUpdate(
        type: 'status_update',
        orderId: 'test_order_123',
        status: 'PREPARING',
        message: 'Your order is being prepared',
        timestamp: DateTime.now().toIso8601String(),
        deliveryPartnerId: null,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
        lastUpdated: DateTime.now().toIso8601String(),
        totalPrice: '20.00',
        address: 'Test Address',
        coordinates: {
          'latitude': '17.4064980',
          'longitude': '78.4772439'
        },
        paymentMode: 'cash',
        supercategory: 'test_category',
        items: [
          OrderStatusItem(
            quantity: 1,
            price: '20.00',
            itemName: 'Test Item',
            itemDescription: 'Test description',
          ),
        ],
      );

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatOrderStatusBubble(
              orderDetails: orderDetails,
              isFromCurrentUser: false,
              currentUserId: 'user_123',
              latestStatusUpdate: statusUpdate,
            ),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify that the widget renders without errors
      expect(find.byType(ChatOrderStatusBubble), findsOneWidget);
      
      // Verify that key elements are present
      expect(find.text('Test Restaurant'), findsOneWidget);
      expect(find.text('Status: Preparing Your Order'), findsOneWidget);
      expect(find.text('Your order is being prepared'), findsOneWidget);
    });

    testWidgets('should render status bubble without status update', (WidgetTester tester) async {
      // Create mock order details
      final orderDetails = OrderDetails(
        orderId: 'test_order_123',
        userId: 'user_123',
        itemIds: ['item_1'],
        items: [
          OrderDetailsItem(
            menuId: 'item_1',
            quantity: 1,
            itemPrice: 20.0,
            itemName: 'Test Item',
          ),
        ],
        totalAmount: 20.0,
        deliveryFees: 5.0,
        orderStatus: 'PENDING',
        createdAt: DateTime.now(),
        restaurantName: 'Test Restaurant',
        deliveryAddress: 'Test Address',
        paymentMode: 'cash',
      );

      // Build the widget without status update
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatOrderStatusBubble(
              orderDetails: orderDetails,
              isFromCurrentUser: false,
              currentUserId: 'user_123',
              latestStatusUpdate: null,
            ),
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify that the widget renders without errors
      expect(find.byType(ChatOrderStatusBubble), findsOneWidget);
      
      // Verify that key elements are present
      expect(find.text('Test Restaurant'), findsOneWidget);
      expect(find.text('Status: Order Placed'), findsOneWidget);
    });
  });
} 
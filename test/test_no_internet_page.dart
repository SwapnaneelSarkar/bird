import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bird/presentation/no_internet/view.dart';
import 'package:bird/constants/router/router.dart';

void main() {
  group('NoInternetPage Tests', () {
    testWidgets('should display correct UI elements', (WidgetTester tester) async {
      // Build the NoInternetPage
      await tester.pumpWidget(
        MaterialApp(
          home: const NoInternetPage(),
          routes: {
            Routes.splash: (context) => const Scaffold(body: Text('Splash Screen')),
          },
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify the main heading is displayed
      expect(find.text('No Internet Connection'), findsOneWidget);
      
      // Verify the subheading is displayed
      expect(find.text('Oops! Seems we\'re offline'), findsOneWidget);
      
      // Verify the description text is displayed
      expect(find.text('Please check your internet connection and try again. Your delicious food is waiting!'), findsOneWidget);
      
      // Verify the Try Again button is displayed
      expect(find.text('Try Again'), findsOneWidget);
      
      // Verify the refresh icon is displayed
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    });

    testWidgets('Try Again button should be present and tappable', (WidgetTester tester) async {
      // Build the NoInternetPage
      await tester.pumpWidget(
        MaterialApp(
          home: const NoInternetPage(),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Find the Try Again button
      final tryAgainButton = find.text('Try Again');
      expect(tryAgainButton, findsOneWidget);
      
      // Verify the button is tappable
      expect(tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed, isNotNull);
    });

    testWidgets('should have correct styling', (WidgetTester tester) async {
      // Build the NoInternetPage
      await tester.pumpWidget(
        MaterialApp(
          home: const NoInternetPage(),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Verify the main heading has extra bold font weight
      final mainHeading = tester.widget<Text>(find.text('No Internet Connection'));
      expect(mainHeading.style?.fontWeight, FontWeight.w800);
      
      // Verify the subheading has w600 font weight
      final subheading = tester.widget<Text>(find.text('Oops! Seems we\'re offline'));
      expect(subheading.style?.fontWeight, FontWeight.w600);
      
      // Verify the Try Again button has correct styling
      final tryAgainButton = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(tryAgainButton.style?.backgroundColor?.resolve({}), isNotNull);
    });
  });
} 
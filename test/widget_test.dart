// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bird/main.dart';
import 'package:bird/presentation/profile_view/bloc.dart';
import 'package:bird/presentation/profile_view/event.dart';
import 'package:bird/presentation/profile_view/state.dart';

void main() {
  testWidgets('Profile logout functionality test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Wait for the app to load
    await tester.pumpAndSettle();

    // Navigate to profile view (you might need to adjust this based on your app flow)
    // For now, we'll test that the ProfileBloc is properly provided globally
    
    // Verify that the ProfileBloc is available in the widget tree
    expect(find.byType(BlocProvider<ProfileBloc>), findsOneWidget);
  });

  testWidgets('ProfileBloc logout event test', (WidgetTester tester) async {
    // Create a mock ProfileBloc for testing
    final profileBloc = ProfileBloc();
    
    // Build a widget with the ProfileBloc
    await tester.pumpWidget(
      BlocProvider<ProfileBloc>(
        create: (_) => profileBloc,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    context.read<ProfileBloc>().add(LogoutRequested());
                  },
                  child: const Text('Logout'),
                );
              },
            ),
          ),
        ),
      ),
    );

    // Verify initial state
    expect(profileBloc.state, isA<ProfileInitial>());

    // Tap the logout button
    await tester.tap(find.text('Logout'));
    await tester.pump();

    // Verify that the logout event was processed
    expect(profileBloc.state, isA<ProfileLoggedOut>());
  });
}

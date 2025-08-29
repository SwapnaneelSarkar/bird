import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bird/presentation/profile_view/bloc.dart';
import 'package:bird/presentation/profile_view/event.dart';
import 'package:bird/presentation/profile_view/state.dart';

void main() {
  group('Logout Functionality Tests', () {
    late ProfileBloc profileBloc;

    setUp(() {
      profileBloc = ProfileBloc();
    });

    tearDown(() {
      profileBloc.close();
    });

    testWidgets('Logout should show loading state and then navigate to login', (WidgetTester tester) async {
      // Build a widget with the ProfileBloc
      await tester.pumpWidget(
        BlocProvider<ProfileBloc>(
          create: (_) => profileBloc,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          context.read<ProfileBloc>().add(LogoutRequested());
                        },
                        child: const Text('Logout'),
                      ),
                      BlocBuilder<ProfileBloc, ProfileState>(
                        builder: (context, state) {
                          if (state is ProfileLoggingOut) {
                            return const Text('Logging out...');
                          } else if (state is ProfileLoggedOut) {
                            return const Text('Logged out successfully');
                          }
                          return const Text('Ready');
                        },
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Verify initial state
      expect(profileBloc.state, isA<ProfileInitial>());
      expect(find.text('Ready'), findsOneWidget);

      // Tap the logout button
      await tester.tap(find.text('Logout'));
      await tester.pump();

      // Verify that the state changed to logging out
      expect(profileBloc.state, isA<ProfileLoggingOut>());
      expect(find.text('Logging out...'), findsOneWidget);

      // Wait for logout to complete with multiple pumps to handle async operations
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      // Verify that the logout event was processed and state changed to logged out
      expect(profileBloc.state, isA<ProfileLoggedOut>());
      expect(find.text('Logged out successfully'), findsOneWidget);
    });

    testWidgets('LoadProfile should be skipped when logout is in progress', (WidgetTester tester) async {
      // Start logout process
      profileBloc.add(LogoutRequested());
      await tester.pump();

      // Verify we're in logging out state
      expect(profileBloc.state, isA<ProfileLoggingOut>());

      // Try to load profile while logout is in progress
      profileBloc.add(LoadProfile());
      await tester.pump();

      // Should still be in logging out state, not loading
      expect(profileBloc.state, isA<ProfileLoggingOut>());
    });

    testWidgets('LoadProfile should be skipped when already logged out', (WidgetTester tester) async {
      // Complete logout process
      profileBloc.add(LogoutRequested());
      
      // Wait for logout to complete
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      // Verify we're in logged out state
      expect(profileBloc.state, isA<ProfileLoggedOut>());

      // Try to load profile after logout
      profileBloc.add(LoadProfile());
      await tester.pump();

      // Should still be in logged out state, not loading
      expect(profileBloc.state, isA<ProfileLoggedOut>());
    });

    test('Logout should complete successfully even with service errors', () async {
      // Start logout process
      profileBloc.add(LogoutRequested());
      
      // Wait for logout to complete with multiple checks
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Check if logout completed
      if (profileBloc.state is ProfileLoggingOut) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // Verify final state is logged out (not stuck in logging out or error)
      expect(
        profileBloc.state is ProfileLoggedOut,
        isTrue,
        reason: 'Logout should complete successfully even with service errors',
      );
    });

    test('Logout should not show error states during logout process', () async {
      // Start logout process
      profileBloc.add(LogoutRequested());
      
      // Wait a bit for logout to start
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Verify we're in logging out state, not error state
      expect(profileBloc.state is ProfileLoggingOut, isTrue);
      expect(profileBloc.state is ProfileError, isFalse);
      
      // Wait for logout to complete
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Verify final state is logged out, not error
      expect(profileBloc.state is ProfileLoggedOut, isTrue);
      expect(profileBloc.state is ProfileError, isFalse);
    });

    test('Profile loading should be prevented during logout', () async {
      // Start logout process
      profileBloc.add(LogoutRequested());
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Try to load profile during logout
      profileBloc.add(LoadProfile());
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Should still be in logging out state, not loading
      expect(profileBloc.state is ProfileLoggingOut, isTrue);
      expect(profileBloc.state is ProfileLoading, isFalse);
    });
  });
} 
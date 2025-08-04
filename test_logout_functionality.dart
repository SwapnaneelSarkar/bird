// Test script to verify logout functionality
// This script can be run to test if the logout functionality works correctly

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bird/presentation/profile_view/bloc.dart';
import 'package:bird/presentation/profile_view/event.dart';
import 'package:bird/presentation/profile_view/state.dart';

void main() {
  // Test the ProfileBloc logout functionality
  testProfileBlocLogout();
}

void testProfileBlocLogout() {
  print('Testing ProfileBloc logout functionality...');
  
  // Create a ProfileBloc instance
  final profileBloc = ProfileBloc();
  
  // Verify initial state
  print('Initial state: ${profileBloc.state.runtimeType}');
  assert(profileBloc.state is ProfileInitial, 'Initial state should be ProfileInitial');
  
  // Add logout event
  profileBloc.add(LogoutRequested());
  
  // Wait a bit for the event to be processed
  Future.delayed(const Duration(milliseconds: 100), () {
    print('State after logout event: ${profileBloc.state.runtimeType}');
    
    // Verify that the state changed to ProfileLoggedOut
    if (profileBloc.state is ProfileLoggedOut) {
      print('✅ Logout functionality test PASSED!');
    } else {
      print('❌ Logout functionality test FAILED!');
      print('Expected ProfileLoggedOut, got ${profileBloc.state.runtimeType}');
    }
  });
}

// Test widget to verify the logout dialog works
class LogoutTestWidget extends StatelessWidget {
  const LogoutTestWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logout Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('Tap the logout icon to test logout functionality'),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<ProfileBloc>().add(LogoutRequested());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
} 
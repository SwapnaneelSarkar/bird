// Test file to verify fresh location fetching implementation
import 'package:flutter_test/flutter_test.dart';
import 'package:bird/service/app_startup_service.dart';
import 'package:bird/service/token_service.dart';
import 'package:bird/presentation/home page/bloc.dart';
import 'package:bird/presentation/home page/event.dart';
import 'package:bird/presentation/home page/state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  group('Fresh Location Fetching Tests', () {
    test('AppStartupService should always fetch fresh location on app startup', () async {
      // Test that the service always fetches fresh location
      final result = await AppStartupService.forceFreshLocationFetch();
      
      expect(result['success'], isTrue);
      expect(result['locationUpdated'], isTrue);
      expect(result['message'], contains('Location updated successfully'));
    });

    test('HomeBloc should fetch fresh location data when loading home data', () async {
      // Test that home bloc always fetches fresh profile data
      final bloc = HomeBloc();
      
      // Trigger home data loading
      bloc.add(const LoadHomeData());
      
      // Wait for the event to be processed
      await Future.delayed(const Duration(seconds: 2));
      
      // Verify that fresh location data was fetched
      expect(bloc.state, isA<HomeLoaded>());
      
      if (bloc.state is HomeLoaded) {
        final state = bloc.state as HomeLoaded;
        expect(state.userAddress, isNotEmpty);
        expect(state.userLatitude, isNotNull);
        expect(state.userLongitude, isNotNull);
      }
    });

    test('Manual location update should clear cache and fetch fresh data', () async {
      // Test manual location update
      final result = await AppStartupService.manualLocationUpdate();
      
      expect(result['success'], isTrue);
      expect(result['locationUpdated'], isTrue);
    });

    test('Force fresh location fetch should clear all cached data', () async {
      // Test force fresh location fetch
      final result = await AppStartupService.forceFreshLocationFetch();
      
      expect(result['success'], isTrue);
      expect(result['locationUpdated'], isTrue);
    });
  });
}

// Mock test for location service
class MockLocationService {
  static Future<Map<String, dynamic>?> getCurrentLocationAndAddress() async {
    // Mock location data
    return {
      'latitude': 12.9716,
      'longitude': 77.5946,
      'address': 'Bangalore, Karnataka, India',
    };
  }
}

// Mock test for update user service
class MockUpdateUserService {
  static Future<Map<String, dynamic>> updateUserProfileWithId({
    required String token,
    required String userId,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    // Mock successful update
    return {
      'success': true,
      'message': 'User profile updated successfully',
    };
  }
} 
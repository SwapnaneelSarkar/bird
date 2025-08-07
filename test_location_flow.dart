// test_location_flow.dart - Test the complete location flow
import 'package:flutter_test/flutter_test.dart';
import 'package:bird/service/app_startup_service.dart';
import 'package:bird/service/token_service.dart';
import 'package:bird/service/profile_get_service.dart';

void main() {
  group('Location Flow Tests', () {
    test('Complete location flow from startup to home page', () async {
      // Simulate app startup
      print('=== Testing Complete Location Flow ===');
      
      // Step 1: App startup - initialize location services
      print('Step 1: App startup - initializing location services...');
      final initResult = await AppStartupService.initializeApp();
      
      expect(initResult, isA<Map<String, dynamic>>());
      expect(initResult.containsKey('success'), isTrue);
      
      print('Init result: $initResult');
      
      // Step 2: Check if user is logged in
      final isLoggedIn = await TokenService.isLoggedIn();
      print('Step 2: User logged in: $isLoggedIn');
      
      if (isLoggedIn) {
        // Step 3: Get user data
        final userData = await TokenService.getUserData();
        final token = await TokenService.getToken();
        final userId = await TokenService.getUserId();
        
        print('Step 3: User data retrieved');
        print('  User ID: $userId');
        print('  Token: ${token != null ? 'Found' : 'Not found'}');
        print('  Address: ${userData?['address']}');
        print('  Latitude: ${userData?['latitude']}');
        print('  Longitude: ${userData?['longitude']}');
        
        expect(userData, isA<Map<String, dynamic>>());
        expect(token, isNotNull);
        expect(userId, isNotNull);
        
        // Step 4: Simulate home page loading - fetch fresh profile data
        print('Step 4: Simulating home page loading...');
        final profileService = ProfileApiService();
        final profileResult = await profileService.getUserProfile(
          token: token!,
          userId: userId!,
        );
        
        expect(profileResult['success'], isTrue);
        
        final freshUserData = profileResult['data'] as Map<String, dynamic>;
        print('Fresh profile data:');
        print('  Address: ${freshUserData['address']}');
        print('  Latitude: ${freshUserData['latitude']}');
        print('  Longitude: ${freshUserData['longitude']}');
        
        // Step 5: Verify location data is consistent
        print('Step 5: Verifying location data consistency...');
        
        if (initResult['locationUpdated'] == true) {
          // If location was updated, verify the fresh data matches
          expect(freshUserData['address'], equals(initResult['address']));
          expect(freshUserData['latitude'], equals(initResult['latitude'].toString()));
          expect(freshUserData['longitude'], equals(initResult['longitude'].toString()));
          print('✓ Location data is consistent after update');
        } else {
          print('Location was not updated (as expected)');
        }
        
        // Step 6: Test manual location update
        print('Step 6: Testing manual location update...');
        final manualResult = await AppStartupService.manualLocationUpdate();
        
        expect(manualResult, isA<Map<String, dynamic>>());
        expect(manualResult.containsKey('success'), isTrue);
        
        print('Manual update result: $manualResult');
        
        // Step 7: Verify manual update updated the profile
        if (manualResult['locationUpdated'] == true) {
          print('Step 7: Verifying manual update updated profile...');
          
          // Fetch profile again to verify it was updated
          final updatedProfileResult = await profileService.getUserProfile(
            token: token,
            userId: userId,
          );
          
          final updatedUserData = updatedProfileResult['data'] as Map<String, dynamic>;
          print('Updated profile data:');
          print('  Address: ${updatedUserData['address']}');
          print('  Latitude: ${updatedUserData['latitude']}');
          print('  Longitude: ${updatedUserData['longitude']}');
          
          expect(updatedUserData['address'], equals(manualResult['address']));
          expect(updatedUserData['latitude'], equals(manualResult['latitude'].toString()));
          expect(updatedUserData['longitude'], equals(manualResult['longitude'].toString()));
          print('✓ Manual update successfully updated profile');
        }
        
        print('=== Location Flow Test Completed Successfully ===');
      } else {
        print('User not logged in, skipping location flow test');
      }
    });
    
    test('Location preferences work correctly', () async {
      print('=== Testing Location Preferences ===');
      
      // Test enabling auto-location
      await AppStartupService.setAutoLocationEnabled(true);
      final isEnabled = await AppStartupService.isAutoLocationEnabled();
      expect(isEnabled, isTrue);
      print('✓ Auto-location enabled: $isEnabled');
      
      // Test disabling auto-location
      await AppStartupService.setAutoLocationEnabled(false);
      final isDisabled = await AppStartupService.isAutoLocationEnabled();
      expect(isDisabled, isFalse);
      print('✓ Auto-location disabled: $isDisabled');
      
      // Reset to enabled
      await AppStartupService.setAutoLocationEnabled(true);
      print('✓ Reset auto-location to enabled');
      
      print('=== Location Preferences Test Completed ===');
    });
  });
} 
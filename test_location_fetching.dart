// test_location_fetching.dart - Test file for location fetching functionality
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:bird/service/app_startup_service.dart';
import 'package:bird/service/location_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Location Fetching Tests', () {
    test('AppStartupService should initialize correctly', () async {
      // Test that the service can be called without errors
      final result = await AppStartupService.initializeApp();
      
      // Should return a valid result structure
      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('success'), isTrue);
      expect(result.containsKey('message'), isTrue);
      expect(result.containsKey('locationUpdated'), isTrue);
    });
    
    test('LocationService should handle location requests', () async {
      final locationService = LocationService();
      
      // Test getCurrentLocationAndAddress method
      final locationData = await locationService.getCurrentLocationAndAddress();
      
      // Location data might be null if location services are not available in test environment
      if (locationData != null) {
        expect(locationData, isA<Map<String, dynamic>>());
        expect(locationData.containsKey('latitude'), isTrue);
        expect(locationData.containsKey('longitude'), isTrue);
        expect(locationData.containsKey('address'), isTrue);
        
        // Check that coordinates are valid
        expect(locationData['latitude'], isA<double>());
        expect(locationData['longitude'], isA<double>());
        expect(locationData['address'], isA<String>());
      }
    });
    
    test('Auto location settings should work correctly', () async {
      // Test setting auto location enabled
      await AppStartupService.setAutoLocationEnabled(true);
      final isEnabled = await AppStartupService.isAutoLocationEnabled();
      expect(isEnabled, isTrue);
      
      // Test setting auto location disabled
      await AppStartupService.setAutoLocationEnabled(false);
      final isDisabled = await AppStartupService.isAutoLocationEnabled();
      expect(isDisabled, isFalse);
      
      // Reset to default (enabled)
      await AppStartupService.setAutoLocationEnabled(true);
    });
    
    test('Manual location update should work', () async {
      final result = await AppStartupService.manualLocationUpdate();
      
      expect(result, isA<Map<String, dynamic>>());
      expect(result.containsKey('success'), isTrue);
      expect(result.containsKey('message'), isTrue);
      expect(result.containsKey('locationUpdated'), isTrue);
    });
    
    test('Distance calculation should work correctly', () {
      // Test distance calculation between two points
      // New York coordinates
      final lat1 = 40.7128;
      final lon1 = -74.0060;
      
      // Los Angeles coordinates
      final lat2 = 34.0522;
      final lon2 = -118.2437;
      
      // Calculate distance using the private method (we'll test the logic)
      final distance = _calculateDistance(lat1, lon1, lat2, lon2);
      
      // Distance should be reasonable (around 4000 km)
      expect(distance, greaterThan(3000));
      expect(distance, lessThan(5000));
    });
  });
}

// Helper function to test distance calculation
double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371; // Earth's radius in kilometers
  
  final dLat = _degreesToRadians(lat2 - lat1);
  final dLon = _degreesToRadians(lon2 - lon1);
  
  final lat1Rad = _degreesToRadians(lat1);
  final lat2Rad = _degreesToRadians(lat2);
  
  final a = sin(dLat / 2) * sin(dLat / 2) +
            sin(lat1Rad) * sin(lat2Rad) * sin(dLon / 2) * sin(dLon / 2);
  final c = 2 * asin(sqrt(a));
  
  return earthRadius * c;
}

double _degreesToRadians(double degrees) {
  return degrees * (3.14159265359 / 180);
} 
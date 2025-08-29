import 'package:flutter_test/flutter_test.dart';
import 'package:bird/service/location_validation_service.dart';
import 'package:bird/service/app_startup_service.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Generate mocks
@GenerateMocks([http.Client])
import 'test_location_validation_api.mocks.dart';

void main() {
  group('Location Validation API Tests', () {
    test('Should call update-user API for location validation', () async {
      // This test verifies that the location validation service
      // actually calls the update-user API endpoint
      
      final mockClient = MockClient();
      
      // Mock successful response
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
        '{"status": true, "message": "Location is serviceable"}',
        200,
      ));
      
      // Test the validation service
      final result = await LocationValidationService.checkLocationServiceability(
        latitude: 37.7749,
        longitude: -122.4194,
        address: 'San Francisco, CA',
      );
      
      // Verify the API was called
      verify(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).called(1);
      
      expect(result['isServiceable'], true);
    });

    test('Should handle unserviceable location response', () async {
      final mockClient = MockClient();
      
      // Mock unserviceable location response
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
        '{"status": false, "message": "Location is outside all defined serviceable areas"}',
        400,
      ));
      
      final result = await LocationValidationService.checkLocationServiceability(
        latitude: 0.0,
        longitude: 0.0,
        address: 'Middle of Ocean',
      );
      
      expect(result['isServiceable'], false);
      expect(result['message'], contains('outside all defined serviceable areas'));
    });

    test('Should force location validation on app restart', () async {
      // This test verifies that the app startup service
      // forces location validation instead of using cached data
      
      final result = await AppStartupService.initializeAppGracefully();
      
      // Should not use recent data cache
      expect(result['recentDataUsed'], isNot(true));
      
      // Should either update location or use fallback
      expect(result['success'], true);
    });
  });
} 
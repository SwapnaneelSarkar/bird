import 'package:flutter_test/flutter_test.dart';
import 'package:bird/service/location_validation_service.dart';

void main() {
  group('Location Validation Service Tests', () {
    test('Should return unserviceable location message', () {
      final message = LocationValidationService.getUnserviceableLocationMessage('Mountain View, CA');
      expect(message, contains('Mountain View, CA'));
      expect(message, contains('do not serve'));
      expect(message, contains('serviceable address'));
    });

    test('Should handle empty address in message', () {
      final message = LocationValidationService.getUnserviceableLocationMessage('');
      expect(message, contains('do not serve'));
      expect(message, contains('serviceable address'));
    });

    test('Should handle null address in message', () {
      final message = LocationValidationService.getUnserviceableLocationMessage('null');
      expect(message, contains('do not serve'));
      expect(message, contains('serviceable address'));
    });
  });
} 
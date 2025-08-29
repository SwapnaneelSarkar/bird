import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constant.dart';
import 'token_service.dart';

class LocationValidationService {
  /// Check if a location is outside serviceable areas by attempting to update the user profile
  static Future<Map<String, dynamic>> checkLocationServiceability({
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    try {
      debugPrint('🔍 LocationValidationService: Checking serviceability for location: $address');
      
      final token = await TokenService.getToken();
      final userId = await TokenService.getUserId();
      
      if (token == null || userId == null) {
        return {
          'success': false,
          'message': 'Authentication required',
          'isServiceable': false,
        };
      }
      
      // Make a test API call to check if the location is serviceable
      final url = Uri.parse('${ApiConstants.baseUrl}/user/update-user/');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id': userId,
          'address': address,
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
        }),
      );
      
      final responseBody = jsonDecode(response.body);
      
      if (response.statusCode == 200 && responseBody['status'] == true) {
        debugPrint('✅ LocationValidationService: Location is serviceable');
        return {
          'success': true,
          'message': 'Location is serviceable',
          'isServiceable': true,
        };
      } else if (response.statusCode == 400 && 
                 (responseBody['message'] ?? '').contains('outside all defined serviceable areas')) {
        debugPrint('❌ LocationValidationService: Location is outside serviceable areas');
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Location is outside serviceable areas',
          'isServiceable': false,
        };
      } else {
        debugPrint('❌ LocationValidationService: Unknown error checking serviceability');
        // If we can't validate, assume it's serviceable to avoid blocking users
        return {
          'success': true,
          'message': 'Unable to validate location, assuming serviceable',
          'isServiceable': true,
        };
      }
    } catch (e) {
      debugPrint('❌ LocationValidationService: Error checking serviceability: $e');
      // If there's an error, assume it's serviceable to avoid blocking users
      return {
        'success': true,
        'message': 'Unable to validate location, assuming serviceable',
        'isServiceable': true,
      };
    }
  }
  
  /// Check if the current user's location is serviceable
  static Future<Map<String, dynamic>> checkCurrentLocationServiceability() async {
    try {
      final userData = await TokenService.getUserData();
      
      if (userData == null || 
          userData['latitude'] == null || 
          userData['longitude'] == null || 
          userData['address'] == null) {
        return {
          'success': false,
          'message': 'No location data available',
          'isServiceable': false,
        };
      }
      
      final latitude = double.tryParse(userData['latitude'].toString());
      final longitude = double.tryParse(userData['longitude'].toString());
      final address = userData['address'].toString();
      
      if (latitude == null || longitude == null) {
        return {
          'success': false,
          'message': 'Invalid location coordinates',
          'isServiceable': false,
        };
      }
      
      debugPrint('🔍 LocationValidationService: Force checking serviceability for current location: $address');
      debugPrint('🔍 LocationValidationService: Coordinates: ($latitude, $longitude)');
      
      return await checkLocationServiceability(
        latitude: latitude,
        longitude: longitude,
        address: address,
      );
    } catch (e) {
      debugPrint('❌ LocationValidationService: Error checking current location: $e');
      return {
        'success': false,
        'message': 'Error checking current location',
        'isServiceable': false,
      };
    }
  }
  
  /// Get a user-friendly message for unserviceable locations
  static String getUnserviceableLocationMessage(String currentAddress) {
    return 'Sorry, we do not serve your current location ($currentAddress) yet. Please select a serviceable address to continue ordering.';
  }
  
  /// Get a more detailed message for unserviceable locations with suggestions
  static String getDetailedUnserviceableMessage(String currentAddress) {
    return 'We haven\'t spread our wings to this area yet.\n\nPlease try a different location within our service area to continue ordering.';
  }
  
  /// Check if a location is serviceable and return detailed result
  static Future<Map<String, dynamic>> checkLocationServiceabilityWithDetails({
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    try {
      debugPrint('🔍 LocationValidationService: Checking serviceability for location: $address');
      
      final token = await TokenService.getToken();
      final userId = await TokenService.getUserId();
      
      if (token == null || userId == null) {
        return {
          'success': false,
          'message': 'Authentication required',
          'isServiceable': false,
          'canRetry': true,
        };
      }
      
      // Make a test API call to check if the location is serviceable
      final url = Uri.parse('${ApiConstants.baseUrl}/user/update-user/');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id': userId,
          'address': address,
          'latitude': latitude.toString(),
          'longitude': longitude.toString(),
        }),
      );
      
      final responseBody = jsonDecode(response.body);
      
      if (response.statusCode == 200 && responseBody['status'] == true) {
        debugPrint('✅ LocationValidationService: Location is serviceable');
        return {
          'success': true,
          'message': 'Location is serviceable',
          'isServiceable': true,
          'canRetry': false,
        };
      } else if (response.statusCode == 400 && 
                 (responseBody['message'] ?? '').contains('outside all defined serviceable areas')) {
        debugPrint('❌ LocationValidationService: Location is outside serviceable areas');
        return {
          'success': false,
          'message': responseBody['message'] ?? 'Location is outside serviceable areas',
          'isServiceable': false,
          'canRetry': true,
          'detailedMessage': getDetailedUnserviceableMessage(address),
        };
      } else {
        debugPrint('❌ LocationValidationService: Unknown error checking serviceability');
        // If we can't validate, assume it's serviceable to avoid blocking users
        return {
          'success': true,
          'message': 'Unable to validate location, assuming serviceable',
          'isServiceable': true,
          'canRetry': false,
        };
      }
    } catch (e) {
      debugPrint('❌ LocationValidationService: Error checking serviceability: $e');
      // If there's an error, assume it's serviceable to avoid blocking users
      return {
        'success': true,
        'message': 'Unable to validate location, assuming serviceable',
        'isServiceable': true,
        'canRetry': true,
      };
    }
  }
} 
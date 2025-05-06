import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../constants/api_constant.dart';

class UpdateAddressService {
  // Method to update just the address and coordinates
  Future<Map<String, dynamic>> updateUserAddress({
    required String token,
    required String mobile,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    try {
      debugPrint('UpdateAddressService: Starting address update...');
      debugPrint('UpdateAddressService: Mobile: $mobile');
      debugPrint('UpdateAddressService: Address: $address');
      debugPrint('UpdateAddressService: Latitude: $latitude');
      debugPrint('UpdateAddressService: Longitude: $longitude');

      // Create a form-data request with only required fields
      final url = Uri.parse('${ApiConstants.baseUrl}/api/user/update-user');
      
      // Create multipart request
      var request = http.MultipartRequest('POST', url);
      
      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add only the necessary fields
      request.fields['mobile'] = mobile;
      request.fields['address'] = address;
      
      // Convert coordinates to string with proper formatting
      // Ensure we're sending exact decimal representations without any rounding
      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();
      
      debugPrint('UpdateAddressService: Sending latitude as: ${request.fields['latitude']}');
      debugPrint('UpdateAddressService: Sending longitude as: ${request.fields['longitude']}');
      
      // Add empty fields for required parameters
      request.fields['username'] = '';
      request.fields['email'] = '';
      
      // Send the request
      debugPrint('UpdateAddressService: Sending request to: $url');
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      debugPrint('UpdateAddressService: Response status: ${response.statusCode}');
      debugPrint('UpdateAddressService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['status'] == true) {
          debugPrint('UpdateAddressService: Address update successful');
          return {
            'success': true,
            'message': responseData['message'] ?? 'Address updated successfully',
            'data': responseData['data'],
          };
        } else {
          debugPrint('UpdateAddressService: Address update failed: ${responseData['message']}');
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to update address',
          };
        }
      } else {
        debugPrint('UpdateAddressService: Address update error: Status ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server error occurred. Please try again.',
        };
      }
    } catch (e) {
      debugPrint('UpdateAddressService: Exception: $e');
      return {
        'success': false,
        'message': 'Network error occurred. Please check your connection.',
      };
    }
  }
}
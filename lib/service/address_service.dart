// lib/service/address_service.dart - UPDATED TO MATCH YOUR API STRUCTURE
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constant.dart';
import 'token_service.dart';

class AddressService {
  
  // Get all saved addresses for the user
  static Future<Map<String, dynamic>> getAllAddresses() async {
    try {
      debugPrint('AddressService: Fetching all addresses...');
      
      final token = await TokenService.getToken();
      final userId = await TokenService.getUserId();
      
      if (token == null || userId == null) {
        debugPrint('AddressService: No token or userId available');
        return {
          'success': false,
          'message': 'Authentication required. Please login again.',
        };
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/api/user/all-addresses?user_id=$userId');
      
      debugPrint('AddressService: Fetch URL: $url');
      
      // FIXED: Use POST as per your API structure
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        // Empty body for POST request
      );

      debugPrint('AddressService: Fetch response status: ${response.statusCode}');
      debugPrint('AddressService: Fetch response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['status'] == true) {
          debugPrint('AddressService: Addresses fetched successfully');
          return {
            'success': true,
            'message': responseData['message'],
            'data': responseData['data'] ?? [],
          };
        } else {
          debugPrint('AddressService: Fetch failed: ${responseData['message']}');
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to fetch addresses',
          };
        }
      } else if (response.statusCode == 401) {
        debugPrint('AddressService: Unauthorized access');
        return {
          'success': false,
          'message': 'Session expired. Please login again.',
        };
      } else {
        debugPrint('AddressService: Server error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server error occurred. Please try again.',
        };
      }
    } catch (e) {
      debugPrint('AddressService: Exception fetching addresses: $e');
      return {
        'success': false,
        'message': 'Network error occurred. Please check your connection.',
      };
    }
  }

  // Save a new address
  static Future<Map<String, dynamic>> saveAddress({
    required String addressLine1,
    required String addressLine2, // Used for address name (Home, Office, etc.)
    required String city,
    required String state,
    required String postalCode,
    required String country,
    required double latitude,
    required double longitude,
    bool isDefault = false,
  }) async {
    try {
      debugPrint('AddressService: Saving new address...');
      
      final token = await TokenService.getToken();
      final userId = await TokenService.getUserId();
      
      if (token == null || userId == null) {
        debugPrint('AddressService: No token or userId available');
        return {
          'success': false,
          'message': 'Authentication required. Please login again.',
        };
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/api/user/addresses');
      
      final payload = {
        'user_id': userId,
        'address_line1': addressLine1,
        'address_line2': addressLine2,
        'city': city,
        'state': state,
        'postal_code': postalCode,
        'country': country,
        'latitude': latitude.toStringAsFixed(8),
        'longitude': longitude.toStringAsFixed(8),
        'is_default': isDefault ? 1 : 0,
      };

      debugPrint('AddressService: Save address payload: $payload');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      debugPrint('AddressService: Save response status: ${response.statusCode}');
      debugPrint('AddressService: Save response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        
        if (responseData['status'] == true) {
          debugPrint('AddressService: Address saved successfully');
          return {
            'success': true,
            'message': responseData['message'],
            'data': responseData['data'],
          };
        } else {
          debugPrint('AddressService: Save failed: ${responseData['message']}');
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to save address',
          };
        }
      } else if (response.statusCode == 401) {
        debugPrint('AddressService: Unauthorized access');
        return {
          'success': false,
          'message': 'Session expired. Please login again.',
        };
      } else {
        debugPrint('AddressService: Server error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server error occurred. Please try again.',
        };
      }
    } catch (e) {
      debugPrint('AddressService: Exception saving address: $e');
      return {
        'success': false,
        'message': 'Network error occurred. Please check your connection.',
      };
    }
  }

  // Update an existing address
  static Future<Map<String, dynamic>> updateAddress({
    required String addressId,
    required String addressLine1,
    required String addressLine2,
    required String city,
    required String state,
    required String postalCode,
    required String country,
    required double latitude,
    required double longitude,
    bool isDefault = false,
  }) async {
    try {
      debugPrint('AddressService: Updating address...');
      
      final token = await TokenService.getToken();
      final userId = await TokenService.getUserId();
      
      if (token == null || userId == null) {
        debugPrint('AddressService: No token or userId available');
        return {
          'success': false,
          'message': 'Authentication required. Please login again.',
        };
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/api/user/addresses/$addressId');
      
      final payload = {
        'user_id': userId,
        'address_line1': addressLine1,
        'address_line2': addressLine2,
        'city': city,
        'state': state,
        'postal_code': postalCode,
        'country': country,
        'latitude': latitude.toStringAsFixed(8),
        'longitude': longitude.toStringAsFixed(8),
        'is_default': isDefault ? 1 : 0,
      };

      debugPrint('AddressService: Update address payload: $payload');
      
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      debugPrint('AddressService: Update response status: ${response.statusCode}');
      debugPrint('AddressService: Update response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['status'] == true) {
          debugPrint('AddressService: Address updated successfully');
          return {
            'success': true,
            'message': responseData['message'],
            'data': responseData['data'],
          };
        } else {
          debugPrint('AddressService: Update failed: ${responseData['message']}');
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to update address',
          };
        }
      } else if (response.statusCode == 401) {
        debugPrint('AddressService: Unauthorized access');
        return {
          'success': false,
          'message': 'Session expired. Please login again.',
        };
      } else {
        debugPrint('AddressService: Server error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server error occurred. Please try again.',
        };
      }
    } catch (e) {
      debugPrint('AddressService: Exception updating address: $e');
      return {
        'success': false,
        'message': 'Network error occurred. Please check your connection.',
      };
    }
  }

  // Delete an address
  static Future<Map<String, dynamic>> deleteAddress(String addressId) async {
    try {
      debugPrint('AddressService: Deleting address...');
      
      final token = await TokenService.getToken();
      
      if (token == null) {
        debugPrint('AddressService: No token available');
        return {
          'success': false,
          'message': 'Authentication required. Please login again.',
        };
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/api/user/addresses/$addressId');
      
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('AddressService: Delete response status: ${response.statusCode}');
      debugPrint('AddressService: Delete response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['status'] == true) {
          debugPrint('AddressService: Address deleted successfully');
          return {
            'success': true,
            'message': responseData['message'],
          };
        } else {
          debugPrint('AddressService: Delete failed: ${responseData['message']}');
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to delete address',
          };
        }
      } else if (response.statusCode == 401) {
        debugPrint('AddressService: Unauthorized access');
        return {
          'success': false,
          'message': 'Session expired. Please login again.',
        };
      } else {
        debugPrint('AddressService: Server error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server error occurred. Please try again.',
        };
      }
    } catch (e) {
      debugPrint('AddressService: Exception deleting address: $e');
      return {
        'success': false,
        'message': 'Network error occurred. Please check your connection.',
      };
    }
  }
}
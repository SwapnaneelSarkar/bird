import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../constants/api_constant.dart';

class ProfileApiService {
  Future<Map<String, dynamic>> getUserProfile({
    required String token,
    required String userId,
  }) async {
    try {
      debugPrint('Fetching user profile for ID: $userId');
      
      // Build the URL with the user_id
      final url = Uri.parse('${ApiConstants.baseUrl}/api/user/$userId');
      
      // Make the request with the authorization token
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('Profile API Response Status: ${response.statusCode}');
      debugPrint('Profile API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['status'] == true) {
          debugPrint('Profile API: Successfully fetched user profile');
          return {
            'success': true,
            'data': responseData['data'],
            'message': responseData['message'],
          };
        } else {
          debugPrint('Profile API: Server returned error: ${responseData['message']}');
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to fetch profile',
          };
        }
      } else if (response.statusCode == 401) {
        debugPrint('Profile API: Unauthorized access - token may be invalid');
        return {
          'success': false,
          'message': 'Unauthorized. Please login again.',
        };
      } else {
        debugPrint('Profile API: Server error with status code ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server error occurred. Please try again.',
        };
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return {
        'success': false,
        'message': 'Network error occurred. Please check your connection.',
      };
    }
  }
}
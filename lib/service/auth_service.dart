import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constant.dart';

class AuthService {
  Future<Map<String, dynamic>> authenticateUser(String phoneNumber) async {
    try {
      debugPrint('Sending auth request for mobile: $phoneNumber');
      
      final response = await http.post(
        Uri.parse(ApiConstants.authUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'mobile': phoneNumber,
        }),
      );

      debugPrint('Auth API Response Status: ${response.statusCode}');
      debugPrint('Auth API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['status'] == true) {
          // Check if it's login or registration based on the message
          final bool isLogin = responseData['message'] == 'Login successful';
          
          // Get user data
          final userData = responseData['data'] as Map<String, dynamic>;
          final String userId = userData['user_id'] ?? '';
          final String token = responseData['token'] ?? '';
          
          // Save the mobile number
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_phone', phoneNumber);
          
          debugPrint('Auth successful - User ID: $userId');
          debugPrint('Token received: ${token.substring(0, 20)}...');
          
          return {
            'success': true,
            'isLogin': isLogin,
            'data': userData,
            'token': token,
          };
        } else {
          debugPrint('Auth API failed: ${responseData['message']}');
          return {
            'success': false,
            'message': responseData['message'] ?? 'Authentication failed',
          };
        }
      } else {
        debugPrint('Auth API Error: Status ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server error occurred',
        };
      }
    } catch (e) {
      debugPrint('Auth API Exception: $e');
      return {
        'success': false,
        'message': 'Network error occurred',
      };
    }
  }
}
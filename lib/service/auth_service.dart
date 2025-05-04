import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constant.dart';

class AuthService {
  Future<Map<String, dynamic>> authenticateUser(String phoneNumber) async {
    try {
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
          
          return {
            'success': true,
            'isLogin': isLogin,
            'data': responseData['data'],
            'token': responseData['token'],
          };
        } else {
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
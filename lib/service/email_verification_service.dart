import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constant.dart';
import 'token_service.dart';

class EmailVerificationService {
  // Send OTP to email
  Future<Map<String, dynamic>> sendEmailOtp(String email) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'Authentication token not found. Please login again.',
        };
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/user/email/send-otp'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'email': email,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'OTP sent successfully',
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to send OTP',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error. Please check your internet connection.',
      };
    }
  }

  // Resend OTP to email
  Future<Map<String, dynamic>> resendEmailOtp(String email) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'Authentication token not found. Please login again.',
        };
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/user/email/resend-otp'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'email': email,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'OTP resent successfully',
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Failed to resend OTP',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error. Please check your internet connection.',
      };
    }
  }

  // Verify OTP for email
  Future<Map<String, dynamic>> verifyEmailOtp(String email, String otp) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        return {
          'success': false,
          'error': 'Authentication token not found. Please login again.',
        };
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/user/email/verify-otp'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'email': email,
          'otp': otp,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Email verified successfully',
        };
      } else {
        return {
          'success': false,
          'error': data['message'] ?? 'Verification failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error. Please check your internet connection.',
      };
    }
  }
} 
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'lib/constants/api_constant.dart';
import 'lib/service/token_service.dart';

void main() async {
  debugPrint('=== TESTING PAYMENT METHODS API ===');
  
  try {
    // Get token
    final token = await TokenService.getToken();
    if (token == null) {
      debugPrint('ERROR: No authentication token found');
      return;
    }
    
    debugPrint('Token found: ${token.substring(0, 20)}...');
    
    // Test payment methods API
    final url = Uri.parse('${ApiConstants.baseUrl}/api/user/paymentMethods');
    debugPrint('Testing URL: $url');
    
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    
    debugPrint('Response Status: ${response.statusCode}');
    debugPrint('Response Body: ${response.body}');
    
    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        debugPrint('Parsed data: $data');
        
        if (data['status'] == true && data['data'] != null) {
          final methods = data['data'] as List;
          debugPrint('SUCCESS: Found ${methods.length} payment methods');
          for (var method in methods) {
            debugPrint('  - ${method['display_name']} (ID: ${method['id']})');
          }
        } else {
          debugPrint('ERROR: API returned false status or no data');
        }
      } catch (jsonError) {
        debugPrint('ERROR: JSON parsing failed: $jsonError');
      }
    } else {
      debugPrint('ERROR: HTTP ${response.statusCode}');
    }
    
  } catch (e) {
    debugPrint('ERROR: Exception: $e');
  }
  
  debugPrint('=== TEST COMPLETE ===');
} 
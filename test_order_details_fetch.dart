import 'dart:convert';
import 'package:http/http.dart' as http;
import 'lib/constants/api_constant.dart';
import 'lib/service/token_service.dart';

// Simple test to verify order details fetching
Future<void> testOrderDetailsFetch(String orderId) async {
  print('Testing order details fetch for order: $orderId');
  
  try {
    final token = await TokenService.getToken();
    if (token == null) {
      print('❌ No token available');
      return;
    }
    
    final url = Uri.parse('${ApiConstants.baseUrl}/api/user/order/$orderId');
    print('🌐 Request URL: $url');
    
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
    
    print('📡 Response status: ${response.statusCode}');
    print('📡 Response body: ${response.body}');
    
    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      
      if ((responseData['status'] == 'SUCCESS' || responseData['status'] == true) && responseData['data'] != null) {
        print('✅ Order details fetched successfully');
        print('📋 Order data: ${responseData['data']}');
      } else {
        print('❌ Invalid response format');
        print('❌ Status: ${responseData['status']}');
        print('❌ Message: ${responseData['message']}');
      }
    } else {
      print('❌ HTTP error: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Exception: $e');
  }
}

// Usage: testOrderDetailsFetch('your_order_id_here'); 
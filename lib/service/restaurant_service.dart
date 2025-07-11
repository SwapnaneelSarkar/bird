import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constant.dart';
import 'token_service.dart';

class RestaurantService {
  static Future<Map<String, dynamic>?> fetchRestaurantByPartnerId(String partnerId) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        debugPrint('RestaurantService: No authentication token available');
        return null;
      }
      final url = Uri.parse('${ApiConstants.baseUrl}/api/partner/restaurant/$partnerId');
      debugPrint('RestaurantService: Fetching restaurant from: $url');
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      debugPrint('RestaurantService: API Response Status: ${response.statusCode}');
      debugPrint('RestaurantService: API Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        debugPrint('RestaurantService: Parsed response data: $responseData');
        
        if (responseData['status'] == 'SUCCESS' && responseData['data'] != null) {
          final data = responseData['data'] as Map<String, dynamic>;
          debugPrint('RestaurantService: Returning restaurant data: $data');
          return data;
        } else {
          debugPrint('RestaurantService: API returned non-success status: ${responseData['message']}');
          return null;
        }
      } else {
        debugPrint('RestaurantService: API Error: Status ${response.statusCode}');
        debugPrint('RestaurantService: Error response body: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('RestaurantService: Error fetching restaurant: $e');
      return null;
    }
  }
} 
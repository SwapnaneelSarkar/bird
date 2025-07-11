import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constant.dart';
import 'token_service.dart';

class FoodTypeService {
  static Future<List<Map<String, dynamic>>> fetchFoodTypes() async {
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        debugPrint('FoodTypeService: No authentication token available');
        return [];
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/api/admin/restaurantFoodTypes');
      debugPrint('FoodTypeService: Fetching food types from: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('FoodTypeService: API Response Status: ${response.statusCode}');
      debugPrint('FoodTypeService: API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['status'] == 'SUCCESS' && responseData['data'] != null) {
          final List<dynamic> foodTypesData = responseData['data'] as List<dynamic>;
          
          // Filter only active food types
          final List<Map<String, dynamic>> activeFoodTypes = foodTypesData
              .where((foodType) => foodType['active'] == 1)
              .map((foodType) => foodType as Map<String, dynamic>)
              .toList();
          
          debugPrint('FoodTypeService: Found ${activeFoodTypes.length} active food types');
          return activeFoodTypes;
        } else {
          debugPrint('FoodTypeService: API returned non-success status: ${responseData['message']}');
          return [];
        }
      } else {
        debugPrint('FoodTypeService: API Error: Status ${response.statusCode}');
        debugPrint('FoodTypeService: Error response body: ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('FoodTypeService: Error fetching food types: $e');
      return [];
    }
  }
} 
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constant.dart';
import '../service/token_service.dart';
import '../models/attribute_model.dart';

class AttributeService {
  static Future<List<AttributeGroup>> fetchMenuItemAttributes(String menuId) async {
    try {
      debugPrint('AttributeService: Fetching attributes for menu item: $menuId');
      
      final token = await TokenService.getToken();
      if (token == null) {
        debugPrint('AttributeService: No authentication token available');
        return [];
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/api/partner/menu_item/$menuId/attributes');
      
      debugPrint('AttributeService: API URL: $url');

      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('AttributeService: API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['status'] == 'SUCCESS' && responseData['data'] != null) {
          final List<dynamic> attributesData = responseData['data'] as List<dynamic>;
          
          final attributes = attributesData
              .map((data) => AttributeGroup.fromJson(data))
              .where((group) => group.values.isNotEmpty) // Filter out groups with no valid values
              .toList();
          
          debugPrint('AttributeService: Successfully fetched ${attributes.length} attribute groups');
          
          // Log attribute details for debugging
          for (var group in attributes) {
            debugPrint('AttributeService: Group: ${group.name}, Type: ${group.type}, Required: ${group.isRequired}, Values: ${group.values.length}');
          }
          
          return attributes;
        } else {
          debugPrint('AttributeService: API returned non-success status: ${responseData['message']}');
          return [];
        }
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        debugPrint('AttributeService: Authentication error: ${response.statusCode}');
        return [];
      } else {
        debugPrint('AttributeService: API Error: Status ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('AttributeService: Error fetching attributes: $e');
      return [];
    }
  }
} 
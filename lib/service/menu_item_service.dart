import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constant.dart';
import '../service/token_service.dart';

class MenuItemService {
  static Future<Map<String, dynamic>> getMenuItemDetails(String menuId) async {
    try {
      debugPrint('MenuItemService: 🔍 Fetching menu item details for: $menuId');
      
      final token = await TokenService.getToken();
      
      if (token == null) {
        debugPrint('MenuItemService: ❌ No token available');
        return {
          'success': false,
          'message': 'Authentication required. Please login again.',
        };
      }
      
      debugPrint('MenuItemService: ✅ Token available');
      
      final url = Uri.parse('${ApiConstants.baseUrl}/api/partner/menu_item/$menuId');
      
      debugPrint('MenuItemService: 🌐 Menu item URL: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('MenuItemService: 📡 Response status: ${response.statusCode}');
      debugPrint('MenuItemService: 📡 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        debugPrint('MenuItemService: 🔍 Response data status: ${responseData['status']}');
        debugPrint('MenuItemService: 🔍 Response data has data: ${responseData['data'] != null}');
        
        if (responseData['status'] == 'SUCCESS' && responseData['data'] != null) {
          debugPrint('MenuItemService: ✅ Menu item details fetched successfully');
          debugPrint('MenuItemService: 📋 Menu item data: ${responseData['data']}');
          
          return {
            'success': true,
            'data': responseData['data'],
            'message': 'Menu item details fetched successfully',
          };
        } else {
          debugPrint('MenuItemService: ❌ Invalid menu item response');
          debugPrint('MenuItemService: ❌ Response status: ${responseData['status']}');
          debugPrint('MenuItemService: ❌ Response message: ${responseData['message']}');
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to fetch menu item details',
          };
        }
      } else if (response.statusCode == 404) {
        debugPrint('MenuItemService: ❌ Menu item not found (404)');
        return {
          'success': false,
          'message': 'Menu item not found',
        };
      } else if (response.statusCode == 401) {
        debugPrint('MenuItemService: ❌ Unauthorized access (401)');
        return {
          'success': false,
          'message': 'Session expired. Please login again.',
        };
      } else {
        debugPrint('MenuItemService: ❌ Server error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server error occurred. Please try again.',
        };
      }
    } catch (e, stackTrace) {
      debugPrint('MenuItemService: ❌ Exception in menu item details: $e');
      debugPrint('MenuItemService: ❌ Stack trace: $stackTrace');
      return {
        'success': false,
        'message': 'Network error occurred. Please check your connection.',
      };
    }
  }
} 
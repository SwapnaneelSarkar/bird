import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constant.dart';
import '../service/token_service.dart';

class MenuItemService {
  // Cache for menu item details to improve performance
  static final Map<String, Map<String, dynamic>> _menuItemCache = {};
  static const Duration _cacheDuration = Duration(minutes: 10);
  static final Map<String, DateTime> _cacheTimestamps = {};
  
  static Future<Map<String, dynamic>> getMenuItemDetails(String menuId) async {
    // Check cache first
    if (_menuItemCache.containsKey(menuId)) {
      final timestamp = _cacheTimestamps[menuId];
      if (timestamp != null && DateTime.now().difference(timestamp) < _cacheDuration) {
        debugPrint('MenuItemService: ✅ Returning cached menu item details for: $menuId');
        return _menuItemCache[menuId]!;
      } else {
        // Cache expired, remove it
        _menuItemCache.remove(menuId);
        _cacheTimestamps.remove(menuId);
        debugPrint('MenuItemService: 🗑️ Removed expired cache for: $menuId');
      }
    }
    
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
          
          final result = {
            'success': true,
            'data': responseData['data'],
            'message': 'Menu item details fetched successfully',
          };
          
          // Cache the successful result
          _menuItemCache[menuId] = result;
          _cacheTimestamps[menuId] = DateTime.now();
          debugPrint('MenuItemService: 💾 Cached menu item details for: $menuId');
          
          return result;
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
  
  // Clear menu item cache
  static void clearMenuItemCache() {
    _menuItemCache.clear();
    _cacheTimestamps.clear();
    debugPrint('MenuItemService: 🗑️ Cleared all menu item cache');
  }
  
  // Clear cache for specific menu item
  static void clearMenuItemCacheForItem(String menuId) {
    _menuItemCache.remove(menuId);
    _cacheTimestamps.remove(menuId);
    debugPrint('MenuItemService: 🗑️ Cleared cache for menu item: $menuId');
  }
} 
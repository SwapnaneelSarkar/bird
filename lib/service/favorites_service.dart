import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constant.dart';
import 'token_service.dart';

class FavoritesService {
  static const String _baseEndpoint = '/api/user/favorites';

  // Add a restaurant to favorites
  static Future<Map<String, dynamic>?> addToFavorites(String partnerId) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        debugPrint('FavoritesService: No authentication token available');
        return null;
      }

      final url = Uri.parse('${ApiConstants.baseUrl}$_baseEndpoint/add');
      debugPrint('FavoritesService: Adding to favorites: $url');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'partner_id': partnerId,
        }),
      );

      debugPrint('FavoritesService: Add to favorites response status: ${response.statusCode}');
      debugPrint('FavoritesService: Add to favorites response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData;
      } else {
        debugPrint('FavoritesService: Add to favorites error: Status ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('FavoritesService: Error adding to favorites: $e');
      return null;
    }
  }

  // Remove a restaurant from favorites
  static Future<Map<String, dynamic>?> removeFromFavorites(String partnerId) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        debugPrint('FavoritesService: No authentication token available');
        return null;
      }

      final url = Uri.parse('${ApiConstants.baseUrl}$_baseEndpoint/remove');
      debugPrint('FavoritesService: Removing from favorites: $url');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'partner_id': partnerId,
        }),
      );

      debugPrint('FavoritesService: Remove from favorites response status: ${response.statusCode}');
      debugPrint('FavoritesService: Remove from favorites response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData;
      } else {
        debugPrint('FavoritesService: Remove from favorites error: Status ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('FavoritesService: Error removing from favorites: $e');
      return null;
    }
  }

  // Toggle favorite status
  static Future<Map<String, dynamic>?> toggleFavorite(String partnerId) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        debugPrint('FavoritesService: No authentication token available');
        return null;
      }

      final url = Uri.parse('${ApiConstants.baseUrl}$_baseEndpoint/toggle');
      debugPrint('FavoritesService: Toggling favorite: $url');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'partner_id': partnerId,
        }),
      );

      debugPrint('FavoritesService: Toggle favorite response status: ${response.statusCode}');
      debugPrint('FavoritesService: Toggle favorite response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return responseData;
      } else {
        debugPrint('FavoritesService: Toggle favorite error: Status ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('FavoritesService: Error toggling favorite: $e');
      return null;
    }
  }

  // Get all favorites
  static Future<List<Map<String, dynamic>>?> getFavorites() async {
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        debugPrint('FavoritesService: No authentication token available');
        return null;
      }

      final url = Uri.parse('${ApiConstants.baseUrl}$_baseEndpoint');
      debugPrint('FavoritesService: Fetching favorites: $url');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('FavoritesService: Get favorites response status: ${response.statusCode}');
      debugPrint('FavoritesService: Get favorites response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['status'] == true && responseData['data'] != null) {
          final List<dynamic> favoritesList = responseData['data'] as List<dynamic>;
          return favoritesList.map((item) => item as Map<String, dynamic>).toList();
        }
        return [];
      } else if (response.statusCode == 404) {
        // Handle "User not found" gracefully - return empty list instead of error
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['message'] == 'User not found') {
          debugPrint('FavoritesService: User not found in favorites system, returning empty list');
          return [];
        }
        debugPrint('FavoritesService: Get favorites error: Status ${response.statusCode}');
        return null;
      } else {
        debugPrint('FavoritesService: Get favorites error: Status ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('FavoritesService: Error fetching favorites: $e');
      return null;
    }
  }

  // Check if a restaurant is in favorites
  static Future<bool?> checkFavoriteStatus(String partnerId) async {
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        debugPrint('FavoritesService: No authentication token available');
        return null;
      }

      final url = Uri.parse('${ApiConstants.baseUrl}$_baseEndpoint/check/$partnerId');
      debugPrint('FavoritesService: Checking favorite status: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('FavoritesService: Check favorite status response status: ${response.statusCode}');
      debugPrint('FavoritesService: Check favorite status response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['status'] == true && responseData['data'] != null) {
          final data = responseData['data'] as Map<String, dynamic>;
          return data['isFavorite'] as bool? ?? false;
        }
        return false;
      } else {
        debugPrint('FavoritesService: Check favorite status error: Status ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('FavoritesService: Error checking favorite status: $e');
      return null;
    }
  }

  // Get favorites count
  static Future<int?> getFavoritesCount() async {
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        debugPrint('FavoritesService: No authentication token available');
        return null;
      }

      final url = Uri.parse('${ApiConstants.baseUrl}$_baseEndpoint/count');
      debugPrint('FavoritesService: Fetching favorites count: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('FavoritesService: Get favorites count response status: ${response.statusCode}');
      debugPrint('FavoritesService: Get favorites count response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        if (responseData['status'] == true && responseData['data'] != null) {
          final data = responseData['data'] as Map<String, dynamic>;
          return data['count'] as int? ?? 0;
        }
        return 0;
      } else {
        debugPrint('FavoritesService: Get favorites count error: Status ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('FavoritesService: Error fetching favorites count: $e');
      return null;
    }
  }
} 
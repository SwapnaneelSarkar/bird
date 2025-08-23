import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constant.dart';
import 'api_exception.dart';
import 'token_service.dart';

class PartnerRestaurantService {
  static Future<Map<String, dynamic>> fetchRestaurantDetails({
    required String partnerId,
  }) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/partner/restaurant/$partnerId');
      debugPrint('PartnerRestaurantService: GET $url');

      String? token;
      try {
        token = await TokenService.getToken();
      } catch (e) {
        debugPrint('PartnerRestaurantService: Failed to get token: $e');
      }

      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 15));
      debugPrint('PartnerRestaurantService: status ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'];
        if (data is Map<String, dynamic>) {
          return data;
        }
        return <String, dynamic>{};
      } else {
        throw ApiException(message: 'Failed to fetch restaurant details (${response.statusCode})', statusCode: response.statusCode);
      }
    } catch (e) {
      debugPrint('PartnerRestaurantService: error $e');
      rethrow;
    }
  }
} 
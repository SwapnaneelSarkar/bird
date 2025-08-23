import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constant.dart';
import 'api_exception.dart';
import 'token_service.dart';

class PartnerCategoriesService {
  static Future<List<Map<String, dynamic>>> fetchPartnerCategories({required String partnerId}) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/partner/$partnerId/categories');
      debugPrint('PartnerCategoriesService: GET $url');

      String? token;
      try {
        token = await TokenService.getToken();
      } catch (e) {
        debugPrint('PartnerCategoriesService: Failed to get token: $e');
      }

      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(url, headers: headers).timeout(const Duration(seconds: 15));
      debugPrint('PartnerCategoriesService: status ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'];
        if (data is List) {
          return data.map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
        return <Map<String, dynamic>>[];
      } else {
        throw ApiException(message: 'Failed to fetch partner categories (${response.statusCode})', statusCode: response.statusCode);
      }
    } catch (e) {
      debugPrint('PartnerCategoriesService: error $e');
      rethrow;
    }
  }
}


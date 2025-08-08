import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constant.dart';
import '../service/token_service.dart';

class PartnerReviewService {
  static Future<Map<String, dynamic>> fetchPartnerReviews(String partnerId) async {
    try {
      debugPrint('PartnerReviewService: Fetching reviews for partner: $partnerId');
      
      final token = await TokenService.getToken();
      
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication required. Please login again.',
        };
      }
      
      final url = Uri.parse('${ApiConstants.baseUrl}/api/user/reviews/partner/$partnerId');
      
      debugPrint('PartnerReviewService: Request URL: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('PartnerReviewService: Response status: ${response.statusCode}');
      debugPrint('PartnerReviewService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['reviews'] != null) {
          final reviews = responseData['reviews'] as List<dynamic>;
          final total = responseData['total'] ?? 0;
          final averageRating = responseData['average_rating'] ?? '0.0';
          
          return {
            'success': true,
            'data': {
              'reviews': reviews,
              'total': total,
              'average_rating': averageRating,
            },
            'message': 'Reviews fetched successfully',
          };
        } else {
          return {
            'success': false,
            'message': 'No reviews data found',
          };
        }
      } else if (response.statusCode == 404) {
        return {
          'success': true,
          'data': {
            'reviews': [],
            'total': 0,
            'average_rating': '0.0',
          },
          'message': 'No reviews found for this partner',
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Session expired. Please login again.',
        };
      } else {
        return {
          'success': false,
          'message': 'Server error occurred. Please try again.',
        };
      }
    } catch (e) {
      debugPrint('PartnerReviewService: Exception in fetch partner reviews: $e');
      return {
        'success': false,
        'message': 'Network error occurred. Please check your connection.',
      };
    }
  }
} 
// lib/services/review_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constant.dart';
import '../service/token_service.dart';
import '../models/review_model.dart';

class ReviewService {
  static Future<ReviewResponse> submitReview({
    required String orderId,
    required int rating,
    required String reviewText,
    String? partnerId, // Make this optional
  }) async {
    try {
      debugPrint('ReviewService: Submitting review for order: $orderId');
      
      final token = await TokenService.getToken();
      final userId = await TokenService.getUserId();
      
      if (token == null || userId == null) {
        debugPrint('ReviewService: No token or userId available');
        return ReviewResponse(
          status: 'ERROR',
          message: 'Authentication required. Please login again.',
        );
      }

      // Create payload without partner_id if it's empty
      final Map<String, dynamic> payload = {
        'order_id': orderId,
        'rating': rating,
        'review_text': reviewText,
        'user_id': userId,
      };
      
      // Only add partner_id if it's provided and not empty
      if (partnerId != null && partnerId.isNotEmpty) {
        payload['partner_id'] = partnerId;
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/api/user/reviews');
      
      debugPrint('ReviewService: Review API URL: $url');
      debugPrint('ReviewService: Review payload: $payload');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      debugPrint('ReviewService: Review response status: ${response.statusCode}');
      debugPrint('ReviewService: Review response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return ReviewResponse.fromJson(responseData);
      } else if (response.statusCode == 400) {
        final responseData = json.decode(response.body);
        debugPrint('ReviewService: Bad request: ${responseData['error']}');
        return ReviewResponse(
          status: 'ERROR',
          message: responseData['error'] ?? 'Invalid request data.',
        );
      } else if (response.statusCode == 401) {
        debugPrint('ReviewService: Unauthorized access');
        return ReviewResponse(
          status: 'ERROR',
          message: 'Session expired. Please login again.',
        );
      } else {
        debugPrint('ReviewService: Server error: ${response.statusCode}');
        return ReviewResponse(
          status: 'ERROR',
          message: 'Server error occurred. Please try again.',
        );
      }
    } catch (e) {
      debugPrint('ReviewService: Exception in submit review: $e');
      return ReviewResponse(
        status: 'ERROR',
        message: 'Network error occurred. Please check your connection.',
      );
    }
  }
}
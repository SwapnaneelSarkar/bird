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

      // Handle both 200 and 201 as successful responses
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return ReviewResponse.fromJson(responseData);
      } else if (response.statusCode == 400) {
        final responseData = json.decode(response.body);
        debugPrint('ReviewService: Bad request: ${responseData['error']}');
        
        // Check if the error message indicates a duplicate review
        final errorMessage = responseData['error']?.toString().toLowerCase() ?? '';
        final responseMessage = responseData['message']?.toString().toLowerCase() ?? '';
        
        if (errorMessage.contains('already') || 
            errorMessage.contains('duplicate') || 
            errorMessage.contains('exists') ||
            responseMessage.contains('already') || 
            responseMessage.contains('duplicate') || 
            responseMessage.contains('exists')) {
          return ReviewResponse(
            status: 'ERROR',
            message: 'You have already submitted a review for this order.',
          );
        }
        
        return ReviewResponse(
          status: 'ERROR',
          message: responseData['error'] ?? responseData['message'] ?? 'Invalid request data.',
        );
      } else if (response.statusCode == 401) {
        debugPrint('ReviewService: Unauthorized access');
        return ReviewResponse(
          status: 'ERROR',
          message: 'Session expired. Please login again.',
        );
      } else if (response.statusCode == 409) {
        // Handle conflict - review already exists
        debugPrint('ReviewService: Review already exists for this order');
        return ReviewResponse(
          status: 'ERROR',
          message: 'You have already submitted a review for this order.',
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

  // Check if a review already exists for an order using the user reviews API (POST with query parameter)
  static Future<Map<String, dynamic>?> checkReviewExists(String orderId) async {
    try {
      debugPrint('ReviewService: Checking if review exists for order: $orderId');
      
      final token = await TokenService.getToken();
      final userId = await TokenService.getUserId();
      
      if (token == null || userId == null) {
        debugPrint('ReviewService: No token or userId available');
        return null;
      }

      final url = Uri.parse('${ApiConstants.baseUrl}/api/user/user-reviews?user_id=$userId');
      
      debugPrint('ReviewService: Check review exists URL: $url');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('ReviewService: Check review exists response status: ${response.statusCode}');
      debugPrint('ReviewService: Check review exists response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final reviews = responseData['reviews'] as List<dynamic>?;
        
        debugPrint('ReviewService: Found ${reviews?.length ?? 0} reviews for user');
        
        if (reviews != null && reviews.isNotEmpty) {
          // Search for the specific orderId in the reviews
          for (var review in reviews) {
            debugPrint('ReviewService: Checking review with order_id: ${review['order_id']} against target: $orderId');
            if (review['order_id'] == orderId) {
              debugPrint('ReviewService: Found existing review for order: $orderId');
              debugPrint('ReviewService: Review details: $review');
              return {
                'exists': true,
                'review': review,
              };
            }
          }
        }
        
        debugPrint('ReviewService: No existing review found for order: $orderId');
        return {
          'exists': false,
          'review': null,
        };
      } else if (response.statusCode == 404) {
        debugPrint('ReviewService: User not found or no reviews available');
        return {
          'exists': false,
          'review': null,
        };
      } else {
        debugPrint('ReviewService: Failed to fetch reviews: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('ReviewService: Exception in check review exists: $e');
      return null;
    }
  }
}
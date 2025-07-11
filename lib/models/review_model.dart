// lib/models/review_model.dart
class ReviewRequest {
  final String? partnerId; // Make optional
  final int rating;
  final String orderId;
  final String reviewText;
  final String userId;

  ReviewRequest({
    this.partnerId, // Make optional
    required this.rating,
    required this.orderId,
    required this.reviewText,
    required this.userId,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'rating': rating,
      'order_id': orderId,
      'review_text': reviewText,
      'user_id': userId,
    };
    
    // Only add partner_id if it's not null and not empty
    if (partnerId != null && partnerId!.isNotEmpty) {
      json['partner_id'] = partnerId;
    }
    
    return json;
  }
}

class ReviewResponse {
  final String status;
  final String message;
  final ReviewData? data;

  ReviewResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory ReviewResponse.fromJson(Map<String, dynamic> json) {
    // Handle different response formats
    String status = json['status'] ?? '';
    String message = json['message'] ?? '';
    
    // If status is empty but message indicates success, set status to SUCCESS
    if (status.isEmpty && message.toLowerCase().contains('successfully')) {
      status = 'SUCCESS';
    }
    
    return ReviewResponse(
      status: status,
      message: message,
      data: json['data'] != null ? ReviewData.fromJson(json['data']) : null,
    );
  }
}

class ReviewData {
  final String orderId;
  final String newStatus;
  final DateTime updatedAt;

  ReviewData({
    required this.orderId,
    required this.newStatus,
    required this.updatedAt,
  });

  factory ReviewData.fromJson(Map<String, dynamic> json) {
    return ReviewData(
      orderId: json['order_id'] ?? '',
      newStatus: json['new_status'] ?? '',
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}
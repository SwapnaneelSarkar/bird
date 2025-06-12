// models/cancel_order_model.dart
class CancelOrderResponse {
  final bool status;
  final String message;
  final CancelOrderData? data;

  CancelOrderResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory CancelOrderResponse.fromJson(Map<String, dynamic> json) {
    return CancelOrderResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? CancelOrderData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

class CancelOrderData {
  final String orderId;
  final String status;

  CancelOrderData({
    required this.orderId,
    required this.status,
  });

  factory CancelOrderData.fromJson(Map<String, dynamic> json) {
    return CancelOrderData(
      orderId: json['order_id'] ?? '',
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'status': status,
    };
  }
}
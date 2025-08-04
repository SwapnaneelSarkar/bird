import 'package:equatable/equatable.dart';

class RecentOrderModel extends Equatable {
  final String orderId;
  final String partnerId;
  final String totalPrice;
  final String address;
  final String orderStatus;
  final String createdAt;
  final String supercategoryName;
  final String? supercategoryId; // Add supercategory ID field

  const RecentOrderModel({
    required this.orderId,
    required this.partnerId,
    required this.totalPrice,
    required this.address,
    required this.orderStatus,
    required this.createdAt,
    required this.supercategoryName,
    this.supercategoryId, // Add supercategory ID parameter
  });

  @override
  List<Object?> get props => [
    orderId,
    partnerId,
    totalPrice,
    address,
    orderStatus,
    createdAt,
    supercategoryName,
    supercategoryId, // Add supercategory ID to props
  ];

  factory RecentOrderModel.fromJson(Map<String, dynamic> json) {
    // Handle supercategory parsing - it can be either an object or a string
    String supercategoryName = 'Unknown';
    String? supercategoryId;
    
    if (json['supercategory'] != null) {
      if (json['supercategory'] is Map<String, dynamic>) {
        // Supercategory is an object with id and name
        final supercategoryData = json['supercategory'] as Map<String, dynamic>;
        supercategoryName = supercategoryData['name']?.toString() ?? 'Unknown';
        supercategoryId = supercategoryData['id']?.toString();
      } else if (json['supercategory'] is String) {
        // Supercategory is a string (just the ID)
        supercategoryName = 'Unknown';
        supercategoryId = json['supercategory'].toString();
      }
    }
    
    return RecentOrderModel(
      orderId: json['order_id'] ?? '',
      partnerId: json['partner_id'] ?? '',
      totalPrice: json['total_price']?.toString() ?? '0',
      address: json['address'] ?? '',
      orderStatus: json['order_status'] ?? 'UNKNOWN',
      createdAt: json['created_at'] ?? '',
      supercategoryName: supercategoryName,
      supercategoryId: supercategoryId,
    );
  }
} 
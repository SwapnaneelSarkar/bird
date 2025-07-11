// lib/models/order_details_model.dart
import '../utils/timezone_utils.dart';

class OrderDetails {
  final String orderId;
  final String userId;
  final List<String> itemIds;
  final List<OrderDetailsItem> items;
  final double totalAmount;
  final double deliveryFees;
  final String orderStatus;
  final DateTime? createdAt;
  final String? restaurantName;
  final String? deliveryAddress;
  final String? partnerId; // Add this field
  final String? paymentMode; // Add payment mode field

  OrderDetails({
    required this.orderId,
    required this.userId,
    required this.itemIds,
    required this.items,
    required this.totalAmount,
    required this.deliveryFees,
    required this.orderStatus,
    this.createdAt,
    this.restaurantName,
    this.deliveryAddress,
    this.partnerId, // Add this parameter
    this.paymentMode, // Add payment mode parameter
  });

  factory OrderDetails.fromJson(Map<String, dynamic> json) {
    List<OrderDetailsItem> orderItems = [];
    if (json['items'] != null) {
      orderItems = (json['items'] as List)
          .map((item) => OrderDetailsItem.fromJson(item))
          .toList();
    }

    return OrderDetails(
      orderId: json['order_id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      itemIds: json['item_ids'] != null
          ? List<String>.from(json['item_ids'])
          : [],
      items: orderItems,
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      deliveryFees: double.tryParse(json['delivery_fees']?.toString() ?? '0') ?? 0.0,
      orderStatus: json['order_status']?.toString() ?? 'Unknown',
      createdAt: json['created_at'] != null
          ? TimezoneUtils.parseToIST(json['created_at'].toString())
          : null,
      restaurantName: json['restaurant_name']?.toString(),
      deliveryAddress: json['delivery_address']?.toString(),
      partnerId: json['partner_id']?.toString() ?? json['restaurant_id']?.toString(), // Add this line
      paymentMode: json['payment_mode']?.toString(), // Add payment mode parsing
    );
  }

  double get subtotal => totalAmount;

  double get grandTotal => totalAmount + deliveryFees;

  bool get canBeCancelled {
    return orderStatus.toLowerCase() == 'pending' ||
           orderStatus.toLowerCase() == 'preparing';
  }

  String get statusDisplayText {
    switch (orderStatus.toLowerCase()) {
      case 'pending':
        return 'Order Placed';
      case 'preparing':
        return 'Preparing';
      case 'ready':
        return 'Ready for Pickup';
      case 'on_the_way':
        return 'On the Way';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return orderStatus;
    }
  }
}

class OrderDetailsItem {
  final String menuId;
  final int quantity;
  final double itemPrice;
  final String? itemName;
  final String? imageUrl;

  OrderDetailsItem({
    required this.menuId,
    required this.quantity,
    required this.itemPrice,
    this.itemName,
    this.imageUrl,
  });

  factory OrderDetailsItem.fromJson(Map<String, dynamic> json) {
    return OrderDetailsItem(
      menuId: json['menu_id']?.toString() ?? '',
      quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      itemPrice: double.tryParse(json['item_price']?.toString() ?? '0') ?? 0.0,
      itemName: json['item_name']?.toString(),
      imageUrl: json['image_url']?.toString(),
    );
  }

  double get totalPrice => itemPrice * quantity;
}
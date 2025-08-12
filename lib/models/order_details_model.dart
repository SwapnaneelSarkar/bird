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
  final String? restaurantAddress; // ADDED: Restaurant address
  final double? rating; // ADDED: Food rating
  final String? reviewText; // ADDED: Review text
  final bool? isCancellable; // ADDED: Whether order can be cancelled from API

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
    this.restaurantAddress, // ADDED
    this.rating, // ADDED
    this.reviewText, // ADDED
    this.isCancellable, // ADDED
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
      restaurantAddress: json['restaurant_address'], // ADDED
      rating: json['rating'] != null ? double.tryParse(json['rating'].toString()) : null, // ADDED
      reviewText: json['review_text']?.toString(), // ADDED
      isCancellable: json['isCancellable'] as bool?, // ADDED
    );
  }

  // ADDED: Method to update restaurant address
  OrderDetails copyWithRestaurantAddress(String? address) {
    return OrderDetails(
      orderId: orderId,
      userId: userId,
      itemIds: itemIds,
      items: items,
      totalAmount: totalAmount,
      deliveryFees: deliveryFees,
      orderStatus: orderStatus,
      createdAt: createdAt,
      restaurantName: restaurantName,
      deliveryAddress: deliveryAddress,
      partnerId: partnerId,
      paymentMode: paymentMode,
      restaurantAddress: address,
      rating: rating,
      reviewText: reviewText,
      isCancellable: isCancellable,
    );
  }

  // ADDED: Method to update rating and review
  OrderDetails copyWithRating(double? rating, String? reviewText) {
    return OrderDetails(
      orderId: orderId,
      userId: userId,
      itemIds: itemIds,
      items: items,
      totalAmount: totalAmount,
      deliveryFees: deliveryFees,
      orderStatus: orderStatus,
      createdAt: createdAt,
      restaurantName: restaurantName,
      deliveryAddress: deliveryAddress,
      partnerId: partnerId,
      paymentMode: paymentMode,
      restaurantAddress: restaurantAddress,
      rating: rating,
      reviewText: reviewText,
      isCancellable: isCancellable,
    );
  }

  double get subtotal => totalAmount;

  double get grandTotal => totalAmount + deliveryFees;

  bool get canBeCancelled {
    // Use the isCancellable field from API if available, otherwise fall back to status-based logic
    if (isCancellable != null) {
      return isCancellable!;
    }
    // Fallback to status-based logic for backward compatibility
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
  final Map<String, dynamic>? attributes; // ADDED: Item attributes

  OrderDetailsItem({
    required this.menuId,
    required this.quantity,
    required this.itemPrice,
    this.itemName,
    this.imageUrl,
    this.attributes, // ADDED
  });

  factory OrderDetailsItem.fromJson(Map<String, dynamic> json) {
    return OrderDetailsItem(
      menuId: json['menu_id']?.toString() ?? '',
      quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
      itemPrice: double.tryParse(json['item_price']?.toString() ?? '0') ?? 0.0,
      itemName: json['item_name']?.toString(),
      imageUrl: json['image_url']?.toString(),
      attributes: json['attributes'] != null ? Map<String, dynamic>.from(json['attributes']) : null, // ADDED
    );
  }

  double get totalPrice => itemPrice * quantity;
}
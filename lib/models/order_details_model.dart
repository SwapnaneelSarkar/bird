// lib/models/order_details_model.dart
import 'package:flutter/foundation.dart';
import '../utils/timezone_utils.dart';
import '../utils/currency_formatter.dart';

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
  final String? currency; // ADDED: Currency from API

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
    this.currency, // ADDED
  });

  factory OrderDetails.fromJson(Map<String, dynamic> json) {
    List<OrderDetailsItem> orderItems = [];
    if (json['items'] != null) {
      orderItems = (json['items'] as List)
          .map((item) => OrderDetailsItem.fromJson(item))
          .toList();
    }

    // Parse created_at field with better error handling
    DateTime? parsedCreatedAt;
    if (json['created_at'] != null) {
      try {
        parsedCreatedAt = TimezoneUtils.parseToIST(json['created_at'].toString());
        debugPrint('OrderDetails: ✅ Successfully parsed created_at: ${json['created_at']} -> ${parsedCreatedAt}');
      } catch (e) {
        debugPrint('OrderDetails: ❌ Error parsing created_at: ${json['created_at']} - $e');
        parsedCreatedAt = null;
      }
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
      createdAt: parsedCreatedAt,
      restaurantName: json['restaurant_name']?.toString(),
      deliveryAddress: json['delivery_address']?.toString(),
      partnerId: json['partner_id']?.toString() ?? json['restaurant_id']?.toString(), // Add this line
      paymentMode: json['payment_mode']?.toString(), // Add payment mode parsing
      restaurantAddress: json['restaurant_address'], // ADDED
      rating: json['rating'] != null ? double.tryParse(json['rating'].toString()) : null, // ADDED
      reviewText: json['review_text']?.toString(), // ADDED
      isCancellable: json['isCancellable'] as bool?, // ADDED
      currency: json['currency']?.toString(), // ADDED
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
      currency: currency,
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
      currency: currency,
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

  // ADDED: Get formatted created date and time in IST
  String get formattedCreatedDateTime {
    if (createdAt == null) {
      return 'Date not available';
    }
    return TimezoneUtils.formatOrderDateTime(createdAt!);
  }

  // ADDED: Get formatted created date only in IST
  String get formattedCreatedDate {
    if (createdAt == null) {
      return 'Date not available';
    }
    return TimezoneUtils.formatOrderDate(createdAt!);
  }

  // ADDED: Get formatted created time only in IST
  String get formattedCreatedTime {
    if (createdAt == null) {
      return 'Time not available';
    }
    return TimezoneUtils.formatTimeOnly(createdAt!);
  }

  // ADDED: Get status color for highlighting
  int get statusColor {
    switch (orderStatus.toLowerCase()) {
      case 'pending':
        return 0xFFFFA500; // Orange
      case 'preparing':
        return 0xFF2196F3; // Blue
      case 'ready':
        return 0xFF4CAF50; // Green
      case 'on_the_way':
        return 0xFF9C27B0; // Purple
      case 'delivered':
        return 0xFF4CAF50; // Green
      case 'cancelled':
        return 0xFFF44336; // Red
      default:
        return 0xFF757575; // Grey
    }
  }

  // ADDED: Get currency symbol using CurrencyFormatter
  String get currencySymbol {
    return CurrencyFormatter.getCurrencySymbol(currency);
  }

  // ADDED: Get formatted price using CurrencyFormatter
  String getFormattedPrice(double amount) {
    return CurrencyFormatter.formatPrice(amount, currency);
  }

  // ADDED: Get formatted price with custom decimal places
  String getFormattedPriceWithDecimals(double amount, int decimalDigits) {
    return CurrencyFormatter.formatPriceWithDecimals(amount, currency, decimalDigits);
  }

  // ADDED: Get currency name
  String get currencyName {
    return CurrencyFormatter.getCurrencyName(currency);
  }

  // ADDED: Get status background color for highlighting
  int get statusBackgroundColor {
    switch (orderStatus.toLowerCase()) {
      case 'pending':
        return 0xFFFFF3E0; // Light Orange
      case 'preparing':
        return 0xFFE3F2FD; // Light Blue
      case 'ready':
        return 0xFFE8F5E8; // Light Green
      case 'on_the_way':
        return 0xFFF3E5F5; // Light Purple
      case 'delivered':
        return 0xFFE8F5E8; // Light Green
      case 'cancelled':
        return 0xFFFFEBEE; // Light Red
      default:
        return 0xFFF5F5F5; // Light Grey
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
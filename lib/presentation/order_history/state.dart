// lib/presentation/order_history/state.dart - Updated OrderItem model
import 'package:equatable/equatable.dart';
import '../../constants/api_constant.dart';
import '../../utils/timezone_utils.dart';
import 'package:flutter/foundation.dart';

abstract class OrderHistoryState extends Equatable {
  const OrderHistoryState();
  
  @override
  List<Object?> get props => [];
}

class OrderHistoryInitial extends OrderHistoryState {}

class OrderHistoryLoading extends OrderHistoryState {}

class OrderHistoryLoaded extends OrderHistoryState {
  final List<OrderItem> allOrders;
  final List<OrderItem> filteredOrders;
  final String selectedFilter;
  final List<String> filterTabs;

  const OrderHistoryLoaded({
    required this.allOrders,
    required this.filteredOrders,
    required this.selectedFilter,
    required this.filterTabs,
  });

  OrderHistoryLoaded copyWith({
    List<OrderItem>? allOrders,
    List<OrderItem>? filteredOrders,
    String? selectedFilter,
    List<String>? filterTabs,
  }) {
    return OrderHistoryLoaded(
      allOrders: allOrders ?? this.allOrders,
      filteredOrders: filteredOrders ?? this.filteredOrders,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      filterTabs: filterTabs ?? this.filterTabs,
    );
  }

  @override
  List<Object?> get props => [allOrders, filteredOrders, selectedFilter, filterTabs];
}

class OrderHistoryError extends OrderHistoryState {
  final String message;

  const OrderHistoryError(this.message);

  @override
  List<Object?> get props => [message];
}

class OrderItem extends Equatable {
  final String id;
  final String name;
  final String restaurantName;
  final String date;
  final double price;
  final String status;
  final String imageUrl;
  final DateTime dateTime;
  final String restaurantId;
  final List<Map<String, dynamic>> items;
  final String? restaurantAddress; // ADDED: Restaurant address
  final String? deliveryAddress; // ADDED: Delivery address
  final double? rating; // ADDED: Food rating
  final String? reviewText; // ADDED: Review text
  final double? restaurantRating; // ADDED: Restaurant rating

  const OrderItem({
    required this.id,
    required this.name,
    required this.restaurantName,
    required this.date,
    required this.price,
    required this.status,
    required this.imageUrl,
    required this.dateTime,
    this.restaurantId = '',
    this.items = const [],
    this.restaurantAddress, // ADDED
    this.deliveryAddress, // ADDED
    this.rating, // ADDED
    this.reviewText, // ADDED
    this.restaurantRating, // ADDED
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    // Debug logging for price fields
    debugPrint('OrderItem.fromJson: Price fields from API:');
    debugPrint('  - total_price: ${json['total_price']} (items only)');
    debugPrint('  - delivery_fees: ${json['delivery_fees']}');
    debugPrint('  - subtotal: ${json['subtotal']} (total including delivery)');
    
    // Use subtotal as the price since it includes delivery fees
    final price = double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0;
    
    debugPrint('  - Final price used: $price');
    
    return OrderItem(
      id: json['order_id'] ?? json['_id'] ?? json['id'] ?? '', // FIXED: Use order_id
      name: json['restaurant_name'] ?? 'Order',
      restaurantName: json['restaurant_name'] ?? 'Unknown Restaurant',
      date: _formatDate(json['datetime']),
      price: price,
      status: _mapStatus(json['order_status'] ?? json['status']), // FIXED: Use order_status
      imageUrl: _getFullImageUrl(json['restaurant_picture'] ?? ''),
      dateTime: TimezoneUtils.parseToIST(json['datetime'] ?? ''),
      restaurantId: json['restaurant_id'] ?? json['partner_id'] ?? '', // ADDED: Use partner_id as fallback
      items: List<Map<String, dynamic>>.from(json['items'] ?? []),
      restaurantAddress: json['restaurant_address'], // ADDED: Will be populated later
      deliveryAddress: json['delivery_address'], // ADDED: From API response
      rating: null, // ADDED: Will be populated later from reviews API
      reviewText: null, // ADDED: Will be populated later from reviews API
      restaurantRating: null, // ADDED: Will be populated later from restaurant API
    );
  }

  // ADDED: Method to update restaurant address
  OrderItem copyWithRestaurantAddress(String? address) {
    return OrderItem(
      id: id,
      name: name,
      restaurantName: restaurantName,
      date: date,
      price: price,
      status: status,
      imageUrl: imageUrl,
      dateTime: dateTime,
      restaurantId: restaurantId,
      items: items,
      restaurantAddress: address,
      deliveryAddress: deliveryAddress,
      rating: rating,
      reviewText: reviewText,
      restaurantRating: restaurantRating,
    );
  }

  // ADDED: Method to update rating and review
  OrderItem copyWithRating(double? rating, String? reviewText) {
    return OrderItem(
      id: id,
      name: name,
      restaurantName: restaurantName,
      date: date,
      price: price,
      status: status,
      imageUrl: imageUrl,
      dateTime: dateTime,
      restaurantId: restaurantId,
      items: items,
      restaurantAddress: restaurantAddress,
      deliveryAddress: deliveryAddress,
      rating: rating,
      reviewText: reviewText,
      restaurantRating: restaurantRating,
    );
  }

  // ADDED: Method to update restaurant rating
  OrderItem copyWithRestaurantRating(double? restaurantRating) {
    return OrderItem(
      id: id,
      name: name,
      restaurantName: restaurantName,
      date: date,
      price: price,
      status: status,
      imageUrl: imageUrl,
      dateTime: dateTime,
      restaurantId: restaurantId,
      items: items,
      restaurantAddress: restaurantAddress,
      deliveryAddress: deliveryAddress,
      rating: rating,
      reviewText: reviewText,
      restaurantRating: restaurantRating,
    );
  }

  static String _formatDate(String? dateTimeStr) {
    if (dateTimeStr == null) return 'Unknown date';
    try {
      final dateTime = TimezoneUtils.parseToIST(dateTimeStr);
      return TimezoneUtils.formatOrderDateTime(dateTime);
    } catch (e) {
      return 'Unknown date';
    }
  }

  static String _mapStatus(String? status) {
    // Return the status as it comes from the API without any mapping
    return status ?? 'Unknown';
  }

  // Helper method to get the full image URL
  static String _getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }
    
    // Handle JSON-encoded URLs (remove quotes and brackets if present)
    String cleanPath = imagePath;
    if (cleanPath.startsWith('["') && cleanPath.endsWith('"]')) {
      cleanPath = cleanPath.substring(2, cleanPath.length - 2);
    } else if (cleanPath.startsWith('"') && cleanPath.endsWith('"')) {
      cleanPath = cleanPath.substring(1, cleanPath.length - 1);
    }
    
    // Check if the image path already has the base URL
    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      return cleanPath;
    }
    
    return '${ApiConstants.baseUrl}/api/${cleanPath.startsWith('/') ? cleanPath.substring(1) : cleanPath}';
  }

  @override
  List<Object?> get props => [id, name, restaurantName, date, price, status, imageUrl, dateTime, restaurantAddress, deliveryAddress, rating, reviewText, restaurantRating];
}

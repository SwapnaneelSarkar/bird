import 'package:equatable/equatable.dart';

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
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['restaurant_name'] ?? 'Order',
      restaurantName: json['restaurant_name'] ?? 'Unknown Restaurant',
      date: _formatDate(json['datetime']),
      price: double.tryParse(json['total_price']?.toString() ?? '0') ?? 0.0,
      status: _mapStatus(json['status']),
      imageUrl: json['restaurant_picture'] ?? '',
      dateTime: DateTime.tryParse(json['datetime'] ?? '') ?? DateTime.now(),
      restaurantId: json['restaurant_id'] ?? '',
      items: List<Map<String, dynamic>>.from(json['items'] ?? []),
    );
  }

  static String _formatDate(String? dateTimeStr) {
    if (dateTimeStr == null) return 'Unknown date';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[dateTime.month - 1]} ${dateTime.day}, ${dateTime.year}';
    } catch (e) {
      return 'Unknown date';
    }
  }

  static String _mapStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return 'Delivered';
      case 'pending':
      case 'ongoing':
      case 'preparing':
        return 'Ongoing';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status ?? 'Unknown';
    }
  }

  @override
  List<Object?> get props => [id, name, restaurantName, date, price, status, imageUrl, dateTime];
}
// lib/presentation/order_details/state.dart
import 'package:equatable/equatable.dart';

abstract class OrderDetailsState extends Equatable {
  const OrderDetailsState();

  @override
  List<Object?> get props => [];
}

class OrderDetailsInitial extends OrderDetailsState {}

class OrderDetailsLoading extends OrderDetailsState {}

class OrderDetailsLoaded extends OrderDetailsState {
  final Map<String, dynamic> orderDetails;
  final Map<String, MenuItemDetail> menuItemDetails;

  const OrderDetailsLoaded({
    required this.orderDetails,
    required this.menuItemDetails,
  });

  OrderDetailsLoaded copyWith({
    Map<String, dynamic>? orderDetails,
    Map<String, MenuItemDetail>? menuItemDetails,
  }) {
    return OrderDetailsLoaded(
      orderDetails: orderDetails ?? this.orderDetails,
      menuItemDetails: menuItemDetails ?? this.menuItemDetails,
    );
  }

  @override
  List<Object?> get props => [orderDetails, menuItemDetails];
}

class OrderDetailsError extends OrderDetailsState {
  final String message;

  const OrderDetailsError(this.message);

  @override
  List<Object?> get props => [message];
}

class MenuItemDetail extends Equatable {
  final String name;
  final String price;
  final String description;

  const MenuItemDetail({
    required this.name,
    required this.price,
    required this.description,
  });

  factory MenuItemDetail.fromJson(Map<String, dynamic> json) {
    return MenuItemDetail(
      name: json['name'] ?? '',
      price: json['price'] ?? '0.00',
      description: json['description'] ?? '',
    );
  }

  @override
  List<Object?> get props => [name, price, description];
}
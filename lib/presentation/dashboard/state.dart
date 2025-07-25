// lib/presentation/category_homepage/state.dart
import 'package:equatable/equatable.dart';

abstract class CategoryHomepageState extends Equatable {
  const CategoryHomepageState();

  @override
  List<Object?> get props => [];
}

class CategoryHomepageInitial extends CategoryHomepageState {
  const CategoryHomepageInitial();
}

class CategoryHomepageLoading extends CategoryHomepageState {
  const CategoryHomepageLoading();
}

class CategoryHomepageLoaded extends CategoryHomepageState {
  final List<CategoryModel> categories;
  final List<RecentOrderModel> recentOrders;
  final Map<String, dynamic>? userData;
  final String userName;
  final String userAddress;

  const CategoryHomepageLoaded({
    required this.categories,
    required this.recentOrders,
    this.userData,
    required this.userName,
    required this.userAddress,
  });

  @override
  List<Object?> get props => [categories, recentOrders, userData, userName, userAddress];

  CategoryHomepageLoaded copyWith({
    List<CategoryModel>? categories,
    List<RecentOrderModel>? recentOrders,
    Map<String, dynamic>? userData,
    String? userName,
    String? userAddress,
  }) {
    return CategoryHomepageLoaded(
      categories: categories ?? this.categories,
      recentOrders: recentOrders ?? this.recentOrders,
      userData: userData ?? this.userData,
      userName: userName ?? this.userName,
      userAddress: userAddress ?? this.userAddress,
    );
  }
}

class CategoryHomepageError extends CategoryHomepageState {
  final String message;

  const CategoryHomepageError({required this.message});

  @override
  List<Object?> get props => [message];
}

class CategorySelected extends CategoryHomepageState {
  final String categoryId;
  final String categoryName;

  const CategorySelected({
    required this.categoryId,
    required this.categoryName,
  });

  @override
  List<Object?> get props => [categoryId, categoryName];
}

// Data Models
class CategoryModel extends Equatable {
  final String id;
  final String name;

  const CategoryModel({
    required this.id,
    required this.name,
  });

  @override
  List<Object?> get props => [id, name];

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

class RecentOrderModel extends Equatable {
  final String orderId;
  final String partnerId;
  final String totalPrice;
  final String address;
  final String orderStatus;
  final String createdAt;
  final String supercategoryName;

  const RecentOrderModel({
    required this.orderId,
    required this.partnerId,
    required this.totalPrice,
    required this.address,
    required this.orderStatus,
    required this.createdAt,
    required this.supercategoryName,
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
  ];

  factory RecentOrderModel.fromJson(Map<String, dynamic> json) {
    return RecentOrderModel(
      orderId: json['order_id'] ?? '',
      partnerId: json['partner_id'] ?? '',
      totalPrice: json['total_price']?.toString() ?? '0',
      address: json['address'] ?? '',
      orderStatus: json['order_status'] ?? 'UNKNOWN',
      createdAt: json['created_at'] ?? '',
      supercategoryName: json['supercategory']?['name'] ?? 'Unknown',
    );
  }
}
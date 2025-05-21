import 'package:equatable/equatable.dart';

abstract class RestaurantDetailsEvent extends Equatable {
  const RestaurantDetailsEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadRestaurantDetails extends RestaurantDetailsEvent {
  final Map<String, dynamic> restaurant;
  final double? userLatitude;
  final double? userLongitude;
  
  const LoadRestaurantDetails(
    this.restaurant, {
    this.userLatitude,
    this.userLongitude,
  });
  
  @override
  List<Object?> get props => [restaurant, userLatitude, userLongitude];
}

class AddItemToCart extends RestaurantDetailsEvent {
  final Map<String, dynamic> item;
  final int quantity;
  
  const AddItemToCart({
    required this.item,
    required this.quantity,
  });
  
  @override
  List<Object?> get props => [item, quantity];
}

class ToggleFavorite extends RestaurantDetailsEvent {
  const ToggleFavorite();
}
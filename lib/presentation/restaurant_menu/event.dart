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
  final Map<String, dynamic>? attributes;
  
  const AddItemToCart({
    required this.item,
    required this.quantity,
    this.attributes,
  });
  
  @override
  List<Object?> get props => [item, quantity, attributes];
}

class ReplaceCartWithNewRestaurant extends RestaurantDetailsEvent {
  final Map<String, dynamic> item;
  final int quantity;
  
  const ReplaceCartWithNewRestaurant({
    required this.item,
    required this.quantity,
  });
  
  @override
  List<Object?> get props => [item, quantity];
}

class LoadCartData extends RestaurantDetailsEvent {
  const LoadCartData();
}

class DismissCartConflict extends RestaurantDetailsEvent {
  const DismissCartConflict();
}

class ToggleFavorite extends RestaurantDetailsEvent {
  const ToggleFavorite();
}
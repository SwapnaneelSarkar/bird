// state.dart
import 'package:equatable/equatable.dart';

abstract class RestaurantDetailsState extends Equatable {
  const RestaurantDetailsState();
  
  @override
  List<Object?> get props => [];
}

class RestaurantDetailsInitial extends RestaurantDetailsState {}

class RestaurantDetailsLoading extends RestaurantDetailsState {}

class RestaurantDetailsLoaded extends RestaurantDetailsState {
  final Map<String, dynamic> restaurant;
  final List<Map<String, dynamic>> menu;
  final List<Map<String, dynamic>> cartItems;
  final bool isFavorite;
  
  const RestaurantDetailsLoaded({
    required this.restaurant,
    required this.menu,
    required this.cartItems,
    required this.isFavorite,
  });
  
  @override
  List<Object?> get props => [restaurant, menu, cartItems, isFavorite];
  
  RestaurantDetailsLoaded copyWith({
    Map<String, dynamic>? restaurant,
    List<Map<String, dynamic>>? menu,
    List<Map<String, dynamic>>? cartItems,
    bool? isFavorite,
  }) {
    return RestaurantDetailsLoaded(
      restaurant: restaurant ?? this.restaurant,
      menu: menu ?? this.menu,
      cartItems: cartItems ?? this.cartItems,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

// state.dart (just this specific class - leave the rest unchanged)
class RestaurantDetailsError extends RestaurantDetailsState {
  final String message;
  final bool needsLogin;
  
  const RestaurantDetailsError(this.message, {this.needsLogin = false});
  
  @override
  List<Object?> get props => [message, needsLogin];
}

class CartUpdateSuccess extends RestaurantDetailsState {
  final String message;
  
  const CartUpdateSuccess(this.message);
  
  @override
  List<Object?> get props => [message];
}
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
  final Map<String, int> cartQuantities;
  final bool isFavorite;
  final int cartItemCount;
  final double cartTotal;
  
  const RestaurantDetailsLoaded({
    required this.restaurant,
    required this.menu,
    required this.cartQuantities,
    required this.isFavorite,
    this.cartItemCount = 0,
    this.cartTotal = 0.0,
  });
  
  @override
  List<Object?> get props => [
    restaurant, 
    menu, 
    cartQuantities, 
    isFavorite, 
    cartItemCount, 
    cartTotal
  ];
  
  RestaurantDetailsLoaded copyWith({
    Map<String, dynamic>? restaurant,
    List<Map<String, dynamic>>? menu,
    Map<String, int>? cartQuantities,
    bool? isFavorite,
    int? cartItemCount,
    double? cartTotal,
  }) {
    return RestaurantDetailsLoaded(
      restaurant: restaurant ?? this.restaurant,
      menu: menu ?? this.menu,
      cartQuantities: cartQuantities ?? this.cartQuantities,
      isFavorite: isFavorite ?? this.isFavorite,
      cartItemCount: cartItemCount ?? this.cartItemCount,
      cartTotal: cartTotal ?? this.cartTotal,
    );
  }
}

class RestaurantDetailsError extends RestaurantDetailsState {
  final String message;
  final bool needsLogin;
  
  const RestaurantDetailsError(this.message, {this.needsLogin = false});
  
  @override
  List<Object?> get props => [message, needsLogin];
}

// REMOVED: CartUpdateSuccess and CartUpdateError states
// These were causing the OpenGL UI rebuild issues

class CartConflictDetected extends RestaurantDetailsState {
  final String currentRestaurant;
  final String newRestaurant;
  final Map<String, dynamic> pendingItem;
  final int pendingQuantity;
  final RestaurantDetailsLoaded previousState;
  
  const CartConflictDetected({
    required this.currentRestaurant,
    required this.newRestaurant,
    required this.pendingItem,
    required this.pendingQuantity,
    required this.previousState,
  });
  
  @override
  List<Object?> get props => [
    currentRestaurant, 
    newRestaurant, 
    pendingItem, 
    pendingQuantity,
    previousState,
  ];
}
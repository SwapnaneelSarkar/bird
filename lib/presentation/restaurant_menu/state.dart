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
  final List<Map<String, dynamic>> categories;
  final Map<String, int> cartQuantities;
  final bool isFavorite;
  final int cartItemCount;
  final double cartTotal;
  final Set<String> collapsedCategories;
  
  const RestaurantDetailsLoaded({
    required this.restaurant,
    required this.menu,
    required this.categories,
    required this.cartQuantities,
    required this.isFavorite,
    this.cartItemCount = 0,
    this.cartTotal = 0.0,
    this.collapsedCategories = const {},
  });
  
  @override
  List<Object?> get props => [
    restaurant, 
    menu, 
    categories,
    cartQuantities, 
    isFavorite, 
    cartItemCount, 
    cartTotal,
    collapsedCategories,
  ];
  
  RestaurantDetailsLoaded copyWith({
    Map<String, dynamic>? restaurant,
    List<Map<String, dynamic>>? menu,
    List<Map<String, dynamic>>? categories,
    Map<String, int>? cartQuantities,
    bool? isFavorite,
    int? cartItemCount,
    double? cartTotal,
    Set<String>? collapsedCategories,
  }) {
    return RestaurantDetailsLoaded(
      restaurant: restaurant ?? this.restaurant,
      menu: menu ?? this.menu,
      categories: categories ?? this.categories,
      cartQuantities: cartQuantities ?? this.cartQuantities,
      isFavorite: isFavorite ?? this.isFavorite,
      cartItemCount: cartItemCount ?? this.cartItemCount,
      cartTotal: cartTotal ?? this.cartTotal,
      collapsedCategories: collapsedCategories ?? this.collapsedCategories,
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

class FirstItemAddedToCart extends RestaurantDetailsState {
  final RestaurantDetailsLoaded loadedState;
  const FirstItemAddedToCart(this.loadedState);

  @override
  List<Object?> get props => [loadedState];
}
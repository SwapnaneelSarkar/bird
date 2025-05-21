import 'package:equatable/equatable.dart';

abstract class RestaurantProfileEvent extends Equatable {
  const RestaurantProfileEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadRestaurantProfile extends RestaurantProfileEvent {
  final String restaurantId;
  final double? userLatitude;
  final double? userLongitude;
  
  const LoadRestaurantProfile({
    required this.restaurantId,
    this.userLatitude,
    this.userLongitude,
  });
  
  @override
  List<Object?> get props => [restaurantId, userLatitude, userLongitude];
}
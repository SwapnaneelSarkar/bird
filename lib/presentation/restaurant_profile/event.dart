// presentation/restaurant_profile/event.dart
import 'package:equatable/equatable.dart';

abstract class RestaurantProfileEvent extends Equatable {
  const RestaurantProfileEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadRestaurantProfile extends RestaurantProfileEvent {
  final String restaurantId;
  
  const LoadRestaurantProfile({
    required this.restaurantId,
  });
  
  @override
  List<Object?> get props => [restaurantId];
}
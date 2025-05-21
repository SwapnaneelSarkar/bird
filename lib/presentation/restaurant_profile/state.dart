import 'package:equatable/equatable.dart';
import '../../models/restaurant_model.dart';

abstract class RestaurantProfileState extends Equatable {
  const RestaurantProfileState();
  
  @override
  List<Object?> get props => [];
}

class RestaurantProfileInitial extends RestaurantProfileState {}

class RestaurantProfileLoading extends RestaurantProfileState {}

class RestaurantProfileLoaded extends RestaurantProfileState {
  final Restaurant restaurant;
  final String? calculatedDistance;
  
  const RestaurantProfileLoaded({
    required this.restaurant,
    this.calculatedDistance,
  });
  
  @override
  List<Object?> get props => [restaurant, calculatedDistance];
}

class RestaurantProfileError extends RestaurantProfileState {
  final String message;
  
  const RestaurantProfileError({
    required this.message,
  });
  
  @override
  List<Object?> get props => [message];
}
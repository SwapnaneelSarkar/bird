import 'package:equatable/equatable.dart';

abstract class HomeState extends Equatable {
  const HomeState();
  
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final String userAddress;
  final bool vegOnly;
  final List<dynamic> restaurants;
  final List<dynamic> categories;
  final double? userLatitude;   // Added user coordinates
  final double? userLongitude;  // Added user coordinates
  
  const HomeLoaded({
    required this.userAddress,
    required this.vegOnly,
    required this.restaurants,
    required this.categories,
    this.userLatitude,
    this.userLongitude,
  });
  
  @override
  List<Object?> get props => [userAddress, vegOnly, restaurants, categories, userLatitude, userLongitude];
  
  HomeLoaded copyWith({
    String? userAddress,
    bool? vegOnly,
    List<dynamic>? restaurants,
    List<dynamic>? categories,
    double? userLatitude,
    double? userLongitude,
  }) {
    return HomeLoaded(
      userAddress: userAddress ?? this.userAddress,
      vegOnly: vegOnly ?? this.vegOnly,
      restaurants: restaurants ?? this.restaurants,
      categories: categories ?? this.categories,
      userLatitude: userLatitude ?? this.userLatitude,
      userLongitude: userLongitude ?? this.userLongitude,
    );
  }
}

class HomeError extends HomeState {
  final String message;
  
  const HomeError(this.message);
  
  @override
  List<Object> get props => [message];
}

class AddressUpdating extends HomeState {}

class AddressUpdateSuccess extends HomeState {
  final String address;
  
  const AddressUpdateSuccess(this.address);
  
  @override
  List<Object> get props => [address];
}

class AddressUpdateFailure extends HomeState {
  final String error;
  
  const AddressUpdateFailure(this.error);
  
  @override
  List<Object> get props => [error];
}
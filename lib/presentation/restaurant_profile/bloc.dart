// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../models/restaurant_model.dart';

// import 'event.dart';
// import 'state.dart';

// class RestaurantProfileBloc extends Bloc<RestaurantProfileEvent, RestaurantProfileState> {
//   RestaurantProfileBloc() : super(RestaurantProfileInitial()) {
//     on<LoadRestaurantProfile>(_onLoadRestaurantProfile);
//   }

//   Future<void> _onLoadRestaurantProfile(
//     LoadRestaurantProfile event,
//     Emitter<RestaurantProfileState> emit,
//   ) async {
//     try {
//       emit(RestaurantProfileLoading());
      
//       debugPrint('RestaurantProfileBloc: Loading restaurant with ID: ${event.restaurantId}');
      
//       // Load data from assets (this path should be registered in pubspec.yaml)
//       final jsonString = await rootBundle.loadString('assets/data/restaurant.json');
//       final jsonData = json.decode(jsonString);
      
//       final restaurants = (jsonData['restaurants'] as List)
//           .map((item) => Restaurant.fromJson(item))
//           .toList();
      
//       try {
//         // Find restaurant with matching ID
//         final restaurant = restaurants.firstWhere(
//           (r) => r.id == event.restaurantId,
//           orElse: () => restaurants.first, // Use first restaurant as fallback
//         );
        
//         debugPrint('RestaurantProfileBloc: Restaurant loaded successfully: ${restaurant.name}');
        
//         emit(RestaurantProfileLoaded(restaurant: restaurant));
//       } catch (e) {
//         debugPrint('RestaurantProfileBloc: Error finding restaurant: $e');
//         // If no restaurant found, emit error
//         emit(RestaurantProfileError(message: 'Restaurant not found'));
//       }
//     } catch (e) {
//       debugPrint('RestaurantProfileBloc: Error loading restaurant data: $e');
//       emit(RestaurantProfileError(message: 'Failed to load restaurant data'));
//     }
//   }
// }
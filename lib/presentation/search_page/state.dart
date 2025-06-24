// lib/presentation/screens/search/state.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

class SearchInitialState extends SearchState {}

class SearchLoadingState extends SearchState {}

class SearchLoadedState extends SearchState {
  final List<SearchRestaurant> restaurants;
  final List<SearchMenuItem> menuItems;
  final String query;

  const SearchLoadedState({
    required this.restaurants,
    required this.menuItems,
    required this.query,
  });

  @override
  List<Object?> get props => [restaurants, menuItems, query];
}

class SearchEmptyState extends SearchState {
  final String query;

  const SearchEmptyState({required this.query});

  @override
  List<Object?> get props => [query];
}

class SearchErrorState extends SearchState {
  final String error;

  const SearchErrorState({required this.error});

  @override
  List<Object?> get props => [error];
}

// Search models
class SearchRestaurant extends Equatable {
  final String partnerId;
  final String restaurantName;
  final String address;
  final double rating;
  final List<String> categories;
  final double latitude;
  final double longitude;
  final List<String> restaurantPhotos;
  final double distance;

  const SearchRestaurant({
    required this.partnerId,
    required this.restaurantName,
    required this.address,
    required this.rating,
    required this.categories,
    required this.latitude,
    required this.longitude,
    required this.restaurantPhotos,
    required this.distance,
  });

  factory SearchRestaurant.fromJson(Map<String, dynamic> json) {
    List<String> photos = [];
    try {
      final photosData = json['restaurant_photos'];
      if (photosData != null) {
        if (photosData is List) {
          // If it's already a List, convert each item to String
          photos = photosData.map((e) => e.toString()).toList();
        } else if (photosData is String) {
          // If it's a String, try to parse as JSON
          if (photosData.startsWith('[') && photosData.endsWith(']')) {
            if (photosData == '[]' || photosData.isEmpty) {
              photos = [];
            } else {
              // Try to parse as JSON first
              try {
                final parsed = jsonDecode(photosData);
                if (parsed is List) {
                  photos = parsed.map((e) => e.toString()).toList();
                }
              } catch (e) {
                // If JSON parsing fails, fall back to string splitting
                photos = photosData
                    .substring(1, photosData.length - 1)
                    .split(',')
                    .map((e) => e.trim().replaceAll('"', ''))
                    .where((e) => e.isNotEmpty)
                    .toList();
              }
            }
          } else {
            // Single string value
            photos = [photosData];
          }
        }
      }
    } catch (e) {
      debugPrint('Error parsing restaurant photos: $e');
    }

    // Parse categories from different possible formats
    List<String> parsedCategories = [];
    if (json['category'] != null) {
      if (json['category'] is List) {
        // If it's already a List, convert each item to String
        parsedCategories = List<String>.from(json['category'].map((e) => e.toString()));
      } else if (json['category'] is String) {
        // If it's a String, try to parse as JSON array first, then as comma-separated
        String categoryStr = json['category'].toString().trim();
        if (categoryStr.startsWith('[') && categoryStr.endsWith(']')) {
          try {
            // Try to parse as JSON array
            final parsed = jsonDecode(categoryStr);
            if (parsed is List) {
              parsedCategories = parsed.map((e) => e.toString()).toList();
            }
          } catch (e) {
            // If JSON parsing fails, fall back to string splitting
            categoryStr = categoryStr.substring(1, categoryStr.length - 1);
            parsedCategories = categoryStr.split(',').map((cat) => cat.trim().replaceAll('"', '')).where((cat) => cat.isNotEmpty).toList();
          }
        } else {
          // Single category as string
          parsedCategories = [categoryStr];
        }
      }
    }

    return SearchRestaurant(
      partnerId: json['partner_id'] ?? '',
      restaurantName: json['restaurant_name'] ?? '',
      address: json['address'] ?? '',
      rating: double.tryParse(json['rating'].toString()) ?? 0.0,
      categories: parsedCategories,
      latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
      restaurantPhotos: photos,
      distance: double.tryParse(json['distance'].toString()) ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [
    partnerId,
    restaurantName,
    address,
    rating,
    categories,
    latitude,
    longitude,
    restaurantPhotos,
    distance,
  ];
}

class SearchMenuItem extends Equatable {
  final String name;
  final String description;
  final double price;
  final String? imageUrl;
  final List<String> categories;
  final SearchRestaurantInfo restaurant;

  const SearchMenuItem({
    required this.name,
    required this.description,
    required this.price,
    this.imageUrl,
    required this.categories,
    required this.restaurant,
  });

  factory SearchMenuItem.fromJson(Map<String, dynamic> json) {
    // Parse categories from different possible formats
    List<String> parsedCategories = [];
    if (json['category'] != null) {
      if (json['category'] is List) {
        // If it's already a List, convert each item to String
        parsedCategories = List<String>.from(json['category'].map((e) => e.toString()));
      } else if (json['category'] is String) {
        // If it's a String, try to parse as JSON array first, then as comma-separated
        String categoryStr = json['category'].toString().trim();
        if (categoryStr.startsWith('[') && categoryStr.endsWith(']')) {
          try {
            // Try to parse as JSON array
            final parsed = jsonDecode(categoryStr);
            if (parsed is List) {
              parsedCategories = parsed.map((e) => e.toString()).toList();
            }
          } catch (e) {
            // If JSON parsing fails, fall back to string splitting
            categoryStr = categoryStr.substring(1, categoryStr.length - 1);
            parsedCategories = categoryStr.split(',').map((cat) => cat.trim().replaceAll('"', '')).where((cat) => cat.isNotEmpty).toList();
          }
        } else {
          // Single category as string
          parsedCategories = [categoryStr];
        }
      }
    }

    return SearchMenuItem(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      imageUrl: json['image_url'],
      categories: parsedCategories,
      restaurant: SearchRestaurantInfo.fromJson(json['restaurant'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [name, description, price, imageUrl, categories, restaurant];
}

class SearchRestaurantInfo extends Equatable {
  final String id;
  final String name;
  final String address;
  final double rating;
  final String cuisineType;
  final double latitude;
  final double longitude;
  final List<String> restaurantPhotos;
  final double distance;

  const SearchRestaurantInfo({
    required this.id,
    required this.name,
    required this.address,
    required this.rating,
    required this.cuisineType,
    required this.latitude,
    required this.longitude,
    required this.restaurantPhotos,
    required this.distance,
  });

  factory SearchRestaurantInfo.fromJson(Map<String, dynamic> json) {
    List<String> photos = [];
    try {
      final photosData = json['restaurant_photos'];
      if (photosData != null) {
        if (photosData is List) {
          photos = photosData.map((e) => e.toString()).toList();
        } else if (photosData is String) {
          if (photosData.startsWith('[') && photosData.endsWith(']')) {
            if (photosData == '[]' || photosData.isEmpty) {
              photos = [];
            } else {
              try {
                final parsed = jsonDecode(photosData);
                if (parsed is List) {
                  photos = parsed.map((e) => e.toString()).toList();
                }
              } catch (e) {
                photos = photosData
                    .substring(1, photosData.length - 1)
                    .split(',')
                    .map((e) => e.trim().replaceAll('"', ''))
                    .where((e) => e.isNotEmpty)
                    .toList();
              }
            }
          } else {
            photos = [photosData];
          }
        }
      }
    } catch (e) {
      debugPrint('Error parsing restaurant info photos: $e');
    }

    // Extract partner_id from the restaurant data
    String partnerId = '';
    if (json['partner_id'] != null) {
      partnerId = json['partner_id'].toString();
    } else if (json['id'] != null) {
      partnerId = json['id'].toString();
    }

    return SearchRestaurantInfo(
      id: partnerId,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      rating: double.tryParse(json['rating'].toString()) ?? 0.0,
      cuisineType: json['cuisine_type'] ?? '',
      latitude: double.tryParse(json['latitude'].toString()) ?? 0.0,
      longitude: double.tryParse(json['longitude'].toString()) ?? 0.0,
      restaurantPhotos: photos,
      distance: double.tryParse(json['distance'].toString()) ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    address,
    rating,
    cuisineType,
    latitude,
    longitude,
    restaurantPhotos,
    distance,
  ];
}
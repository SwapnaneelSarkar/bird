// lib/models/restaurant_model.dart - Fixed version that handles null values
import 'dart:convert';
import 'package:flutter/foundation.dart';

class Restaurant {
  final String id;
  final String name;
  final String address;
  final String? description;
  final String cuisine;
  final double? rating;
  final bool? openNow;
  final String? closesAt;
  final String? imageUrl;
  final bool isVeg;
  final double? latitude;
  final double? longitude;
  final String? openTimings;
  final String? ownerName;
  final String? restaurantType;
  final List<String> photos;

  Restaurant({
    required this.id,
    required this.name,
    required this.address,
    this.description,
    required this.cuisine,
    this.rating,
    this.openNow,
    this.closesAt,
    this.imageUrl,
    required this.isVeg,
    this.latitude,
    this.longitude,
    this.openTimings,
    this.ownerName,
    this.restaurantType,
    this.photos = const [],
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    // CRITICAL FIX: Handle restaurant_photos properly
    List<String> photos = [];
    try {
      final photosField = json['restaurant_photos'];
      if (photosField != null && photosField.toString().isNotEmpty) {
        if (photosField is String) {
          // Handle string representation like "[\"url1\", \"url2\"]"
          String photosString = photosField.toString();
          if (photosString.startsWith('[') && photosString.endsWith(']')) {
            // Remove brackets and parse
            photosString = photosString.substring(1, photosString.length - 1);
            if (photosString.isNotEmpty) {
              photos = photosString
                  .split(',')
                  .map((e) => e.trim().replaceAll('"', '').replaceAll("'", ""))
                  .where((e) => e.isNotEmpty)
                  .toList();
            }
          } else if (photosString.isNotEmpty && !photosString.startsWith('[')) {
            // Single URL as string
            photos = [photosString];
          }
        } else if (photosField is List) {
          // Handle actual list
          photos = List<String>.from(photosField);
        }
      }
    } catch (e) {
      debugPrint('Restaurant: Error parsing photos: $e');
      photos = [];
    }

    // CRITICAL FIX: Safe parsing for all fields
    return Restaurant(
      id: json['partner_id']?.toString() ?? json['id']?.toString() ?? '',
      name: json['restaurant_name']?.toString() ?? json['name']?.toString() ?? 'Unknown Restaurant',
      address: json['address']?.toString() ?? 'Address not available',
      description: json['description']?.toString(),
      cuisine: json['category']?.toString() ?? json['cuisine']?.toString() ?? '',
      rating: _parseDouble(json['rating']),
      openNow: _determineOpenStatus(json['open_timings']?.toString()),
      closesAt: _extractClosingTime(json['open_timings']?.toString()),
      imageUrl: _getImageUrl(json, photos),
      isVeg: _parseVegStatus(json),
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      openTimings: json['open_timings']?.toString(),
      ownerName: json['owner_name']?.toString(),
      restaurantType: json['restaurant_type']?.toString(),
      photos: photos,
    );
  }

  // Helper method to safely parse double values
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // Helper method to determine vegetarian status
  static bool _parseVegStatus(Map<String, dynamic> json) {
    final vegNonVeg = json['veg_nonveg']?.toString().toLowerCase();
    if (vegNonVeg == 'veg') return true;
    if (vegNonVeg == 'non-veg' || vegNonVeg == 'nonveg') return false;
    
    final isVeg = json['isVeg'];
    if (isVeg is bool) return isVeg;
    if (isVeg is String) return isVeg.toLowerCase() == 'true';
    
    return false; // Default to non-veg if unclear
  }

  // Helper method to get the best image URL
  static String? _getImageUrl(Map<String, dynamic> json, List<String> photos) {
    // Try direct image field first
    final directImage = json['image']?.toString();
    if (directImage != null && directImage.isNotEmpty) {
      return directImage;
    }
    
    // Use first photo if available
    if (photos.isNotEmpty) {
      return photos.first;
    }
    
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl ?? (photos.isNotEmpty ? photos.first : ''),
      'cuisine': cuisine,
      'rating': rating ?? 0.0,
      'price': '₹200 for two', // Default value as API doesn't provide this
      'deliveryTime': '20-30 mins', // Default value as API doesn't provide this
      'isVegetarian': isVeg,
      'distance': 1.2, // Default value as API doesn't provide this
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'restaurantType': restaurantType,
      'category': cuisine, // Map cuisine to category for compatibility
    };
  }
  
  // Helper to determine if restaurant is currently open
  static bool? _determineOpenStatus(String? openTimings) {
    if (openTimings == null || openTimings.isEmpty) return null;
    
    try {
      // Parse JSON timing data if available
      final timingData = jsonDecode(openTimings);
      final now = DateTime.now();
      final currentDay = _getDayName(now.weekday);
      
      if (timingData[currentDay] != null) {
        final dayTimings = timingData[currentDay];
        if (dayTimings['open'] != null && dayTimings['close'] != null) {
          final openTime = _parseTime(dayTimings['open']);
          final closeTime = _parseTime(dayTimings['close']);
          
          if (openTime != null && closeTime != null) {
            final currentTime = Duration(hours: now.hour, minutes: now.minute);
            return currentTime.compareTo(openTime) >= 0 && currentTime.compareTo(closeTime) <= 0;
          }
        }
      }
    } catch (e) {
      debugPrint('Restaurant: Error parsing opening hours: $e');
    }
    
    return null; // Unknown status
  }
  
  // Helper to extract closing time
  static String? _extractClosingTime(String? openTimings) {
    if (openTimings == null || openTimings.isEmpty) return null;
    
    try {
      final timingData = jsonDecode(openTimings);
      final now = DateTime.now();
      final currentDay = _getDayName(now.weekday);
      
      if (timingData[currentDay] != null) {
        final dayTimings = timingData[currentDay];
        return dayTimings['close']?.toString();
      }
    } catch (e) {
      debugPrint('Restaurant: Error extracting closing time: $e');
    }
    
    return null;
  }
  
  // Helper to get day name
  static String _getDayName(int weekday) {
    const days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    return days[weekday - 1];
  }
  
  // Helper to parse time string to Duration
  static Duration? _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        final hours = int.parse(parts[0]);
        final minutes = int.parse(parts[1]);
        return Duration(hours: hours, minutes: minutes);
      }
    } catch (e) {
      debugPrint('Restaurant: Error parsing time: $e');
    }
    return null;
  }
}
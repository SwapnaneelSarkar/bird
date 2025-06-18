// lib/models/restaurant_model.dart - COMPLETELY FIXED VERSION
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
    try {
      debugPrint('Restaurant.fromJson: Parsing restaurant data: ${json.keys}');
      
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

      // CRITICAL FIX: Safe parsing for all fields with multiple possible field names
      final id = json['partner_id']?.toString() ?? 
                 json['id']?.toString() ?? 
                 json['restaurant_id']?.toString() ?? 
                 '';
      
      final name = json['restaurant_name']?.toString() ?? 
                   json['name']?.toString() ?? 
                   'Unknown Restaurant';
      
      final address = json['address']?.toString() ?? 'Address not available';
      
      final description = json['description']?.toString();
      
      final cuisine = json['category']?.toString() ?? 
                     json['cuisine']?.toString() ?? 
                     json['cuisine_type']?.toString() ?? 
                     '';
      
      final rating = _parseDouble(json['rating']);
      
      final openNow = _determineOpenStatus(json['open_timings']?.toString());
      
      final closesAt = _extractClosingTime(json['open_timings']?.toString());
      
      final imageUrl = _getImageUrl(json, photos);
      
      final isVeg = _parseVegStatus(json);
      
      final latitude = _parseDouble(json['latitude']);
      
      final longitude = _parseDouble(json['longitude']);
      
      final openTimings = json['open_timings']?.toString();
      
      final ownerName = json['owner_name']?.toString();
      
      final restaurantType = json['restaurant_type']?.toString();

      debugPrint('Restaurant.fromJson: Successfully parsed restaurant: $name');
      
      return Restaurant(
        id: id,
        name: name,
        address: address,
        description: description,
        cuisine: cuisine,
        rating: rating,
        openNow: openNow,
        closesAt: closesAt,
        imageUrl: imageUrl,
        isVeg: isVeg,
        latitude: latitude,
        longitude: longitude,
        openTimings: openTimings,
        ownerName: ownerName,
        restaurantType: restaurantType,
        photos: photos,
      );
    } catch (e) {
      debugPrint('Restaurant.fromJson: Error parsing restaurant: $e');
      debugPrint('Restaurant.fromJson: Raw data: $json');
      
      // Return a fallback restaurant instead of throwing
      return Restaurant(
        id: json['partner_id']?.toString() ?? json['id']?.toString() ?? 'unknown',
        name: json['restaurant_name']?.toString() ?? json['name']?.toString() ?? 'Unknown Restaurant',
        address: json['address']?.toString() ?? 'Address not available',
        cuisine: json['category']?.toString() ?? json['cuisine']?.toString() ?? 'Unknown',
        isVeg: false,
      );
    }
  }

  // Helper method to safely parse double values
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
    return null;
  }

  // Helper method to determine vegetarian status
  static bool _parseVegStatus(Map<String, dynamic> json) {
    // Check veg_nonveg field first
    final vegNonVeg = json['veg_nonveg']?.toString().toLowerCase();
    if (vegNonVeg == 'veg') return true;
    if (vegNonVeg == 'non-veg' || vegNonVeg == 'nonveg') return false;
    
    // Check isVeg field
    final isVeg = json['isVeg'];
    if (isVeg is bool) return isVeg;
    if (isVeg is String) return isVeg.toLowerCase() == 'true';
    if (isVeg is int) return isVeg == 1;
    
    // Check is_veg field
    final isVegAlt = json['is_veg'];
    if (isVegAlt is bool) return isVegAlt;
    if (isVegAlt is String) return isVegAlt.toLowerCase() == 'true';
    if (isVegAlt is int) return isVegAlt == 1;
    
    return false; // Default to non-veg if unclear
  }

  // Helper method to get the best image URL
  static String? _getImageUrl(Map<String, dynamic> json, List<String> photos) {
    // Try different possible image field names
    final imageFields = ['image', 'image_url', 'restaurant_image', 'photo'];
    
    for (final field in imageFields) {
      final directImage = json[field]?.toString();
      if (directImage != null && directImage.isNotEmpty && directImage != 'null') {
        return directImage;
      }
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
      'partner_id': id, // For compatibility
      'name': name,
      'restaurant_name': name, // For compatibility
      'imageUrl': imageUrl ?? (photos.isNotEmpty ? photos.first : ''),
      'cuisine': cuisine,
      'category': cuisine, // For compatibility
      'rating': rating ?? 0.0,
      'price': '₹200 for two', // Default value as API doesn't provide this
      'deliveryTime': '20-30 mins', // Default value as API doesn't provide this
      'isVegetarian': isVeg,
      'isVeg': isVeg, // For compatibility
      'veg_nonveg': isVeg ? 'veg' : 'non-veg', // For compatibility
      'distance': 1.2, // Default value as API doesn't provide this
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'restaurantType': restaurantType,
      'restaurant_type': restaurantType, // For compatibility
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
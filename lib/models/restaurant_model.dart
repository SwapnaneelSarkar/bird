// models/restaurant_model.dart
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
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['partner_id'] ?? json['id'] ?? '',
      name: json['restaurant_name'] ?? json['name'] ?? '',
      address: json['address'] ?? 'Address not available',
      description: json['description'],
      cuisine: json['category'] ?? '',
      rating: json['rating'] != null 
          ? double.tryParse(json['rating'].toString())
          : null,
      openNow: _determineOpenStatus(json['open_timings']),
      closesAt: _extractClosingTime(json['open_timings']),
      imageUrl: json['image'],
      isVeg: json['veg_nonveg'] == 'veg' || (json['isVeg'] == true),
      latitude: json['latitude'] != null 
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null 
          ? double.tryParse(json['longitude'].toString())
          : null,
      openTimings: json['open_timings'],
      ownerName: json['owner_name'],
    );
  }

  // Add this method to convert Restaurant to Map for the UI
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl ?? '',
      'cuisine': cuisine,
      'rating': rating ?? 0.0,
      'price': '₹200 for two', // Default value as API doesn't provide this
      'deliveryTime': '20-30 mins', // Default value as API doesn't provide this
      'isVeg': isVeg,
      'distance': 1.2, // Default value as API doesn't provide this
      'address': address,
    };
  }

  // Helper to determine if restaurant is currently open
  static bool? _determineOpenStatus(String? openTimingsJson) {
    if (openTimingsJson == null) return null;
    
    try {
      // Parse the JSON string
      final Map<String, dynamic> timings = json.decode(openTimingsJson);
      
      // Get current day of week
      final now = DateTime.now();
      String dayOfWeek;
      
      switch (now.weekday) {
        case 1: dayOfWeek = 'mon'; break;
        case 2: dayOfWeek = 'tue'; break;
        case 3: dayOfWeek = 'wed'; break;
        case 4: dayOfWeek = 'thu'; break;
        case 5: dayOfWeek = 'fri'; break;
        case 6: dayOfWeek = 'sat'; break;
        case 7: dayOfWeek = 'sun'; break;
        default: dayOfWeek = 'mon';
      }
      
      // Check if the day exists in the timings
      if (!timings.containsKey(dayOfWeek)) return false;
      
      // Get hours for today
      final String hoursString = timings[dayOfWeek];
      
      // Parse opening and closing hours
      if (hoursString.toLowerCase().contains('closed')) return false;
      
      if (hoursString.contains('-')) {
        // For simplicity just return true if hours exist
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error parsing opening hours: $e');
      return null;
    }
  }
  
  // Helper to extract closing time from open_timings JSON
  static String? _extractClosingTime(String? openTimingsJson) {
    if (openTimingsJson == null) return null;
    
    try {
      // Parse the JSON string
      final Map<String, dynamic> timings = json.decode(openTimingsJson);
      
      // Get current day of week
      final now = DateTime.now();
      String dayOfWeek;
      
      switch (now.weekday) {
        case 1: dayOfWeek = 'mon'; break;
        case 2: dayOfWeek = 'tue'; break;
        case 3: dayOfWeek = 'wed'; break;
        case 4: dayOfWeek = 'thu'; break;
        case 5: dayOfWeek = 'fri'; break;
        case 6: dayOfWeek = 'sat'; break;
        case 7: dayOfWeek = 'sun'; break;
        default: dayOfWeek = 'mon';
      }
      
      // Check if the day exists in the timings
      if (!timings.containsKey(dayOfWeek)) return null;
      
      // Get hours for today
      final String hoursString = timings[dayOfWeek];
      
      // Parse closing time
      if (hoursString.toLowerCase().contains('closed')) return 'Closed today';
      
      if (hoursString.contains('-')) {
        final parts = hoursString.split('-');
        if (parts.length == 2) {
          return parts[1].trim();
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Error extracting closing time: $e');
      return null;
    }
  }
}
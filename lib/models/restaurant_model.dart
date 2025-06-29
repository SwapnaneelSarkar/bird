// lib/models/restaurant_model.dart - UPDATED VERSION WITH BETTER ERROR HANDLING
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../utils/timezone_utils.dart';

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
  final List<String> availableCategories;

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
    this.availableCategories = const [],
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    try {
      debugPrint('Restaurant.fromJson: Parsing restaurant data with keys: ${json.keys}');
      
      // CRITICAL FIX: Handle restaurant_photos properly
      List<String> photos = [];
      try {
        final photosField = json['restaurant_photos'];
        if (photosField != null && photosField.toString().isNotEmpty && photosField.toString() != 'null') {
          if (photosField is String) {
            // Handle string representation like "[\"url1\", \"url2\"]" or just "url"
            String photosString = photosField.toString().trim();
            if (photosString.startsWith('[') && photosString.endsWith(']')) {
              // Remove brackets and parse
              photosString = photosString.substring(1, photosString.length - 1);
              if (photosString.isNotEmpty) {
                photos = photosString
                    .split(',')
                    .map((e) => e.trim().replaceAll('"', '').replaceAll("'", ""))
                    .where((e) => e.isNotEmpty && e != 'null')
                    .toList();
              }
            } else if (photosString.isNotEmpty && !photosString.startsWith('[') && photosString != 'null') {
              // Single URL as string
              photos = [photosString];
            }
          } else if (photosField is List) {
            // Handle actual list
            photos = List<String>.from(photosField.where((e) => e != null && e.toString().isNotEmpty && e.toString() != 'null'));
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
                     'Various';
      
      final rating = _parseDouble(json['rating']);
      
      // Use open_timings or fallback to operational_hours
      final timingsRaw = json['open_timings']?.toString() ?? json['operational_hours']?.toString();
      final openNow = _determineOpenStatus(timingsRaw);
      final closesAt = _extractClosingTime(timingsRaw);
      final openTimings = timingsRaw;
      
      final imageUrl = _getImageUrl(json, photos);
      
      final isVeg = _parseVegStatus(json);
      
      final latitude = _parseDouble(json['latitude']);
      
      final longitude = _parseDouble(json['longitude']);
      
      final ownerName = json['owner_name']?.toString();
      
      final restaurantType = json['restaurant_type']?.toString();

      // Parse availableCategories field
      List<String> availableCategories = [];
      try {
        final availableCategoriesField = json['availableCategories'];
        if (availableCategoriesField != null) {
          if (availableCategoriesField is List) {
            availableCategories = List<String>.from(availableCategoriesField.where((e) => e != null && e.toString().isNotEmpty));
          } else if (availableCategoriesField is String) {
            // Handle string representation like "[\"category1\", \"category2\"]" or just "category"
            String categoriesString = availableCategoriesField.toString().trim();
            if (categoriesString.startsWith('[') && categoriesString.endsWith(']')) {
              // Remove brackets and parse
              categoriesString = categoriesString.substring(1, categoriesString.length - 1);
              if (categoriesString.isNotEmpty) {
                availableCategories = categoriesString
                    .split(',')
                    .map((e) => e.trim().replaceAll('"', '').replaceAll("'", ""))
                    .where((e) => e.isNotEmpty && e != 'null')
                    .toList();
              }
            } else if (categoriesString.isNotEmpty && !categoriesString.startsWith('[') && categoriesString != 'null') {
              // Single category as string
              availableCategories = [categoriesString];
            }
          }
        }
      } catch (e) {
        debugPrint('Restaurant: Error parsing availableCategories: $e');
        availableCategories = [];
      }

      debugPrint('Restaurant.fromJson: Successfully parsed restaurant: $name (ID: $id)');
      
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
        availableCategories: availableCategories,
      );
    } catch (e) {
      debugPrint('Restaurant.fromJson: Error parsing restaurant: $e');
      debugPrint('Restaurant.fromJson: Raw data: $json');
      
      // Return a fallback restaurant instead of throwing
      return Restaurant(
        id: json['partner_id']?.toString() ?? json['id']?.toString() ?? 'unknown',
        name: json['restaurant_name']?.toString() ?? json['name']?.toString() ?? 'Unknown Restaurant',
        address: json['address']?.toString() ?? 'Address not available',
        cuisine: json['category']?.toString() ?? json['cuisine']?.toString() ?? 'Various',
        isVeg: _parseVegStatus(json),
        availableCategories: [],
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

  // Helper method to determine if restaurant is currently open (IST aware, parses open_timings JSON)
  static bool? _determineOpenStatus(String? openTimings) {
    if (openTimings == null || openTimings.isEmpty) return null;
    try {
      // If 24/7 or 24 in timings, always open
      if (openTimings.toLowerCase().contains('24')) return true;
      // Parse timings JSON
      final timings = Map<String, dynamic>.from(json.decode(openTimings.replaceAll("\\", "")));
      final now = TimezoneUtils.getCurrentTimeIST();
      final weekday = now.weekday; // 1=Mon, 7=Sun
      final dayKey = _weekdayToKey(weekday);
      final todayHours = timings[dayKey]?.toString();
      
      if (todayHours == null || todayHours.toLowerCase().contains('closed')) return false;
      // Parse hours, e.g. "9am - 9pm" or "10:30am - 11:15pm" or "10.42am - 9pm"
      final match = RegExp(r'(\d{1,2}([:.]\d{2})?\s*[ap]m)\s*-\s*(\d{1,2}([:.]\d{2})?\s*[ap]m)', caseSensitive: false).firstMatch(todayHours);
      if (match != null) {
        final openStr = match.group(1)!;
        final closeStr = match.group(3)!;
        final openTime = _parseTimeIST(openStr, now);
        final closeTime = _parseTimeIST(closeStr, now);
        
        if (openTime != null && closeTime != null) {
          // If close is past midnight, adjust
          final closeAdjusted = closeTime.isBefore(openTime) ? closeTime.add(const Duration(days: 1)) : closeTime;
          
          // Add a small tolerance (1 minute) to handle edge cases
          final tolerance = const Duration(minutes: 1);
          final openTimeWithTolerance = openTime.subtract(tolerance);
          
          final isOpen = now.isAfter(openTimeWithTolerance) && now.isBefore(closeAdjusted);
          
          // Debug log for troubleshooting
          debugPrint('Restaurant open status: Current=${now.hour}:${now.minute}, Open=${openTime.hour}:${openTime.minute}, Close=${closeAdjusted.hour}:${closeAdjusted.minute}, IsOpen=$isOpen');
          
          return isOpen;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error parsing open status: $e');
      return null;
    }
  }

  // Helper method to extract closing time for today (in IST, from open_timings JSON)
  static String? _extractClosingTime(String? openTimings) {
    if (openTimings == null || openTimings.isEmpty) return null;
    try {
      if (openTimings.toLowerCase().contains('24')) return '11:59 PM';
      final timings = Map<String, dynamic>.from(json.decode(openTimings.replaceAll("\\", "")));
      final now = TimezoneUtils.getCurrentTimeIST();
      final weekday = now.weekday;
      final dayKey = _weekdayToKey(weekday);
      final todayHours = timings[dayKey]?.toString();
      if (todayHours == null || todayHours.toLowerCase().contains('closed')) return null;
      final match = RegExp(r'(\d{1,2}([:.]\d{2})?\s*[ap]m)\s*-\s*(\d{1,2}([:.]\d{2})?\s*[ap]m)', caseSensitive: false).firstMatch(todayHours);
      if (match != null) {
        final closeStr = match.group(3)!;
        return closeStr.toUpperCase();
      }
      return null;
    } catch (e) {
      debugPrint('Error parsing closing time: $e');
      return null;
    }
  }

  // Helper: Convert weekday int to key string used in timings JSON
  static String _weekdayToKey(int weekday) {
    switch (weekday) {
      case 1: return 'mon';
      case 2: return 'tue';
      case 3: return 'wed';
      case 4: return 'thu';
      case 5: return 'fri';
      case 6: return 'sat';
      case 7: return 'sun';
      default: return 'mon';
    }
  }

  // Helper: Parse a time string like "9am" or "10:30pm" to DateTime today in IST
  static DateTime? _parseTimeIST(String timeStr, DateTime baseDay) {
    try {
      final cleaned = timeStr.trim().toLowerCase().replaceAll(' ', '');
      
      // Updated regex to handle both colon and dot separators: "10:42am" or "10.42am"
      final match = RegExp(r'^(\d{1,2})([:.](\d{2}))?(am|pm)').firstMatch(cleaned);
      if (match != null) {
        int hour = int.parse(match.group(1)!);
        int minute = match.group(3) != null ? int.parse(match.group(3)!) : 0;
        final isPM = match.group(4) == 'pm';
        
        if (hour == 12) {
          hour = isPM ? 12 : 0;
        } else if (isPM) {
          hour += 12;
        }
        
        return DateTime(baseDay.year, baseDay.month, baseDay.day, hour, minute);
      }
      return null;
    } catch (e) {
      debugPrint('Error parsing time string "$timeStr": $e');
      return null;
    }
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
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'openTimings': openTimings,
      'ownerName': ownerName,
      'restaurantType': restaurantType,
      'restaurant_photos': photos,
      'photos': photos, // For compatibility
      'openNow': openNow,
      'closesAt': closesAt,
      'description': description,
    };
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return 'Restaurant(id: $id, name: $name, cuisine: $cuisine, isVeg: $isVeg, rating: $rating)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Restaurant && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // Helper method to create a copy with updated fields
  Restaurant copyWith({
    String? id,
    String? name,
    String? address,
    String? description,
    String? cuisine,
    double? rating,
    bool? openNow,
    String? closesAt,
    String? imageUrl,
    bool? isVeg,
    double? latitude,
    double? longitude,
    String? openTimings,
    String? ownerName,
    String? restaurantType,
    List<String>? photos,
    List<String>? availableCategories,
  }) {
    return Restaurant(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      description: description ?? this.description,
      cuisine: cuisine ?? this.cuisine,
      rating: rating ?? this.rating,
      openNow: openNow ?? this.openNow,
      closesAt: closesAt ?? this.closesAt,
      imageUrl: imageUrl ?? this.imageUrl,
      isVeg: isVeg ?? this.isVeg,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      openTimings: openTimings ?? this.openTimings,
      ownerName: ownerName ?? this.ownerName,
      restaurantType: restaurantType ?? this.restaurantType,
      photos: photos ?? this.photos,
      availableCategories: availableCategories ?? this.availableCategories,
    );
  }
}
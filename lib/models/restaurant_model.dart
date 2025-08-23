// lib/models/restaurant_model.dart - UPDATED WITH SUPERCATEGORY FIELD
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
  final List<String> availableFoodTypes; // ADD AVAILABLE FOOD TYPES FIELD
  final int? isAcceptingOrder;
  final Map<String, dynamic>? restaurantFoodType;
  final String? supercategory; // ADD SUPERCATEGORY FIELD
  final int? reviewCount; // ADD REVIEW COUNT FIELD

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
    this.availableFoodTypes = const [], // ADD AVAILABLE FOOD TYPES PARAMETER
    this.isAcceptingOrder,
    this.restaurantFoodType,
    this.supercategory, // ADD SUPERCATEGORY PARAMETER
    this.reviewCount, // ADD REVIEW COUNT PARAMETER
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    try {
      debugPrint('Restaurant.fromJson: Parsing restaurant data with keys: ${json.keys}');
      debugPrint('Restaurant.fromJson: Full JSON data: $json');
      
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
      // Handle the case where description is "null" string
      final finalDescription = (description == null || description == 'null' || description.isEmpty) ? null : description;
      debugPrint('Restaurant: Parsed description: "$finalDescription" for restaurant: $name');
      
      final cuisine = json['category']?.toString() ?? 
                     json['cuisine']?.toString() ?? 
                     json['cuisine_type']?.toString() ?? 
                     'Various';
      
      final rating = _parseDouble(json['rating']);
      
      // Use open_timings or fallback to operational_hours
      final timingsRaw = json['open_timings'] ?? json['operational_hours'];
      debugPrint('Restaurant: Raw timings data: $timingsRaw (type: ${timingsRaw.runtimeType})');
      final openNow = _determineOpenStatus(timingsRaw);
      final closesAt = _extractClosingTime(timingsRaw);
      final openTimings = timingsRaw != null ? jsonEncode(timingsRaw) : null;
      debugPrint('Restaurant: Parsed openNow: $openNow, closesAt: $closesAt, openTimings: $openTimings');
      
      final imageUrl = _getImageUrl(json, photos);
      
      final isVeg = _parseVegStatus(json);
      
      final latitude = _parseDouble(json['latitude']);
      
      final longitude = _parseDouble(json['longitude']);
      
      final ownerName = json['owner_name']?.toString();
      
      final restaurantType = json['restaurant_type']?.toString();

      // PARSE SUPERCATEGORY FIELD
      final supercategory = json['supercategory']?.toString();
      debugPrint('Restaurant: Parsed supercategory: $supercategory for restaurant: $name');

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

      // Parse availableFoodTypes field
      List<String> availableFoodTypes = [];
      try {
        final availableFoodTypesField = json['availableFoodTypes'];
        debugPrint('Restaurant: Raw availableFoodTypes field: $availableFoodTypesField (type: ${availableFoodTypesField.runtimeType})');
        
        if (availableFoodTypesField != null) {
          if (availableFoodTypesField is List) {
            availableFoodTypes = List<String>.from(availableFoodTypesField.where((e) => e != null && e.toString().isNotEmpty));
            debugPrint('Restaurant: Parsed availableFoodTypes from List: $availableFoodTypes');
          } else if (availableFoodTypesField is String) {
            // Handle string representation like "[\"foodtype1\", \"foodtype2\"]" or just "foodtype"
            String foodTypesString = availableFoodTypesField.toString().trim();
            debugPrint('Restaurant: Parsing availableFoodTypes from String: "$foodTypesString"');
            if (foodTypesString.startsWith('[') && foodTypesString.endsWith(']')) {
              // Remove brackets and parse
              foodTypesString = foodTypesString.substring(1, foodTypesString.length - 1);
              if (foodTypesString.isNotEmpty) {
                availableFoodTypes = foodTypesString
                    .split(',')
                    .map((e) => e.trim().replaceAll('"', '').replaceAll("'", ""))
                    .where((e) => e.isNotEmpty && e != 'null')
                    .toList();
              }
            } else if (foodTypesString.isNotEmpty && !foodTypesString.startsWith('[') && foodTypesString != 'null') {
              // Single food type as string
              availableFoodTypes = [foodTypesString];
            }
            debugPrint('Restaurant: Parsed availableFoodTypes from String: $availableFoodTypes');
          }
        } else {
          debugPrint('Restaurant: availableFoodTypes field is null or empty');
          
          // Fallback: Try to derive food types from other fields
          final vegNonVeg = json['veg_nonveg']?.toString().toLowerCase();
          if (vegNonVeg != null && vegNonVeg.isNotEmpty) {
            if (vegNonVeg == 'veg' || vegNonVeg == 'vegetarian') {
              availableFoodTypes = ['Vegetarian']; // Use food type name instead of ID
            } else if (vegNonVeg == 'non-veg' || vegNonVeg == 'non-vegetarian') {
              availableFoodTypes = ['Non-Vegetarian']; // Use food type name instead of ID
            } else if (vegNonVeg == 'both' || vegNonVeg == 'veg & non-veg') {
              availableFoodTypes = ['Vegetarian', 'Non-Vegetarian']; // Use food type names instead of IDs
            }
            debugPrint('Restaurant: Derived availableFoodTypes from veg_nonveg: $availableFoodTypes');
          }
        }
      } catch (e) {
        debugPrint('Restaurant: Error parsing availableFoodTypes: $e');
        availableFoodTypes = [];
      }

      // Parse isAcceptingOrder field
      final isAcceptingOrder = json['isAcceptingOrder']?.toInt();

      // Parse restaurantFoodType field
      Map<String, dynamic>? restaurantFoodType;
      try {
        final foodTypeField = json['restaurantFoodType'];
        if (foodTypeField != null && foodTypeField is Map<String, dynamic>) {
          restaurantFoodType = foodTypeField;
        }
      } catch (e) {
        debugPrint('Restaurant: Error parsing restaurantFoodType: $e');
        restaurantFoodType = null;
      }

      // Parse reviewCount field
      int? reviewCount;
      try {
        final reviewCountField = json['reviewCount'];
        if (reviewCountField != null) {
          if (reviewCountField is int) {
            reviewCount = reviewCountField;
          } else if (reviewCountField is String) {
            reviewCount = int.tryParse(reviewCountField);
          }
        }
      } catch (e) {
        debugPrint('Restaurant: Error parsing reviewCount: $e');
        reviewCount = null;
      }

      debugPrint('Restaurant.fromJson: Successfully parsed restaurant: $name (ID: $id, Supercategory: $supercategory)');
      
      return Restaurant(
        id: id,
        name: name,
        address: address,
        description: finalDescription,
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
        availableFoodTypes: availableFoodTypes, // ADD AVAILABLE FOOD TYPES TO CONSTRUCTOR
        isAcceptingOrder: isAcceptingOrder,
        restaurantFoodType: restaurantFoodType,
        supercategory: supercategory, // ADD SUPERCATEGORY TO CONSTRUCTOR
        reviewCount: reviewCount, // ADD REVIEW COUNT TO CONSTRUCTOR
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
        isAcceptingOrder: null,
        restaurantFoodType: null,
        supercategory: json['supercategory']?.toString(), // ADD SUPERCATEGORY TO FALLBACK
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
  static bool? _determineOpenStatus(dynamic timingsData) {
    if (timingsData == null) return null;
    
    try {
      final now = TimezoneUtils.getCurrentTimeIST();
      final currentDay = _getDayName(now.weekday);
      
      // Handle both Map and String inputs
      Map<String, dynamic> timings;
      if (timingsData is Map<String, dynamic>) {
        timings = timingsData;
      } else if (timingsData is String) {
        timings = json.decode(timingsData);
      } else {
        return null;
      }
      
      final String todayTimings = timings[currentDay.toLowerCase()]?.toString() ?? '';
      
      if (todayTimings.isEmpty) return false;
      
      return _isCurrentlyOpen(todayTimings, now);
    } catch (e) {
      debugPrint('Restaurant: Error parsing operational hours: $e');
      return null;
    }
  }

  // Helper method to extract closing time from timings
  static String? _extractClosingTime(dynamic timingsData) {
    if (timingsData == null) return null;
    
    try {
      final now = TimezoneUtils.getCurrentTimeIST();
      final currentDay = _getDayName(now.weekday);
      
      // Handle both Map and String inputs
      Map<String, dynamic> timings;
      if (timingsData is Map<String, dynamic>) {
        timings = timingsData;
      } else if (timingsData is String) {
        timings = json.decode(timingsData);
      } else {
        return null;
      }
      
      final String todayTimings = timings[currentDay.toLowerCase()]?.toString() ?? '';
      
      if (todayTimings.isEmpty) return null;
      
      // Extract closing time from format like "9am - 11.59pm"
      final parts = todayTimings.split(' - ');
      if (parts.length == 2) {
        return parts[1].trim();
      }
    } catch (e) {
      debugPrint('Restaurant: Error extracting closing time: $e');
    }
    
    return null;
  }

  // Helper method to get day name from weekday number
  static String _getDayName(int weekday) {
    const days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
    return days[weekday - 1];
  }

  // Helper method to check if restaurant is currently open
  static bool _isCurrentlyOpen(String timings, DateTime now) {
    try {
      // Parse timings like "9am - 11.59pm"
      final parts = timings.split(' - ');
      if (parts.length != 2) return false;
      
      final openTime = _parseTime(parts[0].trim());
      final closeTime = _parseTime(parts[1].trim());
      
      if (openTime == null || closeTime == null) return false;
      
      final currentMinutes = now.hour * 60 + now.minute;
      
      // Handle case where restaurant closes after midnight
      if (closeTime < openTime) {
        return currentMinutes >= openTime || currentMinutes <= closeTime;
      } else {
        return currentMinutes >= openTime && currentMinutes <= closeTime;
      }
    } catch (e) {
      debugPrint('Restaurant: Error checking if currently open: $e');
      return false;
    }
  }

  // Helper method to parse time strings like "9am", "11.59pm"
  static int? _parseTime(String timeStr) {
    try {
      timeStr = timeStr.toLowerCase().trim();
      bool isPM = timeStr.contains('pm');
      bool isAM = timeStr.contains('am');
      
      if (!isPM && !isAM) return null;
      
      // Remove am/pm
      String numStr = timeStr.replaceAll('am', '').replaceAll('pm', '').trim();
      
      // Handle formats like "11.59" or "9"
      List<String> parts = numStr.contains('.') ? numStr.split('.') : [numStr, '0'];
      
      int hours = int.tryParse(parts[0]) ?? 0;
      int minutes = int.tryParse(parts[1]) ?? 0;
      
      // Convert to 24-hour format
      if (isPM && hours != 12) {
        hours += 12;
      } else if (isAM && hours == 12) {
        hours = 0;
      }
      
      return hours * 60 + minutes;
    } catch (e) {
      debugPrint('Restaurant: Error parsing time: $e');
      return null;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'partner_id': id, // For compatibility
      'name': name,
      'restaurant_name': name, // For compatibility
      'address': address,
      'description': description,
      'imageUrl': imageUrl ?? (photos.isNotEmpty ? photos.first : ''),
      'cuisine': cuisine,
      'category': cuisine, // For compatibility
      'rating': rating ?? 0.0,
      'price': '200 for two', // Default value as API doesn't provide this
      'isVegetarian': isVeg,
      'isVeg': isVeg, // For compatibility
      'veg_nonveg': isVeg ? 'veg' : 'non-veg', // For compatibility
      'latitude': latitude,
      'longitude': longitude,
      'openTimings': openTimings,
      'ownerName': ownerName,
      'restaurantType': restaurantType,
      'restaurant_photos': photos,
      'photos': photos, // For compatibility
      'openNow': openNow,
      'closesAt': closesAt,
      'isAcceptingOrder': isAcceptingOrder,
      'availableFoodTypes': availableFoodTypes, // ADD AVAILABLE FOOD TYPES TO MAP
      'supercategory': supercategory, // ADD SUPERCATEGORY TO MAP
      'reviewCount': reviewCount, // ADD REVIEW COUNT TO MAP
    };
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() {
    return 'Restaurant(id: $id, name: $name, cuisine: $cuisine, isVeg: $isVeg, rating: $rating, supercategory: $supercategory)';
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
    List<String>? availableFoodTypes, // ADD AVAILABLE FOOD TYPES TO COPYWITH
    int? isAcceptingOrder,
    String? supercategory, // ADD SUPERCATEGORY TO COPYWITH
    int? reviewCount, // ADD REVIEW COUNT TO COPYWITH
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
              availableFoodTypes: availableFoodTypes ?? this.availableFoodTypes, // ADD AVAILABLE FOOD TYPES TO COPYWITH
        isAcceptingOrder: isAcceptingOrder ?? this.isAcceptingOrder,
        supercategory: supercategory ?? this.supercategory, // ADD SUPERCATEGORY TO COPYWITH
        reviewCount: reviewCount ?? this.reviewCount, // ADD REVIEW COUNT TO COPYWITH
      );
  }
}
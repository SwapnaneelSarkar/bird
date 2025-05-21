import 'dart:math';
import 'package:flutter/foundation.dart';

class DistanceUtil {
  // Earth radius in kilometers
  static const double earthRadius = 6371.0;
  
  // Calculate the distance between two geographic coordinates using the Haversine formula
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    debugPrint('DistanceUtil: Calculating distance between:');
    debugPrint('DistanceUtil: User location: ($lat1, $lon1)');
    debugPrint('DistanceUtil: Restaurant location: ($lat2, $lon2)');
    
    // Convert degrees to radians
    final double lat1Rad = lat1 * pi / 180.0;
    final double lon1Rad = lon1 * pi / 180.0;
    final double lat2Rad = lat2 * pi / 180.0;
    final double lon2Rad = lon2 * pi / 180.0;
    
    // Haversine formula
    final double dLat = lat2Rad - lat1Rad;
    final double dLon = lon2Rad - lon1Rad;
    
    final double a = sin(dLat / 2) * sin(dLat / 2) +
                     cos(lat1Rad) * cos(lat2Rad) * 
                     sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    // Distance in kilometers
    final double distance = earthRadius * c;
    debugPrint('DistanceUtil: Calculated distance: $distance km');
    return distance;
  }
  
  // Format the distance in a user-friendly way
  static String formatDistance(double distanceKm) {
    String result;
    
    if (distanceKm < 1.0) {
      // For distances less than 1 km, show in meters
      final int meters = (distanceKm * 1000).round();
      result = '$meters m';
    } else if (distanceKm < 10.0) {
      // For distances between 1-10 km, show one decimal place
      result = '${distanceKm.toStringAsFixed(1)} km';
    } else {
      // For distances above 10 km, show without decimal places
      result = '${distanceKm.round()} km';
    }
    
    debugPrint('DistanceUtil: Formatted distance: $result');
    return result;
  }
}
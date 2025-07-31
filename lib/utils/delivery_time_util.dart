import 'dart:math';

class DeliveryTimeUtil {
  // Base delivery time in minutes
  static const int baseDeliveryTime = 15;
  
  // Additional minutes per 5km
  static const int additionalMinutesPer5km = 10;
  
  // Calculate delivery time based on distance
  static String calculateDeliveryTime(double distanceKm) {
    // Calculate total delivery time
    double totalMinutes = baseDeliveryTime.toDouble();
    
    // Add additional time for every 5km
    if (distanceKm > 0) {
      double additionalTime = (distanceKm / 5.0) * additionalMinutesPer5km;
      totalMinutes += additionalTime;
    }
    
    // Round to nearest 10-minute range
    int roundedMinutes = _roundToNearest10(totalMinutes);
    
    // Create time window (e.g., 20-30 mins for 25 mins)
    int lowerBound = ((roundedMinutes - 1) ~/ 10) * 10;
    int upperBound = lowerBound + 10;
    
    // Ensure minimum time window of 10 minutes
    if (upperBound - lowerBound < 10) {
      upperBound = lowerBound + 10;
    }
    
    return '${lowerBound}-${upperBound} mins';
  }
  
  // Round to nearest 10-minute interval
  static int _roundToNearest10(double minutes) {
    return (minutes / 10.0).round() * 10;
  }
  
  // Calculate delivery time for a specific distance and return as a string
  static String getDeliveryTimeString(double distanceKm) {
    return calculateDeliveryTime(distanceKm);
  }
} 
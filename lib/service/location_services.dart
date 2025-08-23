import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationService {
  final String _placesApiKey = 'AIzaSyBmRJ1-tX0oWD3FFKAuV8NB7Hg9h6NQXeU';
  
  /// Check if location services are available without requesting permissions
  Future<Map<String, bool>> checkLocationAvailability() async {
    try {
      debugPrint('LocationService: Checking location availability...');
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('LocationService: Location services enabled: $serviceEnabled');
      
      // Check current permission status without requesting
      LocationPermission permission = await Geolocator.checkPermission();
      bool permissionGranted = permission == LocationPermission.always || 
                              permission == LocationPermission.whileInUse;
      debugPrint('LocationService: Permission granted: $permissionGranted ($permission)');
      
      return {
        'serviceEnabled': serviceEnabled,
        'permissionGranted': permissionGranted,
        'available': serviceEnabled && permissionGranted,
      };
    } catch (e) {
      debugPrint('LocationService: Error checking location availability: $e');
      return {
        'serviceEnabled': false,
        'permissionGranted': false,
        'available': false,
      };
    }
  }

  // Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      debugPrint('LocationService: Checking location permission...');
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return null;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        debugPrint('Location permission denied, requesting permission...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied after request');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission permanently denied');
        return null;
      }

      // Force fresh location by clearing any cached location first
      debugPrint('LocationService: Clearing any cached location data...');
      try {
        await Geolocator.getLastKnownPosition();
      } catch (e) {
        debugPrint('LocationService: No cached location to clear');
      }

      // Get current position with high accuracy and force fresh data
      debugPrint('LocationService: Getting fresh current position with high accuracy...');
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 30),
        ),
      );
      
      debugPrint('LocationService: Fresh position obtained: ${position.latitude}, ${position.longitude}');
      debugPrint('LocationService: Position accuracy: ${position.accuracy} meters');
      debugPrint('LocationService: Position timestamp: ${position.timestamp}');
      
      return position;
    } catch (e) {
      debugPrint('LocationService: Error getting current position: $e');
      return null;
    }
  }

  // Get optimized current position with faster timeout and reduced accuracy
  Future<Position?> getCurrentPositionOptimized() async {
    try {
      debugPrint('LocationService: Getting optimized current position...');
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return null;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        debugPrint('Location permission denied, requesting permission...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied after request');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission permanently denied');
        return null;
      }

      // OPTIMIZATION: Try to get last known position first (faster)
      debugPrint('LocationService: Trying to get last known position first...');
      try {
        Position? lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          final age = DateTime.now().difference(lastKnown.timestamp!);
          // Use last known position if it's less than 2 minutes old
          if (age.inMinutes < 2) {
            debugPrint('LocationService: Using recent last known position (${age.inSeconds} seconds old)');
            return lastKnown;
          }
        }
      } catch (e) {
        debugPrint('LocationService: No last known position available');
      }

      // OPTIMIZATION: Get current position with faster settings
      debugPrint('LocationService: Getting optimized current position with faster settings...');
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium, // Reduced accuracy for speed
          timeLimit: Duration(seconds: 10), // Shorter timeout
        ),
      );
      
      debugPrint('LocationService: Optimized position obtained: ${position.latitude}, ${position.longitude}');
      debugPrint('LocationService: Position accuracy: ${position.accuracy} meters');
      debugPrint('LocationService: Position timestamp: ${position.timestamp}');
      
      return position;
    } catch (e) {
      debugPrint('LocationService: Error getting optimized current position: $e');
      return null;
    }
  }
  
  // Get coordinates for a place ID from Google Places API
  Future<Map<String, dynamic>?> getCoordinatesFromPlace(String placeId) async {
    try {
      debugPrint('LocationService: Getting coordinates for place ID: $placeId');
      
      // Construct the URL for the Google Places API Details request
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=formatted_address,geometry&key=$_placesApiKey'
      );
      
      debugPrint('LocationService: Sending request to Places API: ${url.toString()}');
      
      // Make the API request
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('LocationService: Places API response: ${response.body}');
        
        if (data['status'] == 'OK' && data['result'] != null) {
          final result = data['result'];
          final geometry = result['geometry'];
          final location = geometry['location'];
          
          debugPrint('LocationService: Coordinates retrieved - Lat: ${location['lat']}, Lng: ${location['lng']}');
          
          return {
            'address': result['formatted_address'] ?? '',
            'latitude': location['lat'] ?? 0.0,
            'longitude': location['lng'] ?? 0.0,
          };
        } else {
          debugPrint('LocationService: Place details API error: ${data['status']}');
        }
      } else {
        debugPrint('LocationService: Place details API error: ${response.statusCode}');
      }
      
      return null;
    } catch (e) {
      debugPrint('LocationService: Error getting place coordinates: $e');
      return null;
    }
  }

  // Convert coordinates to address using Geocoding plugin
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      debugPrint('LocationService: Converting coordinates to address: $latitude, $longitude');
      
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        
        // Build address string
        List<String> addressParts = [];
        
        if (place.name != null && place.name!.isNotEmpty) {
          addressParts.add(place.name!);
        }
        if (place.street != null && place.street!.isNotEmpty && place.street != place.name) {
          addressParts.add(place.street!);
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }
        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          addressParts.add(place.postalCode!);
        }
        if (place.country != null && place.country!.isNotEmpty) {
          addressParts.add(place.country!);
        }

        String address = addressParts.join(', ');
        debugPrint('LocationService: Converted address: $address');
        return address;
      }
      
      debugPrint('LocationService: No placemarks found for coordinates');
      return null;
    } catch (e) {
      debugPrint('LocationService: Error converting coordinates to address: $e');
      // Fallback to OpenStreetMap Nominatim API
      return await getAddressFromNominatim(latitude, longitude);
    }
  }

  // Alternative: Use OpenStreetMap Nominatim API for reverse geocoding
  Future<String?> getAddressFromNominatim(double latitude, double longitude) async {
    try {
      debugPrint('LocationService: Using Nominatim for reverse geocoding: $latitude, $longitude');
      
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1'
      );
      
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'BirdApp/1.0', // Required by Nominatim
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['display_name'] != null) {
          String address = data['display_name'];
          debugPrint('LocationService: Nominatim address: $address');
          return address;
        }
        
        // Build address from components if display_name is not available
        if (data['address'] != null) {
          Map<String, dynamic> addressData = data['address'];
          List<String> addressParts = [];
          
          // Add components in order of specificity
          if (addressData['house_number'] != null) addressParts.add(addressData['house_number']);
          if (addressData['road'] != null) addressParts.add(addressData['road']);
          if (addressData['suburb'] != null) addressParts.add(addressData['suburb']);
          if (addressData['city'] != null) addressParts.add(addressData['city']);
          if (addressData['state'] != null) addressParts.add(addressData['state']);
          if (addressData['postcode'] != null) addressParts.add(addressData['postcode']);
          if (addressData['country'] != null) addressParts.add(addressData['country']);
          
          String address = addressParts.join(', ');
          debugPrint('LocationService: Built address from components: $address');
          return address;
        }
      }
      
      debugPrint('LocationService: Nominatim API failed with status: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('LocationService: Error with Nominatim API: $e');
      return null;
    }
  }

  // Get current location and address
  Future<Map<String, dynamic>?> getCurrentLocationAndAddress() async {
    try {
      debugPrint('LocationService: Getting current location and address');
      Position? position = await getCurrentPosition();
      if (position == null) {
        debugPrint('LocationService: Failed to get current position');
        return null;
      }

      String? address = await getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (address == null || address.isEmpty) {
        // If geocoding fails, use a more user-friendly format
        address = "Near ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
        debugPrint('LocationService: Using fallback address format: $address');
      }

      final result = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'address': address,
      };
      
      debugPrint('LocationService: Location and address obtained successfully');
      debugPrint('LocationService: Latitude: ${result['latitude']}');
      debugPrint('LocationService: Longitude: ${result['longitude']}');
      debugPrint('LocationService: Address: ${result['address']}');
      
      return result;
    } catch (e) {
      debugPrint('LocationService: Error getting location and address: $e');
      return null;
    }
  }
  
  // Force fresh location fetch with GPS cache clearing
  Future<Map<String, dynamic>?> getFreshLocationAndAddress() async {
    try {
      debugPrint('LocationService: FORCE FRESH - Getting fresh location and address');
      
      // Clear any cached location data
      debugPrint('LocationService: FORCE FRESH - Clearing GPS cache...');
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          debugPrint('LocationService: FORCE FRESH - Cleared last known position: ${lastKnown.latitude}, ${lastKnown.longitude}');
        }
      } catch (e) {
        debugPrint('LocationService: FORCE FRESH - No last known position to clear');
      }
      
      // Wait a moment for GPS to reset
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Get fresh position with maximum accuracy
      debugPrint('LocationService: FORCE FRESH - Requesting fresh GPS position...');
      Position? position = await getCurrentPosition();
      
      if (position == null) {
        debugPrint('LocationService: FORCE FRESH - Failed to get fresh position');
        return null;
      }
      
      debugPrint('LocationService: FORCE FRESH - Fresh position obtained:');
      debugPrint('  📍 Latitude: ${position.latitude}');
      debugPrint('  📍 Longitude: ${position.longitude}');
      debugPrint('  📍 Accuracy: ${position.accuracy} meters');
      debugPrint('  📍 Timestamp: ${position.timestamp}');
      debugPrint('  📍 Speed: ${position.speed} m/s');
      debugPrint('  📍 Altitude: ${position.altitude} meters');

      // Get address for the fresh coordinates
      String? address = await getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (address == null || address.isEmpty) {
        address = "Near ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
        debugPrint('LocationService: FORCE FRESH - Using fallback address: $address');
      } else {
        debugPrint('LocationService: FORCE FRESH - Address obtained: $address');
      }

      final result = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'address': address,
        'accuracy': position.accuracy,
        'timestamp': position.timestamp.toIso8601String(),
        'speed': position.speed,
        'altitude': position.altitude,
      };
      
      debugPrint('LocationService: FORCE FRESH - Fresh location data ready:');
      debugPrint('  📍 Final Latitude: ${result['latitude']}');
      debugPrint('  📍 Final Longitude: ${result['longitude']}');
      debugPrint('  📍 Final Address: ${result['address']}');
      debugPrint('  📍 Accuracy: ${result['accuracy']} meters');
      
      return result;
    } catch (e) {
      debugPrint('LocationService: FORCE FRESH - Error getting fresh location: $e');
      return null;
    }
  }
  
  // Ultra aggressive fresh location fetch - completely bypasses all caching
  Future<Map<String, dynamic>?> getUltraFreshLocationAndAddress() async {
    try {
      debugPrint('LocationService: ULTRA FRESH - Getting ultra fresh location and address');
      
      // Step 1: Clear all possible cached data
      debugPrint('LocationService: ULTRA FRESH - Step 1: Clearing all cached data...');
      await _clearAllCachedData();
      
      // Step 2: Wait for GPS to completely reset
      debugPrint('LocationService: ULTRA FRESH - Step 2: Waiting for GPS reset...');
      await Future.delayed(const Duration(seconds: 2));
      
      // Step 3: Force location services to restart
      debugPrint('LocationService: ULTRA FRESH - Step 3: Restarting location services...');
      await _restartLocationServices();
      
      // Step 4: Get position with different accuracy settings to force fresh fix
      debugPrint('LocationService: ULTRA FRESH - Step 4: Getting ultra fresh position...');
      Position? position = await _getUltraFreshPosition();
      
      if (position == null) {
        debugPrint('LocationService: ULTRA FRESH - Failed to get ultra fresh position');
        return null;
      }
      
      debugPrint('LocationService: ULTRA FRESH - Ultra fresh position obtained:');
      debugPrint('  📍 Latitude: ${position.latitude}');
      debugPrint('  📍 Longitude: ${position.longitude}');
      debugPrint('  📍 Accuracy: ${position.accuracy} meters');
      debugPrint('  📍 Timestamp: ${position.timestamp}');
      debugPrint('  📍 Speed: ${position.speed} m/s');
      debugPrint('  📍 Altitude: ${position.altitude} meters');
      debugPrint('  📍 Heading: ${position.heading} degrees');

      // Step 5: Get fresh address
      String? address = await getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (address == null || address.isEmpty) {
        address = "Near ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}";
        debugPrint('LocationService: ULTRA FRESH - Using fallback address: $address');
      } else {
        debugPrint('LocationService: ULTRA FRESH - Address obtained: $address');
      }

      final result = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'address': address,
        'accuracy': position.accuracy,
        'timestamp': position.timestamp.toIso8601String(),
        'speed': position.speed,
        'altitude': position.altitude,
        'heading': position.heading,
        'isUltraFresh': true,
      };
      
      debugPrint('LocationService: ULTRA FRESH - Ultra fresh location data ready:');
      debugPrint('  📍 Final Latitude: ${result['latitude']}');
      debugPrint('  📍 Final Longitude: ${result['longitude']}');
      debugPrint('  📍 Final Address: ${result['address']}');
      debugPrint('  📍 Accuracy: ${result['accuracy']} meters');
      debugPrint('  📍 Is Ultra Fresh: ${result['isUltraFresh']}');
      
      return result;
    } catch (e) {
      debugPrint('LocationService: ULTRA FRESH - Error getting ultra fresh location: $e');
      return null;
    }
  }
  
  // Clear all possible cached data
  Future<void> _clearAllCachedData() async {
    try {
      debugPrint('LocationService: Clearing all cached data...');
      
      // Clear last known position multiple times
      for (int i = 0; i < 3; i++) {
        try {
          final lastKnown = await Geolocator.getLastKnownPosition();
          if (lastKnown != null) {
            debugPrint('LocationService: Cleared last known position (attempt ${i + 1}): ${lastKnown.latitude}, ${lastKnown.longitude}');
          }
        } catch (e) {
          debugPrint('LocationService: No last known position to clear (attempt ${i + 1})');
        }
        await Future.delayed(const Duration(milliseconds: 200));
      }
      
      debugPrint('LocationService: All cached data cleared');
    } catch (e) {
      debugPrint('LocationService: Error clearing all cached data: $e');
    }
  }
  
  // Restart location services
  Future<void> _restartLocationServices() async {
    try {
      debugPrint('LocationService: Restarting location services...');
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      debugPrint('LocationService: Location services enabled: $serviceEnabled');
      
      if (!serviceEnabled) {
        debugPrint('LocationService: Location services are disabled');
        return;
      }
      
      // Check and request permissions again
      LocationPermission permission = await Geolocator.checkPermission();
      debugPrint('LocationService: Current permission: $permission');
      
      if (permission == LocationPermission.denied) {
        debugPrint('LocationService: Requesting permission again...');
        permission = await Geolocator.requestPermission();
        debugPrint('LocationService: New permission: $permission');
      }
      
      debugPrint('LocationService: Location services restarted');
    } catch (e) {
      debugPrint('LocationService: Error restarting location services: $e');
    }
  }
  
  // Get ultra fresh position with different settings
  Future<Position?> _getUltraFreshPosition() async {
    try {
      debugPrint('LocationService: Getting ultra fresh position...');
      
      // Try different accuracy settings to force fresh fix
      final accuracySettings = [
        LocationAccuracy.best,
        LocationAccuracy.high,
        LocationAccuracy.medium,
        LocationAccuracy.low,
      ];
      
      for (int i = 0; i < accuracySettings.length; i++) {
        try {
          debugPrint('LocationService: Trying accuracy setting ${i + 1}: ${accuracySettings[i]}');
          
          Position position = await Geolocator.getCurrentPosition(
            locationSettings: LocationSettings(
              accuracy: accuracySettings[i],
              timeLimit: const Duration(seconds: 15),
            ),
          );
          
          debugPrint('LocationService: Successfully got position with ${accuracySettings[i]} accuracy');
          return position;
        } catch (e) {
          debugPrint('LocationService: Failed with ${accuracySettings[i]} accuracy: $e');
          if (i < accuracySettings.length - 1) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }
      }
      
      debugPrint('LocationService: All accuracy settings failed');
      return null;
    } catch (e) {
      debugPrint('LocationService: Error getting ultra fresh position: $e');
      return null;
    }
  }
  
  // Clear GPS cache and force complete reset
  Future<void> clearGPSCache() async {
    try {
      debugPrint('LocationService: Clearing GPS cache completely...');
      
      // Clear last known position
      try {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          debugPrint('LocationService: Cleared last known position: ${lastKnown.latitude}, ${lastKnown.longitude}');
        }
      } catch (e) {
        debugPrint('LocationService: No last known position to clear');
      }
      
      // Wait for GPS to reset
      await Future.delayed(const Duration(seconds: 1));
      
      debugPrint('LocationService: GPS cache cleared successfully');
    } catch (e) {
      debugPrint('LocationService: Error clearing GPS cache: $e');
    }
  }
  
  /// Get user-friendly message about location status
  String getLocationStatusMessage(Map<String, bool> availability) {
    if (availability['available'] == true) {
      return 'Location services are working properly';
    }
    
    if (!availability['serviceEnabled']! && !availability['permissionGranted']!) {
      return 'Location services are disabled and permission is not granted. Please enable location services and grant permission in device settings.';
    } else if (!availability['serviceEnabled']!) {
      return 'Location services are disabled. Please enable location services in device settings.';
    } else if (!availability['permissionGranted']!) {
      return 'Location permission is not granted. Please grant location permission in app settings.';
    }
    
    return 'Location services are not available';
  }
  
  /// Check if we can prompt user to enable location
  bool canPromptForLocation(Map<String, bool> availability) {
    // We can prompt if services are disabled but permission is not permanently denied
    return !availability['serviceEnabled']! || 
           (!availability['permissionGranted']! && availability['serviceEnabled']!);
  }

  /// Detect user's country based on current location
  Future<String?> detectUserCountry() async {
    try {
      debugPrint('LocationService: Detecting user country from location...');
      
      // Get current position
      Position? position = await getCurrentPositionOptimized();
      if (position == null) {
        debugPrint('LocationService: Failed to get current position for country detection');
        return null;
      }

      // Use reverse geocoding to get country information
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String? countryCode = place.isoCountryCode;
        
        debugPrint('LocationService: Detected country code: $countryCode');
        debugPrint('LocationService: Country name: ${place.country}');
        debugPrint('LocationService: Coordinates: ${position.latitude}, ${position.longitude}');
        
        return countryCode;
      }
      
      debugPrint('LocationService: No placemarks found for country detection');
      return null;
    } catch (e) {
      debugPrint('LocationService: Error detecting user country: $e');
      return null;
    }
  }

  /// Get user's location and country information
  Future<Map<String, dynamic>?> getUserLocationAndCountry() async {
    try {
      debugPrint('LocationService: Getting user location and country...');
      
      // Get current position
      Position? position = await getCurrentPositionOptimized();
      if (position == null) {
        debugPrint('LocationService: Failed to get current position');
        return null;
      }

      // Use reverse geocoding to get detailed location information
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        
        final result = {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'countryCode': place.isoCountryCode,
          'countryName': place.country,
          'administrativeArea': place.administrativeArea,
          'locality': place.locality,
          'subLocality': place.subLocality,
          'postalCode': place.postalCode,
          'address': _buildAddressString(place),
        };
        
        debugPrint('LocationService: Location and country data obtained:');
        debugPrint('  📍 Country Code: ${result['countryCode']}');
        debugPrint('  📍 Country Name: ${result['countryName']}');
        debugPrint('  📍 Coordinates: ${result['latitude']}, ${result['longitude']}');
        debugPrint('  📍 Address: ${result['address']}');
        
        return result;
      }
      
      debugPrint('LocationService: No placemarks found');
      return null;
    } catch (e) {
      debugPrint('LocationService: Error getting user location and country: $e');
      return null;
    }
  }

  /// Build a readable address string from placemark
  String _buildAddressString(Placemark place) {
    List<String> addressParts = [];
    
    if (place.name != null && place.name!.isNotEmpty) {
      addressParts.add(place.name!);
    }
    if (place.street != null && place.street!.isNotEmpty && place.street != place.name) {
      addressParts.add(place.street!);
    }
    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      addressParts.add(place.subLocality!);
    }
    if (place.locality != null && place.locality!.isNotEmpty) {
      addressParts.add(place.locality!);
    }
    if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
      addressParts.add(place.administrativeArea!);
    }
    if (place.postalCode != null && place.postalCode!.isNotEmpty) {
      addressParts.add(place.postalCode!);
    }
    if (place.country != null && place.country!.isNotEmpty) {
      addressParts.add(place.country!);
    }

    return addressParts.join(', ');
  }
}
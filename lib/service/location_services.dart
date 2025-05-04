import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LocationService {
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

      // Get current position
      debugPrint('Getting current position...');
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      debugPrint('Current position: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('Error getting current position: $e');
      return null;
    }
  }

  // Convert coordinates to address using Geocoding plugin
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      debugPrint('Converting coordinates to address using Geocoding: $latitude, $longitude');
      
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
        debugPrint('Converted address: $address');
        return address;
      }
      
      debugPrint('No placemarks found for coordinates');
      return null;
    } catch (e) {
      debugPrint('Error converting coordinates to address with Geocoding: $e');
      // Fallback to OpenStreetMap Nominatim API
      return await getAddressFromNominatim(latitude, longitude);
    }
  }

  // Alternative: Use OpenStreetMap Nominatim API for reverse geocoding
  Future<String?> getAddressFromNominatim(double latitude, double longitude) async {
    try {
      debugPrint('Using Nominatim for reverse geocoding: $latitude, $longitude');
      
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
          debugPrint('Nominatim address: $address');
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
          debugPrint('Built address from components: $address');
          return address;
        }
      }
      
      debugPrint('Nominatim API failed with status: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Error with Nominatim API: $e');
      return null;
    }
  }

  // Get current location and address
  Future<Map<String, dynamic>?> getCurrentLocationAndAddress() async {
    try {
      Position? position = await getCurrentPosition();
      if (position == null) {
        debugPrint('Failed to get current position');
        return null;
      }

      String? address = await getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (address == null || address.isEmpty) {
        // If geocoding fails, use a more user-friendly format
        address = "Near ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
        debugPrint('Using fallback address format: $address');
      }

      final result = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'address': address,
      };
      
      debugPrint('Location service result:');
      debugPrint('Latitude: ${result['latitude']}');
      debugPrint('Longitude: ${result['longitude']}');
      debugPrint('Address: ${result['address']}');
      
      return result;
    } catch (e) {
      debugPrint('Error getting location and address: $e');
      return null;
    }
  }
}
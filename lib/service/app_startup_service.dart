import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'location_services.dart';
import 'token_service.dart';
import 'update_user_service.dart';
import 'address_service.dart';
import 'profile_get_service.dart';

class AppStartupService {
  static final LocationService _locationService = LocationService();
  static final UpdateUserService _updateUserService = UpdateUserService();
  
  /// Initialize app startup services with optimized location handling
  static Future<Map<String, dynamic>> initializeAppGracefully() async {
    try {
      debugPrint('🔍 AppStartupService: Starting optimized app initialization...');
      
      // Check if user is logged in
      final isLoggedIn = await TokenService.isLoggedIn();
      debugPrint('🔍 AppStartupService: User logged in status: $isLoggedIn');
      
      if (!isLoggedIn) {
        debugPrint('AppStartupService: User not logged in, skipping location fetch');
        return {
          'success': true,
          'message': 'User not logged in',
          'locationUpdated': false,
        };
      }
      
      // Get user data
      final userData = await TokenService.getUserData();
      final token = await TokenService.getToken();
      final userId = await TokenService.getUserId();
      
      debugPrint('🔍 AppStartupService: Current user data:');
      debugPrint('  User ID: $userId');
      debugPrint('  Token: ${token != null ? 'Found' : 'Not found'}');
      debugPrint('  Current Address: ${userData?['address']}');
      debugPrint('  Current Latitude: ${userData?['latitude']}');
      debugPrint('  Current Longitude: ${userData?['longitude']}');
      
      if (token == null || userId == null) {
        debugPrint('AppStartupService: No token or userId available');
        return {
          'success': false,
          'message': 'Authentication required',
          'locationUpdated': false,
        };
      }
      
      // FORCE LOCATION VALIDATION: Always validate location on app restart
      // Removed 5-minute cache to ensure fresh validation every time
      debugPrint('🔍 AppStartupService: Force validating location on app restart...');
      
      // OPTIMIZATION: Check location availability with timeout
      debugPrint('🔍 AppStartupService: Checking location availability with timeout...');
      final locationAvailability = await _locationService.checkLocationAvailability()
          .timeout(const Duration(seconds: 3), onTimeout: () {
        debugPrint('🔄 AppStartupService: Location availability check timed out, using fallback');
        return {
          'serviceEnabled': false,
          'permissionGranted': false,
          'available': false,
        };
      });
      
      debugPrint('🔍 AppStartupService: Location availability: $locationAvailability');
      
      if (!locationAvailability['available']!) {
        debugPrint('🔄 AppStartupService: Location not available, using graceful fallback...');
        
        // Check if user has existing location data
        final existingAddress = userData?['address'];
        final existingLatitude = userData?['latitude'];
        final existingLongitude = userData?['longitude'];
        
        if (existingAddress != null && existingLatitude != null && existingLongitude != null) {
          debugPrint('🔄 AppStartupService: Using existing location data');
          debugPrint('  📍 Existing Address: $existingAddress');
          debugPrint('  📍 Existing Latitude: $existingLatitude');
          debugPrint('  📍 Existing Longitude: $existingLongitude');
          
          return {
            'success': true,
            'message': 'Using saved location - location services unavailable',
            'locationUpdated': false,
            'fallbackUsed': true,
            'locationAvailability': locationAvailability,
          };
        } else {
          debugPrint('🔄 AppStartupService: No existing location data, proceeding without location');
          return {
            'success': true,
            'message': 'Location services unavailable - continuing without location',
            'locationUpdated': false,
            'noLocationAccess': true,
            'locationAvailability': locationAvailability,
          };
        }
      }
      
      // OPTIMIZATION: Use fast location fetch with shorter timeout
      debugPrint('🔍 AppStartupService: Location available, fetching optimized location...');
      final locationData = await _getOptimizedLocation()
          .timeout(const Duration(seconds: 8), onTimeout: () {
        debugPrint('🔄 AppStartupService: Location fetch timed out, using fallback');
        return null;
      });
      
      if (locationData == null) {
        debugPrint('❌ AppStartupService: Failed to fetch location despite availability check');
        // Fall back to existing data or no location
        final existingAddress = userData?['address'];
        final existingLatitude = userData?['latitude'];
        final existingLongitude = userData?['longitude'];
        
        if (existingAddress != null && existingLatitude != null && existingLongitude != null) {
          return {
            'success': true,
            'message': 'Using saved location - fetch failed',
            'locationUpdated': false,
            'fallbackUsed': true,
            'locationAvailability': locationAvailability,
          };
        } else {
          return {
            'success': true,
            'message': 'Location fetch failed - continuing without location',
            'locationUpdated': false,
            'noLocationAccess': true,
            'locationAvailability': locationAvailability,
          };
        }
      }
      
      debugPrint('✅ AppStartupService: Optimized location fetched successfully');
      debugPrint('  📍 New Latitude: ${locationData['latitude']}');
      debugPrint('  📍 New Longitude: ${locationData['longitude']}');
      debugPrint('  📍 New Address: ${locationData['address']}');
      debugPrint('  📍 Accuracy: ${locationData['accuracy']} meters');
      debugPrint('  📍 Timestamp: ${locationData['timestamp']}');
      
      // OPTIMIZATION: Update user profile in background to avoid blocking
      _updateUserProfileInBackground(locationData, token, userId);
      
      return {
        'success': true,
        'message': 'Location updated successfully',
        'locationUpdated': true,
        'locationData': locationData,
        'locationAvailability': locationAvailability,
        'backgroundUpdate': true,
      };
    } catch (e) {
      debugPrint('❌ AppStartupService: Error in optimized initialization: $e');
      return {
        'success': true,
        'message': 'Initialization completed with errors - continuing',
        'locationUpdated': false,
        'error': e.toString(),
      };
    }
  }

  /// Initialize app startup services including location fetching
  static Future<Map<String, dynamic>> initializeApp() async {
    try {
      debugPrint('🔍 AppStartupService: Starting app initialization...');
      
      // Check if user is logged in
      final isLoggedIn = await TokenService.isLoggedIn();
      debugPrint('🔍 AppStartupService: User logged in status: $isLoggedIn');
      
      if (!isLoggedIn) {
        debugPrint('AppStartupService: User not logged in, skipping location fetch');
        return {
          'success': true,
          'message': 'User not logged in',
          'locationUpdated': false,
        };
      }
      
      // Get user data
      final userData = await TokenService.getUserData();
      final token = await TokenService.getToken();
      final userId = await TokenService.getUserId();
      
      debugPrint('🔍 AppStartupService: Current user data:');
      debugPrint('  User ID: $userId');
      debugPrint('  Token: ${token != null ? 'Found' : 'Not found'}');
      debugPrint('  Current Address: ${userData?['address']}');
      debugPrint('  Current Latitude: ${userData?['latitude']}');
      debugPrint('  Current Longitude: ${userData?['longitude']}');
      
      if (token == null || userId == null) {
        debugPrint('AppStartupService: No token or userId available');
        return {
          'success': false,
          'message': 'Authentication required',
          'locationUpdated': false,
        };
      }
      
      // Always fetch fresh location data on app startup
      debugPrint('🔍 AppStartupService: Always fetching fresh location on app startup...');
      
      // Fetch current location with ultra fresh method
      debugPrint('🔍 AppStartupService: Fetching ultra fresh location with complete GPS cache clearing...');
      final locationData = await _locationService.getUltraFreshLocationAndAddress();
      
      if (locationData == null) {
        debugPrint('❌ AppStartupService: Failed to fetch ultra fresh location');
        // Check if user has existing location data to fall back to
        final existingAddress = userData?['address'];
        final existingLatitude = userData?['latitude'];
        final existingLongitude = userData?['longitude'];
        
        if (existingAddress != null && existingLatitude != null && existingLongitude != null) {
          debugPrint('🔄 AppStartupService: Using existing location data as fallback');
          debugPrint('  📍 Existing Address: $existingAddress');
          debugPrint('  📍 Existing Latitude: $existingLatitude');
          debugPrint('  📍 Existing Longitude: $existingLongitude');
          
          return {
            'success': true,
            'message': 'Using existing location data - location services unavailable',
            'locationUpdated': false,
            'fallbackUsed': true,
          };
        } else {
          debugPrint('🔄 AppStartupService: No existing location data, allowing app access without location');
          return {
            'success': true,
            'message': 'Location services not available - continuing without location',
            'locationUpdated': false,
            'noLocationAccess': true,
          };
        }
      }
      
      debugPrint('✅ AppStartupService: Ultra fresh location fetched successfully');
      debugPrint('  📍 New Latitude: ${locationData['latitude']}');
      debugPrint('  📍 New Longitude: ${locationData['longitude']}');
      debugPrint('  📍 New Address: ${locationData['address']}');
      debugPrint('  📍 Accuracy: ${locationData['accuracy']} meters');
      debugPrint('  📍 Timestamp: ${locationData['timestamp']}');
      debugPrint('  📍 Is Ultra Fresh: ${locationData['isUltraFresh']}');
      
      // Always update user profile with fresh location data
      debugPrint('🔍 AppStartupService: Updating user profile with fresh location...');
      final updateResult = await _updateUserService.updateUserProfileWithId(
        token: token,
        userId: userId,
        address: locationData['address'],
        latitude: locationData['latitude'],
        longitude: locationData['longitude'],
      );
      
      if (updateResult['success'] == true) {
        debugPrint('✅ AppStartupService: User profile updated with fresh location');
        
        // Refresh user data in TokenService to reflect updated location
        await _refreshUserDataInTokenService(token, userId);
        
        // Save current location as a new address if user has no addresses
        await _saveLocationAsAddress(locationData, token, userId);
        
        await _updateLastLocationFetchTime();
        
        return {
          'success': true,
          'message': 'Location updated successfully',
          'locationUpdated': true,
        };
      } else {
        debugPrint('❌ AppStartupService: Failed to update user profile');
        return {
          'success': false,
          'message': updateResult['message'] ?? 'Failed to update location',
          'locationUpdated': false,
        };
      }
    } catch (e) {
      debugPrint('❌ AppStartupService: Error during initialization: $e');
      return {
        'success': false,
        'message': 'Error during app initialization',
        'locationUpdated': false,
      };
    }
  }
  
  /// Check if we should fetch location (based on last fetch time or user preference)
  static Future<bool> _shouldFetchLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if user has disabled auto-location updates
      final autoLocationEnabled = prefs.getBool('auto_location_enabled') ?? true;
      if (!autoLocationEnabled) {
        debugPrint('AppStartupService: Auto location updates disabled by user');
        return false;
      }
      
      // For app startup, always fetch location if user is logged in
      // This ensures we have the latest location when the app starts
      final isAppStartup = prefs.getBool('is_app_startup') ?? true;
      if (isAppStartup) {
        debugPrint('AppStartupService: App startup detected, fetching location');
        await prefs.setBool('is_app_startup', false);
        return true;
      }
      
      // Check last fetch time for subsequent fetches
      final lastFetchTime = prefs.getInt('last_location_fetch_time');
      if (lastFetchTime != null) {
        final lastFetch = DateTime.fromMillisecondsSinceEpoch(lastFetchTime);
        final now = DateTime.now();
        final difference = now.difference(lastFetch);
        
        // Don't fetch if last fetch was less than 1 hour ago
        if (difference.inHours < 1) {
          debugPrint('AppStartupService: Last location fetch was ${difference.inMinutes} minutes ago, skipping');
          return false;
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('AppStartupService: Error checking location fetch preference: $e');
      return true; // Default to fetching if there's an error
    }
  }
  
  /// Update the last location fetch time
  static Future<void> _updateLastLocationFetchTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_location_fetch_time', DateTime.now().millisecondsSinceEpoch);
      debugPrint('AppStartupService: Updated last location fetch time');
    } catch (e) {
      debugPrint('AppStartupService: Error updating last fetch time: $e');
    }
  }
  
  /// Save current location as a new address
  static Future<void> _saveLocationAsAddress(
    Map<String, dynamic> locationData,
    String token,
    String userId,
  ) async {
    try {
      debugPrint('AppStartupService: Checking if user has existing addresses...');
      
      final addressResult = await AddressService.getAllAddresses();
      List<Map<String, dynamic>> existingAddresses = [];
      
      if (addressResult['success'] == true && addressResult['data'] != null) {
        existingAddresses = List<Map<String, dynamic>>.from(addressResult['data']);
        debugPrint('AppStartupService: User has ${existingAddresses.length} existing addresses');
      }
      
      // Only save as new address if user has no addresses
      if (existingAddresses.isEmpty) {
        debugPrint('AppStartupService: No existing addresses found, saving current location as new address...');
        
        final saveResult = await AddressService.saveAddress(
          addressLine1: locationData['address'],
          addressLine2: 'Current Location',
          city: '',
          state: '',
          postalCode: '',
          country: '',
          latitude: locationData['latitude'],
          longitude: locationData['longitude'],
        );
        
        if (saveResult['success'] == true) {
          debugPrint('AppStartupService: Current location saved as new address successfully');
        } else {
          debugPrint('AppStartupService: Failed to save current location as address: ${saveResult['message']}');
        }
      } else {
        debugPrint('AppStartupService: User has existing addresses, skipping address save');
      }
    } catch (e) {
      debugPrint('AppStartupService: Error saving location as address: $e');
    }
  }
  
  /// Parse address string into components
  static Map<String, String> _parseAddress(String address) {
    try {
      final parts = address.split(', ');
      final result = <String, String>{};
      
      if (parts.isNotEmpty) {
        result['main'] = parts.first;
        
        // Try to extract city, state, postal code, country
        for (int i = parts.length - 1; i >= 0; i--) {
          final part = parts[i].trim();
          
          // Check for postal code (usually 5-6 digits)
          if (RegExp(r'^\d{5,6}$').hasMatch(part)) {
            result['postalCode'] = part;
          }
          // Check for country (usually last part and not a number)
          else if (i == parts.length - 1 && !RegExp(r'^\d').hasMatch(part)) {
            result['country'] = part;
          }
          // Check for state (usually second to last if not a number)
          else if (i == parts.length - 2 && !RegExp(r'^\d').hasMatch(part)) {
            result['state'] = part;
          }
          // Check for city (usually third to last if not a number)
          else if (i == parts.length - 3 && !RegExp(r'^\d').hasMatch(part)) {
            result['city'] = part;
          }
        }
      }
      
      return result;
    } catch (e) {
      debugPrint('AppStartupService: Error parsing address: $e');
      return {'main': address};
    }
  }
  
  /// Calculate distance between two coordinates in kilometers
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final lat1Rad = _degreesToRadians(lat1);
    final lat2Rad = _degreesToRadians(lat2);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
              sin(lat1Rad) * sin(lat2Rad) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * asin(sqrt(a));
    
    return earthRadius * c;
  }
  
  /// Convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }
  
  /// Enable or disable auto location updates
  static Future<void> setAutoLocationEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auto_location_enabled', enabled);
      debugPrint('AppStartupService: Auto location updates ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      debugPrint('AppStartupService: Error setting auto location preference: $e');
    }
  }
  
  /// Get auto location enabled status
  static Future<bool> isAutoLocationEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('auto_location_enabled') ?? true;
    } catch (e) {
      debugPrint('AppStartupService: Error getting auto location preference: $e');
      return true;
    }
  }
  
  /// Manually trigger location update
  static Future<Map<String, dynamic>> manualLocationUpdate() async {
    try {
      debugPrint('AppStartupService: Manual location update triggered');
      
      // Clear all cached location data to ensure fresh fetch
      await _clearCachedLocationData();
      
      // Get fresh location data directly
      debugPrint('AppStartupService: Getting ultra fresh location data...');
      final locationData = await _locationService.getUltraFreshLocationAndAddress();
      
      if (locationData == null) {
        debugPrint('AppStartupService: Failed to get fresh location data');
        return {
          'success': false,
          'message': 'Failed to get current location',
          'locationUpdated': false,
        };
      }
      
      // Get user data
      final token = await TokenService.getToken();
      final userId = await TokenService.getUserId();
      
      if (token == null || userId == null) {
        debugPrint('AppStartupService: No token or userId for manual update');
        return {
          'success': false,
          'message': 'Authentication required',
          'locationUpdated': false,
        };
      }
      
      // Update user profile with fresh location data
      debugPrint('AppStartupService: Updating user profile with fresh location...');
      final updateResult = await _updateUserService.updateUserProfileWithId(
        token: token,
        userId: userId,
        address: locationData['address'],
        latitude: locationData['latitude'],
        longitude: locationData['longitude'],
      );
      
      if (updateResult['success'] == true) {
        debugPrint('AppStartupService: User profile updated with fresh location');
        
        // Refresh user data in TokenService
        await _refreshUserDataInTokenService(token, userId);
        
        return {
          'success': true,
          'message': 'Location updated successfully',
          'locationUpdated': true,
        };
      } else {
        debugPrint('AppStartupService: Failed to update user profile');
        return {
          'success': false,
          'message': updateResult['message'] ?? 'Failed to update location',
          'locationUpdated': false,
        };
      }
    } catch (e) {
      debugPrint('AppStartupService: Error during manual location update: $e');
      return {
        'success': false,
        'message': 'Error during manual location update',
        'locationUpdated': false,
      };
    }
  }
  
  /// Clear cached location data to ensure fresh location fetching
  static Future<void> _clearCachedLocationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Clear last fetch time to force fresh fetch
      await prefs.remove('last_location_fetch_time');
      
      // Clear any cached location preferences
      await prefs.remove('cached_location_address');
      await prefs.remove('cached_location_latitude');
      await prefs.remove('cached_location_longitude');
      
      // Clear GPS cache
      await _locationService.clearGPSCache();
      
      debugPrint('AppStartupService: Cleared cached location data and GPS cache');
    } catch (e) {
      debugPrint('AppStartupService: Error clearing cached location data: $e');
    }
  }
  
  /// Force fresh location fetch (clears cache and fetches new location)
  static Future<Map<String, dynamic>> forceFreshLocationFetch() async {
    try {
      debugPrint('AppStartupService: Force fresh location fetch triggered');
      
      // Clear all cached data
      await _clearCachedLocationData();
      
      // Reset app startup flag
      await resetAppStartupFlag();
      
      // Call initialization for fresh fetch
      return await initializeApp();
    } catch (e) {
      debugPrint('AppStartupService: Error during force fresh location fetch: $e');
      return {
        'success': false,
        'message': 'Error during force fresh location fetch',
        'locationUpdated': false,
      };
    }
  }
  
  /// Force ultra fresh location fetch (completely bypasses all caching)
  static Future<Map<String, dynamic>> forceUltraFreshLocationFetch() async {
    try {
      debugPrint('AppStartupService: Force ultra fresh location fetch triggered');
      
      // Clear all cached data including GPS cache
      await _clearCachedLocationData();
      
      // Reset app startup flag
      await resetAppStartupFlag();
      
      // Get user data
      final token = await TokenService.getToken();
      final userId = await TokenService.getUserId();
      
      if (token == null || userId == null) {
        debugPrint('AppStartupService: No token or userId for ultra fresh update');
        return {
          'success': false,
          'message': 'Authentication required',
          'locationUpdated': false,
        };
      }
      
      // Get ultra fresh location data
      debugPrint('AppStartupService: Getting ultra fresh location data...');
      final locationData = await _locationService.getUltraFreshLocationAndAddress();
      
      if (locationData == null) {
        debugPrint('AppStartupService: Failed to get ultra fresh location data');
        // Check if user has existing location data to fall back to
        final userData = await TokenService.getUserData();
        final existingAddress = userData?['address'];
        final existingLatitude = userData?['latitude'];
        final existingLongitude = userData?['longitude'];
        
        if (existingAddress != null && existingLatitude != null && existingLongitude != null) {
          debugPrint('🔄 AppStartupService: Using existing location data as fallback for force update');
          return {
            'success': true,
            'message': 'Using existing location data - location services unavailable',
            'locationUpdated': false,
            'fallbackUsed': true,
          };
        } else {
          debugPrint('🔄 AppStartupService: No location data available, allowing app access');
          return {
            'success': true,
            'message': 'Location services not available - continuing without location',
            'locationUpdated': false,
            'noLocationAccess': true,
          };
        }
      }
      
      // Update user profile with ultra fresh location data
      debugPrint('AppStartupService: Updating user profile with ultra fresh location...');
      final updateResult = await _updateUserService.updateUserProfileWithId(
        token: token,
        userId: userId,
        address: locationData['address'],
        latitude: locationData['latitude'],
        longitude: locationData['longitude'],
      );
      
      if (updateResult['success'] == true) {
        debugPrint('AppStartupService: User profile updated with ultra fresh location');
        
        // Refresh user data in TokenService
        await _refreshUserDataInTokenService(token, userId);
        
        return {
          'success': true,
          'message': 'Ultra fresh location updated successfully',
          'locationUpdated': true,
          'isUltraFresh': true,
        };
      } else {
        debugPrint('AppStartupService: Failed to update user profile with ultra fresh location');
        return {
          'success': false,
          'message': updateResult['message'] ?? 'Failed to update location',
          'locationUpdated': false,
        };
      }
    } catch (e) {
      debugPrint('AppStartupService: Error during ultra fresh location fetch: $e');
      return {
        'success': false,
        'message': 'Error during ultra fresh location fetch',
        'locationUpdated': false,
      };
    }
  }
  
  /// Reset app startup flag (call this when app is closed/reopened)
  static Future<void> resetAppStartupFlag() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_app_startup', true);
      debugPrint('AppStartupService: App startup flag reset');
    } catch (e) {
      debugPrint('AppStartupService: Error resetting app startup flag: $e');
    }
  }
  
  /// Force location fetch on next app startup
  static Future<void> forceLocationFetchOnNextStartup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_app_startup', true);
      await prefs.remove('last_location_fetch_time');
      debugPrint('AppStartupService: Forced location fetch on next startup');
    } catch (e) {
      debugPrint('AppStartupService: Error forcing location fetch: $e');
    }
  }
  
  /// Refresh user data in TokenService to reflect updated location
  static Future<void> _refreshUserDataInTokenService(String token, String userId) async {
    try {
      debugPrint('🔍 AppStartupService: Refreshing user data in TokenService...');
      
      // Import the profile service to fetch updated user data
      final ProfileApiService profileService = ProfileApiService();
      
      // Fetch the updated user profile
      final profileResult = await profileService.getUserProfile(
        token: token,
        userId: userId,
      );
      
      if (profileResult['success'] == true && profileResult['data'] != null) {
        final updatedUserData = profileResult['data'] as Map<String, dynamic>;
        
        // Update the user data in TokenService
        await TokenService.saveUserData(updatedUserData);
        
        debugPrint('✅ AppStartupService: User data refreshed in TokenService successfully');
        debugPrint('  📍 Updated address: ${updatedUserData['address']}');
        debugPrint('  📍 Updated coordinates: ${updatedUserData['latitude']}, ${updatedUserData['longitude']}');
      } else {
        debugPrint('❌ AppStartupService: Failed to refresh user data: ${profileResult['message']}');
      }
    } catch (e) {
      debugPrint('❌ AppStartupService: Error refreshing user data in TokenService: $e');
    }
  }

  /// Clear all location-related cache and force fresh start
  static Future<void> clearAllLocationCache() async {
    try {
      debugPrint('AppStartupService: Clearing all location-related cache...');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Clear all location-related preferences
      await prefs.remove('last_location_fetch_time');
      await prefs.remove('cached_location_address');
      await prefs.remove('cached_location_latitude');
      await prefs.remove('cached_location_longitude');
      await prefs.remove('is_app_startup');
      await prefs.remove('auto_location_enabled');
      
      // Clear GPS cache
      await _locationService.clearGPSCache();
      
      // Clear user data in TokenService to force fresh fetch
      await TokenService.clearAll();
      
      debugPrint('AppStartupService: All location cache cleared successfully');
    } catch (e) {
      debugPrint('AppStartupService: Error clearing all location cache: $e');
    }
  }

  /// Check if we have recent location data (less than 5 minutes old)
  static Future<bool> _hasRecentLocationData(Map<String, dynamic>? userData) async {
    try {
      if (userData == null) return false;
      
      final updatedAt = userData['updated_at'];
      if (updatedAt == null) return false;
      
      final updatedAtTime = DateTime.tryParse(updatedAt);
      if (updatedAtTime == null) return false;
      
      final now = DateTime.now();
      final difference = now.difference(updatedAtTime);
      
      // Consider data recent if less than 5 minutes old
      final isRecent = difference.inMinutes < 5;
      debugPrint('AppStartupService: Location data age: ${difference.inMinutes} minutes, isRecent: $isRecent');
      
      return isRecent;
    } catch (e) {
      debugPrint('AppStartupService: Error checking location data age: $e');
      return false;
    }
  }

  /// Get optimized location with faster timeout and reduced accuracy requirements
  static Future<Map<String, dynamic>?> _getOptimizedLocation() async {
    try {
      debugPrint('LocationService: Getting optimized location with faster timeout...');
      
      // Use faster location settings
      final position = await _locationService.getCurrentPositionOptimized();
      
      if (position == null) {
        debugPrint('LocationService: Failed to get optimized position');
        return null;
      }
      
      // Get address with timeout
      String? address = await _locationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 3), onTimeout: () {
        debugPrint('LocationService: Address fetch timed out, using fallback');
        return null;
      });

      if (address == null || address.isEmpty) {
        address = "Near ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}";
        debugPrint('LocationService: Using fallback address format: $address');
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
      
      debugPrint('LocationService: Optimized location data ready:');
      debugPrint('  📍 Latitude: ${result['latitude']}');
      debugPrint('  📍 Longitude: ${result['longitude']}');
      debugPrint('  📍 Address: ${result['address']}');
      debugPrint('  📍 Accuracy: ${result['accuracy']} meters');
      
      return result;
    } catch (e) {
      debugPrint('LocationService: Error getting optimized location: $e');
      return null;
    }
  }

  /// Update user profile in background to avoid blocking the UI
  static Future<void> _updateUserProfileInBackground(
    Map<String, dynamic> locationData,
    String token,
    String userId,
  ) async {
    try {
      debugPrint('🔍 AppStartupService: Updating user profile in background...');
      
      final updateResult = await _updateUserService.updateUserProfileWithId(
        token: token,
        userId: userId,
        address: locationData['address'],
        latitude: locationData['latitude'],
        longitude: locationData['longitude'],
      );
      
      if (updateResult['success'] == true) {
        debugPrint('✅ AppStartupService: Background profile update successful');
        await _updateLastLocationFetchTime();
        
        // Refresh user data in TokenService in background
        _refreshUserDataInTokenService(token, userId);
      } else {
        debugPrint('❌ AppStartupService: Background profile update failed: ${updateResult['message']}');
      }
    } catch (e) {
      debugPrint('❌ AppStartupService: Error in background profile update: $e');
    }
  }

  /// Force fresh location validation by calling the update API
  static Future<Map<String, dynamic>> forceLocationValidation() async {
    try {
      debugPrint('🔍 AppStartupService: Force validating location...');
      
      final userData = await TokenService.getUserData();
      final token = await TokenService.getToken();
      final userId = await TokenService.getUserId();
      
      if (userData == null || token == null || userId == null) {
        return {
          'success': false,
          'message': 'Authentication required',
          'isServiceable': false,
        };
      }
      
      final latitude = double.tryParse(userData['latitude'].toString());
      final longitude = double.tryParse(userData['longitude'].toString());
      final address = userData['address'].toString();
      
      if (latitude == null || longitude == null) {
        return {
          'success': false,
          'message': 'Invalid location coordinates',
          'isServiceable': false,
        };
      }
      
      // Force call the update API to validate location
      final updateResult = await _updateUserService.updateUserProfileWithId(
        token: token,
        userId: userId,
        address: address,
        latitude: latitude,
        longitude: longitude,
      );
      
      if (updateResult['success'] == true) {
        debugPrint('✅ AppStartupService: Location validation successful');
        return {
          'success': true,
          'message': 'Location is serviceable',
          'isServiceable': true,
        };
      } else {
        debugPrint('❌ AppStartupService: Location validation failed: ${updateResult['message']}');
        return {
          'success': false,
          'message': updateResult['message'] ?? 'Location is not serviceable',
          'isServiceable': false,
        };
      }
    } catch (e) {
      debugPrint('❌ AppStartupService: Error in force location validation: $e');
      return {
        'success': false,
        'message': 'Error validating location',
        'isServiceable': false,
      };
    }
  }
} 
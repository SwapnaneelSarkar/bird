import 'package:flutter/foundation.dart';
import '../service/currency_service.dart';
import '../service/profile_get_service.dart';
import '../service/token_service.dart';

class CurrencyUtils {
  static String? _cachedCurrencySymbol;
  
  /// Get currency symbol, using cached value if available
  static Future<String> getCurrencySymbol(double? lat, double? lng) async {
    if (_cachedCurrencySymbol != null) {
      return _cachedCurrencySymbol!;
    }
    
    if (lat != null && lng != null) {
      try {
        _cachedCurrencySymbol = await CurrencyService.getCurrencySymbolFromCoordinates(lat, lng);
        debugPrint('CurrencyUtils: Currency symbol cached: $_cachedCurrencySymbol');
        return _cachedCurrencySymbol!;
      } catch (e) {
        debugPrint('CurrencyUtils: Error getting currency symbol: $e');
      }
    }
    
    // Default fallback
    _cachedCurrencySymbol = '\$';
    return _cachedCurrencySymbol!;
  }

  /// Get currency symbol using user's profile coordinates
  static Future<String> getCurrencySymbolFromUserLocation() async {
    if (_cachedCurrencySymbol != null) {
      return _cachedCurrencySymbol!;
    }

    try {
      // Get user token and ID
      final token = await TokenService.getToken();
      final userId = await TokenService.getUserId();
      
      if (token != null && userId != null) {
        // Get user profile to fetch coordinates
        final profileService = ProfileApiService();
        final result = await profileService.getUserProfile(
          token: token,
          userId: userId,
        );
        
        if (result['success'] == true) {
          final userData = result['data'] as Map<String, dynamic>;
          
          // Get coordinates from profile
          if (userData['latitude'] != null && userData['longitude'] != null) {
            final latitude = double.tryParse(userData['latitude'].toString());
            final longitude = double.tryParse(userData['longitude'].toString());
            
            if (latitude != null && longitude != null) {
              debugPrint('CurrencyUtils: Using user coordinates - Lat: $latitude, Long: $longitude');
              _cachedCurrencySymbol = await CurrencyService.getCurrencySymbolFromCoordinates(latitude, longitude);
              debugPrint('CurrencyUtils: Currency symbol cached from user location: $_cachedCurrencySymbol');
              return _cachedCurrencySymbol!;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('CurrencyUtils: Error getting currency from user location: $e');
    }
    
    // Default fallback
    _cachedCurrencySymbol = '\$';
    return _cachedCurrencySymbol!;
  }
  
  /// Clear cached currency symbol
  static void clearCache() {
    _cachedCurrencySymbol = null;
    CurrencyService.clearCache();
    debugPrint('CurrencyUtils: Cache cleared');
  }
  
  /// Format price with current currency symbol
  static String formatPrice(double price, String currencySymbol) {
    return '$currencySymbol${price.toStringAsFixed(2)}';
  }

  /// Format price using user's location currency
  static Future<String> formatPriceWithUserCurrency(double price) async {
    final currencySymbol = await getCurrencySymbolFromUserLocation();
    return formatPrice(price, currencySymbol);
  }
} 
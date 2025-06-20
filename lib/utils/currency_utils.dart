import 'package:flutter/foundation.dart';
import '../service/currency_service.dart';

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
} 
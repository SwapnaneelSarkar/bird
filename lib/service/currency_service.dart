import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';

class CurrencyService {
  static const String _defaultCurrencySymbol = '\$';
  
  // Cache for currency symbols to avoid repeated API calls
  static final Map<String, String> _symbolCache = {};

  /// Get currency symbol based on coordinates
  /// Returns the appropriate currency symbol for the given coordinates
  static Future<String> getCurrencySymbolFromCoordinates(double lat, double lng) async {
    try {
      debugPrint('CurrencyService: Getting currency for coordinates: $lat, $lng');
      
      // Get country code from coordinates
      final countryCode = await getCountryCodeFromCoordinates(lat, lng);
      if (countryCode == null) {
        debugPrint('CurrencyService: Could not determine country code, using default');
        return _defaultCurrencySymbol;
      }
      
      debugPrint('CurrencyService: Country code determined: $countryCode');
      
      // Get currency symbol for the country
      return getCurrencySymbolForCountry(countryCode);
    } catch (e) {
      debugPrint('CurrencyService: Error getting currency symbol: $e');
      return _defaultCurrencySymbol;
    }
  }

  /// Reverse geocode coordinates to get country code
  static Future<String?> getCountryCodeFromCoordinates(double lat, double lng) async {
    try {
      debugPrint('CurrencyService: Reverse geocoding coordinates: $lat, $lng');
      
      final placemarks = await placemarkFromCoordinates(lat, lng);
      
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        final countryCode = placemark.isoCountryCode;
        
        debugPrint('CurrencyService: Country: ${placemark.country}');
        debugPrint('CurrencyService: Country code: $countryCode');
        
        return countryCode;
      }
      
      debugPrint('CurrencyService: No placemarks found for coordinates');
      return null;
    } catch (e) {
      debugPrint('CurrencyService: Error in reverse geocoding: $e');
      return null;
    }
  }

  /// Get currency symbol for a specific country code
  static String getCurrencySymbolForCountry(String countryCode) {
    // Check cache first
    if (_symbolCache.containsKey(countryCode)) {
      return _symbolCache[countryCode]!;
    }

    try {
      // Create locale from country code
      final locale = countryCodeToLocale(countryCode);
      
      // Get currency symbol using intl package
      final format = NumberFormat.simpleCurrency(locale: locale);
      final symbol = format.currencySymbol;
      
      // Cache the result
      _symbolCache[countryCode] = symbol;
      
      debugPrint('CurrencyService: Currency symbol for $countryCode: $symbol');
      return symbol;
    } catch (e) {
      debugPrint('CurrencyService: Error getting currency symbol for $countryCode: $e');
      // Return default symbol and cache it
      _symbolCache[countryCode] = _defaultCurrencySymbol;
      return _defaultCurrencySymbol;
    }
  }

  /// Convert country code to locale string
  static String countryCodeToLocale(String countryCode) {
    // Map of country codes to their primary language
    final languageMap = {
      'IN': 'hi', // India - Hindi
      'US': 'en', // United States - English
      'GB': 'en', // United Kingdom - English
      'CA': 'en', // Canada - English
      'AU': 'en', // Australia - English
      'DE': 'de', // Germany - German
      'FR': 'fr', // France - French
      'IT': 'it', // Italy - Italian
      'ES': 'es', // Spain - Spanish
      'JP': 'ja', // Japan - Japanese
      'CN': 'zh', // China - Chinese
      'KR': 'ko', // South Korea - Korean
      'BR': 'pt', // Brazil - Portuguese
      'RU': 'ru', // Russia - Russian
      'SA': 'ar', // Saudi Arabia - Arabic
      'AE': 'ar', // UAE - Arabic
      'SG': 'en', // Singapore - English
      'MY': 'ms', // Malaysia - Malay
      'TH': 'th', // Thailand - Thai
      'VN': 'vi', // Vietnam - Vietnamese
      'ID': 'id', // Indonesia - Indonesian
      'PH': 'en', // Philippines - English
      'BD': 'bn', // Bangladesh - Bengali
      'PK': 'ur', // Pakistan - Urdu
      'LK': 'si', // Sri Lanka - Sinhala
      'NP': 'ne', // Nepal - Nepali
      'MM': 'my', // Myanmar - Burmese
      'KE': 'sw', // Kenya - Swahili
      'GH': 'en', // Ghana - English
      'ET': 'am', // Ethiopia - Amharic
      'EG': 'ar', // Egypt - Arabic
      'ZA': 'en', // South Africa - English
      'NG': 'en', // Nigeria - English
    };

    final language = languageMap[countryCode] ?? 'en';
    final locale = '${language}_$countryCode';
    
    debugPrint('CurrencyService: Locale for $countryCode: $locale');
    return locale;
  }

  /// Clear the currency cache
  static void clearCache() {
    _symbolCache.clear();
    debugPrint('CurrencyService: Cache cleared');
  }
} 
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class CurrencyFormatter {
  static final Map<String, String> _currencySymbols = {
    'INR': '₹',
    'USD': '\$',
    'EUR': '€',
    'GBP': '£',
    'AED': 'د.إ',
    'SAR': 'ر.س',
    'QAR': 'ر.ق',
    'KWD': 'د.ك',
    'BHD': 'د.ب',
    'OMR': 'ر.ع.',
    'JOD': 'د.أ',
    'LBP': 'ل.ل',
    'EGP': 'ج.م',
    'MAD': 'د.م.',
    'TND': 'د.ت',
    'DZD': 'د.ج',
    'LYD': 'ل.د',
    'SDG': 'ج.س.',
    'SOS': 'S',
    'DJF': 'Fdj',
    'KMF': 'CF',
    'MUR': '₨',
    'SCR': '₨',
    'SLL': 'Le',
    'GMD': 'D',
    'GHS': '₵',
    'NGN': '₦',
    'XOF': 'CFA',
    'XAF': 'FCFA',
    'CDF': 'FC',
    'RWF': 'FRw',
    'BIF': 'FBu',
    'TZS': 'TSh',
    'UGX': 'USh',
    'KES': 'KSh',
    'ETB': 'Br',
    'ERN': 'Nfk',
  };

  static final Map<String, String> _currencyLocales = {
    'INR': 'en_IN',
    'USD': 'en_US',
    'EUR': 'en_DE',
    'GBP': 'en_GB',
    'AED': 'ar_AE',
    'SAR': 'ar_SA',
    'QAR': 'ar_QA',
    'KWD': 'ar_KW',
    'BHD': 'ar_BH',
    'OMR': 'ar_OM',
    'JOD': 'ar_JO',
    'LBP': 'ar_LB',
    'EGP': 'ar_EG',
    'MAD': 'ar_MA',
    'TND': 'ar_TN',
    'DZD': 'ar_DZ',
    'LYD': 'ar_LY',
    'SDG': 'ar_SD',
    'SOS': 'so_SO',
    'DJF': 'ar_DJ',
    'KMF': 'ar_KM',
    'MUR': 'en_MU',
    'SCR': 'en_SC',
    'SLL': 'en_SL',
    'GMD': 'en_GM',
    'GHS': 'en_GH',
    'NGN': 'en_NG',
    'XOF': 'fr_BF',
    'XAF': 'fr_CM',
    'CDF': 'fr_CD',
    'RWF': 'rw_RW',
    'BIF': 'rn_BI',
    'TZS': 'sw_TZ',
    'UGX': 'en_UG',
    'KES': 'en_KE',
    'ETB': 'am_ET',
    'ERN': 'ti_ER',
  };

  /// Get currency symbol for a given currency code
  static String getCurrencySymbol(String? currencyCode) {
    if (currencyCode == null || currencyCode.isEmpty) {
      return '₹'; // Default to INR
    }

    final code = currencyCode.toUpperCase();
    return _currencySymbols[code] ?? '₹';
  }

  /// Get appropriate locale for a given currency code
  static String getCurrencyLocale(String? currencyCode) {
    if (currencyCode == null || currencyCode.isEmpty) {
      return 'en_IN'; // Default to Indian locale
    }

    final code = currencyCode.toUpperCase();
    return _currencyLocales[code] ?? 'en_US';
  }

  /// Format price with proper currency formatting
  static String formatPrice(double amount, String? currencyCode) {
    if (currencyCode == null || currencyCode.isEmpty) {
      return NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: 2,
      ).format(amount);
    }

    try {
      final code = currencyCode.toUpperCase();
      final locale = getCurrencyLocale(code);
      final symbol = getCurrencySymbol(code);

      return NumberFormat.currency(
        locale: locale,
        symbol: symbol,
        decimalDigits: 2,
      ).format(amount);
    } catch (e) {
      debugPrint('CurrencyFormatter: Error formatting price for $currencyCode: $e');
      // Fallback to simple formatting
      final symbol = getCurrencySymbol(currencyCode);
      return '$symbol${amount.toStringAsFixed(2)}';
    }
  }

  /// Format price with custom decimal places
  static String formatPriceWithDecimals(double amount, String? currencyCode, int decimalDigits) {
    if (currencyCode == null || currencyCode.isEmpty) {
      return NumberFormat.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: decimalDigits,
      ).format(amount);
    }

    try {
      final code = currencyCode.toUpperCase();
      final locale = getCurrencyLocale(code);
      final symbol = getCurrencySymbol(code);

      return NumberFormat.currency(
        locale: locale,
        symbol: symbol,
        decimalDigits: decimalDigits,
      ).format(amount);
    } catch (e) {
      debugPrint('CurrencyFormatter: Error formatting price for $currencyCode: $e');
      // Fallback to simple formatting
      final symbol = getCurrencySymbol(currencyCode);
      return '$symbol${amount.toStringAsFixed(decimalDigits)}';
    }
  }

  /// Parse currency amount from string
  static double? parseCurrencyAmount(String amount, String? currencyCode) {
    if (amount.isEmpty) return null;

    try {
      final code = currencyCode?.toUpperCase() ?? 'INR';
      final locale = getCurrencyLocale(code);

      return NumberFormat.currency(locale: locale).parse(amount)?.toDouble();
    } catch (e) {
      debugPrint('CurrencyFormatter: Error parsing amount $amount for $currencyCode: $e');
      return null;
    }
  }

  /// Get currency name for a given currency code
  static String getCurrencyName(String? currencyCode) {
    if (currencyCode == null || currencyCode.isEmpty) {
      return 'Indian Rupee';
    }

    final code = currencyCode.toUpperCase();
    final currencyNames = {
      'INR': 'Indian Rupee',
      'USD': 'US Dollar',
      'EUR': 'Euro',
      'GBP': 'British Pound',
      'AED': 'UAE Dirham',
      'SAR': 'Saudi Riyal',
      'QAR': 'Qatari Riyal',
      'KWD': 'Kuwaiti Dinar',
      'BHD': 'Bahraini Dinar',
      'OMR': 'Omani Rial',
      'JOD': 'Jordanian Dinar',
      'LBP': 'Lebanese Pound',
      'EGP': 'Egyptian Pound',
      'MAD': 'Moroccan Dirham',
      'TND': 'Tunisian Dinar',
      'DZD': 'Algerian Dinar',
      'LYD': 'Libyan Dinar',
      'SDG': 'Sudanese Pound',
      'SOS': 'Somali Shilling',
      'DJF': 'Djiboutian Franc',
      'KMF': 'Comorian Franc',
      'MUR': 'Mauritian Rupee',
      'SCR': 'Seychellois Rupee',
      'SLL': 'Sierra Leonean Leone',
      'GMD': 'Gambian Dalasi',
      'GHS': 'Ghanaian Cedi',
      'NGN': 'Nigerian Naira',
      'XOF': 'West African CFA Franc',
      'XAF': 'Central African CFA Franc',
      'CDF': 'Congolese Franc',
      'RWF': 'Rwandan Franc',
      'BIF': 'Burundian Franc',
      'TZS': 'Tanzanian Shilling',
      'UGX': 'Ugandan Shilling',
      'KES': 'Kenyan Shilling',
      'ETB': 'Ethiopian Birr',
      'ERN': 'Eritrean Nakfa',
    };

    return currencyNames[code] ?? 'Unknown Currency';
  }
} 
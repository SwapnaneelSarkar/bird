import 'package:flutter_test/flutter_test.dart';
import 'package:bird/utils/currency_formatter.dart';

void main() {
  group('CurrencyFormatter Tests', () {
    test('should return correct currency symbols', () {
      expect(CurrencyFormatter.getCurrencySymbol('INR'), equals('₹'));
      expect(CurrencyFormatter.getCurrencySymbol('USD'), equals('\$'));
      expect(CurrencyFormatter.getCurrencySymbol('EUR'), equals('€'));
      expect(CurrencyFormatter.getCurrencySymbol('GBP'), equals('£'));
      expect(CurrencyFormatter.getCurrencySymbol('AED'), equals('د.إ'));
      expect(CurrencyFormatter.getCurrencySymbol('SAR'), equals('ر.س'));
      expect(CurrencyFormatter.getCurrencySymbol('QAR'), equals('ر.ق'));
      expect(CurrencyFormatter.getCurrencySymbol('KWD'), equals('د.ك'));
      expect(CurrencyFormatter.getCurrencySymbol('BHD'), equals('د.ب'));
      expect(CurrencyFormatter.getCurrencySymbol('OMR'), equals('ر.ع.'));
      expect(CurrencyFormatter.getCurrencySymbol('JOD'), equals('د.أ'));
      expect(CurrencyFormatter.getCurrencySymbol('LBP'), equals('ل.ل'));
      expect(CurrencyFormatter.getCurrencySymbol('EGP'), equals('ج.م'));
      expect(CurrencyFormatter.getCurrencySymbol('MAD'), equals('د.م.'));
      expect(CurrencyFormatter.getCurrencySymbol('TND'), equals('د.ت'));
      expect(CurrencyFormatter.getCurrencySymbol('DZD'), equals('د.ج'));
      expect(CurrencyFormatter.getCurrencySymbol('LYD'), equals('ل.د'));
      expect(CurrencyFormatter.getCurrencySymbol('SDG'), equals('ج.س.'));
      expect(CurrencyFormatter.getCurrencySymbol('SOS'), equals('S'));
      expect(CurrencyFormatter.getCurrencySymbol('DJF'), equals('Fdj'));
      expect(CurrencyFormatter.getCurrencySymbol('KMF'), equals('CF'));
      expect(CurrencyFormatter.getCurrencySymbol('MUR'), equals('₨'));
      expect(CurrencyFormatter.getCurrencySymbol('SCR'), equals('₨'));
      expect(CurrencyFormatter.getCurrencySymbol('SLL'), equals('Le'));
      expect(CurrencyFormatter.getCurrencySymbol('GMD'), equals('D'));
      expect(CurrencyFormatter.getCurrencySymbol('GHS'), equals('₵'));
      expect(CurrencyFormatter.getCurrencySymbol('NGN'), equals('₦'));
      expect(CurrencyFormatter.getCurrencySymbol('XOF'), equals('CFA'));
      expect(CurrencyFormatter.getCurrencySymbol('XAF'), equals('FCFA'));
      expect(CurrencyFormatter.getCurrencySymbol('CDF'), equals('FC'));
      expect(CurrencyFormatter.getCurrencySymbol('RWF'), equals('FRw'));
      expect(CurrencyFormatter.getCurrencySymbol('BIF'), equals('FBu'));
      expect(CurrencyFormatter.getCurrencySymbol('TZS'), equals('TSh'));
      expect(CurrencyFormatter.getCurrencySymbol('UGX'), equals('USh'));
      expect(CurrencyFormatter.getCurrencySymbol('KES'), equals('KSh'));
      expect(CurrencyFormatter.getCurrencySymbol('ETB'), equals('Br'));
      expect(CurrencyFormatter.getCurrencySymbol('ERN'), equals('Nfk'));
    });

    test('should return default symbol for unknown currency', () {
      expect(CurrencyFormatter.getCurrencySymbol('UNKNOWN'), equals('₹'));
      expect(CurrencyFormatter.getCurrencySymbol(null), equals('₹'));
      expect(CurrencyFormatter.getCurrencySymbol(''), equals('₹'));
    });

    test('should format prices correctly', () {
      // Test INR formatting
      expect(CurrencyFormatter.formatPrice(1234.56, 'INR'), contains('₹'));
      expect(CurrencyFormatter.formatPrice(1234.56, 'INR'), contains('1,234.56'));
      
      // Test USD formatting
      expect(CurrencyFormatter.formatPrice(1234.56, 'USD'), contains('\$'));
      expect(CurrencyFormatter.formatPrice(1234.56, 'USD'), contains('1,234.56'));
      
      // Test EUR formatting
      expect(CurrencyFormatter.formatPrice(1234.56, 'EUR'), contains('€'));
      expect(CurrencyFormatter.formatPrice(1234.56, 'EUR'), contains('1,234.56'));
      
      // Test AED formatting
      expect(CurrencyFormatter.formatPrice(1234.56, 'AED'), contains('د.إ'));
      
      // Test zero amount
      expect(CurrencyFormatter.formatPrice(0.0, 'INR'), contains('₹0.00'));
      
      // Test negative amount
      expect(CurrencyFormatter.formatPrice(-1234.56, 'INR'), contains('-₹'));
    });

    test('should format prices with custom decimal places', () {
      expect(CurrencyFormatter.formatPriceWithDecimals(1234.5, 'INR', 1), contains('₹1,234.5'));
      expect(CurrencyFormatter.formatPriceWithDecimals(1234.567, 'INR', 3), contains('₹1,234.567'));
      expect(CurrencyFormatter.formatPriceWithDecimals(1234, 'INR', 0), contains('₹1,234'));
    });

    test('should return correct currency names', () {
      expect(CurrencyFormatter.getCurrencyName('INR'), equals('Indian Rupee'));
      expect(CurrencyFormatter.getCurrencyName('USD'), equals('US Dollar'));
      expect(CurrencyFormatter.getCurrencyName('EUR'), equals('Euro'));
      expect(CurrencyFormatter.getCurrencyName('GBP'), equals('British Pound'));
      expect(CurrencyFormatter.getCurrencyName('AED'), equals('UAE Dirham'));
      expect(CurrencyFormatter.getCurrencyName('SAR'), equals('Saudi Riyal'));
      expect(CurrencyFormatter.getCurrencyName('QAR'), equals('Qatari Riyal'));
      expect(CurrencyFormatter.getCurrencyName('KWD'), equals('Kuwaiti Dinar'));
      expect(CurrencyFormatter.getCurrencyName('BHD'), equals('Bahraini Dinar'));
      expect(CurrencyFormatter.getCurrencyName('OMR'), equals('Omani Rial'));
      expect(CurrencyFormatter.getCurrencyName('JOD'), equals('Jordanian Dinar'));
      expect(CurrencyFormatter.getCurrencyName('LBP'), equals('Lebanese Pound'));
      expect(CurrencyFormatter.getCurrencyName('EGP'), equals('Egyptian Pound'));
      expect(CurrencyFormatter.getCurrencyName('MAD'), equals('Moroccan Dirham'));
      expect(CurrencyFormatter.getCurrencyName('TND'), equals('Tunisian Dinar'));
      expect(CurrencyFormatter.getCurrencyName('DZD'), equals('Algerian Dinar'));
      expect(CurrencyFormatter.getCurrencyName('LYD'), equals('Libyan Dinar'));
      expect(CurrencyFormatter.getCurrencyName('SDG'), equals('Sudanese Pound'));
      expect(CurrencyFormatter.getCurrencyName('SOS'), equals('Somali Shilling'));
      expect(CurrencyFormatter.getCurrencyName('DJF'), equals('Djiboutian Franc'));
      expect(CurrencyFormatter.getCurrencyName('KMF'), equals('Comorian Franc'));
      expect(CurrencyFormatter.getCurrencyName('MUR'), equals('Mauritian Rupee'));
      expect(CurrencyFormatter.getCurrencyName('SCR'), equals('Seychellois Rupee'));
      expect(CurrencyFormatter.getCurrencyName('SLL'), equals('Sierra Leonean Leone'));
      expect(CurrencyFormatter.getCurrencyName('GMD'), equals('Gambian Dalasi'));
      expect(CurrencyFormatter.getCurrencyName('GHS'), equals('Ghanaian Cedi'));
      expect(CurrencyFormatter.getCurrencyName('NGN'), equals('Nigerian Naira'));
      expect(CurrencyFormatter.getCurrencyName('XOF'), equals('West African CFA Franc'));
      expect(CurrencyFormatter.getCurrencyName('XAF'), equals('Central African CFA Franc'));
      expect(CurrencyFormatter.getCurrencyName('CDF'), equals('Congolese Franc'));
      expect(CurrencyFormatter.getCurrencyName('RWF'), equals('Rwandan Franc'));
      expect(CurrencyFormatter.getCurrencyName('BIF'), equals('Burundian Franc'));
      expect(CurrencyFormatter.getCurrencyName('TZS'), equals('Tanzanian Shilling'));
      expect(CurrencyFormatter.getCurrencyName('UGX'), equals('Ugandan Shilling'));
      expect(CurrencyFormatter.getCurrencyName('KES'), equals('Kenyan Shilling'));
      expect(CurrencyFormatter.getCurrencyName('ETB'), equals('Ethiopian Birr'));
      expect(CurrencyFormatter.getCurrencyName('ERN'), equals('Eritrean Nakfa'));
    });

    test('should return default name for unknown currency', () {
      expect(CurrencyFormatter.getCurrencyName('UNKNOWN'), equals('Unknown Currency'));
      expect(CurrencyFormatter.getCurrencyName(null), equals('Indian Rupee'));
      expect(CurrencyFormatter.getCurrencyName(''), equals('Indian Rupee'));
    });

    test('should handle case insensitive currency codes', () {
      expect(CurrencyFormatter.getCurrencySymbol('inr'), equals('₹'));
      expect(CurrencyFormatter.getCurrencySymbol('Inr'), equals('₹'));
      expect(CurrencyFormatter.getCurrencySymbol('INR'), equals('₹'));
      
      expect(CurrencyFormatter.getCurrencyName('usd'), equals('US Dollar'));
      expect(CurrencyFormatter.getCurrencyName('Usd'), equals('US Dollar'));
      expect(CurrencyFormatter.getCurrencyName('USD'), equals('US Dollar'));
    });
  });
} 
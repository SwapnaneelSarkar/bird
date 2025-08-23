import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Address Name Validation Tests', () {
    test('should prevent duplicate "home" names', () {
      // Mock saved addresses with one "home" address
      final savedAddresses = [
        {'address_line2': 'Home', 'address_id': '1'},
        {'address_line2': 'Office', 'address_id': '2'},
      ];
      
      // Helper function to check if "home" name exists
      bool isHomeNameExists(List<Map<String, dynamic>> addresses) {
        return addresses.any((a) => 
          (a['address_line2'] ?? 'Other').toString().toLowerCase() == 'home'
        );
      }
      
      // Test that "home" name exists
      expect(isHomeNameExists(savedAddresses), true);
      
      // Test that "office" name doesn't conflict
      expect(isHomeNameExists([
        {'address_line2': 'Office', 'address_id': '1'},
        {'address_line2': 'Work', 'address_id': '2'},
      ]), false);
    });
    
    test('should allow editing existing "home" address', () {
      // Mock saved addresses with one "home" address
      final savedAddresses = [
        {'address_line2': 'Home', 'address_id': '1'},
        {'address_line2': 'Office', 'address_id': '2'},
      ];
      
      // Helper function to check if "home" name exists excluding current address
      bool isHomeNameExistsExcludingCurrent(
        List<Map<String, dynamic>> addresses, 
        String currentAddressId
      ) {
        return addresses
          .where((a) => a['address_id']?.toString() != currentAddressId)
          .any((a) => (a['address_line2'] ?? 'Other').toString().toLowerCase() == 'home');
      }
      
      // Test that editing the existing "home" address is allowed
      expect(isHomeNameExistsExcludingCurrent(savedAddresses, '1'), false);
      
      // Test that trying to create another "home" address is blocked
      expect(isHomeNameExistsExcludingCurrent(savedAddresses, '3'), true);
    });
    
    test('should handle case-insensitive validation', () {
      final savedAddresses = [
        {'address_line2': 'HOME', 'address_id': '1'},
        {'address_line2': 'Home', 'address_id': '2'},
        {'address_line2': 'home', 'address_id': '3'},
      ];
      
      bool isHomeNameExists(List<Map<String, dynamic>> addresses) {
        return addresses.any((a) => 
          (a['address_line2'] ?? 'Other').toString().toLowerCase() == 'home'
        );
      }
      
      // All variations should be detected as "home"
      expect(isHomeNameExists(savedAddresses), true);
    });
  });
} 
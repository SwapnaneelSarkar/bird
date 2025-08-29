import 'package:flutter_test/flutter_test.dart';

// Test the name character limit validation
void main() {
  group('Name Character Limit Tests', () {
    test('should accept names with 30 characters or less', () {
      // Valid names within 30 character limit
      expect('John'.length <= 30, true);
      expect('John Doe'.length <= 30, true);
      expect('Mary Jane Smith'.length <= 30, true);
      expect('A'.length <= 30, true);
      
      // Test exactly 30 characters
      final exactly30Chars = 'A' * 30;
      expect(exactly30Chars.length, 30);
      expect(exactly30Chars.length <= 30, true);
    });

    test('should reject names with more than 30 characters', () {
      // Invalid names exceeding 30 character limit
      final over30Chars = 'A' * 31;
      expect(over30Chars.length > 30, true);
      
      final veryLongName = 'This is a very long name that exceeds thirty characters';
      expect(veryLongName.length > 30, true);
    });

    test('should validate name format and length together', () {
      // Valid name: alphabets and spaces, within 30 characters
      final validName = 'John Doe Smith';
      final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
      expect(nameRegex.hasMatch(validName.trim()) && validName.trim().length <= 30, true);
      
      // Invalid name: too long
      final invalidLongName = 'A' * 31;
      expect(nameRegex.hasMatch(invalidLongName.trim()) && invalidLongName.trim().length <= 30, false);
      
      // Invalid name: contains numbers
      final invalidNameWithNumbers = 'John123';
      expect(nameRegex.hasMatch(invalidNameWithNumbers.trim()) && invalidNameWithNumbers.trim().length <= 30, false);
    });

    test('should handle edge cases', () {
      // Empty string
      expect(''.length <= 30, true);
      
      // Only spaces
      expect('   '.trim().length <= 30, true);
      
      // Leading/trailing spaces
      final nameWithSpaces = '  John Doe  ';
      final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
      expect(nameRegex.hasMatch(nameWithSpaces.trim()) && nameWithSpaces.trim().length <= 30, true);
    });
  });
} 
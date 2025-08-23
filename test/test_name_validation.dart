import 'package:flutter_test/flutter_test.dart';

// Test the name validation regex pattern
void main() {
  group('Name Validation Tests', () {
    test('should accept valid names with only alphabets and spaces', () {
      final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
      
      // Valid names
      expect(nameRegex.hasMatch('John'), true);
      expect(nameRegex.hasMatch('John Doe'), true);
      expect(nameRegex.hasMatch('Mary Jane'), true);
      expect(nameRegex.hasMatch('O\'Connor'), false); // Contains apostrophe
      expect(nameRegex.hasMatch('Jean-Pierre'), false); // Contains hyphen
      expect(nameRegex.hasMatch('José'), false); // Contains accent
      expect(nameRegex.hasMatch('John123'), false); // Contains numbers
      expect(nameRegex.hasMatch('John@Doe'), false); // Contains special characters
      expect(nameRegex.hasMatch('John_Doe'), false); // Contains underscore
      expect(nameRegex.hasMatch(''), false); // Empty string
      expect(nameRegex.hasMatch('   '), true); // Only spaces
      expect(nameRegex.hasMatch('  John  '), true); // Leading/trailing spaces
    });

    test('should reject names with numbers', () {
      final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
      
      expect(nameRegex.hasMatch('John123'), false);
      expect(nameRegex.hasMatch('123John'), false);
      expect(nameRegex.hasMatch('John 123'), false);
    });

    test('should reject names with special characters', () {
      final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
      
      expect(nameRegex.hasMatch('John@Doe'), false);
      expect(nameRegex.hasMatch('John#Doe'), false);
      expect(nameRegex.hasMatch('John\$Doe'), false);
      expect(nameRegex.hasMatch('John%Doe'), false);
      expect(nameRegex.hasMatch('John&Doe'), false);
      expect(nameRegex.hasMatch('John*Doe'), false);
    });

    test('should reject names with punctuation', () {
      final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
      
      expect(nameRegex.hasMatch('John.Doe'), false);
      expect(nameRegex.hasMatch('John,Doe'), false);
      expect(nameRegex.hasMatch('John;Doe'), false);
      expect(nameRegex.hasMatch('John:Doe'), false);
      expect(nameRegex.hasMatch('John!Doe'), false);
      expect(nameRegex.hasMatch('John?Doe'), false);
    });
  });
} 
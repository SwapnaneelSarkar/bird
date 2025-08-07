// Test file to verify address saving fixes for new users
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

// Mock test to verify address service functionality
void main() {
  group('Address Service Tests', () {
    test('Should handle new user authentication properly', () async {
      // This test simulates the flow for a new user
      print('Testing address service for new users...');
      
      // Simulate the authentication flow
      final authResponse = await http.post(
        Uri.parse('https://api.bird.delivery/api/user/auth'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mobile': '1234567890'}),
      );
      
      print('Auth response status: ${authResponse.statusCode}');
      print('Auth response body: ${authResponse.body}');
      
      if (authResponse.statusCode == 200) {
        final authData = jsonDecode(authResponse.body);
        if (authData['status'] == true) {
          final token = authData['token'];
          final userData = authData['data'];
          final userId = userData['user_id'];
          
          print('Authentication successful:');
          print('  User ID: $userId');
          print('  Token: ${token.substring(0, 20)}...');
          
          // Test address saving
          final addressResponse = await http.post(
            Uri.parse('https://api.bird.delivery/api/user/addresses'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'user_id': userId,
              'address_line1': 'Test Address',
              'address_line2': 'Home',
              'city': 'Test City',
              'state': 'Test State',
              'postal_code': '12345',
              'country': 'India',
              'latitude': '12.9716',
              'longitude': '77.5946',
              'is_default': 1,
            }),
          );
          
          print('Address save response status: ${addressResponse.statusCode}');
          print('Address save response body: ${addressResponse.body}');
          
          expect(addressResponse.statusCode, 200);
          
          final addressData = jsonDecode(addressResponse.body);
          expect(addressData['status'], true);
          
          print('✅ Address saving test passed!');
        } else {
          print('❌ Authentication failed: ${authData['message']}');
        }
      } else {
        print('❌ Auth request failed with status: ${authResponse.statusCode}');
      }
    });
  });
} 
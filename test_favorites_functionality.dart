import 'dart:convert';
import 'package:http/http.dart' as http;

// Test the favorites API endpoints
void main() async {
  print('Testing Favorites API functionality...\n');
  
  const String baseUrl = 'https://api.bird.delivery';
  const String testPartnerId = 'R1362a07d1f';
  
  // Note: You'll need to replace this with a valid token for testing
  const String testToken = 'YOUR_TEST_TOKEN_HERE';
  
  if (testToken == 'YOUR_TEST_TOKEN_HERE') {
    print('⚠️  Please replace testToken with a valid authentication token to run tests');
    return;
  }
  
  try {
    // Test 1: Get favorites count
    print('1. Testing get favorites count...');
    final countResponse = await http.get(
      Uri.parse('$baseUrl/api/user/favorites/count'),
      headers: {
        'Authorization': 'Bearer $testToken',
        'Content-Type': 'application/json',
      },
    );
    
    print('Count Response Status: ${countResponse.statusCode}');
    print('Count Response Body: ${countResponse.body}\n');
    
    // Test 2: Get all favorites
    print('2. Testing get all favorites...');
    final favoritesResponse = await http.get(
      Uri.parse('$baseUrl/api/user/favorites'),
      headers: {
        'Authorization': 'Bearer $testToken',
        'Content-Type': 'application/json',
      },
    );
    
    print('Favorites Response Status: ${favoritesResponse.statusCode}');
    print('Favorites Response Body: ${favoritesResponse.body}\n');
    
    // Test 3: Check favorite status
    print('3. Testing check favorite status...');
    final checkResponse = await http.get(
      Uri.parse('$baseUrl/api/user/favorites/check/$testPartnerId'),
      headers: {
        'Authorization': 'Bearer $testToken',
        'Content-Type': 'application/json',
      },
    );
    
    print('Check Response Status: ${checkResponse.statusCode}');
    print('Check Response Body: ${checkResponse.body}\n');
    
    // Test 4: Toggle favorite
    print('4. Testing toggle favorite...');
    final toggleResponse = await http.post(
      Uri.parse('$baseUrl/api/user/favorites/toggle'),
      headers: {
        'Authorization': 'Bearer $testToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'partner_id': testPartnerId,
      }),
    );
    
    print('Toggle Response Status: ${toggleResponse.statusCode}');
    print('Toggle Response Body: ${toggleResponse.body}\n');
    
    print('✅ All tests completed!');
    
  } catch (e) {
    print('❌ Error during testing: $e');
  }
} 
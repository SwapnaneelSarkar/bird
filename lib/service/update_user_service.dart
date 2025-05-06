import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../constants/api_constant.dart';

class UpdateUserService {
  Future<Map<String, dynamic>> updateUserProfile({
    required String token,
    required String mobile,
    required String username,
    required String email,
    String? password,
    required String address,
    required double latitude,
    required double longitude,
    File? imageFile,
  }) async {
    try {
      debugPrint('UpdateUserService: Starting profile update...');
      debugPrint('UpdateUserService: Token: $token');
      debugPrint('UpdateUserService: Mobile: $mobile');
      debugPrint('UpdateUserService: Username: $username');
      debugPrint('UpdateUserService: Email: $email');
      debugPrint('UpdateUserService: Address: $address');
      debugPrint('UpdateUserService: Latitude: $latitude');
      debugPrint('UpdateUserService: Longitude: $longitude');
      debugPrint('UpdateUserService: Has image: ${imageFile != null}');

      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(ApiConstants.updateUserUrl));
      
      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Add text fields - ensure all parameters are sent correctly
      request.fields['mobile'] = mobile;
      request.fields['username'] = username;
      request.fields['email'] = email;
      if (password != null && password.isNotEmpty) {
        request.fields['password'] = password;
      }
      request.fields['address'] = address;
      
      // Convert coordinates to string and ensure they are not NaN or Infinity
      if (!latitude.isNaN && !latitude.isInfinite) {
        request.fields['latitude'] = latitude.toString();
        debugPrint('UpdateUserService: Adding latitude field: ${latitude.toString()}');
      } else {
        request.fields['latitude'] = '0.0';
        debugPrint('UpdateUserService: Invalid latitude, using 0.0 instead');
      }
      
      if (!longitude.isNaN && !longitude.isInfinite) {
        request.fields['longitude'] = longitude.toString();
        debugPrint('UpdateUserService: Adding longitude field: ${longitude.toString()}');
      } else {
        request.fields['longitude'] = '0.0';
        debugPrint('UpdateUserService: Invalid longitude, using 0.0 instead');
      }

      // Add image file if exists
      if (imageFile != null && await imageFile.exists()) {
        debugPrint('UpdateUserService: Adding image to request...');
        var imageStream = http.ByteStream(imageFile.openRead());
        var imageLength = await imageFile.length();
        
        var multipartFile = http.MultipartFile(
          'image',
          imageStream,
          imageLength,
          filename: 'profile_image${imageFile.path.substring(imageFile.path.lastIndexOf('.'))}',
        );
        
        request.files.add(multipartFile);
      }

      debugPrint('UpdateUserService: Sending request to: ${ApiConstants.updateUserUrl}');
      
      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      debugPrint('UpdateUserService: Response status: ${response.statusCode}');
      debugPrint('UpdateUserService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['status'] == true) {
          debugPrint('UpdateUserService: Profile update successful');
          return {
            'success': true,
            'message': responseData['message'] ?? 'Profile updated successfully',
            'data': responseData['data'],
          };
        } else {
          debugPrint('UpdateUserService: Profile update failed: ${responseData['message']}');
          return {
            'success': false,
            'message': responseData['message'] ?? 'Profile update failed',
          };
        }
      } else {
        debugPrint('UpdateUserService: Profile update error: Status ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server error occurred. Please try again.',
        };
      }
    } catch (e) {
      debugPrint('UpdateUserService: Profile update exception: $e');
      return {
        'success': false,
        'message': 'Network error occurred. Please check your connection.',
      };
    }
  }
  
  // Upload just the profile image
  Future<Map<String, dynamic>> uploadProfileImage({
    required String token,
    required String mobile,
    required File imageFile,
  }) async {
    try {
      debugPrint('UpdateUserService: Starting profile image upload...');
      debugPrint('UpdateUserService: Token: $token');
      debugPrint('UpdateUserService: Mobile: $mobile');
      debugPrint('UpdateUserService: Has image: ${imageFile != null}');

      // Create a form data request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/api/user/update-user'),
      );
      
      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add the mobile number field - this is critical
      request.fields['mobile'] = mobile;
      
      // Add other required fields with empty values to avoid null issues
      request.fields['username'] = '';
      request.fields['email'] = '';
      request.fields['address'] = '';
      request.fields['latitude'] = '0.0';
      request.fields['longitude'] = '0.0';

      // Add the image file if it exists
      if (imageFile != null && await imageFile.exists()) {
        var imageStream = http.ByteStream(imageFile.openRead());
        var length = await imageFile.length();
        
        var multipartFile = http.MultipartFile(
          'image', // Make sure this field name matches what your API expects
          imageStream,
          length,
          filename: 'profile_image.jpg',
        );
        
        request.files.add(multipartFile);
        debugPrint('UpdateUserService: Image file added to request');
      }

      // Send the request
      debugPrint('UpdateUserService: Sending request to: ${request.url}');
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      debugPrint('UpdateUserService: Response status: ${response.statusCode}');
      debugPrint('UpdateUserService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['status'] == true) {
          debugPrint('UpdateUserService: Image upload successful');
          return {
            'success': true,
            'message': responseData['message'] ?? 'Profile image updated successfully',
            'data': responseData['data'],
          };
        } else {
          debugPrint('UpdateUserService: Image upload failed: ${responseData['message']}');
          return {
            'success': false,
            'message': responseData['message'] ?? 'Profile image update failed',
          };
        }
      } else {
        debugPrint('UpdateUserService: Profile image update error: Status ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server error occurred. Please try again.',
        };
      }
    } catch (e) {
      debugPrint('UpdateUserService: Profile image update exception: $e');
      return {
        'success': false,
        'message': 'Network error occurred. Please check your connection.',
      };
    }
  }
}
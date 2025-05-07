import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../../constants/api_constant.dart';

class UpdateUserService {
  Future<Map<String, dynamic>> updateUserProfile({
    required String token,
    required String mobile,
    String? username,
    String? email,
    String? password,
    String? address,
    double? latitude,
    double? longitude,
    File? imageFile,
  }) async {
    try {
      debugPrint('UpdateUserService: Starting profile update...');
      debugPrint('UpdateUserService: Token: $token');
      debugPrint('UpdateUserService: Mobile: $mobile');
      
      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(ApiConstants.updateUserUrl));
      
      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Add mobile field - only required field
      request.fields['mobile'] = mobile;
      
      // Add optional fields only if they are provided
      if (username != null) {
        request.fields['username'] = username;
        debugPrint('UpdateUserService: Username: $username');
      }
      
      if (email != null) {
        request.fields['email'] = email;
        debugPrint('UpdateUserService: Email: $email');
      }
      
      if (password != null && password.isNotEmpty) {
        request.fields['password'] = password;
        debugPrint('UpdateUserService: Password provided');
      }
      
      if (address != null) {
        request.fields['address'] = address;
        debugPrint('UpdateUserService: Address: $address');
      }
      
      // Add latitude if provided and valid
      if (latitude != null && !latitude.isNaN && !latitude.isInfinite) {
        request.fields['latitude'] = latitude.toString();
        debugPrint('UpdateUserService: Latitude: $latitude');
      }
      
      // Add longitude if provided and valid
      if (longitude != null && !longitude.isNaN && !longitude.isInfinite) {
        request.fields['longitude'] = longitude.toString();
        debugPrint('UpdateUserService: Longitude: $longitude');
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
      
      // Add only the mobile number field - this is critical
      request.fields['mobile'] = mobile;

      // Add the image file if it exists
      if (await imageFile.exists()) {
        var imageStream = http.ByteStream(imageFile.openRead());
        var length = await imageFile.length();
        
        var multipartFile = http.MultipartFile(
          'image', // Make sure this field name matches what your API expects
          imageStream,
          length,
          filename: 'profile_image${imageFile.path.substring(imageFile.path.lastIndexOf('.'))}',
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
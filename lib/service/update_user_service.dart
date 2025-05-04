import 'dart:convert';
import 'dart:io';
import 'package:bird/constants/api_constant.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

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
      debugPrint('Token: $token');
      debugPrint('Mobile: $mobile');
      debugPrint('Username: $username');
      debugPrint('Email: $email');
      debugPrint('Address: $address');
      debugPrint('Latitude: $latitude');
      debugPrint('Longitude: $longitude');
      debugPrint('Has image: ${imageFile != null}');

      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(ApiConstants.updateUserUrl));
      
      // Add headers
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Add text fields
      request.fields['mobile'] = mobile;
      request.fields['username'] = username;
      request.fields['email'] = email;
      if (password != null && password.isNotEmpty) {
        request.fields['password'] = password;
      }
      request.fields['address'] = address;
      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();

      // Add image file if exists
      if (imageFile != null && await imageFile.exists()) {
        debugPrint('Adding image to request...');
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

      debugPrint('Sending request to: ${ApiConstants.updateUserUrl}');
      
      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        
        if (responseData['status'] == true) {
          debugPrint('Profile update successful');
          return {
            'success': true,
            'message': responseData['message'] ?? 'Profile updated successfully',
            'data': responseData['data'],
          };
        } else {
          debugPrint('Profile update failed: ${responseData['message']}');
          return {
            'success': false,
            'message': responseData['message'] ?? 'Profile update failed',
          };
        }
      } else {
        debugPrint('Profile update error: Status ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server error occurred. Please try again.',
        };
      }
    } catch (e) {
      debugPrint('Profile update exception: $e');
      return {
        'success': false,
        'message': 'Network error occurred. Please check your connection.',
      };
    }
  }
}
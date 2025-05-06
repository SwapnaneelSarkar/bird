import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ProfileService {
  static const String _nameKey = 'user_name';
  static const String _emailKey = 'user_email';
  static const String _photoPathKey = 'user_photo_path';
  static const String _profileCompletedKey = 'profile_completed';

  // Save user name
  static Future<bool> saveName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.setString(_nameKey, name);
      debugPrint('Name saved: ${result ? "Success" : "Failed"}');
      return result;
    } catch (e) {
      debugPrint('Error saving name: $e');
      return false;
    }
  }

  // Get user name
  static Future<String?> getName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_nameKey);
    } catch (e) {
      debugPrint('Error retrieving name: $e');
      return null;
    }
  }

  // Save user email
  static Future<bool> saveEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.setString(_emailKey, email);
      debugPrint('Email saved: ${result ? "Success" : "Failed"}');
      return result;
    } catch (e) {
      debugPrint('Error saving email: $e');
      return false;
    }
  }

  // Get user email
  static Future<String?> getEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_emailKey);
    } catch (e) {
      debugPrint('Error retrieving email: $e');
      return null;
    }
  }

  // Save user photo
  static Future<String?> savePhoto(File photo) async {
    try {
      // Get the application documents directory
      final directory = await getApplicationDocumentsDirectory();
      
      // Create a subdirectory for profile photos
      final profilePhotosDir = Directory('${directory.path}/profile_photos');
      if (!await profilePhotosDir.exists()) {
        await profilePhotosDir.create(recursive: true);
      }
      
      // Generate a unique filename
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}${path.extension(photo.path)}';
      final savedImagePath = '${profilePhotosDir.path}/$fileName';
      
      // Copy the file to the application directory
      final savedImage = await photo.copy(savedImagePath);
      
      // Save the file path in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_photoPathKey, savedImage.path);
      
      debugPrint('Photo saved at: ${savedImage.path}');
      return savedImage.path;
    } catch (e) {
      debugPrint('Error saving photo: $e');
      return null;
    }
  }

  // Get user photo
  static Future<File?> getPhoto() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final photoPath = prefs.getString(_photoPathKey);
      
      if (photoPath != null) {
        final file = File(photoPath);
        if (await file.exists()) {
          return file;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error retrieving photo: $e');
      return null;
    }
  }

  // Save profile completed status
  static Future<bool> setProfileCompleted(bool completed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(_profileCompletedKey, completed);
    } catch (e) {
      debugPrint('Error saving profile completed status: $e');
      return false;
    }
  }

  // Check if profile is completed
  static Future<bool> isProfileCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_profileCompletedKey) ?? false;
    } catch (e) {
      debugPrint('Error checking profile completed status: $e');
      return false;
    }
  }

  // Save complete profile data
  // Update the saveProfileData method in ProfileService (paste-5.txt)
static Future<bool> saveProfileData({
  required String name,
  required String email,
  File? photo,
  String? address,
  double? latitude,
  double? longitude,
}) async {
  try {
    bool success = true;
    
    // Save name
    success = success && await saveName(name);
    
    // Save email
    success = success && await saveEmail(email);
    
    // Save address and coordinates if provided
    if (address != null) {
      final prefs = await SharedPreferences.getInstance();
      success = success && await prefs.setString('user_address', address);
    }
    
    if (latitude != null) {
      final prefs = await SharedPreferences.getInstance();
      success = success && await prefs.setDouble('user_latitude', latitude);
    }
    
    if (longitude != null) {
      final prefs = await SharedPreferences.getInstance();
      success = success && await prefs.setDouble('user_longitude', longitude);
    }
    
    // Save photo if provided
    if (photo != null) {
      final photoPath = await savePhoto(photo);
      success = success && (photoPath != null);
    }
    
    // Mark profile as completed
    if (success) {
      await setProfileCompleted(true);
    }
    
    return success;
  } catch (e) {
    debugPrint('Error saving profile data: $e');
    return false;
  }
}

// Update the getProfileData method as well
static Future<Map<String, dynamic>> getProfileData() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final name = await getName();
    final email = await getEmail();
    final photo = await getPhoto();
    final isCompleted = await isProfileCompleted();
    final address = prefs.getString('user_address');
    final latitude = prefs.getDouble('user_latitude');
    final longitude = prefs.getDouble('user_longitude');
    
    return {
      'name': name,
      'email': email,
      'photo': photo,
      'isCompleted': isCompleted,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  } catch (e) {
    debugPrint('Error retrieving profile data: $e');
    return {
      'name': null,
      'email': null,
      'photo': null,
      'isCompleted': false,
      'address': null,
      'latitude': null,
      'longitude': null,
    };
  }
}


  // Clear profile data
  static Future<bool> clearProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get and delete the photo file if it exists
      final photoPath = prefs.getString(_photoPathKey);
      if (photoPath != null) {
        final photoFile = File(photoPath);
        if (await photoFile.exists()) {
          await photoFile.delete();
        }
      }
      
      // Clear all profile-related preferences
      await prefs.remove(_nameKey);
      await prefs.remove(_emailKey);
      await prefs.remove(_photoPathKey);
      await prefs.remove(_profileCompletedKey);
      
      debugPrint('Profile data cleared');
      return true;
    } catch (e) {
      debugPrint('Error clearing profile data: $e');
      return false;
    }
  }
}
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class TokenService {
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userDataKey = 'user_data';

  // Save token
  static Future<bool> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.setString(_tokenKey, token);
      debugPrint('Token saved: ${result ? "Success" : "Failed"}');
      return result;
    } catch (e) {
      debugPrint('Error saving token: $e');
      return false;
    }
  }

  // Get token
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      debugPrint('Token retrieved: ${token != null ? "Found" : "Not found"}');
      return token;
    } catch (e) {
      debugPrint('Error retrieving token: $e');
      return null;
    }
  }

  // Save user ID
  static Future<bool> saveUserId(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.setInt(_userIdKey, userId);
      debugPrint('User ID saved: ${result ? "Success" : "Failed"}');
      return result;
    } catch (e) {
      debugPrint('Error saving user ID: $e');
      return false;
    }
  }

  // Get user ID
  static Future<int?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt(_userIdKey);
      debugPrint('User ID retrieved: ${userId ?? "Not found"}');
      return userId;
    } catch (e) {
      debugPrint('Error retrieving user ID: $e');
      return null;
    }
  }

  // Save user data as JSON string
  static Future<bool> saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = jsonEncode(userData);
      final result = await prefs.setString(_userDataKey, userDataString);
      debugPrint('User data saved: ${result ? "Success" : "Failed"}');
      return result;
    } catch (e) {
      debugPrint('Error saving user data: $e');
      return false;
    }
  }

  // Get user data
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString(_userDataKey);
      if (userDataString != null) {
        final userData = jsonDecode(userDataString) as Map<String, dynamic>;
        debugPrint('User data retrieved successfully');
        return userData;
      }
      debugPrint('No user data found');
      return null;
    } catch (e) {
      debugPrint('Error retrieving user data: $e');
      return null;
    }
  }

  // Clear all saved data (for logout)
  static Future<bool> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userIdKey);
      await prefs.remove(_userDataKey);
      debugPrint('All user data cleared');
      return true;
    } catch (e) {
      debugPrint('Error clearing user data: $e');
      return false;
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    try {
      final token = await getToken();
      final userId = await getUserId();
      final isLoggedIn = token != null && userId != null;
      debugPrint('Is user logged in: $isLoggedIn');
      return isLoggedIn;
    } catch (e) {
      debugPrint('Error checking login status: $e');
      return false;
    }
  }

  // Save complete auth data (token + user data)
  static Future<bool> saveAuthData(String token, Map<String, dynamic> userData) async {
    try {
      final tokenSaved = await saveToken(token);
      final userDataSaved = await saveUserData(userData);
      
      if (userData['id'] != null) {
        final userIdSaved = await saveUserId(userData['id']);
        return tokenSaved && userDataSaved && userIdSaved;
      }
      
      return tokenSaved && userDataSaved;
    } catch (e) {
      debugPrint('Error saving auth data: $e');
      return false;
    }
  }
}
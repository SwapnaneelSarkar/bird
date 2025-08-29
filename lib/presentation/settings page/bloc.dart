import 'dart:convert';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/api_constant.dart';

import 'package:http/http.dart' as http;

import '../../service/profile_get_service.dart';
import '../../service/token_service.dart';
import '../../service/update_user_service.dart';
import '../../service/verification_service.dart';
import '../../service/firebase_services.dart';
import 'event.dart';
import 'state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final ProfileApiService _profileApiService = ProfileApiService();
  final UpdateUserService _updateUserService = UpdateUserService();
  final VerificationService _verificationService = VerificationService();

  SettingsBloc() : super(SettingsInitial()) {
    on<LoadUserSettings>(_onLoadUserSettings);
    on<UpdateUserSettings>(_onUpdateUserSettings);
    on<UpdateProfileImage>(_onUpdateProfileImage);
    on<DeleteAccount>(_onDeleteAccount);
    on<DeleteAccountWithOtp>(_onDeleteAccountWithOtp);
  }

  Future<void> _onLoadUserSettings(LoadUserSettings event, Emitter<SettingsState> emit) async {
    try {
      emit(SettingsLoading());
      
      // Get token and user ID
      final token = await TokenService.getToken();
      final userId = await TokenService.getUserId();
      
      if (token == null || userId == null) {
        emit(SettingsError(message: 'Please login again'));
        return;
      }
      
      debugPrint('SettingsBloc: Loading user settings for user ID: $userId');
      
      // Fetch user profile
      final result = await _profileApiService.getUserProfile(
        token: token,
        userId: userId,
      );
      
      if (result['success'] == true) {
        final userData = result['data'] as Map<String, dynamic>;
        debugPrint('SettingsBloc: Settings loaded successfully: ${userData['username']}');
        
        // Check for latitude and longitude
        if (userData['latitude'] != null) {
          debugPrint('SettingsBloc: User latitude: ${userData['latitude']}');
        }
        if (userData['longitude'] != null) {
          debugPrint('SettingsBloc: User longitude: ${userData['longitude']}');
        }
        
        emit(SettingsLoaded(userData: userData));
      } else {
        debugPrint('SettingsBloc: Failed to load settings: ${result['message']}');
        emit(SettingsError(message: result['message'] ?? 'Failed to load settings'));
      }
    } catch (e) {
      debugPrint('SettingsBloc: Error loading settings: $e');
      emit(SettingsError(message: 'Error loading settings'));
    }
  }

  Future<void> _onUpdateUserSettings(UpdateUserSettings event, Emitter<SettingsState> emit) async {
    try {
      // Store current state first to preserve it during updating
      final currentState = state;
      Map<String, dynamic> currentUserData = {};
      
      if (currentState is SettingsLoaded) {
        currentUserData = Map<String, dynamic>.from(currentState.userData);
        emit(SettingsLoaded(userData: currentUserData));
      }

      emit(SettingsUpdating());
      
      final token = await TokenService.getToken();
      final userId = await TokenService.getUserId();
      
      if (token == null || userId == null) {
        emit(SettingsError(message: 'Please login again'));
        return;
      }
      
      // Prepare address/coordinate values
      String newAddress = event.address ?? currentUserData['address']?.toString() ?? '';
      double latitude = event.latitude ?? (currentUserData['latitude'] != null ? double.tryParse(currentUserData['latitude'].toString()) ?? 0.0 : 0.0);
      double longitude = event.longitude ?? (currentUserData['longitude'] != null ? double.tryParse(currentUserData['longitude'].toString()) ?? 0.0 : 0.0);
      
      final result = await _updateUserService.updateUserProfileWithId(
        token: token,
        userId: userId,
        username: event.name ?? currentUserData['username']?.toString() ?? '',
        email: event.email ?? currentUserData['email']?.toString() ?? '',
        password: event.password,
        address: newAddress,
        latitude: latitude,
        longitude: longitude,
        imageFile: event.imageFile,
      );
      
      if (result['success'] == true) {
        debugPrint('SettingsBloc: Profile updated successfully');
        add(LoadUserSettings());
        emit(SettingsUpdateSuccess(message: 'Profile updated successfully'));
      } else {
        debugPrint('SettingsBloc: Profile update failed: ${result['message']}');
        // On failure, do NOT update address/lat/lng in the state. Show error message and keep previous values.
        if (currentState is SettingsLoaded) {
          emit(SettingsLoaded(userData: currentUserData));
        }
        emit(SettingsError(message: result['message'] ?? 'Failed to update profile'));
      }
    } catch (e) {
      debugPrint('SettingsBloc: Error updating settings: $e');
      final currentState = state;
      if (currentState is SettingsLoaded) {
        emit(SettingsLoaded(userData: currentState.userData));
      }
      emit(SettingsError(message: 'Error updating settings'));
    }
  }

  Future<void> _onUpdateProfileImage(UpdateProfileImage event, Emitter<SettingsState> emit) async {
    try {
      // Store the current state to maintain UI stability
      final currentState = state;
      if (currentState is SettingsLoaded) {
        // Create a copy of the current user data
        final Map<String, dynamic> updatedUserData = Map<String, dynamic>.from(currentState.userData);
        
        debugPrint('SettingsBloc: Profile image selected: ${event.imageFile.path}');
        
        // We don't update the userData yet as we're only selecting the image
        // This prevents UI from disappearing as we're maintaining the same state
        
        // Re-emit the current state to prevent UI elements from disappearing
        emit(SettingsLoaded(userData: updatedUserData));
        
        // Just show a notification that image has been selected
        emit(SettingsUpdateSuccess(message: 'Profile photo selected. Press Save to update your profile.'));
        
        // Re-emit the SettingsLoaded state to ensure UI is preserved
        emit(SettingsLoaded(userData: updatedUserData));
      } else {
        emit(SettingsError(message: 'Please reload settings before selecting a profile image'));
      }
    } catch (e) {
      debugPrint('SettingsBloc: Error selecting profile image: $e');
      emit(SettingsError(message: 'Error selecting profile image'));
    }
  }

  Future<void> _onDeleteAccount(DeleteAccount event, Emitter<SettingsState> emit) async {
    // Store current state to restore if needed
    final currentState = state;
    emit(SettingsDeleting());
    
    try {
      // Get token and user ID
      final token = await TokenService.getToken();
      final userId = await TokenService.getUserId();
      
      if (token == null || userId == null) {
        emit(SettingsError(message: 'Please login again'));
        // Restore previous state
        if (currentState is SettingsLoaded) {
          emit(currentState);
        }
        return;
      }
      
      debugPrint('SettingsBloc: Attempting to delete account for user ID: $userId');
      
      // Make API call to delete user using user_id instead of mobile
      final url = Uri.parse('${ApiConstants.baseUrl}/api/user/delete-user');
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'user_id': userId,
        }),
      );
      
      debugPrint('SettingsBloc: Delete account response: ${response.body}');
      
      final result = jsonDecode(response.body);
      
      if (response.statusCode == 200 && (result['status'] == true || result['success'] == true)) {
        // Clear FCM tokens before clearing other data
        debugPrint('SettingsBloc: Clearing FCM tokens on account deletion...');
        try {
          await NotificationService().clearFCMTokensOnLogout();
          debugPrint('SettingsBloc: FCM tokens cleared successfully');
        } catch (e) {
          debugPrint('SettingsBloc: Error clearing FCM tokens: $e');
          // Don't fail account deletion if FCM clearing fails
        }
        
        // Clear all saved data
        await TokenService.clearAll();
        
        debugPrint('SettingsBloc: Account deleted successfully');
        emit(SettingsAccountDeleted());
      } else {
        debugPrint('SettingsBloc: Failed to delete account: ${result['message']}');
        // Restore previous state
        if (currentState is SettingsLoaded) {
          emit(currentState);
        }
        emit(SettingsError(message: result['message'] ?? 'Failed to delete account'));
      }
    } catch (e) {
      debugPrint('SettingsBloc: Error during account deletion: $e');
      // Restore previous state
      if (currentState is SettingsLoaded) {
        emit(currentState);
      }
      emit(SettingsError(message: 'Account deletion failed'));
    }
  }

  Future<void> _onDeleteAccountWithOtp(DeleteAccountWithOtp event, Emitter<SettingsState> emit) async {
    // Store current state to restore if needed
    final currentState = state;
    emit(SettingsDeleting());
    
    try {
      debugPrint('SettingsBloc: 🗑️ Starting account deletion process...');
      
      // Get token and user ID
      final token = await TokenService.getToken();
      final userId = await TokenService.getUserId();
      
      debugPrint('SettingsBloc: 🗑️ Token: ${token != null ? 'Found' : 'Not found'}');
      debugPrint('SettingsBloc: 🗑️ User ID: $userId');
      
      if (token == null || userId == null) {
        debugPrint('SettingsBloc: 🗑️ ❌ Token or User ID is null');
        emit(SettingsError(message: 'Please login again'));
        // Restore previous state
        if (currentState is SettingsLoaded) {
          emit(currentState);
        }
        return;
      }
      
      debugPrint('SettingsBloc: 🗑️ Proceeding with account deletion after OTP verification');
      
      // OTP is already verified in the dialog, proceed directly with account deletion
      final url = Uri.parse('${ApiConstants.baseUrl}/api/user/delete-user');
      debugPrint('SettingsBloc: 🗑️ Delete URL: $url');
      
      final requestBody = jsonEncode({
        'user_id': userId,
      });
      debugPrint('SettingsBloc: 🗑️ Request body: $requestBody');
      
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      debugPrint('SettingsBloc: 🗑️ Request headers: $headers');
      
      debugPrint('SettingsBloc: 🗑️ Making DELETE request...');
      final response = await http.delete(
        url,
        headers: headers,
        body: requestBody,
      );
      
      debugPrint('SettingsBloc: 🗑️ Response status code: ${response.statusCode}');
      debugPrint('SettingsBloc: 🗑️ Response headers: ${response.headers}');
      debugPrint('SettingsBloc: 🗑️ Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('SettingsBloc: 🗑️ Parsed response: $result');
        
        if (result['status'] == true || result['success'] == true) {
          // Clear FCM tokens before clearing other data
          debugPrint('SettingsBloc: 🗑️ Clearing FCM tokens on account deletion...');
          try {
            await NotificationService().clearFCMTokensOnLogout();
            debugPrint('SettingsBloc: 🗑️ FCM tokens cleared successfully');
          } catch (e) {
            debugPrint('SettingsBloc: 🗑️ Error clearing FCM tokens: $e');
            // Don't fail account deletion if FCM clearing fails
          }
          
          // Clear all saved data
          debugPrint('SettingsBloc: 🗑️ Clearing all saved data...');
          await TokenService.clearAll();
          debugPrint('SettingsBloc: 🗑️ All data cleared successfully');
          
          debugPrint('SettingsBloc: 🗑️ ✅ Account deleted successfully');
          emit(SettingsAccountDeleted());
        } else {
          debugPrint('SettingsBloc: 🗑️ ❌ API returned success: false - ${result['message']}');
          // Restore previous state
          if (currentState is SettingsLoaded) {
            emit(currentState);
          }
          emit(SettingsError(message: result['message'] ?? 'Failed to delete account'));
        }
      } else {
        debugPrint('SettingsBloc: 🗑️ ❌ HTTP error: ${response.statusCode}');
        final result = jsonDecode(response.body);
        debugPrint('SettingsBloc: 🗑️ Error response: $result');
        // Restore previous state
        if (currentState is SettingsLoaded) {
          emit(currentState);
        }
        emit(SettingsError(message: result['message'] ?? 'Failed to delete account'));
      }
    } catch (e) {
      debugPrint('SettingsBloc: 🗑️ ❌ Exception during account deletion: $e');
      debugPrint('SettingsBloc: 🗑️ Exception type: ${e.runtimeType}');
      // Restore previous state
      if (currentState is SettingsLoaded) {
        emit(currentState);
      }
      emit(SettingsError(message: 'Account deletion failed: ${e.toString()}'));
    }
  }
}
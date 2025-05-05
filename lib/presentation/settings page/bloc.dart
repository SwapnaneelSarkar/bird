import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../service/profile_get_service.dart';
import '../../service/update_user_service.dart';
import '../../service/token_service.dart';
import 'event.dart';
import 'state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final ProfileApiService _profileApiService = ProfileApiService();
  final UpdateUserService _updateUserService = UpdateUserService();

  SettingsBloc() : super(SettingsInitial()) {
    on<LoadUserSettings>(_onLoadUserSettings);
    on<UpdateUserSettings>(_onUpdateUserSettings);
    on<UpdateProfileImage>(_onUpdateProfileImage);
    on<DeleteAccount>(_onDeleteAccount);
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
      
      debugPrint('Loading user settings for user ID: $userId');
      
      // Fetch user profile
      final result = await _profileApiService.getUserProfile(
        token: token,
        userId: userId,
      );
      
      if (result['success'] == true) {
        final userData = result['data'] as Map<String, dynamic>;
        debugPrint('Settings loaded successfully: ${userData['username']}');
        emit(SettingsLoaded(userData: userData));
      } else {
        debugPrint('Failed to load settings: ${result['message']}');
        emit(SettingsError(message: result['message'] ?? 'Failed to load settings'));
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
      emit(SettingsError(message: 'Error loading settings'));
    }
  }

  Future<void> _onUpdateUserSettings(UpdateUserSettings event, Emitter<SettingsState> emit) async {
    try {
      emit(SettingsUpdating());
      
      final token = await TokenService.getToken();
      
      if (token == null) {
        emit(SettingsError(message: 'Please login again'));
        return;
      }
      
      // Get current state to preserve other fields
      final currentState = state;
      Map<String, dynamic> currentUserData = {};
      
      if (currentState is SettingsLoaded) {
        currentUserData = currentState.userData;
      }
      
      // Update user profile
      final result = await _updateUserService.updateUserProfile(
        token: token,
        mobile: event.phone ?? currentUserData['mobile'] ?? '',
        username: event.name ?? currentUserData['username'] ?? '',
        email: event.email ?? currentUserData['email'] ?? '',
        password: event.password,
        address: event.address ?? currentUserData['address'] ?? '',
        latitude: currentUserData['latitude'] ?? 0.0,
        longitude: currentUserData['longitude'] ?? 0.0,
        imageFile: event.imageFile,
      );
      
      if (result['success'] == true) {
        // Fetch updated user data to ensure we have the latest
        add(LoadUserSettings());
        emit(SettingsUpdateSuccess(message: 'Profile updated successfully'));
      } else {
        emit(SettingsError(message: result['message']));
      }
    } catch (e) {
      debugPrint('Error updating settings: $e');
      emit(SettingsError(message: 'Error updating settings'));
    }
  }

  Future<void> _onUpdateProfileImage(UpdateProfileImage event, Emitter<SettingsState> emit) async {
    try {
      emit(SettingsUpdating());
      
      final token = await TokenService.getToken();
      final userId = await TokenService.getUserId();
      
      if (token == null || userId == null) {
        emit(SettingsError(message: 'Please login again'));
        return;
      }
      
      // Get current state to preserve other fields
      final currentState = state;
      Map<String, dynamic> currentUserData = {};
      
      if (currentState is SettingsLoaded) {
        currentUserData = currentState.userData;
      }
      
      // Update just the profile image
      final result = await _updateUserService.updateUserProfile(
        token: token,
        mobile: currentUserData['mobile'] ?? '',
        username: currentUserData['username'] ?? '',
        email: currentUserData['email'] ?? '',
        address: currentUserData['address'] ?? '',
        latitude: currentUserData['latitude'] ?? 0.0,
        longitude: currentUserData['longitude'] ?? 0.0,
        imageFile: event.imageFile,
      );
      
      if (result['success'] == true) {
        // Fetch updated user data to ensure we have the latest
        add(LoadUserSettings());
        emit(SettingsUpdateSuccess(message: 'Profile image updated successfully'));
      } else {
        emit(SettingsError(message: result['message']));
      }
    } catch (e) {
      debugPrint('Error updating profile image: $e');
      emit(SettingsError(message: 'Error updating profile image'));
    }
  }

  Future<void> _onDeleteAccount(DeleteAccount event, Emitter<SettingsState> emit) async {
    // This would typically call a delete account API
    // For now, we'll just log the user out as a placeholder
    emit(SettingsDeleting());
    
    try {
      // Clear all saved data
      await TokenService.clearAll();
      
      await Future.delayed(const Duration(seconds: 1));
      emit(SettingsAccountDeleted());
    } catch (e) {
      debugPrint('Error during account deletion: $e');
      emit(SettingsError(message: 'Account deletion failed'));
    }
  }
}
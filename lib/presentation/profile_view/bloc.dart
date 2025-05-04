import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../service/profile_get_service.dart';
import '../../service/profile_service.dart';
import '../../service/token_service.dart';
import 'event.dart';
import 'state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileApiService _profileApiService = ProfileApiService();

  ProfileBloc() : super(ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onLoadProfile(LoadProfile event, Emitter<ProfileState> emit) async {
    try {
      emit(ProfileLoading());
      
      // Get token and user ID
      final token = await TokenService.getToken();
      final userId = await TokenService.getUserId();
      
      if (token == null || userId == null) {
        emit(ProfileError(message: 'Please login again'));
        return;
      }
      
      debugPrint('Loading profile for user ID: $userId');
      
      // Fetch user profile
      final result = await _profileApiService.getUserProfile(
        token: token,
        userId: userId,
      );
      
      if (result['success'] == true) {
        final userData = result['data'] as Map<String, dynamic>;
        debugPrint('Profile loaded successfully: ${userData['username']}');
        emit(ProfileLoaded(userData: userData));
      } else {
        debugPrint('Failed to load profile: ${result['message']}');
        emit(ProfileError(message: result['message'] ?? 'Failed to load profile'));
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      emit(ProfileError(message: 'Error loading profile'));
    }
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<ProfileState> emit) async {
    emit(ProfileLoggingOut());
    
    try {
      // Clear all saved data
      await TokenService.clearAll();
      await ProfileService.clearProfileData();
      
      await Future.delayed(const Duration(seconds: 1));
      emit(ProfileLoggedOut());
    } catch (e) {
      debugPrint('Error during logout: $e');
      emit(ProfileError(message: 'Logout failed'));
    }
  }
}
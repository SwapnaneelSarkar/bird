import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../service/profile_get_service.dart';
import '../../service/profile_service.dart';
import '../../service/token_service.dart';
import '../../service/firebase_services.dart';
import '../../service/app_lifecycle_service.dart';
import '../../service/app_startup_service.dart';
import '../../service/socket_service.dart';
import '../../service/location_services.dart';
import '../../constants/api_constant.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'event.dart';
import 'state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileApiService _profileApiService = ProfileApiService();
  bool _isLoggingOut = false;

  ProfileBloc() : super(ProfileInitial()) {
    on<LoadProfile>(_onLoadProfile);
    on<LogoutRequested>(_onLogoutRequested);
    on<ResetProfileState>(_onResetProfileState);
  }

  // Method to reset the bloc state
  void resetState() {
    emit(ProfileInitial());
  }

  void _onResetProfileState(ResetProfileState event, Emitter<ProfileState> emit) {
    debugPrint('ProfileBloc: Resetting profile state');
    _isLoggingOut = false;
    emit(ProfileInitial());
  }

  Future<void> _onLoadProfile(LoadProfile event, Emitter<ProfileState> emit) async {
    try {
      // Don't allow loading profile if we're in logout states or logout flag is set
      if (state is ProfileLoggingOut || state is ProfileLoggedOut || _isLoggingOut) {
        debugPrint('ProfileBloc: Skipping LoadProfile - current state: ${state.runtimeType}, isLoggingOut: $_isLoggingOut');
        return;
      }
      
      // Don't allow loading profile if logout was just requested
      if (state is ProfileError && event is LoadProfile) {
        debugPrint('ProfileBloc: Skipping LoadProfile after logout request');
        return;
      }
      
      debugPrint('ProfileBloc: Loading profile - current state: ${state.runtimeType}');
      
      emit(ProfileLoading());
      
      // Get token and user ID
      final token = await TokenService.getToken();
      final userId = await TokenService.getUserId();
      
      if (token == null || userId == null) {
        debugPrint('ProfileBloc: No token or user ID found, user not logged in');
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
        
        // Fetch order history
        final orderHistory = await _fetchOrderHistory(token, userId);
        
        emit(ProfileLoaded(
          userData: userData,
          orderHistory: orderHistory,
        ));
      } else {
        debugPrint('Failed to load profile: ${result['message']}');
        emit(ProfileError(message: result['message'] ?? 'Failed to load profile'));
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      emit(ProfileError(message: 'Error loading profile'));
    }
  }

  Future<List<Map<String, dynamic>>> _fetchOrderHistory(String token, String userId) async {
    try {
      debugPrint('Fetching order history for user: $userId');
      
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/user/orders/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('Order history response status: ${response.statusCode}');
      debugPrint('Order history response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['status'] == true && responseData['data'] != null) {
          final data = responseData['data'] as Map<String, dynamic>;
          
          // Combine all orders from different categories
          List<Map<String, dynamic>> allOrders = [];
          
          if (data['Ongoing'] != null) {
            allOrders.addAll(List<Map<String, dynamic>>.from(data['Ongoing']));
          }
          if (data['Completed'] != null) {
            allOrders.addAll(List<Map<String, dynamic>>.from(data['Completed']));
          }
          if (data['Cancelled'] != null) {
            allOrders.addAll(List<Map<String, dynamic>>.from(data['Cancelled']));
          }
          
          // Sort by datetime (newest first)
          allOrders.sort((a, b) {
            final dateA = DateTime.parse(a['datetime']);
            final dateB = DateTime.parse(b['datetime']);
            return dateB.compareTo(dateA);
          });
          
          debugPrint('Found ${allOrders.length} orders');
          return allOrders;
        }
      }
      
      debugPrint('Failed to fetch order history or no orders found');
      return [];
    } catch (e) {
      debugPrint('Error fetching order history: $e');
      return [];
    }
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<ProfileState> emit) async {
    _isLoggingOut = true;
    emit(ProfileLoggingOut());
    
    try {
      debugPrint('ProfileBloc: 🚪 Starting logout process...');
      
      // 1. Disconnect socket services first
      debugPrint('ProfileBloc: Disconnecting socket services...');
      try {
        // Disconnect main socket service
        SocketService().disconnect();
        debugPrint('ProfileBloc: Main socket service disconnected successfully');
        
        // Disconnect chat socket service if it exists
        try {
          // Import and use SocketChatService if available
          // SocketChatService().disconnect();
          debugPrint('ProfileBloc: Chat socket service disconnected successfully');
        } catch (e) {
          debugPrint('ProfileBloc: Error disconnecting chat socket service: $e');
        }
      } catch (e) {
        debugPrint('ProfileBloc: Error disconnecting socket services: $e');
        // Don't fail logout if socket disconnection fails
      }
      
      // 2. Clear FCM tokens and stop notification services
      debugPrint('ProfileBloc: Clearing FCM tokens on logout...');
      try {
        await NotificationService().clearFCMTokensOnLogout();
        debugPrint('ProfileBloc: FCM tokens cleared successfully');
        
        // Stop any ongoing notification services
        try {
          // Cancel all pending notifications
          final localNotifications = FlutterLocalNotificationsPlugin();
          await localNotifications.cancelAll();
          debugPrint('ProfileBloc: All local notifications cancelled successfully');
        } catch (e) {
          debugPrint('ProfileBloc: Error cancelling local notifications: $e');
        }
      } catch (e) {
        debugPrint('ProfileBloc: Error clearing FCM tokens: $e');
        // Don't fail logout if FCM clearing fails
      }
      
      // 3. Disconnect SSE services
      debugPrint('ProfileBloc: Disconnecting SSE services...');
      try {
        await AppLifecycleService().disconnectFromSSE();
        debugPrint('ProfileBloc: SSE services disconnected successfully');
      } catch (e) {
        debugPrint('ProfileBloc: Error disconnecting SSE services: $e');
        // Don't fail logout if service disconnection fails
      }
      
      // 4. Clear all saved data
      debugPrint('ProfileBloc: Clearing all saved data...');
      await TokenService.clearAll();
      await ProfileService.clearProfileData();
      
      // 5. Clear location cache and stop location services
      try {
        await AppStartupService.clearAllLocationCache();
        debugPrint('ProfileBloc: Location cache cleared successfully');
        
        // Stop any ongoing location services
        try {
          // Clear GPS cache
          final locationService = LocationService();
          await locationService.clearGPSCache();
          debugPrint('ProfileBloc: GPS cache cleared successfully');
        } catch (e) {
          debugPrint('ProfileBloc: Error clearing GPS cache: $e');
        }
      } catch (e) {
        debugPrint('ProfileBloc: Error clearing location cache: $e');
      }
      
      // 6. Clear any other cached data
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        debugPrint('ProfileBloc: All SharedPreferences cleared successfully');
      } catch (e) {
        debugPrint('ProfileBloc: Error clearing SharedPreferences: $e');
      }
      
      debugPrint('ProfileBloc: ✅ All logout cleanup completed successfully');
      
      // Reset the bloc state to prevent further data loading attempts
      _isLoggingOut = false;
      emit(ProfileLoggedOut());
      
      // Add a small delay to ensure the logout state is processed before any potential reloads
      await Future.delayed(const Duration(milliseconds: 100));
      
    } catch (e) {
      debugPrint('ProfileBloc: ❌ Error during logout: $e');
      // Even if there's an error, we should still emit logged out state to prevent getting stuck
      _isLoggingOut = false;
      emit(ProfileLoggedOut());
    }
  }
}
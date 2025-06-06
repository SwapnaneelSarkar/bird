import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../service/profile_get_service.dart';
import '../../service/profile_service.dart';
import '../../service/token_service.dart';
import '../../constants/api_constant.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
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
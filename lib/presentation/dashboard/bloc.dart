// lib/presentation/category_homepage/bloc.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import '../../constants/api_constant.dart';
import '../../service/token_service.dart';
import 'event.dart';
import 'state.dart';

class CategoryHomepageBloc extends Bloc<CategoryHomepageEvent, CategoryHomepageState> {
  CategoryHomepageBloc() : super(const CategoryHomepageInitial()) {
    on<LoadCategoryHomepage>(_onLoadCategoryHomepage);
    on<RefreshCategoryHomepage>(_onRefreshCategoryHomepage);
    on<SelectCategory>(_onSelectCategory);
    on<NavigateToProfile>(_onNavigateToProfile);
    on<NavigateToOrderHistory>(_onNavigateToOrderHistory);
    on<NavigateToSettings>(_onNavigateToSettings);
  }

  Future<void> _onLoadCategoryHomepage(
    LoadCategoryHomepage event,
    Emitter<CategoryHomepageState> emit,
  ) async {
    emit(const CategoryHomepageLoading());
    
    try {
      debugPrint('CategoryHomepageBloc: Loading category homepage data...');
      
      // Get authentication data
      final token = await TokenService.getToken();
      final userId = await TokenService.getUserId();
      final userData = await TokenService.getUserData();
      
      if (token == null || userId == null) {
        emit(const CategoryHomepageError(message: 'Please login again'));
        return;
      }

      // Load data concurrently
      final results = await Future.wait([
        _fetchSupercategories(token),
        _fetchRecentOrders(token, userId),
      ]);

      final categories = results[0] as List<CategoryModel>;
      final recentOrders = results[1] as List<RecentOrderModel>;

      // Extract user info
      final userName = userData?['name'] ?? userData?['full_name'] ?? 'User';
      final userAddress = userData?['address'] ?? 'Add delivery address';

      emit(CategoryHomepageLoaded(
        categories: categories,
        recentOrders: recentOrders,
        userData: userData,
        userName: userName,
        userAddress: userAddress,
      ));

      debugPrint('CategoryHomepageBloc: Homepage loaded with ${categories.length} categories and ${recentOrders.length} recent orders');
    } catch (e) {
      debugPrint('CategoryHomepageBloc: Error loading homepage: $e');
      emit(CategoryHomepageError(message: 'Failed to load data. Please try again.'));
    }
  }

  Future<void> _onRefreshCategoryHomepage(
    RefreshCategoryHomepage event,
    Emitter<CategoryHomepageState> emit,
  ) async {
    add(const LoadCategoryHomepage());
  }

  Future<void> _onSelectCategory(
    SelectCategory event,
    Emitter<CategoryHomepageState> emit,
  ) async {
    debugPrint('CategoryHomepageBloc: Category selected - ${event.categoryName} (${event.categoryId})');
    emit(CategorySelected(
      categoryId: event.categoryId,
      categoryName: event.categoryName,
    ));
  }

  Future<void> _onNavigateToProfile(
    NavigateToProfile event,
    Emitter<CategoryHomepageState> emit,
  ) async {
    debugPrint('CategoryHomepageBloc: Navigate to profile');
    // Navigation will be handled in the UI layer
  }

  Future<void> _onNavigateToOrderHistory(
    NavigateToOrderHistory event,
    Emitter<CategoryHomepageState> emit,
  ) async {
    debugPrint('CategoryHomepageBloc: Navigate to order history');
    // Navigation will be handled in the UI layer
  }

  Future<void> _onNavigateToSettings(
    NavigateToSettings event,
    Emitter<CategoryHomepageState> emit,
  ) async {
    debugPrint('CategoryHomepageBloc: Navigate to settings');
    // Navigation will be handled in the UI layer
  }

  // API Methods
  Future<List<CategoryModel>> _fetchSupercategories(String token) async {
    try {
      debugPrint('CategoryHomepageBloc: Fetching supercategories...');
      
      final url = Uri.parse('${ApiConstants.baseUrl}/api/partner/supercategories');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('CategoryHomepageBloc: Supercategories response status: ${response.statusCode}');
      debugPrint('CategoryHomepageBloc: Supercategories response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['status'] == 'SUCCESS' && responseData['data'] != null) {
          final List<dynamic> categoriesData = responseData['data'];
          
          return categoriesData.map((json) => CategoryModel.fromJson(json)).toList();
        } else {
          debugPrint('CategoryHomepageBloc: API returned error: ${responseData['message'] ?? 'Unknown error'}');
          return [];
        }
      } else {
        debugPrint('CategoryHomepageBloc: HTTP error ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('CategoryHomepageBloc: Error fetching supercategories: $e');
      return [];
    }
  }

  Future<List<RecentOrderModel>> _fetchRecentOrders(String token, String userId) async {
    try {
      debugPrint('CategoryHomepageBloc: Fetching recent orders for user: $userId');
      
      final url = Uri.parse('${ApiConstants.baseUrl}/api/user/orders/recent?count=10&user_id=$userId');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('CategoryHomepageBloc: Recent orders response status: ${response.statusCode}');
      debugPrint('CategoryHomepageBloc: Recent orders response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData['status'] == true && responseData['data'] != null) {
          final List<dynamic> ordersData = responseData['data'];
          
          return ordersData.map((json) => RecentOrderModel.fromJson(json)).toList();
        } else {
          debugPrint('CategoryHomepageBloc: API returned error: ${responseData['message'] ?? 'Unknown error'}');
          return [];
        }
      } else {
        debugPrint('CategoryHomepageBloc: HTTP error ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('CategoryHomepageBloc: Error fetching recent orders: $e');
      return [];
    }
  }
}
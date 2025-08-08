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

      // Load categories
      final categories = await _fetchSupercategories(token);

      // Extract user info
      final userName = userData?['username'] ?? userData?['name'] ?? userData?['full_name'] ?? 'User';
      final userAddress = userData?['address'] ?? 'Add delivery address';

      emit(CategoryHomepageLoaded(
        categories: categories,
        userData: userData,
        userName: userName,
        userAddress: userAddress,
      ));

      debugPrint('CategoryHomepageBloc: Homepage loaded with ${categories.length} categories');
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
          debugPrint('CategoryHomepageBloc: Found ${categoriesData.length} categories in response');
          
          final List<CategoryModel> categories = [];
          for (int i = 0; i < categoriesData.length; i++) {
            final categoryJson = categoriesData[i];
            try {
              final category = CategoryModel.fromJson(categoryJson);
              debugPrint('CategoryHomepageBloc: Created category: ${category.name} with image: ${category.image}');
              categories.add(category);
            } catch (e) {
              debugPrint('CategoryHomepageBloc: Error parsing category $i: $e');
            }
          }
          
          return categories;
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


}
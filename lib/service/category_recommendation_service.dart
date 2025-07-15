import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constant.dart';
import '../service/token_service.dart';
import '../service/order_history_service.dart';

class CategoryRecommendationService {
  // Fetch categories with user recommendations
  static Future<List<Map<String, dynamic>>> fetchRecommendedCategories() async {
    try {
      debugPrint('CategoryRecommendationService: Fetching recommended categories...');
      
      final token = await TokenService.getToken();
      final userId = await TokenService.getUserId();
      
      if (token == null || userId == null) {
        debugPrint('CategoryRecommendationService: No token or user ID available');
        return _getStaticCategories();
      }

      // First, fetch user's order history to analyze preferences
      final orderHistoryResult = await OrderHistoryService.fetchOrderHistory();
      Map<String, int> categoryPreferences = {};
      
      if (orderHistoryResult['success'] == true && orderHistoryResult['data'] != null) {
        final orders = orderHistoryResult['data'] as List<Map<String, dynamic>>;
        categoryPreferences = _analyzeUserPreferences(orders);
        debugPrint('CategoryRecommendationService: Analyzed preferences: $categoryPreferences');
      }

      // Fetch categories from API with user_id parameter
      final url = Uri.parse('${ApiConstants.baseUrl}/api/partner/categories?user_id=$userId');
      
      debugPrint('CategoryRecommendationService: Fetching categories from: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('CategoryRecommendationService: Response status: ${response.statusCode}');
      debugPrint('CategoryRecommendationService: Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'SUCCESS' && data['data'] != null) {
          final categoriesData = data['data'] as List<dynamic>;
          debugPrint('CategoryRecommendationService: Fetched ${categoriesData.length} categories from API');
          
          // Convert to our format and apply recommendations
          final List<Map<String, dynamic>> formattedCategories = [];
          
          for (var categoryJson in categoriesData) {
            try {
              final category = _formatCategoryFromApi(categoryJson);
              if (category != null) {
                formattedCategories.add(category);
              }
            } catch (e) {
              debugPrint('CategoryRecommendationService: Error formatting category: $e');
            }
          }
          
          // Apply recommendation algorithm
          final recommendedCategories = _applyRecommendations(formattedCategories, categoryPreferences);
          
          debugPrint('CategoryRecommendationService: Returning ${recommendedCategories.length} recommended categories');
          return recommendedCategories;
        } else {
          debugPrint('CategoryRecommendationService: API returned error status: ${data['status']}');
        }
      } else {
        debugPrint('CategoryRecommendationService: HTTP error ${response.statusCode}');
      }
      
      // Fallback to static categories
      debugPrint('CategoryRecommendationService: Using static categories as fallback');
      return _getStaticCategories();
      
    } catch (e) {
      debugPrint('CategoryRecommendationService: Error fetching recommended categories: $e');
      return _getStaticCategories();
    }
  }

  // Analyze user preferences from order history
  static Map<String, int> _analyzeUserPreferences(List<Map<String, dynamic>> orders) {
    Map<String, int> preferences = {};
    
    for (var order in orders) {
      // Extract items from order
      final items = order['items'] as List<dynamic>? ?? [];
      
      for (var item in items) {
        // Try to extract category information from item
        String? categoryName = _extractCategoryFromItem(item);
        
        if (categoryName != null) {
          preferences[categoryName] = (preferences[categoryName] ?? 0) + 1;
        }
      }
    }
    
    debugPrint('CategoryRecommendationService: User preferences: $preferences');
    return preferences;
  }

  // Extract category from order item
  static String? _extractCategoryFromItem(Map<String, dynamic> item) {
    // Try different possible field names for category
    final categoryName = item['category']?.toString()?.toLowerCase() ??
                        item['category_name']?.toString()?.toLowerCase() ??
                        item['menu_category']?.toString()?.toLowerCase() ??
                        item['item_category']?.toString()?.toLowerCase();
    
    if (categoryName != null && categoryName.isNotEmpty) {
      return categoryName;
    }
    
    // If no direct category, try to infer from item name
    final itemName = item['item_name']?.toString()?.toLowerCase() ??
                    item['name']?.toString()?.toLowerCase() ??
                    '';
    
    return _inferCategoryFromItemName(itemName);
  }

  // Infer category from item name using simple keyword matching
  static String? _inferCategoryFromItemName(String itemName) {
    if (itemName.isEmpty) return null;
    
    // Define category keywords
    final categoryKeywords = {
      'pizza': ['pizza', 'margherita', 'pepperoni', 'cheese'],
      'burger': ['burger', 'sandwich', 'patty'],
      'chinese': ['chinese', 'noodle', 'fried rice', 'manchurian', 'szechuan'],
      'indian': ['biryani', 'curry', 'dal', 'roti', 'naan', 'tandoori'],
      'dessert': ['ice cream', 'cake', 'pastry', 'sweet', 'dessert'],
      'drinks': ['coffee', 'tea', 'juice', 'smoothie', 'milkshake', 'beverage'],
      'breakfast': ['breakfast', 'omelette', 'pancake', 'toast'],
      'seafood': ['fish', 'shrimp', 'crab', 'lobster', 'seafood'],
      'bakery': ['bread', 'bun', 'croissant', 'muffin', 'bakery'],
      'salad': ['salad', 'vegetable', 'healthy'],
      'soup': ['soup', 'broth'],
      'snacks': ['snack', 'chips', 'popcorn', 'nuts'],
    };
    
    for (var entry in categoryKeywords.entries) {
      for (var keyword in entry.value) {
        if (itemName.contains(keyword)) {
          return entry.key;
        }
      }
    }
    
    return null;
  }

  // Apply recommendation algorithm to sort categories
  static List<Map<String, dynamic>> _applyRecommendations(
    List<Map<String, dynamic>> categories,
    Map<String, int> userPreferences,
  ) {
    // Create a copy to avoid modifying the original list
    final List<Map<String, dynamic>> recommendedCategories = List.from(categories);
    
    // Calculate recommendation scores
    for (var category in recommendedCategories) {
      final categoryName = category['name']?.toString()?.toLowerCase() ?? '';
      final displayOrder = category['display_order'] ?? 999;
      
      // Base score from display_order (lower is better)
      double score = 1000.0 - (displayOrder is int ? displayOrder.toDouble() : displayOrder);
      
      // Boost score based on user preferences
      for (var preference in userPreferences.entries) {
        final preferenceCategory = preference.key;
        final preferenceCount = preference.value;
        
        // Check if this category matches user preference
        if (_categoriesMatch(categoryName, preferenceCategory)) {
          // Boost score based on how often user ordered this category
          score += preferenceCount * 100;
          debugPrint('CategoryRecommendationService: Boosting $categoryName by ${preferenceCount * 100} points');
        }
      }
      
      category['_recommendation_score'] = score;
    }
    
    // Sort by recommendation score (highest first)
    recommendedCategories.sort((a, b) {
      final scoreA = a['_recommendation_score'] ?? 0.0;
      final scoreB = b['_recommendation_score'] ?? 0.0;
      return scoreB.compareTo(scoreA);
    });
    
    // Remove the temporary score field
    for (var category in recommendedCategories) {
      category.remove('_recommendation_score');
    }
    
    debugPrint('CategoryRecommendationService: Categories sorted by recommendations');
    return recommendedCategories;
  }

  // Check if two category names match (with fuzzy matching)
  static bool _categoriesMatch(String category1, String category2) {
    if (category1 == category2) return true;
    
    // Check if one contains the other
    if (category1.contains(category2) || category2.contains(category1)) return true;
    
    // Check for common variations
    final variations = {
      'pizza': ['pizza'],
      'burger': ['burger', 'sandwich'],
      'chinese': ['chinese', 'chinese food'],
      'indian': ['indian', 'north indian', 'south indian'],
      'dessert': ['dessert', 'desserts'],
      'drinks': ['drinks', 'beverages', 'beverage'],
      'breakfast': ['breakfast'],
      'seafood': ['seafood', 'sea food'],
      'bakery': ['bakery', 'bakery items'],
      'salad': ['salad', 'salads'],
      'soup': ['soup', 'soups'],
      'snacks': ['snacks', 'snack'],
    };
    
    for (var entry in variations.entries) {
      if (entry.value.contains(category1) && entry.value.contains(category2)) {
        return true;
      }
    }
    
    return false;
  }

  // Format category data from API response
  static Map<String, dynamic>? _formatCategoryFromApi(dynamic categoryJson) {
    try {
      if (categoryJson is! Map<String, dynamic>) return null;
      
      final Map<String, dynamic> category = categoryJson;
      
      // Extract category name
      final String? name = category['name']?.toString();
      if (name == null || name.isEmpty) return null;
      
      // Map category names to appropriate icons and colors
      final iconData = _getCategoryIconAndColor(name.toLowerCase());
      
      return {
        'name': name,
        'icon': iconData['icon'],
        'color': iconData['color'],
        'id': category['id']?.toString(),
        'image': category['image']?.toString(),
        'description': category['description']?.toString(),
        'display_order': category['display_order'] ?? 999,
        'active': category['active'] ?? 1,
      };
    } catch (e) {
      debugPrint('CategoryRecommendationService: Error formatting category: $e');
      return null;
    }
  }

  // Helper method to get icon and color based on category name
  static Map<String, String> _getCategoryIconAndColor(String categoryName) {
    if (categoryName.contains('pizza')) {
      return {'icon': 'local_pizza', 'color': 'red'};
    } else if (categoryName.contains('burger') || categoryName.contains('sandwich')) {
      return {'icon': 'lunch_dining', 'color': 'amber'};
    } else if (categoryName.contains('sushi') || categoryName.contains('japanese')) {
      return {'icon': 'set_meal', 'color': 'blue'};
    } else if (categoryName.contains('dessert') || categoryName.contains('sweet') || categoryName.contains('ice')) {
      return {'icon': 'icecream', 'color': 'pink'};
    } else if (categoryName.contains('drink') || categoryName.contains('beverage') || categoryName.contains('juice')) {
      return {'icon': 'local_drink', 'color': 'teal'};
    } else if (categoryName.contains('chinese') || categoryName.contains('noodle') || categoryName.contains('ramen')) {
      return {'icon': 'ramen_dining', 'color': 'orange'};
    } else if (categoryName.contains('breakfast') || categoryName.contains('bread')) {
      return {'icon': 'free_breakfast', 'color': 'brown'};
    } else if (categoryName.contains('veg') || categoryName.contains('salad')) {
      return {'icon': 'spa', 'color': 'green'};
    } else if (categoryName.contains('biryani') || categoryName.contains('rice') || categoryName.contains('indian')) {
      return {'icon': 'restaurant', 'color': 'deepOrange'};
    } else if (categoryName.contains('chicken') || categoryName.contains('meat')) {
      return {'icon': 'restaurant_menu', 'color': 'red'};
    } else if (categoryName.contains('seafood') || categoryName.contains('fish')) {
      return {'icon': 'set_meal', 'color': 'blue'};
    } else if (categoryName.contains('bakery')) {
      return {'icon': 'bakery_dining', 'color': 'brown'};
    } else if (categoryName.contains('soup')) {
      return {'icon': 'soup_kitchen', 'color': 'orange'};
    } else if (categoryName.contains('snack')) {
      return {'icon': 'fastfood', 'color': 'amber'};
    } else {
      return {'icon': 'restaurant', 'color': 'orange'};
    }
  }

  // Static categories as fallback
  static List<Map<String, dynamic>> _getStaticCategories() {
    debugPrint('CategoryRecommendationService: Using static categories as fallback');
    return [
      {'name': 'Pizza', 'icon': 'local_pizza', 'color': 'red', 'display_order': 1},
      {'name': 'Burger', 'icon': 'lunch_dining', 'color': 'amber', 'display_order': 2},
      {'name': 'Sushi', 'icon': 'set_meal', 'color': 'blue', 'display_order': 3},
      {'name': 'Dessert', 'icon': 'icecream', 'color': 'pink', 'display_order': 4},
      {'name': 'Drinks', 'icon': 'local_drink', 'color': 'teal', 'display_order': 5},
    ];
  }
} 
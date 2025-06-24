// models/menu_item.dart
import 'dart:convert';

class MenuItem {
  final String menuId;
  final String name;
  final double price;
  final bool available;
  final String? imageUrl;
  final String? description;
  final List<String> categories;
  final bool isVeg;
  final bool isTaxIncluded;
  final bool isCancellable;
  final List<String> tags;
  
  MenuItem({
    required this.menuId,
    required this.name,
    required this.price,
    required this.available,
    this.imageUrl,
    this.description,
    required this.categories,
    required this.isVeg,
    required this.isTaxIncluded,
    required this.isCancellable,
    required this.tags,
  });
  
  factory MenuItem.fromJson(Map<String, dynamic> json) {
    // Parse price (handling string or numeric values)
    double parsedPrice = 0.0;
    if (json['price'] != null) {
      if (json['price'] is String) {
        parsedPrice = double.tryParse(json['price'].toString()) ?? 0.0;
      } else {
        parsedPrice = (json['price'] as num).toDouble();
      }
    }
    
    // Parse categories from different possible formats
    List<String> parsedCategories = [];
    if (json['category'] != null) {
      if (json['category'] is List) {
        // If it's already a List, convert each item to String
        parsedCategories = List<String>.from(json['category'].map((e) => e.toString()));
      } else if (json['category'] is String) {
        // If it's a String, try to parse as JSON array first, then as comma-separated
        String categoryStr = json['category'].toString().trim();
        if (categoryStr.startsWith('[') && categoryStr.endsWith(']')) {
          try {
            // Try to parse as JSON array
            final parsed = jsonDecode(categoryStr);
            if (parsed is List) {
              parsedCategories = parsed.map((e) => e.toString()).toList();
            }
          } catch (e) {
            // If JSON parsing fails, fall back to string splitting
            categoryStr = categoryStr.substring(1, categoryStr.length - 1);
            parsedCategories = categoryStr.split(',').map((cat) => cat.trim().replaceAll('"', '')).where((cat) => cat.isNotEmpty).toList();
          }
        } else {
          // Single category as string
          parsedCategories = [categoryStr];
        }
      }
    }
    
    // Parse tags from string representation
    List<String> parsedTags = [];
    if (json['tags'] != null) {
      String tagsStr = json['tags'].toString();
      // Handle JSON string format like "{\"shahi\", \"paneer\"}"
      tagsStr = tagsStr.replaceAll('\\', '')
                       .replaceAll('"{', '{')
                       .replaceAll('}"', '}')
                       .replaceAll('"', '')
                       .replaceAll('{', '')
                       .replaceAll('}', '');
      parsedTags = tagsStr.split(',').map((tag) => tag.trim()).toList();
    }
    
    return MenuItem(
      menuId: json['menu_id'] ?? '',
      name: json['name'] ?? '',
      price: parsedPrice,
      available: json['available'] ?? true,
      imageUrl: json['image_url'],
      description: json['description'] ?? '',
      categories: parsedCategories,
      isVeg: json['isVeg'] ?? false,
      isTaxIncluded: json['isTaxIncluded'] ?? true,
      isCancellable: json['isCancellable'] ?? true,
      tags: parsedTags,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': menuId,
      'name': name,
      'price': price,
      'description': description,
      'imageUrl': imageUrl,
      'isVeg': isVeg,
      'category': categories,
      // We don't include default values anymore per request
    };
  }
}
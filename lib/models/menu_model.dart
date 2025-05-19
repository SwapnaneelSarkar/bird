// models/menu_item.dart
class MenuItem {
  final String menuId;
  final String name;
  final double price;
  final bool available;
  final String? imageUrl;
  final String? description;
  final String category;
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
    required this.category,
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
      category: json['category'] ?? '',
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
      'category': category,
      // We don't include default values anymore per request
    };
  }
}
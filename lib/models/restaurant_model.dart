class Restaurant {
  final String id;
  final String name;
  final String imageUrl;
  final String cuisine;
  final double rating;
  final String price;
  final String deliveryTime;
  final String address;
  final double avgCostPerPerson;
  final double distance;
  final bool isVeg;
  final List<MenuItem> menu;
  final String? legalName;
  final String? gstNumber;
  final String? fssaiLicenseNumber;
  final bool? openNow;
  final String? closesAt;
  
  Restaurant({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.cuisine,
    required this.rating,
    required this.price,
    required this.deliveryTime,
    required this.address,
    required this.avgCostPerPerson,
    required this.distance,
    required this.isVeg,
    required this.menu,
    this.legalName,
    this.gstNumber,
    this.fssaiLicenseNumber,
    this.openNow,
    this.closesAt,
  });
  
  factory Restaurant.fromJson(Map<String, dynamic> json) {
    // Parse menu items if available
    List<MenuItem> menuItems = [];
    if (json['menu'] != null) {
      menuItems = (json['menu'] as List)
          .map((item) => MenuItem.fromJson(item))
          .toList();
    }
    
    return Restaurant(
      id: json['id'],
      name: json['name'],
      imageUrl: json['imageUrl'],
      cuisine: json['cuisine'],
      rating: json['rating'] is int ? (json['rating'] as int).toDouble() : json['rating'],
      price: json['price'],
      deliveryTime: json['deliveryTime'],
      address: json['address'],
      avgCostPerPerson: json['avgCostPerPerson'] is int ? 
          (json['avgCostPerPerson'] as int).toDouble() : 
          json['avgCostPerPerson'],
      distance: json['distance'] is int ? 
          (json['distance'] as int).toDouble() : 
          json['distance'],
      isVeg: json['isVeg'],
      menu: menuItems,
      legalName: json['legalName'],
      gstNumber: json['gstNumber'],
      fssaiLicenseNumber: json['fssaiLicenseNumber'],
      openNow: json['openNow'],
      closesAt: json['closesAt'],
    );
  }
}

class MenuItem {
  final String id;
  final String name;
  final double price;
  final String description;
  final String imageUrl;
  final bool isVeg;
  final String category;
  final String cookTime;
  final bool isPopular;
  
  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.imageUrl,
    required this.isVeg,
    required this.category,
    required this.cookTime,
    required this.isPopular,
  });
  
  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'],
      name: json['name'],
      price: json['price'] is int ? 
          (json['price'] as int).toDouble() : 
          json['price'],
      description: json['description'],
      imageUrl: json['imageUrl'],
      isVeg: json['isVeg'],
      category: json['category'],
      cookTime: json['cookTime'],
      isPopular: json['isPopular'],
    );
  }
}
// lib/models/restaurant_model.dart
class Restaurant {
  final String partnerId;
  final String name;
  final String category;
  final double? rating;
  final String vegNonveg;
  final String? image;
  final double latitude;
  final double longitude;
  
  // Additional display fields
  final String cuisine;
  final String price;
  final String deliveryTime;

  Restaurant({
    required this.partnerId,
    required this.name,
    required this.category,
    this.rating,
    required this.vegNonveg,
    this.image,
    required this.latitude,
    required this.longitude,
    this.cuisine = "Various",
    this.price = "₹150 for two",
    this.deliveryTime = "30-40 mins",
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      partnerId: json['partner_id'] ?? '',
      name: json['restaurant_name'] ?? '',
      category: json['category'] ?? '',
      rating: json['rating'] != null ? double.parse(json['rating'].toString()) : null,
      vegNonveg: json['veg_nonveg'] ?? '',
      image: json['image'],
      latitude: json['latitude'] != null ? double.parse(json['latitude'].toString()) : 0.0,
      longitude: json['longitude'] != null ? double.parse(json['longitude'].toString()) : 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': partnerId,
      'name': name,
      'imageUrl': image ?? 'assets/images/restaurant_placeholder.jpg',
      'cuisine': category,
      'rating': rating ?? 4.0,
      'price': price,
      'deliveryTime': deliveryTime,
      'isVeg': vegNonveg.toLowerCase() == 'veg',
    };
  }
}
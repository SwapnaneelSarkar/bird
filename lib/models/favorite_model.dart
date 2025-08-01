class FavoriteModel {
  final int favoriteId;
  final String favoritedAt;
  final String partnerId;
  final String restaurantName;
  final String address;
  final String latitude;
  final String longitude;
  final String cuisine;
  final String? category;
  final String rating;
  final String? restaurantPhotos;
  final int blockStatus;
  final String? deliveryRadius;
  final String operationalHours;

  FavoriteModel({
    required this.favoriteId,
    required this.favoritedAt,
    required this.partnerId,
    required this.restaurantName,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.cuisine,
    this.category,
    required this.rating,
    this.restaurantPhotos,
    required this.blockStatus,
    this.deliveryRadius,
    required this.operationalHours,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      favoriteId: json['favorite_id'] as int? ?? 0,
      favoritedAt: json['favorited_at'] as String? ?? '',
      partnerId: json['partner_id'] as String? ?? '',
      restaurantName: json['restaurant_name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      latitude: json['latitude'] as String? ?? '',
      longitude: json['longitude'] as String? ?? '',
      cuisine: json['cuisine'] as String? ?? '',
      category: json['category'] as String?,
      rating: json['rating'] as String? ?? '0.00',
      restaurantPhotos: json['restaurant_photos'] as String?,
      blockStatus: json['block_status'] as int? ?? 1,
      deliveryRadius: json['delivery_radius'] as String?,
      operationalHours: json['operational_hours'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'favorite_id': favoriteId,
      'favorited_at': favoritedAt,
      'partner_id': partnerId,
      'restaurant_name': restaurantName,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'cuisine': cuisine,
      'category': category,
      'rating': rating,
      'restaurant_photos': restaurantPhotos,
      'block_status': blockStatus,
      'delivery_radius': deliveryRadius,
      'operational_hours': operationalHours,
    };
  }

  // Helper method to get latitude as double
  double? get latitudeAsDouble {
    try {
      return double.tryParse(latitude);
    } catch (e) {
      return null;
    }
  }

  // Helper method to get longitude as double
  double? get longitudeAsDouble {
    try {
      return double.tryParse(longitude);
    } catch (e) {
      return null;
    }
  }

  // Helper method to get rating as double
  double get ratingAsDouble {
    try {
      return double.tryParse(rating) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  // Helper method to check if restaurant is blocked
  bool get isBlocked => blockStatus == 0;

  // Helper method to get first photo URL
  String? get firstPhotoUrl {
    if (restaurantPhotos == null || restaurantPhotos!.isEmpty) {
      return null;
    }
    try {
      // Assuming restaurant_photos is a JSON string with photo URLs
      // You might need to adjust this based on your actual data structure
      return restaurantPhotos;
    } catch (e) {
      return null;
    }
  }
} 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../constants/color/colorConstant.dart';
import '../utils/distance_util.dart';

class RestaurantCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final String cuisine;
  final dynamic rating;
  final String deliveryTime;
  final bool isVeg;
  final VoidCallback onTap;
  final double? restaurantLatitude;
  final double? restaurantLongitude;
  final double? userLatitude;
  final double? userLongitude;
  final String? restaurantType;
  final int? isAcceptingOrder;

  const RestaurantCard({
    Key? key,
    required this.name,
    required this.imageUrl,
    required this.cuisine,
    required this.rating,
    required this.deliveryTime,
    this.isVeg = false,
    required this.onTap,
    this.restaurantLatitude,
    this.restaurantLongitude,
    this.userLatitude,
    this.userLongitude,
    this.restaurantType,
    this.isAcceptingOrder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    double ratingValue = _parseRating(rating);
    return _buildVerticalCard(context, ratingValue, screenWidth);
  }

  double _parseRating(dynamic rating) {
    if (rating == null) return 0.0;
    if (rating is double) return rating;
    if (rating is int) return rating.toDouble();
    if (rating is String) return double.tryParse(rating) ?? 0.0;
    return 0.0;
  }

  Widget _buildVerticalCard(BuildContext context, double ratingValue, double screenWidth) {
    final bool isNotAcceptingOrders = isAcceptingOrder == 0;
    
    return GestureDetector(
      onTap: isNotAcceptingOrders ? null : onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: 8),
        decoration: BoxDecoration(
          color: isNotAcceptingOrders ? Colors.grey[100] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isNotAcceptingOrders ? 0.03 : 0.1),
              offset: Offset(0, 5),
              blurRadius: 15,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(isNotAcceptingOrders ? 0.01 : 0.05),
              offset: Offset(0, 2),
              blurRadius: 5,
              spreadRadius: 0,
            ),
          ],
          border: Border.all(
            color: isNotAcceptingOrders ? Colors.grey[300]! : Colors.white.withOpacity(0.8),
            width: 0.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image section
              Stack(
                children: [
                  // Restaurant Image
                  SizedBox(
                    width: double.infinity,
                    height: 150,
                    child: _buildImage(imageUrl),
                  ),
                  
                  // Enhanced grey overlay when not accepting orders
                  if (isNotAcceptingOrders)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.grey.withOpacity(0.7),
                              Colors.grey.withOpacity(0.8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  
                  // Gradient overlay for image
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(isNotAcceptingOrders ? 0.5 : 0.2),
                          ],
                          stops: [0.7, 1.0],
                        ),
                      ),
                    ),
                  ),
                  
                  // Enhanced "Currently not accepting order" overlay
                  if (isNotAcceptingOrders)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.1),
                        ),
                        child: Center(
                          child: Container(
                            margin: EdgeInsets.all(16),
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.pause_circle_outline,
                                  color: Colors.grey[600],
                                  size: 32,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Currently not accepting order',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[800],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Check back later',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  // Rating badge (elevated look)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: EdgeInsets.zero,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _buildYellowRatingBadge(ratingValue),
                    ),
                  ),
                  
                  // Restaurant Type badge - moved to bottom left of image
                  if (restaurantType != null && restaurantType!.isNotEmpty)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: EdgeInsets.zero,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _buildTypeTagBadge(restaurantType!),
                      ),
                    ),
                ],
              ),
              
              // Content section with reduced vertical space and improved alignment
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8), // reduce vertical padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // ensure it doesn't try to fill extra space
                  children: [
                    // Name and rating row with proper alignment
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Restaurant name (flex to handle long names)
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontSize: 16, 
                              fontWeight: FontWeight.bold,
                              color: isNotAcceptingOrders ? Colors.grey[500] : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            softWrap: true,
                          ),
                        ),
                        // Delivery time with minimum width to prevent squishing
                        Container(
                          constraints: BoxConstraints(minWidth: 60),
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isNotAcceptingOrders ? Colors.grey[200] : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            deliveryTime,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: isNotAcceptingOrders ? Colors.grey[500] : Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    
                    // Cuisine and location row with proper alignment
                    SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cuisine description (flex to handle variable length)
                        Expanded(
                          child: Text(
                            cuisine,
                            style: GoogleFonts.poppins(
                              fontSize: 12, 
                              color: isNotAcceptingOrders ? Colors.grey[400] : Colors.grey[600],
                              fontWeight: FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            softWrap: true,
                          ),
                        ),
                        // Small spacing between cuisine and distance
                        SizedBox(width: 8),
                        // Display calculated distance instead of "Nearby"
                        _buildInfoItem(Icons.place_outlined, _getDistanceText(), isNotAcceptingOrders),
                      ],
                    ),
                    
                    // Additional status indicator for not accepting orders
                    if (isNotAcceptingOrders) ...[
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              color: Colors.orange[600],
                              size: 14,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Temporarily unavailable',
                              style: GoogleFonts.poppins(
                                color: Colors.orange[700],
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Updated method to create the restaurant type badge with the app theme color
  Widget _buildTypeTagBadge(String type) {
    final bool isNotAcceptingOrders = isAcceptingOrder == 0;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            // Using ColorManager.primary with a darker opacity (0.95)
            color: isNotAcceptingOrders 
                ? Colors.grey.withOpacity(0.8)
                : ColorManager.primary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: Text(
            type,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.4), // Darker shadow for better contrast
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Calculate and display distance instead of "Nearby"
  String _getDistanceText() {
    if (userLatitude != null && userLongitude != null &&
        restaurantLatitude != null && restaurantLongitude != null) {
      try {
        debugPrint('RestaurantCard: Calculating distance for $name');
        // Calculate distance using the Haversine formula
        final distance = DistanceUtil.calculateDistance(
          userLatitude!,
          userLongitude!,
          restaurantLatitude!,
          restaurantLongitude!
        );
        
        // Format the distance in a user-friendly way
        final formattedDistance = DistanceUtil.formatDistance(distance);
        debugPrint('RestaurantCard: Distance for $name: $formattedDistance');
        return formattedDistance;
      } catch (e) {
        debugPrint('RestaurantCard: Error calculating distance: $e');
        return "Nearby";
      }
    }
    
    // If any of the required coordinates is missing, fall back to "Nearby"
    debugPrint('RestaurantCard: Missing coordinates for $name, using "Nearby"');
    return "Nearby";
  }

  Widget _buildYellowRatingBadge(double ratingValue) {
    final bool isNotAcceptingOrders = isAcceptingOrder == 0;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isNotAcceptingOrders 
                ? Colors.grey.withOpacity(0.7)
                : ColorManager.primary.withOpacity(0.7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ratingValue > 0 ? ratingValue.toStringAsFixed(1) : "New",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
              if (ratingValue > 0) ...[
                const SizedBox(width: 2),
                Icon(
                  Icons.star, 
                  color: Colors.white, 
                  size: 12,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, bool isNotAcceptingOrders) {
    return Row(
      children: [
        Icon(icon, size: 14, color: isNotAcceptingOrders ? Colors.grey[500] : Colors.grey[600]),
        const SizedBox(width: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: isNotAcceptingOrders ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.startsWith('http')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholder(isLoading: true);
        },
      );
    } else {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }
  }

  Widget _buildPlaceholder({bool isLoading = false}) {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: isLoading
            ? CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFFFFD700)),
                strokeWidth: 2,
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant, size: 24, color: Colors.grey[400]),
                  const SizedBox(height: 4),
                  Text(
                    'No image',
                    style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }
}
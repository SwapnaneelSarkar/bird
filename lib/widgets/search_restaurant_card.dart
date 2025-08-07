import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import '../constants/color/colorConstant.dart';
import '../utils/distance_util.dart';
import '../utils/delivery_time_util.dart';
import 'responsive_text.dart';

class SearchRestaurantCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final String cuisine;
  final dynamic rating;
  final bool isVeg;
  final VoidCallback onTap;
  final double? restaurantLatitude;
  final double? restaurantLongitude;
  final double? userLatitude;
  final double? userLongitude;
  final String? restaurantType;
  final int? isAcceptingOrder;
  final String? partnerId;
  final bool? isFavorite;
  final bool? isLoading;
  final VoidCallback? onFavoriteToggle;
  final bool? isFoodSupercategory;

  const SearchRestaurantCard({
    Key? key,
    required this.name,
    required this.imageUrl,
    required this.cuisine,
    required this.rating,
    this.isVeg = false,
    required this.onTap,
    this.restaurantLatitude,
    this.restaurantLongitude,
    this.userLatitude,
    this.userLongitude,
    this.restaurantType,
    this.isAcceptingOrder,
    this.partnerId,
    this.isFavorite,
    this.isLoading,
    this.onFavoriteToggle,
    this.isFoodSupercategory,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    double ratingValue = _parseRating(rating);
    
    // Check if this is a store (non-food supercategory)
    final isStore = isFoodSupercategory != null 
        ? !isFoodSupercategory! 
        : (restaurantType != null && restaurantType != 'restaurant');
    
    if (isStore) {
      return _buildSearchInstamartStoreCard(context, ratingValue, screenWidth, screenHeight);
    }
    
    return _buildSearchVerticalCard(context, ratingValue, screenWidth, screenHeight);
  }

  double _parseRating(dynamic rating) {
    if (rating == null) return 0.0;
    if (rating is double) return rating;
    if (rating is int) return rating.toDouble();
    if (rating is String) return double.tryParse(rating) ?? 0.0;
    return 0.0;
  }

  Widget _buildSearchVerticalCard(BuildContext context, double ratingValue, double screenWidth, double screenHeight) {
    final bool isNotAcceptingOrders = isAcceptingOrder == 0;
    
    return GestureDetector(
      onTap: isNotAcceptingOrders ? null : onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: screenHeight * 0.008),
        decoration: BoxDecoration(
          color: isNotAcceptingOrders ? Colors.grey[100] : Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isNotAcceptingOrders ? 0.03 : 0.08),
              offset: Offset(0, 3),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
          border: Border.all(
            color: isNotAcceptingOrders ? Colors.grey[300]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
          child: Row(
            children: [
              // Image section
              Container(
                width: screenWidth * 0.25,
                height: screenHeight * 0.12,
                child: Stack(
                  children: [
                    // Restaurant Image
                    SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: _buildImage(imageUrl),
                    ),
                    
                    // Enhanced grey overlay when not accepting orders
                    if (isNotAcceptingOrders)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.7),
                          ),
                        ),
                      ),
                    
                    // Rating badge
                    Positioned(
                      top: screenHeight * 0.008,
                      right: screenWidth * 0.015,
                      child: _buildYellowRatingBadge(ratingValue, screenWidth),
                    ),
                    
                    // Favorite button
                    if (partnerId != null && onFavoriteToggle != null)
                      Positioned(
                        top: screenHeight * 0.008,
                        left: screenWidth * 0.015,
                        child: GestureDetector(
                          onTap: () {
                            if (onFavoriteToggle != null && !(isLoading == true)) {
                              onFavoriteToggle!();
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.all(screenWidth * 0.01),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(screenWidth * 0.015),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: isLoading == true
                                ? SizedBox(
                                    width: screenWidth * 0.025,
                                    height: screenWidth * 0.025,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        isFavorite == true ? Colors.red[400]! : Colors.grey[600]!,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    isFavorite == true ? Icons.favorite : Icons.favorite_border,
                                    color: isFavorite == true ? Colors.red[400] : Colors.grey[600],
                                    size: screenWidth * 0.03,
                                  ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Content section
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.03),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top section: Name and delivery time
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Restaurant name
                          Expanded(
                            child: ResponsiveText(
                              text: name,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: isNotAcceptingOrders ? Colors.grey[500] : Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              maxFontSize: screenWidth * 0.035,
                              minFontSize: screenWidth * 0.03,
                            ),
                          ),
                          // Delivery time
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.015, vertical: screenHeight * 0.003),
                            decoration: BoxDecoration(
                              color: isNotAcceptingOrders ? Colors.grey[200] : ColorManager.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(screenWidth * 0.015),
                            ),
                            child: ResponsiveText(
                              text: _getDeliveryTimeText(),
                              style: GoogleFonts.poppins(
                                color: isNotAcceptingOrders ? Colors.grey[500] : ColorManager.primary,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                              maxFontSize: screenWidth * 0.025,
                              minFontSize: screenWidth * 0.02,
                            ),
                          ),
                        ],
                      ),
                      
                      // Middle section: Cuisine
                      if (cuisine.isNotEmpty)
                        ResponsiveText(
                          text: cuisine,
                          style: GoogleFonts.poppins(
                            color: isNotAcceptingOrders ? Colors.grey[400] : Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          maxFontSize: screenWidth * 0.025,
                          minFontSize: screenWidth * 0.02,
                        ),
                      
                      // Bottom section: Distance and status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Distance
                          _buildInfoItem(Icons.place_outlined, _getDistanceText(), isNotAcceptingOrders, screenWidth),
                          
                          // Status indicator for not accepting orders
                          if (isNotAcceptingOrders)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.015, vertical: screenHeight * 0.003),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(screenWidth * 0.01),
                                border: Border.all(
                                  color: Colors.orange.withOpacity(0.3),
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: Colors.orange[600],
                                    size: screenWidth * 0.025,
                                  ),
                                  SizedBox(width: screenWidth * 0.01),
                                  ResponsiveText(
                                    text: 'Unavailable',
                                    style: GoogleFonts.poppins(
                                      color: Colors.orange[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxFontSize: screenWidth * 0.02,
                                    minFontSize: screenWidth * 0.018,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchInstamartStoreCard(BuildContext context, double ratingValue, double screenWidth, double screenHeight) {
    final bool isNotAcceptingOrders = isAcceptingOrder == 0;
    final scale = (screenWidth / 400).clamp(0.8, 1.2);
    
    return GestureDetector(
      onTap: isNotAcceptingOrders ? null : onTap,
      child: Container(
        width: (screenWidth - 32) / 2, // 2 cards per row with margins
        margin: EdgeInsets.all(4 * scale),
        decoration: BoxDecoration(
          color: isNotAcceptingOrders ? Colors.grey[100] : Colors.white,
          borderRadius: BorderRadius.circular(8 * scale),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isNotAcceptingOrders ? 0.03 : 0.06),
              offset: Offset(0, 2),
              blurRadius: 6,
              spreadRadius: 0,
            ),
          ],
          border: Border.all(
            color: isNotAcceptingOrders ? Colors.grey[300]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8 * scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image section
              Stack(
                children: [
                  // Store Image
                  SizedBox(
                    width: double.infinity,
                    height: 160 * scale, // Larger image height for search
                    child: _buildImage(imageUrl),
                  ),
                  
                  // Enhanced grey overlay when not accepting orders
                  if (isNotAcceptingOrders)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.7),
                        ),
                      ),
                    ),
                  
                  // Favorite button
                  if (partnerId != null && onFavoriteToggle != null)
                    Positioned(
                      top: 6 * scale,
                      right: 6 * scale,
                      child: GestureDetector(
                        onTap: () {
                          if (onFavoriteToggle != null && !(isLoading == true)) {
                            onFavoriteToggle!();
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(4 * scale),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(6 * scale),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: isLoading == true
                              ? SizedBox(
                                  width: 12 * scale,
                                  height: 12 * scale,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isFavorite == true ? Colors.red[400]! : Colors.grey[600]!,
                                    ),
                                  ),
                                )
                              : Icon(
                                  isFavorite == true ? Icons.favorite : Icons.favorite_border,
                                  color: isFavorite == true ? Colors.red[400] : Colors.grey[600],
                                  size: 12 * scale,
                                ),
                        ),
                      ),
                    ),
                  
                  // Rating badge
                  if (ratingValue > 0)
                    Positioned(
                      top: 6 * scale,
                      left: 6 * scale,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 4 * scale, vertical: 2 * scale),
                        decoration: BoxDecoration(
                          color: ColorManager.instamartGreen,
                          borderRadius: BorderRadius.circular(4 * scale),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.white,
                              size: 10 * scale,
                            ),
                            SizedBox(width: 2 * scale),
                            Text(
                              ratingValue.toStringAsFixed(1),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 9 * scale,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              
              // Content section with custom spacing for search
              Padding(
                padding: EdgeInsets.only(
                  left: 8 * scale,
                  right: 8 * scale,
                  top: 8 * scale,
                  bottom: 4 * scale, // Reduced bottom padding
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Store name
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 14 * scale, // Larger font for search
                        fontWeight: FontWeight.w600,
                        color: isNotAcceptingOrders ? Colors.grey[600] : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: 5 * scale), // More spacing between name and category
                    
                    // Cuisine/category
                    if (cuisine.isNotEmpty)
                      Text(
                        cuisine,
                        style: GoogleFonts.poppins(
                          fontSize: 12 * scale, // Larger font for search
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    
                    SizedBox(height: 5 * scale), // More spacing between category and delivery info
                    
                    // Delivery info row
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12 * scale,
                          color: ColorManager.instamartGreen,
                        ),
                        SizedBox(width: 3 * scale),
                        Text(
                          '20-30 min',
                          style: GoogleFonts.poppins(
                            fontSize: 11 * scale, // Larger font for search
                            color: ColorManager.instamartGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Spacer(),
                        Icon(
                          Icons.location_on,
                          size: 12 * scale,
                          color: Colors.grey[500],
                        ),
                        SizedBox(width: 3 * scale),
                        Expanded(
                          child: Text(
                            _calculateDistance(),
                            style: GoogleFonts.poppins(
                              fontSize: 11 * scale, // Larger font for search
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 2 * scale), // Minimal spacing
                    
                    // Add to cart button - only show for food supercategories
                    if (!isNotAcceptingOrders && isFoodSupercategory == true)
                      Container(
                        width: double.infinity,
                        height: 24 * scale,
                        child: ElevatedButton(
                          onPressed: onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorManager.instamartGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4 * scale),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(
                            'Add to Cart',
                            style: GoogleFonts.poppins(
                              fontSize: 10 * scale,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    else if (isNotAcceptingOrders && isFoodSupercategory == true)
                      Container(
                        width: double.infinity,
                        height: 24 * scale,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4 * scale),
                        ),
                        child: Center(
                          child: Text(
                            'Not Available',
                            style: GoogleFonts.poppins(
                              fontSize: 10 * scale,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _calculateDistance() {
    if (restaurantLatitude == null || restaurantLongitude == null || 
        userLatitude == null || userLongitude == null) {
      return 'Distance N/A';
    }
    
    final distance = DistanceUtil.calculateDistance(
      userLatitude!, userLongitude!,
      restaurantLatitude!, restaurantLongitude!,
    );
    
    if (distance < 1) {
      return '${(distance * 1000).round()}m';
    } else {
      return '${distance.toStringAsFixed(1)}km';
    }
  }

  // Calculate and display distance instead of "Nearby"
  String _getDistanceText() {
    if (userLatitude != null && userLongitude != null &&
        restaurantLatitude != null && restaurantLongitude != null) {
      try {
        final distance = DistanceUtil.calculateDistance(
          userLatitude!,
          userLongitude!,
          restaurantLatitude!,
          restaurantLongitude!
        );
        
        final formattedDistance = DistanceUtil.formatDistance(distance);
        return formattedDistance;
      } catch (e) {
        return "Nearby";
      }
    }
    
    return "Nearby";
  }

  // Calculate and display delivery time based on distance
  String _getDeliveryTimeText() {
    if (userLatitude != null && userLongitude != null &&
        restaurantLatitude != null && restaurantLongitude != null) {
      try {
        final distance = DistanceUtil.calculateDistance(
          userLatitude!,
          userLongitude!,
          restaurantLatitude!,
          restaurantLongitude!
        );
        
        final deliveryTime = DeliveryTimeUtil.calculateDeliveryTime(distance);
        return deliveryTime;
      } catch (e) {
        return "20-30 mins";
      }
    }
    
    return "20-30 mins";
  }

  Widget _buildYellowRatingBadge(double ratingValue, double screenWidth) {
    final bool isNotAcceptingOrders = isAcceptingOrder == 0;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(screenWidth * 0.015),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.015, vertical: screenWidth * 0.008),
          decoration: BoxDecoration(
            color: isNotAcceptingOrders 
                ? Colors.grey.withOpacity(0.7)
                : ColorManager.primary.withOpacity(0.8),
            borderRadius: BorderRadius.circular(screenWidth * 0.015),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ResponsiveText(
                text: ratingValue > 0 ? ratingValue.toStringAsFixed(1) : "New",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 1,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                maxFontSize: screenWidth * 0.025,
                minFontSize: screenWidth * 0.02,
              ),
              if (ratingValue > 0) ...[
                SizedBox(width: screenWidth * 0.003),
                Icon(
                  Icons.star, 
                  color: Colors.white, 
                  size: screenWidth * 0.02,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, bool isNotAcceptingOrders, double screenWidth) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: screenWidth * 0.025, color: isNotAcceptingOrders ? Colors.grey[500] : Colors.grey[600]),
        SizedBox(width: screenWidth * 0.003),
        ResponsiveText(
          text: value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w400,
            color: isNotAcceptingOrders ? Colors.grey[500] : Colors.grey[600],
          ),
          maxFontSize: screenWidth * 0.022,
          minFontSize: screenWidth * 0.018,
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
                  Icon(Icons.restaurant, size: 20, color: Colors.grey[400]),
                  const SizedBox(height: 2),
                  Text(
                    'No image',
                    style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 10),
                  ),
                ],
              ),
      ),
    );
  }
} 
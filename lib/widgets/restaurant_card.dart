import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'package:geocoding/geocoding.dart';
import '../constants/color/colorConstant.dart';
import '../utils/distance_util.dart';
import '../utils/delivery_time_util.dart';
import 'responsive_text.dart';

class RestaurantCard extends StatefulWidget {
  final String name;
  final String imageUrl;
  final String cuisine;
  final String? description;
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

  const RestaurantCard({
    Key? key,
    required this.name,
    required this.imageUrl,
    required this.cuisine,
    this.description,
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
  State<RestaurantCard> createState() => _RestaurantCardState();
}

class _RestaurantCardState extends State<RestaurantCard> {
  String? _restaurantAddress;
  bool _isLoadingAddress = false;

  @override
  void initState() {
    super.initState();
    _loadRestaurantAddress();
  }

  Future<void> _loadRestaurantAddress() async {
    if (widget.restaurantLatitude == null || widget.restaurantLongitude == null) {
      return;
    }

    setState(() {
      _isLoadingAddress = true;
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        widget.restaurantLatitude!,
        widget.restaurantLongitude!,
      );

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        String address = '';
        
        // Build address from available components
        if (placemark.street != null && placemark.street!.isNotEmpty) {
          address += placemark.street!;
        }
        
        if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += placemark.subLocality!;
        }
        
        if (placemark.locality != null && placemark.locality!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += placemark.locality!;
        }

        // If we have a very long address, truncate it intelligently
        if (address.length > 50) {
          List<String> parts = address.split(', ');
          if (parts.length > 2) {
            address = '${parts[0]}, ${parts[1]}';
          } else if (address.length > 50) {
            address = address.substring(0, 47) + '...';
          }
        }

        setState(() {
          _restaurantAddress = address.isNotEmpty ? address : 'Address not available';
          _isLoadingAddress = false;
        });
      }
    } catch (e) {
      debugPrint('Error getting restaurant address: $e');
      setState(() {
        _restaurantAddress = 'Address not available';
        _isLoadingAddress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    double ratingValue = _parseRating(widget.rating);
    
    // Debug logging
    debugPrint('RestaurantCard build: "${widget.name}" - description: "${widget.description}", cuisine: "${widget.cuisine}"');
    
    // Check if this is a store (non-food supercategory)
    // Use the explicit isFoodSupercategory parameter if provided, otherwise fall back to restaurantType
    final isStore = widget.isFoodSupercategory != null 
        ? !widget.isFoodSupercategory! 
        : (widget.restaurantType != null && widget.restaurantType != 'restaurant');
    
    if (isStore) {
      return _buildInstamartStoreCard(context, ratingValue, screenWidth, screenHeight);
    }
    
    return _buildVerticalCard(context, ratingValue, screenWidth, screenHeight);
  }

  double _parseRating(dynamic rating) {
    if (rating == null) return 0.0;
    if (rating is double) return rating;
    if (rating is int) return rating.toDouble();
    if (rating is String) return double.tryParse(rating) ?? 0.0;
    return 0.0;
  }

  Widget _buildVerticalCard(BuildContext context, double ratingValue, double screenWidth, double screenHeight) {
    final bool isNotAcceptingOrders = widget.isAcceptingOrder == 0;
    
    return GestureDetector(
      onTap: isNotAcceptingOrders ? null : widget.onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.01),
        decoration: BoxDecoration(
          color: isNotAcceptingOrders ? Colors.grey[100] : Colors.white,
          borderRadius: BorderRadius.circular(screenWidth * 0.05),
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
          borderRadius: BorderRadius.circular(screenWidth * 0.05),
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
                    height: screenHeight * 0.176, // Reduced image height by 20%
                    child: _buildImage(widget.imageUrl),
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
                            margin: EdgeInsets.all(screenWidth * 0.04),
                            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: screenHeight * 0.015),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(screenWidth * 0.03),
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
                                  size: screenWidth * 0.08,
                                ),
                                SizedBox(height: screenHeight * 0.01),
                                ResponsiveText(
                                  text: 'Currently not accepting order',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxFontSize: screenWidth * 0.035,
                                  minFontSize: screenWidth * 0.03,
                                ),
                                SizedBox(height: screenHeight * 0.005),
                                ResponsiveText(
                                  text: 'Check back later',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w400,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxFontSize: screenWidth * 0.03,
                                  minFontSize: screenWidth * 0.025,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  // Rating badge (elevated look)
                  Positioned(
                    top: screenHeight * 0.015,
                    right: screenWidth * 0.03,
                    child: Container(
                      padding: EdgeInsets.zero,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _buildYellowRatingBadge(ratingValue, screenWidth),
                    ),
                  ),
                  
                  // Favorite button
                  if (widget.partnerId != null && widget.onFavoriteToggle != null)
                    Positioned(
                      top: screenHeight * 0.015,
                      left: screenWidth * 0.03,
                      child: GestureDetector(
                        onTap: () {
                          if (widget.onFavoriteToggle != null && !(widget.isLoading == true)) {
                            widget.onFavoriteToggle!();
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(screenWidth * 0.015),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(screenWidth * 0.025),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: widget.isLoading == true
                              ? SizedBox(
                                  width: screenWidth * 0.035,
                                  height: screenWidth * 0.035,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      widget.isFavorite == true ? Colors.red[400]! : Colors.grey[600]!,
                                    ),
                                  ),
                                )
                              : Icon(
                                  widget.isFavorite == true ? Icons.favorite : Icons.favorite_border,
                                  color: widget.isFavorite == true ? Colors.red[400] : Colors.grey[600],
                                  size: screenWidth * 0.045,
                                ),
                        ),
                      ),
                    ),
                  
                  // Restaurant Type badge - moved to bottom left of image
                  if (widget.restaurantType != null && widget.restaurantType!.isNotEmpty)
                    Positioned(
                      bottom: screenHeight * 0.015,
                      left: screenWidth * 0.03,
                      child: Container(
                        padding: EdgeInsets.zero,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(screenWidth * 0.02),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _buildTypeTagBadge(widget.restaurantType!, screenWidth),
                      ),
                    ),
                ],
              ),
              
              // Content section with reduced vertical space and improved alignment
              Padding(
                padding: EdgeInsets.fromLTRB(screenWidth * 0.04, screenHeight * 0.012, screenWidth * 0.04, screenHeight * 0.012), // Reduced vertical padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name and rating row with proper alignment
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Restaurant name (flex to handle long names)
                        Expanded(
                          child: ResponsiveText(
                            text: widget.name,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: isNotAcceptingOrders ? Colors.grey[500] : Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            maxFontSize: screenWidth * 0.037,
                            minFontSize: screenWidth * 0.032,
                          ),
                        ),
                        // Delivery time with minimum width to prevent squishing
                        Container(
                          constraints: BoxConstraints(minWidth: screenWidth * 0.13),
                          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.015, vertical: screenHeight * 0.004),
                          decoration: BoxDecoration(
                            color: isNotAcceptingOrders ? Colors.grey[200] : Colors.transparent,
                            borderRadius: BorderRadius.circular(screenWidth * 0.018),
                          ),
                          child: ResponsiveText(
                            text: _getDeliveryTimeText(),
                            style: GoogleFonts.poppins(
                              color: isNotAcceptingOrders ? Colors.grey[500] : Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxFontSize: screenWidth * 0.032,
                            minFontSize: screenWidth * 0.027,
                          ),
                        ),
                      ],
                    ),
                    
                    // Cuisine and location row with proper alignment
                    SizedBox(height: screenHeight * 0.008),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Description (preferred) or cuisine (flex to handle variable length)
                        Expanded(
                          child: ResponsiveText(
                            text: (widget.description != null && widget.description!.isNotEmpty) 
                                ? widget.description! 
                                : widget.cuisine,
                            style: GoogleFonts.poppins(
                              color: isNotAcceptingOrders ? Colors.grey[400] : Colors.grey[600],
                              fontWeight: FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            maxFontSize: screenWidth * 0.027,
                            minFontSize: screenWidth * 0.022,
                          ),
                        ),
                        // Small spacing between cuisine and distance
                        SizedBox(width: screenWidth * 0.02),
                        // Display calculated distance instead of "Nearby"
                        _buildInfoItem(Icons.place_outlined, _getDistanceText(), isNotAcceptingOrders, screenWidth),
                      ],
                    ),
                    
                    // Address row
                    if (_restaurantAddress != null || _isLoadingAddress) ...[
                      SizedBox(height: screenHeight * 0.005),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined, 
                            size: screenWidth * 0.032, 
                            color: isNotAcceptingOrders ? Colors.grey[400] : Colors.grey[500]
                          ),
                          SizedBox(width: screenWidth * 0.01),
                          Expanded(
                            child: _isLoadingAddress
                                ? Row(
                                    children: [
                                      SizedBox(
                                        width: screenWidth * 0.025,
                                        height: screenWidth * 0.025,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                                        ),
                                      ),
                                      SizedBox(width: screenWidth * 0.02),
                                      ResponsiveText(
                                        text: 'Loading address...',
                                        style: GoogleFonts.poppins(
                                          color: Colors.grey[400],
                                          fontWeight: FontWeight.w400,
                                        ),
                                        maxFontSize: screenWidth * 0.025,
                                        minFontSize: screenWidth * 0.022,
                                      ),
                                    ],
                                  )
                                : ResponsiveText(
                                    text: _restaurantAddress!,
                                    style: GoogleFonts.poppins(
                                      color: isNotAcceptingOrders ? Colors.grey[400] : Colors.grey[500],
                                      fontWeight: FontWeight.w400,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    maxFontSize: screenWidth * 0.025,
                                    minFontSize: screenWidth * 0.022,
                                  ),
                          ),
                        ],
                      ),
                    ],
                    
                    // Additional status indicator for not accepting orders
                    if (isNotAcceptingOrders) ...[
                      SizedBox(height: screenHeight * 0.01),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.025, vertical: screenHeight * 0.008),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(screenWidth * 0.015),
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
                              size: screenWidth * 0.035,
                            ),
                            SizedBox(width: screenWidth * 0.015),
                            ResponsiveText(
                              text: 'Temporarily unavailable',
                              style: GoogleFonts.poppins(
                                color: Colors.orange[700],
                                fontWeight: FontWeight.w500,
                              ),
                              maxFontSize: screenWidth * 0.028,
                              minFontSize: screenWidth * 0.025,
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

  Widget _buildInstamartStoreCard(BuildContext context, double ratingValue, double screenWidth, double screenHeight) {
    final bool isNotAcceptingOrders = widget.isAcceptingOrder == 0;
    final scale = (screenWidth / 400).clamp(0.7, 1.0);
    
    return GestureDetector(
      onTap: isNotAcceptingOrders ? null : widget.onTap,
      child: Container(
        width: (screenWidth - 48) / 2, // 2 cards per row with margins
        margin: EdgeInsets.all(6 * scale),
        decoration: BoxDecoration(
          color: isNotAcceptingOrders ? Colors.grey[100] : Colors.white,
          borderRadius: BorderRadius.circular(10 * scale),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isNotAcceptingOrders ? 0.03 : 0.06),
              offset: Offset(0, 1),
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
          borderRadius: BorderRadius.circular(10 * scale),
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
                    height: 120 * scale, // Increased image height for homepage
                    child: _buildImage(widget.imageUrl),
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
                  if (widget.partnerId != null && widget.onFavoriteToggle != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () {
                          if (widget.onFavoriteToggle != null && !(widget.isLoading == true)) {
                            widget.onFavoriteToggle!();
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          child: widget.isLoading == true
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      widget.isFavorite == true ? Colors.red[400]! : Colors.grey[600]!,
                                    ),
                                  ),
                                )
                              : Icon(
                                  widget.isFavorite == true ? Icons.favorite : Icons.favorite_border,
                                  color: widget.isFavorite == true ? Colors.red[400] : Colors.grey[600],
                                  size: 16,
                                ),
                        ),
                      ),
                    ),
                  
                  // Rating badge
                  if (ratingValue > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: ColorManager.instamartGreen,
                          borderRadius: BorderRadius.circular(6),
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
                              size: 12,
                            ),
                            SizedBox(width: 2),
                            Text(
                              ratingValue.toStringAsFixed(1),
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              
              // Content section
              Padding(
                padding: EdgeInsets.all(8 * scale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Store name
                    Text(
                      widget.name,
                      style: GoogleFonts.poppins(
                        fontSize: 13 * scale,
                        fontWeight: FontWeight.w600,
                        color: isNotAcceptingOrders ? Colors.grey[600] : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: 4),
                    
                    // Description (preferred) or cuisine/category
                    if (widget.description != null && widget.description!.isNotEmpty)
                      Text(
                        widget.description!,
                        style: GoogleFonts.poppins(
                          fontSize: 11 * scale,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    else if (widget.cuisine.isNotEmpty)
                      Text(
                        widget.cuisine,
                        style: GoogleFonts.poppins(
                          fontSize: 11 * scale,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    
                    SizedBox(height: 4 * scale),
                    
                    // Address for store card
                    if (_restaurantAddress != null && !_isLoadingAddress)
                      Padding(
                        padding: EdgeInsets.only(bottom: 4 * scale),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 10 * scale,
                              color: Colors.grey[500],
                            ),
                            SizedBox(width: 3 * scale),
                            Expanded(
                              child: Text(
                                _restaurantAddress!,
                                style: GoogleFonts.poppins(
                                  fontSize: 9 * scale,
                                  color: Colors.grey[500],
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
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
                            fontSize: 10 * scale,
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
                              fontSize: 10 * scale,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w400,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 4 * scale),
                    
                    // Add to cart button - only show for food supercategories
                    if (!isNotAcceptingOrders && widget.isFoodSupercategory == true)
                      Container(
                        width: double.infinity,
                        height: 26 * scale,
                        child: ElevatedButton(
                          onPressed: widget.onTap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorManager.instamartGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: Text(
                            'Add to Cart',
                            style: GoogleFonts.poppins(
                              fontSize: 11 * scale,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    else if (isNotAcceptingOrders && widget.isFoodSupercategory == true)
                      Container(
                        width: double.infinity,
                        height: 26 * scale,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            'Not Available',
                            style: GoogleFonts.poppins(
                              fontSize: 11 * scale,
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
    if (widget.restaurantLatitude == null || widget.restaurantLongitude == null || 
        widget.userLatitude == null || widget.userLongitude == null) {
      return 'Distance N/A';
    }
    
    final distance = DistanceUtil.calculateDistance(
      widget.userLatitude!, widget.userLongitude!,
      widget.restaurantLatitude!, widget.restaurantLongitude!,
    );
    
    if (distance < 1) {
      return '${(distance * 1000).round()}m';
    } else {
      return '${distance.toStringAsFixed(1)}km';
    }
  }

  // Updated method to create the restaurant type badge with the app theme color
  Widget _buildTypeTagBadge(String type, double screenWidth) {
    final bool isNotAcceptingOrders = widget.isAcceptingOrder == 0;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(screenWidth * 0.02),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02, vertical: screenWidth * 0.01),
          decoration: BoxDecoration(
            color: isNotAcceptingOrders 
                ? Colors.grey.withOpacity(0.8)
                : ColorManager.primary,
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: ResponsiveText(
            text: type,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            maxFontSize: screenWidth * 0.03,
            minFontSize: screenWidth * 0.025,
          ),
        ),
      ),
    );
  }

  // Calculate and display distance instead of "Nearby"
  String _getDistanceText() {
    if (widget.userLatitude != null && widget.userLongitude != null &&
        widget.restaurantLatitude != null && widget.restaurantLongitude != null) {
      try {
        debugPrint('RestaurantCard: Calculating distance for ${widget.name}');
        // Calculate distance using the Haversine formula
        final distance = DistanceUtil.calculateDistance(
          widget.userLatitude!,
          widget.userLongitude!,
          widget.restaurantLatitude!,
          widget.restaurantLongitude!
        );
        
        // Format the distance in a user-friendly way
        final formattedDistance = DistanceUtil.formatDistance(distance);
        debugPrint('RestaurantCard: Distance for ${widget.name}: $formattedDistance');
        return formattedDistance;
      } catch (e) {
        debugPrint('RestaurantCard: Error calculating distance: $e');
        return "Nearby";
      }
    }
    
    // If any of the required coordinates is missing, fall back to "Nearby"
    debugPrint('RestaurantCard: Missing coordinates for ${widget.name}, using "Nearby"');
    return "Nearby";
  }

  // Calculate and display delivery time based on distance
  String _getDeliveryTimeText() {
    if (widget.userLatitude != null && widget.userLongitude != null &&
        widget.restaurantLatitude != null && widget.restaurantLongitude != null) {
      try {
        // Calculate distance using the Haversine formula
        final distance = DistanceUtil.calculateDistance(
          widget.userLatitude!,
          widget.userLongitude!,
          widget.restaurantLatitude!,
          widget.restaurantLongitude!
        );
        
        // Calculate delivery time based on distance
        final deliveryTime = DeliveryTimeUtil.calculateDeliveryTime(distance);
        debugPrint('RestaurantCard: Delivery time for ${widget.name}: $deliveryTime (distance: ${distance.toStringAsFixed(2)} km)');
        return deliveryTime;
      } catch (e) {
        debugPrint('RestaurantCard: Error calculating delivery time: $e');
        return "20-30 mins";
      }
    }
    
    // If any of the required coordinates is missing, fall back to default
    debugPrint('RestaurantCard: Missing coordinates for ${widget.name}, using default delivery time');
    return "20-30 mins";
  }

  Widget _buildYellowRatingBadge(double ratingValue, double screenWidth) {
    final bool isNotAcceptingOrders = widget.isAcceptingOrder == 0;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(screenWidth * 0.02),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02, vertical: screenWidth * 0.01),
          decoration: BoxDecoration(
            color: isNotAcceptingOrders 
                ? Colors.grey.withOpacity(0.7)
                : ColorManager.primary.withOpacity(0.7),
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
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
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                maxFontSize: screenWidth * 0.035,
                minFontSize: screenWidth * 0.03,
              ),
              if (ratingValue > 0) ...[
                SizedBox(width: screenWidth * 0.005),
                Icon(
                  Icons.star, 
                  color: Colors.white, 
                  size: screenWidth * 0.03,
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
        Icon(icon, size: screenWidth * 0.035, color: isNotAcceptingOrders ? Colors.grey[500] : Colors.grey[600]),
        SizedBox(width: screenWidth * 0.005),
        ResponsiveText(
          text: value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w400,
            color: isNotAcceptingOrders ? Colors.grey[500] : Colors.grey[600],
          ),
          maxFontSize: screenWidth * 0.03,
          minFontSize: screenWidth * 0.025,
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
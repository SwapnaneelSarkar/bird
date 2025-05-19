// presentation/restaurant_profile/view.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../constants/color/colorConstant.dart';
import '../../constants/font/fontManager.dart';
import '../../widgets/cached_image.dart';

import 'bloc.dart';
import 'event.dart';
import 'state.dart';

class RestaurantProfileView extends StatefulWidget {
  final String restaurantId;

  const RestaurantProfileView({
    Key? key,
    required this.restaurantId,
  }) : super(key: key);

  @override
  State<RestaurantProfileView> createState() => _RestaurantProfileViewState();
}

class _RestaurantProfileViewState extends State<RestaurantProfileView> {
  
  @override
  void initState() {
    super.initState();
    // Trigger loading of restaurant data when the view is built
    context.read<RestaurantProfileBloc>().add(
          LoadRestaurantProfile(restaurantId: widget.restaurantId),
        );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocBuilder<RestaurantProfileBloc, RestaurantProfileState>(
        builder: (context, state) {
          if (state is RestaurantProfileLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is RestaurantProfileLoaded) {
            return _buildContent(context, state);
          } else if (state is RestaurantProfileError) {
            return _buildErrorView(context, state);
          }
          // Initial state or any other state
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, RestaurantProfileError state) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: const Icon(
                    Icons.arrow_back,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red[400],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Error: ${state.message}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorManager.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                    ),
                    onPressed: () {
                      context.read<RestaurantProfileBloc>().add(
                            LoadRestaurantProfile(restaurantId: widget.restaurantId),
                          );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Retry',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, RestaurantProfileLoaded state) {
    final restaurant = state.restaurant;
    final size = MediaQuery.of(context).size;
    final horizontalPadding = size.width * 0.045;
    
    return SafeArea(
      child: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back Button
            Container(
              margin: EdgeInsets.all(horizontalPadding),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    splashColor: ColorManager.primary.withOpacity(0.3),
                    onTap: () => Navigator.pop(context),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.arrow_back,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Restaurant Header Card
            Container(
              margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Restaurant Name with fancy styling
                    Hero(
                      tag: 'restaurant_name_${restaurant.name}',
                      child: Text(
                        restaurant.name,
                        style: TextStyle(
                          fontSize: _responsiveFontSize(context, 28),
                          fontWeight: FontWeight.bold,
                          color: ColorManager.black,
                          fontFamily: FontFamily.ArbutusSlab,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              blurRadius: 2.0,
                              color: Colors.black.withOpacity(0.1),
                              offset: Offset(1.0, 1.0),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Cuisine with pill-shaped background
                    Container(
                      margin: EdgeInsets.only(top: 8),
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: ColorManager.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        restaurant.cuisine,
                        style: TextStyle(
                          fontSize: _responsiveFontSize(context, 14),
                          fontWeight: FontWeight.w500,
                          color: ColorManager.primary,
                          fontFamily: FontFamily.Montserrat,
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 15),
                    
                    // Description (if available) with styled container
                    if (restaurant.description != null && restaurant.description!.isNotEmpty)
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          restaurant.description!,
                          style: TextStyle(
                            fontSize: _responsiveFontSize(context, 14),
                            fontWeight: FontWeightManager.regular,
                            color: ColorManager.black.withOpacity(0.7),
                            fontFamily: FontFamily.Montserrat,
                            height: 1.4,
                          ),
                        ),
                      ),
                    
                    SizedBox(height: 15),
                    
                    // Address with icon
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 20,
                          color: ColorManager.primary,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            restaurant.address,
                            style: TextStyle(
                              fontSize: _responsiveFontSize(context, 14),
                              fontWeight: FontWeightManager.regular,
                              color: ColorManager.black,
                              fontFamily: FontFamily.Montserrat,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Opening Hours Row with styled container
            if (restaurant.openNow != null || restaurant.closesAt != null)
              Container(
                margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: restaurant.openNow == true 
                      ? [Colors.green.withOpacity(0.1), Colors.green.withOpacity(0.05)]
                      : [Colors.red.withOpacity(0.1), Colors.red.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Open Now with clock icon
                    if (restaurant.openNow != null)
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded, 
                            size: _responsiveFontSize(context, 20), 
                            color: restaurant.openNow == true ? Colors.green : Colors.red,
                          ),
                          SizedBox(width: size.width * 0.02),
                          Text(
                            restaurant.openNow == true ? "Open Now" : "Closed",
                            style: TextStyle(
                              fontSize: _responsiveFontSize(context, 14),
                              fontWeight: FontWeightManager.medium,
                              color: restaurant.openNow == true ? Colors.green : Colors.red,
                              fontFamily: FontFamily.Montserrat,
                            ),
                          ),
                        ],
                      ),
                    
                    // Closing time with fancy styling
                    if (restaurant.closesAt != null)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          "Closes at ${restaurant.closesAt}",
                          style: TextStyle(
                            fontSize: _responsiveFontSize(context, 13),
                            fontWeight: FontWeightManager.medium,
                            color: ColorManager.black,
                            fontFamily: FontFamily.Montserrat,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            
            SizedBox(height: size.height * 0.035),
            
            // Photos Section Title with fancy divider
            Padding(
              padding: EdgeInsets.only(left: horizontalPadding, right: horizontalPadding),
              child: Row(
                children: [
                  Text(
                    "Photos",
                    style: TextStyle(
                      fontSize: _responsiveFontSize(context, 20),
                      fontWeight: FontWeightManager.semiBold,
                      color: ColorManager.black,
                      fontFamily: FontFamily.Montserrat,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            ColorManager.primary.withOpacity(0.3),
                            Colors.transparent,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: size.height * 0.015),
            
            // Photos Grid with Enhanced UI
            _buildPhotoGrid(context, restaurant.imageUrl),
            
            // Owner Information if available
            if (restaurant.ownerName != null && restaurant.ownerName!.isNotEmpty)
              Container(
                margin: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20),
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: ColorManager.primary.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: ColorManager.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person,
                            color: ColorManager.primary,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Restaurant Owner",
                          style: TextStyle(
                            fontSize: _responsiveFontSize(context, 16),
                            fontWeight: FontWeightManager.semiBold,
                            color: ColorManager.black,
                            fontFamily: FontFamily.Montserrat,
                          ),
                        ),
                      ],
                    ),
                    
                    Divider(
                      height: 20,
                      thickness: 1,
                      color: Colors.grey.withOpacity(0.1),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        restaurant.ownerName!,
                        style: TextStyle(
                          fontSize: _responsiveFontSize(context, 16),
                          fontWeight: FontWeightManager.medium,
                          color: ColorManager.black,
                          fontFamily: FontFamily.Montserrat,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            
            // Opening Hours details if available
            if (restaurant.openTimings != null)
              Container(
                margin: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 10),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          color: ColorManager.primary,
                          size: 24,
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Opening Hours",
                          style: TextStyle(
                            fontSize: _responsiveFontSize(context, 18),
                            fontWeight: FontWeightManager.semiBold,
                            color: ColorManager.black,
                            fontFamily: FontFamily.Montserrat,
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 15),
                    
                    _buildOpeningHoursInfo(context, restaurant.openTimings!),
                  ],
                ),
              ),
            
            // Add some bottom padding
            SizedBox(height: size.height * 0.05),
          ],
        ),
      ),
    );
  }
  
  // Build photo grid with enhanced UI
  Widget _buildPhotoGrid(BuildContext context, String? imageUrl) {
    final size = MediaQuery.of(context).size;
    final horizontalPadding = size.width * 0.045;
    
    return SizedBox(
      height: size.width * 0.5,
      child: ListView(
        physics: BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        children: [
          // If restaurant has an image, display it first
          if (imageUrl != null && imageUrl.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(right: size.width * 0.02),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: size.width * 0.6,
                  height: size.width * 0.5,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CachedImage(
                          imageUrl: imageUrl,
                          width: size.width * 0.6,
                          height: size.width * 0.5,
                          fit: BoxFit.cover,
                          placeholder: (context) => Container(
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(ColorManager.primary),
                              ),
                            ),
                          ),
                          errorWidget: (context, error) => Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.restaurant,
                              size: 50,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                      ),
                      // Add a slight gradient overlay at the bottom for depth
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 60,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.5),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Add placeholders for additional photos
          ...List.generate(imageUrl != null && imageUrl.isNotEmpty ? 3 : 4, (index) {
            return Padding(
              padding: EdgeInsets.only(right: size.width * 0.02),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: size.width * 0.6,
                  height: size.width * 0.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.grey[200]!,
                        Colors.grey[300]!,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      _getIconForIndex(index),
                      size: 50,
                      color: Colors.grey[400],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
  
  // Helper method to get different icons for each photo placeholder
  IconData _getIconForIndex(int index) {
    switch (index) {
      case 0: return Icons.restaurant;
      case 1: return Icons.food_bank;
      case 2: return Icons.dinner_dining;
      case 3: return Icons.chair;
      default: return Icons.image;
    }
  }
  
  // Parse and display opening hours with enhanced styling
  Widget _buildOpeningHoursInfo(BuildContext context, String openTimingsJson) {
    try {
      final Map<String, dynamic> timings = Map<String, dynamic>.from(
        json.decode(openTimingsJson.replaceAll("\\", ""))
      );
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: timings.entries.map((entry) {
          final day = _formatDayName(entry.key);
          final hours = entry.value;
          final isToday = _isToday(day);
          
          return Container(
            margin: EdgeInsets.only(bottom: 8),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isToday ? ColorManager.primary.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isToday ? ColorManager.primary.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    day,
                    style: TextStyle(
                      fontSize: _responsiveFontSize(context, 14),
                      fontWeight: isToday ? FontWeightManager.bold : FontWeightManager.medium,
                      fontFamily: FontFamily.Montserrat,
                      color: isToday ? ColorManager.primary : ColorManager.black,
                    ),
                  ),
                ),
                Text(
                  hours,
                  style: TextStyle(
                    fontSize: _responsiveFontSize(context, 14),
                    fontWeight: isToday ? FontWeightManager.medium : FontWeightManager.regular,
                    fontFamily: FontFamily.Montserrat,
                    color: isToday ? ColorManager.primary : ColorManager.black,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    } catch (e) {
      debugPrint('Error parsing opening hours: $e');
      return Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.red[400],
              size: 20,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Opening hours information unavailable",
                style: TextStyle(
                  fontSize: _responsiveFontSize(context, 14),
                  fontWeight: FontWeightManager.regular,
                  color: Colors.red[800],
                  fontFamily: FontFamily.Montserrat,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
  
  // Check if day is today
  bool _isToday(String day) {
    final now = DateTime.now();
    final weekday = now.weekday;
    
    switch (day.toLowerCase()) {
      case 'monday': return weekday == 1;
      case 'tuesday': return weekday == 2;
      case 'wednesday': return weekday == 3;
      case 'thursday': return weekday == 4;
      case 'friday': return weekday == 5;
      case 'saturday': return weekday == 6;
      case 'sunday': return weekday == 7;
      default: return false;
    }
  }
  
  // Format day abbreviation to full name
  String _formatDayName(String day) {
    switch (day.toLowerCase()) {
      case 'mon': return 'Monday';
      case 'tue': return 'Tuesday';
      case 'wed': return 'Wednesday';
      case 'thu': return 'Thursday';
      case 'fri': return 'Friday';
      case 'sat': return 'Saturday';
      case 'sun': return 'Sunday';
      default: return day;
    }
  }
  
  // Helper method for responsive font sizing
  double _responsiveFontSize(BuildContext context, double size) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Base width for calculations
    const baseWidth = 390.0;
    return size * (screenWidth / baseWidth);
  }
}
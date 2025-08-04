import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/color/colorConstant.dart';
import '../../constants/font/fontManager.dart';
import '../../models/restaurant_model.dart';
import '../../utils/timezone_utils.dart';
import '../../widgets/veg_nonveg_icons.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';

class RestaurantProfileView extends StatefulWidget {
  final String restaurantId;
  final double? userLatitude;
  final double? userLongitude;

  const RestaurantProfileView({
    Key? key,
    required this.restaurantId,
    this.userLatitude,
    this.userLongitude,
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
          LoadRestaurantProfile(
            restaurantId: widget.restaurantId,
            userLatitude: widget.userLatitude,
            userLongitude: widget.userLongitude,
          ),
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
                child: const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(
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
                            LoadRestaurantProfile(
                              restaurantId: widget.restaurantId,
                              userLatitude: widget.userLatitude,
                              userLongitude: widget.userLongitude,
                            ),
                          );
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh, size: 18),
                        SizedBox(width: 8),
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
    final Restaurant restaurant = state.restaurant;
    
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 3,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(8.0),
                  child: const Icon(Icons.arrow_back),
                ),
              ),
            ),
            
            // Restaurant header section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant name
                  Text(
                    restaurant.name,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  
                  // Cuisine type
                  Text(
                    restaurant.cuisine,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Address
                  Text(
                    restaurant.address,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            
            const Divider(),
            
            // Restaurant badges section (distance, rating, veg status)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Distance badge
                  if (state.calculatedDistance != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue[300]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.place_outlined, color: Colors.blue[800], size: 16),
                          const SizedBox(width: 4),
                          Text(
                            state.calculatedDistance!,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.blue[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  const SizedBox(width: 8),
                  
                  // Veg/Non-veg badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: restaurant.isVeg ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        restaurant.isVeg 
                          ? VegNonVegIcons.vegIcon(
                              size: 14,
                              color: Colors.green,
                              borderColor: Colors.white,
                            )
                          : VegNonVegIcons.nonVegIcon(
                              size: 14,
                              color: Colors.orange,
                              borderColor: Colors.white,
                            ),
                        const SizedBox(width: 4),
                        Text(
                          restaurant.isVeg ? "Pure Veg" : "Non-Veg",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: restaurant.isVeg ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Rating badge (if available)
                  if (restaurant.rating != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 2),
                          Text(
                            "${restaurant.rating}",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.amber[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            
            // Opening hours section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: restaurant.openNow == true ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    restaurant.openNow == true ? "Open Now" : "Closed",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: restaurant.openNow == true ? Colors.green : Colors.red,
                    ),
                  ),
                  if (restaurant.closesAt != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      "Closes at ${restaurant.closesAt}",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ]
                ],
              ),
            ),
            
            // PROMINENT DISTANCE DISPLAY
            if (state.calculatedDistance != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.directions,
                      color: Colors.blue[700],
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Distance",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                          ),
                          Text(
                            state.calculatedDistance!,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            
            // Vegetarian status
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            //   child: Row(
            //     children: [
            //       Icon(
            //         restaurant.isVeg ? Icons.eco : Icons.restaurant,
            //         color: restaurant.isVeg ? Colors.green : Colors.orange,
            //         size: 20,
            //       ),
            //       // const SizedBox(width: 8),
            //       // Text(
            //       //   restaurant.isVeg ? "Pure Vegetarian" : "Non-Vegetarian Available",
            //       //   style: GoogleFonts.poppins(
            //       //     fontSize: 14,
            //       //     color: restaurant.isVeg ? Colors.green[700] : Colors.orange[700],
            //       //     fontWeight: FontWeight.w500,
            //       //   ),
            //       // ),
            //     ],
            //   ),
            // ),
            
            // Opening days section
            if (restaurant.openTimings != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _buildOpeningDays(restaurant.openTimings!),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Additional Restaurant Information
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Additional Information",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Rating if available
                    if (restaurant.rating != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Rating: ${restaurant.rating}/5",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    
                    // Owner information if available
                    if (restaurant.ownerName != null && restaurant.ownerName!.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            color: Colors.purple[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Owner: ${restaurant.ownerName}",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const Divider(height: 32),
            
            // Photos section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Photos",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Photo grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildPhotoGrid(restaurant),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPhotoGrid(Restaurant restaurant) {
    // Use actual restaurant photos if available
    final photos = restaurant.photos;
    
    if (photos.isEmpty) {
      // Show placeholder if no photos available
      return GridView.count(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: [
          _buildPhotoItem('assets/interior.jpg', 'Interior'),
          _buildPhotoItem('assets/food1.jpg', 'Food'),
          _buildPhotoItem('assets/food2.jpg', 'Food'),
          _buildPhotoItem('assets/outdoor.jpg', 'Outdoor'),
        ],
      );
    }
    
    // Show actual restaurant photos
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: photos.map((photoUrl) {
        return _buildPhotoItem(photoUrl, 'Restaurant');
      }).toList(),
    );
  }
  
  Widget _buildPhotoItem(String imageUrl, String label) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Check if it's a network URL or asset
          imageUrl.startsWith('http') || imageUrl.startsWith('https')
              ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: Icon(
                        Icons.restaurant,
                        size: 40,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                )
              : Image.asset(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: Center(
                      child: Icon(
                        label == 'Interior' || label == 'Outdoor' 
                            ? Icons.restaurant 
                            : Icons.restaurant_menu,
                        size: 40,
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              color: Colors.black.withOpacity(0.6),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildOpeningDays(String openTimingsJson) {
    try {
      final Map<String, dynamic> timings = Map<String, dynamic>.from(
        json.decode(openTimingsJson.replaceAll("\\", ""))
      );
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Opening Hours",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          ...timings.entries.map((entry) {
            final day = _formatDayName(entry.key);
            final hours = entry.value;
            final isToday = _isToday(day);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      day,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday ? Colors.green : Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    hours,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      );
    } catch (e) {
      return Text(
        "Opening hours information unavailable",
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.red,
        ),
      );
    }
  }
  
  // Helper method to check if day is today
  bool _isToday(String day) {
    final now = TimezoneUtils.getCurrentTimeIST();
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
}
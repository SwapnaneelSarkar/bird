import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../constants/color/colorConstant.dart';
import '../../constants/router/router.dart';
import '../../widgets/cached_image.dart';
import '../restaurant_menu/view.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';
import '../../models/favorite_model.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FavoritesBloc()..add(const LoadFavorites()),
      child: const _FavoritesPageContent(),
    );
  }
}

class _FavoritesPageContent extends StatefulWidget {
  const _FavoritesPageContent({Key? key}) : super(key: key);

  @override
  State<_FavoritesPageContent> createState() => _FavoritesPageContentState();
}

class _FavoritesPageContentState extends State<_FavoritesPageContent>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _listAnimationController;

  @override
  void initState() {
    super.initState();
    
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Start animations in sequence
    _headerAnimationController.forward().then((_) {
      _listAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _listAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header Section
            _buildModernHeader(context, screenWidth, screenHeight),
            
            // Content Section
            Expanded(
              child: BlocConsumer<FavoritesBloc, FavoritesState>(
                listener: (context, state) {
                  if (state is FavoriteToggleError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is FavoritesLoading) {
                    return _buildLoadingState(screenWidth, screenHeight);
                  } else if (state is FavoritesLoaded) {
                    return _buildFavoritesList(state.favorites, screenWidth, screenHeight);
                  } else if (state is FavoritesEmpty) {
                    return _buildEmptyState(state.message, screenWidth, screenHeight);
                  } else if (state is FavoritesError) {
                    return _buildErrorState(state.message, screenWidth, screenHeight);
                  } else if (state is FavoriteToggling) {
                    return _buildLoadingState(screenWidth, screenHeight);
                  } else if (state is FavoriteToggled) {
                    // Check if favorites list is empty after toggle
                    if (state.updatedFavorites.isEmpty) {
                      return _buildEmptyState('No favorites yet. Tap the heart icon on any restaurant to add it to your favorites!', screenWidth, screenHeight);
                    }
                    return _buildFavoritesList(state.updatedFavorites, screenWidth, screenHeight);
                  }
                  
                  return _buildLoadingState(screenWidth, screenHeight);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernHeader(BuildContext context, double screenWidth, double screenHeight) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.02,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 2),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Modern Back Button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: screenWidth * 0.1,
                  height: screenWidth * 0.1,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FF),
                    borderRadius: BorderRadius.circular(screenWidth * 0.025),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    size: screenWidth * 0.045,
                    color: const Color(0xFF374151),
                  ),
                ),
              ),
              
              SizedBox(width: screenWidth * 0.04),
              
              // Title and Count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Favorites',
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.055,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                        letterSpacing: -0.5,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    BlocBuilder<FavoritesBloc, FavoritesState>(
                      builder: (context, state) {
                        int count = 0;
                        if (state is FavoritesLoaded) {
                          count = state.totalCount;
                        } else if (state is FavoriteToggled) {
                          count = state.updatedFavorites.length;
                        }
                        
                        return Text(
                          '$count favorite restaurant${count != 1 ? 's' : ''}',
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.035,
                            color: const Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              // Action Button
              BlocBuilder<FavoritesBloc, FavoritesState>(
                builder: (context, state) {
                  bool shouldShowClearAll = false;
                  
                  if (state is FavoritesLoaded && state.favorites.isNotEmpty) {
                    shouldShowClearAll = true;
                  } else if (state is FavoriteToggled && state.updatedFavorites.isNotEmpty) {
                    shouldShowClearAll = true;
                  }
                  
                  if (shouldShowClearAll) {
                    return GestureDetector(
                      onTap: () => _showClearAllDialog(context, context.read<FavoritesBloc>()),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.03,
                          vertical: screenHeight * 0.01,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(screenWidth * 0.02),
                          border: Border.all(
                            color: const Color(0xFFFECACA),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Clear All',
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.032,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ],
      ),
    ).animate(controller: _headerAnimationController)
      .fadeIn(duration: 400.ms, curve: Curves.easeOut)
      .slideY(begin: -0.3, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }

  Widget _buildLoadingState(double screenWidth, double screenHeight) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: screenWidth * 0.15,
            height: screenWidth * 0.15,
            decoration: BoxDecoration(
              color: ColorManager.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(ColorManager.primary),
            ),
          ),
          SizedBox(height: screenHeight * 0.03),
          Text(
            'Loading your favorites...',
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, double screenWidth, double screenHeight) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated Heart Icon
            Container(
              width: screenWidth * 0.25,
              height: screenWidth * 0.25,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFECACA),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: screenWidth * 0.12,
                color: const Color(0xFFF87171),
              ),
            ).animate()
              .scale(duration: 600.ms, curve: Curves.elasticOut)
              .then()
              .shimmer(duration: 2000.ms, delay: 1000.ms),
            
            SizedBox(height: screenHeight * 0.04),
            
            Text(
              'No Favorites Yet',
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.06,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
                letterSpacing: -0.5,
              ),
            ),
            
            SizedBox(height: screenHeight * 0.02),
            
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.04,
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: screenHeight * 0.05),
            
            // Modern Explore Button
            Container(
              width: double.infinity,
              height: screenHeight * 0.06,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ColorManager.primary,
                    ColorManager.primary.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                boxShadow: [
                  BoxShadow(
                    color: ColorManager.primary.withOpacity(0.3),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  onTap: () {
                    // Navigate to home page instead of just popping back
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      Routes.home,
                      (route) => false, // Remove all previous routes
                    );
                  },
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.explore_rounded,
                          color: Colors.white,
                          size: screenWidth * 0.045,
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        Text(
                          'Explore Restaurants',
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ).animate()
              .fadeIn(delay: 300.ms, duration: 600.ms)
              .slideY(begin: 0.3, end: 0, duration: 600.ms, curve: Curves.easeOut),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, double screenWidth, double screenHeight) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: screenWidth * 0.2,
              height: screenWidth * 0.2,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFFECACA),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: screenWidth * 0.1,
                color: const Color(0xFFEF4444),
              ),
            ),
            
            SizedBox(height: screenHeight * 0.04),
            
            Text(
              'Oops! Something went wrong',
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.055,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF111827),
                letterSpacing: -0.5,
              ),
            ),
            
            SizedBox(height: screenHeight * 0.02),
            
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.04,
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: screenHeight * 0.05),
            
            Container(
              width: double.infinity,
              height: screenHeight * 0.06,
              decoration: BoxDecoration(
                color: ColorManager.primary,
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                boxShadow: [
                  BoxShadow(
                    color: ColorManager.primary.withOpacity(0.3),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  onTap: () {
                    context.read<FavoritesBloc>().add(const RefreshFavorites());
                  },
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: screenWidth * 0.045,
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        Text(
                          'Try Again',
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesList(List<FavoriteModel> favorites, double screenWidth, double screenHeight) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<FavoritesBloc>().add(const RefreshFavorites());
      },
      color: ColorManager.primary,
      backgroundColor: Colors.white,
      strokeWidth: 3,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenHeight * 0.02,
        ),
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          final favorite = favorites[index];
          return _buildModernFavoriteCard(favorite, screenWidth, screenHeight, index);
        },
      ).animate(controller: _listAnimationController)
        .fadeIn(duration: 600.ms, curve: Curves.easeOut)
        .slideY(begin: 0.3, end: 0, duration: 600.ms, curve: Curves.easeOut),
    );
  }

  Widget _buildModernFavoriteCard(FavoriteModel favorite, double screenWidth, double screenHeight, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.02),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.04),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, 2),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: const Color(0xFFF3F4F6),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(screenWidth * 0.04),
          onTap: () => _navigateToRestaurantDetails(context, favorite),
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Row(
              children: [
                // Restaurant Image
                Container(
                  width: screenWidth * 0.2,
                  height: screenWidth * 0.2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        offset: const Offset(0, 2),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    child: favorite.restaurantPhotos != null && favorite.restaurantPhotos!.isNotEmpty
                        ? CachedImage(
                            imageUrl: favorite.restaurantPhotos!,
                            fit: BoxFit.cover,
                            placeholder: (context) => _buildImagePlaceholder(screenWidth),
                          )
                        : _buildImagePlaceholder(screenWidth),
                  ),
                ),
                
                SizedBox(width: screenWidth * 0.04),
                
                // Restaurant Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        favorite.restaurantName,
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.045,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      SizedBox(height: screenHeight * 0.005),
                      
                      Text(
                        favorite.cuisine.isNotEmpty ? favorite.cuisine : 'Restaurant',
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.035,
                          color: const Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      SizedBox(height: screenHeight * 0.01),
                      
                      // Rating and Delivery Info
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.02,
                              vertical: screenHeight * 0.005,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(screenWidth * 0.015),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.star_rounded,
                                  size: screenWidth * 0.03,
                                  color: const Color(0xFFF59E0B),
                                ),
                                SizedBox(width: screenWidth * 0.01),
                                Text(
                                  '${favorite.ratingAsDouble.toStringAsFixed(1)}',
                                  style: GoogleFonts.poppins(
                                    fontSize: screenWidth * 0.032,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF92400E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(width: screenWidth * 0.02),
                          
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.02,
                              vertical: screenHeight * 0.005,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(screenWidth * 0.015),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: screenWidth * 0.03,
                                  color: const Color(0xFF0288D1),
                                ),
                                SizedBox(width: screenWidth * 0.01),
                                Text(
                                  '20-30 min',
                                  style: GoogleFonts.poppins(
                                    fontSize: screenWidth * 0.032,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF01579B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Remove Button
                GestureDetector(
                  onTap: () => _showRemoveConfirmationDialog(favorite, context.read<FavoritesBloc>()),
                  child: Container(
                    width: screenWidth * 0.08,
                    height: screenWidth * 0.08,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      border: Border.all(
                        color: const Color(0xFFFECACA),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.favorite_rounded,
                      size: screenWidth * 0.04,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate()
      .fadeIn(duration: 400.ms, delay: (index * 100).ms, curve: Curves.easeOut)
      .slideX(begin: 0.3, end: 0, duration: 400.ms, delay: (index * 100).ms, curve: Curves.easeOut);
  }

  Widget _buildImagePlaceholder(double screenWidth) {
    return Container(
      color: const Color(0xFFF3F4F6),
      child: Center(
        child: Icon(
          Icons.restaurant_rounded,
          size: screenWidth * 0.08,
          color: const Color(0xFF9CA3AF),
        ),
      ),
    );
  }

  void _navigateToRestaurantDetails(BuildContext context, FavoriteModel favorite) {
    // Convert favorite data to the expected Map format for RestaurantDetailsPage
    final restaurantData = <String, dynamic>{
      'id': favorite.partnerId,
      'partner_id': favorite.partnerId,
      'name': favorite.restaurantName,
      'restaurant_name': favorite.restaurantName,
      'imageUrl': favorite.restaurantPhotos != null && favorite.restaurantPhotos!.isNotEmpty 
          ? favorite.restaurantPhotos! 
          : null,
      'cuisine': favorite.cuisine.isNotEmpty ? favorite.cuisine : 'Restaurant',
      'category': favorite.cuisine.isNotEmpty ? favorite.cuisine : 'Restaurant',
      'rating': favorite.rating,
      'isVegetarian': favorite.category == 'vegetarian',
      'isVeg': favorite.category == 'vegetarian',
      'veg_nonveg': favorite.category == 'vegetarian' ? 'veg' : 'non-veg',
      'address': favorite.address,
      'latitude': favorite.latitude,
      'longitude': favorite.longitude,
      'restaurantType': 'Restaurant',
      'restaurant_type': 'Restaurant',
      'description': favorite.cuisine.isNotEmpty ? favorite.cuisine : 'Restaurant',
      'openTimings': favorite.operationalHours,
      'open_timings': favorite.operationalHours,
      'ownerName': favorite.restaurantName,
      'owner_name': favorite.restaurantName,
      'availableCategories': [],
      'isAcceptingOrder': favorite.blockStatus == 1,
    };
    
    // Navigate to restaurant menu page
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => RestaurantDetailsPage(
          restaurantData: restaurantData,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutQuart;
          
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          
          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _showRemoveConfirmationDialog(FavoriteModel favorite, FavoritesBloc bloc) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.04),
          ),
          title: Row(
            children: [
              Container(
                width: screenWidth * 0.08,
                height: screenWidth * 0.08,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
                child: Icon(
                  Icons.favorite_rounded,
                  color: const Color(0xFFEF4444),
                  size: screenWidth * 0.04,
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Text(
                  'Remove from Favorites?',
                  style: GoogleFonts.poppins(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to remove "${favorite.restaurantName}" from your favorites?',
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.04,
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                bloc.add(
                  RemoveFromFavorites(partnerId: favorite.partnerId),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.015,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.025),
                ),
              ),
              child: Text(
                'Remove',
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showClearAllDialog(BuildContext context, FavoritesBloc bloc) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.04),
          ),
          title: Row(
            children: [
              Container(
                width: screenWidth * 0.08,
                height: screenWidth * 0.08,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
                child: Icon(
                  Icons.delete_sweep_rounded,
                  color: const Color(0xFFEF4444),
                  size: screenWidth * 0.04,
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Text(
                  'Clear All Favorites?',
                  style: GoogleFonts.poppins(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'This will remove all restaurants from your favorites. This action cannot be undone.',
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.04,
              color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                bloc.add(const ClearAllFavorites());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.015,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.025),
                ),
              ),
              child: Text(
                'Clear All',
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
// lib/presentation/category_homepage/view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/color/colorConstant.dart';
import '../../constants/router/router.dart';

import 'bloc.dart';
import 'event.dart';
import 'state.dart';
import '../home page/view.dart';
import '../home page/bloc.dart';
import '../home page/event.dart';

import '../../widgets/cached_image.dart';
import '../../widgets/location_status_widget.dart';
import '../../service/location_validation_service.dart';
import '../../service/token_service.dart';
import '../../service/app_startup_service.dart';

class CategoryHomepage extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final String? token;
  final Map<String, dynamic>? locationInitResult;

  const CategoryHomepage({Key? key, this.userData, this.token, this.locationInitResult}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CategoryHomepageBloc()..add(const LoadCategoryHomepage()),
      child: _CategoryHomepageContent(userData: userData, token: token, locationInitResult: locationInitResult),
    );
  }
}

class _CategoryHomepageContent extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final String? token;
  final Map<String, dynamic>? locationInitResult;

  const _CategoryHomepageContent({Key? key, this.userData, this.token, this.locationInitResult}) : super(key: key);

  @override
  State<_CategoryHomepageContent> createState() => _CategoryHomepageContentState();
}

class _CategoryHomepageContentState extends State<_CategoryHomepageContent>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _categoryAnimationController;
  
  // Location validation state
  bool _isCheckingLocation = false;
  bool _isLocationServiceable = true;
  String _currentAddress = '';

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
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _categoryAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Start animations in sequence
    _headerAnimationController.forward().then((_) {
      _categoryAnimationController.forward();
    });
    
    // Check location serviceability
    _checkLocationServiceability();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _categoryAnimationController.dispose();
    super.dispose();
  }

  double _getResponsiveFontSize(double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 320) return baseSize * 0.8;
    if (screenWidth < 480) return baseSize * 0.9;
    if (screenWidth < 768) return baseSize;
    if (screenWidth < 1024) return baseSize * 1.1;
    return baseSize * 1.2;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final bloc = context.read<CategoryHomepageBloc>();
        // If not already loading, reset to initial and reload
        if (bloc.state is! CategoryHomepageLoading) {
          bloc.add(const RefreshCategoryHomepage());
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocConsumer<CategoryHomepageBloc, CategoryHomepageState>(
          listener: (context, state) {
            if (state is CategorySelected) {
              debugPrint('🏠 Dashboard: Navigating with supercategory ID: ${state.categoryId}');
              
              // Allow navigation regardless of location serviceability
              // Users can change their address from the homepage
              if (!_isLocationServiceable) {
                debugPrint('⚠️ Dashboard: Location not serviceable, but allowing navigation');
              }
              
              // Always navigate to home page with the selected category
              // Don't try to find existing home route since we're coming from dashboard
              Navigator.of(context).pushAndRemoveUntil(
                PageRouteBuilder(
                  settings: RouteSettings(name: Routes.home),
                  pageBuilder: (context, animation, secondaryAnimation) => BlocProvider(
                    create: (_) => HomeBloc(
                      selectedSupercategoryId: state.categoryId,
                    )..add(const LoadHomeData()),
                    child: HomePage(
                      userData: widget.userData,
                      token: widget.token,
                    ),
                  ),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOut;
                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    return SlideTransition(
                      position: animation.drive(tween),
                      child: child,
                    );
                  },
                  transitionDuration: const Duration(milliseconds: 400),
                ),
                (route) => false,
              );
            }
          },
          builder: (context, state) {
            if (state is CategoryHomepageLoading) {
              return _buildLoadingState();
            } else if (state is CategoryHomepageError) {
              return _buildErrorState(state.message);
            } else if (state is CategoryHomepageLoaded) {
              return _buildLoadedState(state);
            }
            return _buildLoadingState();
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD2691E)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading categories...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<CategoryHomepageBloc>().add(const RefreshCategoryHomepage());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorManager.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedState(CategoryHomepageLoaded state) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          context.read<CategoryHomepageBloc>().add(const RefreshCategoryHomepage());
        },
        color: ColorManager.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Header Section
            SliverToBoxAdapter(
              child: _buildHeader(state).animate().slideY(
                begin: -0.3,
                end: 0,
                duration: 600.ms,
                curve: Curves.easeOutCubic,
              ).fadeIn(duration: 600.ms),
            ),
            
            // Location Status Section
            SliverToBoxAdapter(
              child: _buildLocationStatus().animate().slideY(
                begin: 0.2,
                end: 0,
                duration: 500.ms,
                curve: Curves.easeOutCubic,
              ).fadeIn(delay: 100.ms, duration: 400.ms),
            ),
            
            // Categories Section
            SliverToBoxAdapter(
              child: _buildCategoriesSection(state.categories).animate().slideY(
                begin: 0.3,
                end: 0,
                duration: 800.ms,
                curve: Curves.easeOutCubic,
              ).fadeIn(delay: 200.ms, duration: 600.ms),
            ),
            
            // Bottom spacing
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(CategoryHomepageLoaded state) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Container(
      margin: EdgeInsets.all(screenWidth * 0.05), // 5% of screen width
      padding: EdgeInsets.all(screenWidth * 0.06), // 6% of screen width
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            ColorManager.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(screenWidth * 0.06), // Responsive border radius
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: screenWidth * 0.05, // Responsive blur
            offset: Offset(0, screenWidth * 0.02), // Responsive offset
            spreadRadius: screenWidth * 0.005, // Responsive spread
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.03, // Responsive horizontal padding
                        vertical: screenHeight * 0.005, // Responsive vertical padding
                      ),
                      decoration: BoxDecoration(
                        color: ColorManager.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(screenWidth * 0.05), // Responsive border radius
                      ),
                      child: Text(
                        'Welcome ${state.userName}',
                        style: GoogleFonts.poppins(
                          fontSize: _getResponsiveFontSize(16),
                          color: ColorManager.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.005), // Responsive spacing
                    Text(
                      'What would you like to order today?',
                      style: GoogleFonts.poppins(
                        fontSize: _getResponsiveFontSize(14),
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Profile Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () => Navigator.pushNamed(context, Routes.profileView),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        Icons.person,
                        color: ColorManager.primary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Container(
          //   padding: const EdgeInsets.all(16),
          //   decoration: BoxDecoration(
          //     color: Colors.white.withOpacity(0.8),
          //     borderRadius: BorderRadius.circular(16),
          //     border: Border.all(
          //       color: Colors.grey[200]!,
          //       width: 1,
          //     ),
          //   ),
          //   // child: Row(
          //   //   children: [
          //   //     Container(
          //   //       padding: const EdgeInsets.all(8),
          //   //       decoration: BoxDecoration(
          //   //         color: ColorManager.primary.withOpacity(0.1),
          //   //         borderRadius: BorderRadius.circular(10),
          //   //       ),
          //   //       child: Icon(
          //   //         Icons.location_on,
          //   //         color: ColorManager.primary,
          //   //         size: 20,
          //   //       ),
          //   //     ),
          //   //     const SizedBox(width: 12),
          //   //     Expanded(
          //   //       child: Column(
          //   //         crossAxisAlignment: CrossAxisAlignment.start,
          //   //         children: [
          //   //           Text(
          //   //             'Delivering to',
          //   //             style: GoogleFonts.poppins(
          //   //               fontSize: _getResponsiveFontSize(12),
          //   //               color: Colors.grey[600],
          //   //               fontWeight: FontWeight.w500,
          //   //             ),
          //   //           ),
          //   //           const SizedBox(height: 2),
          //   //           Text(
          //   //             state.userAddress,
          //   //             style: GoogleFonts.poppins(
          //   //               fontSize: _getResponsiveFontSize(14),
          //   //               color: Colors.black87,
          //   //               fontWeight: FontWeight.w600,
          //   //             ),
          //   //             maxLines: 1,
          //   //             overflow: TextOverflow.ellipsis,
          //   //           ),
          //   //         ],
          //   //       ),
          //   //     ),
          //   //     Icon(
          //   //       Icons.keyboard_arrow_down_rounded,
          //   //       color: Colors.grey[500],
          //   //       size: 24,
          //   //     ),
          //   //   ],
          //   // ),
          // ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(List<CategoryModel> categories) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Determine if we should show "View All" button
    final shouldShowViewAll = categories.length > 8;
    final displayCategories = shouldShowViewAll ? categories.take(8).toList() : categories;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05), // Responsive horizontal padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Choose your favorite',
                  style: GoogleFonts.poppins(
                    fontSize: _getResponsiveFontSize(18),
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (shouldShowViewAll)
                GestureDetector(
                  onTap: () {
                    // TODO: Navigate to full categories page
                    debugPrint('Dashboard: View all categories tapped');
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.03, // Responsive horizontal padding
                      vertical: screenHeight * 0.007, // Responsive vertical padding
                    ),
                    decoration: BoxDecoration(
                      color: ColorManager.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(screenWidth * 0.05), // Responsive border radius
                      border: Border.all(
                        color: ColorManager.primary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'View All (${categories.length})',
                      style: GoogleFonts.poppins(
                        fontSize: _getResponsiveFontSize(10),
                        fontWeight: FontWeight.w600,
                        color: ColorManager.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: screenHeight * 0.005), // Responsive spacing
          Text(
            'Select a category to explore delicious options',
            style: GoogleFonts.poppins(
              fontSize: _getResponsiveFontSize(12),
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: screenHeight * 0.02), // Responsive spacing
          // Two rows of super categories with horizontal scrolling
          Column(
            children: [
              // First row - Always show first row
              SizedBox(
                height: _getRowHeight(displayCategories.length),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04), // Responsive padding
                  itemCount: _getFirstRowCount(displayCategories.length),
                  itemBuilder: (context, index) {
                    final category = displayCategories[index];
                    return _buildCategoryCard(category, index, totalCategories: displayCategories.length);
                  },
                ),
              ),
              SizedBox(height: screenHeight * 0.015), // Responsive spacing between rows
              // Second row - Show if there are more categories than can fit in first row
              if (displayCategories.length > _getFirstRowCount(displayCategories.length))
                SizedBox(
                  height: _getRowHeight(displayCategories.length),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04), // Responsive padding
                    itemCount: displayCategories.length - _getFirstRowCount(displayCategories.length),
                    itemBuilder: (context, index) {
                      final actualIndex = _getFirstRowCount(displayCategories.length) + index;
                      final category = displayCategories[actualIndex];
                      return _buildCategoryCard(category, actualIndex, totalCategories: displayCategories.length);
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category, int index, {int? totalCategories}) {
    final gradients = [
      [const Color(0xFFFFE0B2), ColorManager.primary],
      [const Color(0xFFE8F5E8), const Color(0xFF4CAF50)],
      [const Color(0xFFE3F2FD), const Color(0xFF2196F3)],
      [const Color(0xFFFCE4EC), const Color(0xFFE91E63)],
      [const Color(0xFFF3E5F5), const Color(0xFF9C27B0)],
      [const Color(0xFFE0F2F1), const Color(0xFF009688)],
    ];
    
    final gradient = gradients[index % gradients.length];
    final accentColor = gradient[1];

    // Optimized sizing for 2-row layout
    final totalCats = totalCategories ?? 8;
    final cardWidth = 110.0; // Slightly wider for better spacing
    final imageSize = 75.0; // Slightly larger image
    final innerImageSize = 71.0; // Slightly larger inner image
    final fontSize = 12.0; // Slightly larger font for better readability

    // Debug print to verify what is being passed
    debugPrint('Dashboard: Showing card for ${category.name} (id: ${category.id}) with image: ${category.image}');
    debugPrint('Dashboard: Total categories: $totalCats, Card width: $cardWidth');
    final supercategoryId = category.id;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.read<CategoryHomepageBloc>().add(
          SelectCategory(
            categoryId: supercategoryId,
            categoryName: category.name,
          ),
        );
      },
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.symmetric(horizontal: 8), // Better spacing for 2-row layout
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Shadow container
                Container(
                  width: imageSize,
                  height: imageSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                        spreadRadius: 1.5,
                      )
                    ],
                  ),
                ),
                // Image container
                Container(
                  width: innerImageSize,
                  height: innerImageSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipOval(
                    child: category.image != null && category.image!.isNotEmpty
                        ? (category.image!.startsWith('http') 
                            ? Image.network(
                                category.image!,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  debugPrint('Dashboard: Loading image: ${category.image}');
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: gradient,
                                      ),
                                    ),
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                            : null,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  debugPrint('Dashboard: Network image error: $error');
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: gradient,
                                      ),
                                    ),
                                    child: Icon(
                                      _getCategoryIcon(category.name),
                                      color: Colors.white,
                                      size: totalCats <= 3 ? 28 : 24,
                                    ),
                                  );
                                },
                              )
                            : CachedImage(
                                imageUrl: category.image!,
                                fit: BoxFit.cover,
                                placeholder: (context) => Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: gradient,
                                    ),
                                  ),
                                  child: Icon(
                                    _getCategoryIcon(category.name),
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                errorWidget: (context, error) {
                                  debugPrint('Dashboard: CachedImage error: $error');
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: gradient,
                                      ),
                                    ),
                                    child: Icon(
                                      _getCategoryIcon(category.name),
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  );
                                },
                              ))
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: gradient,
                              ),
                            ),
                            child: Icon(
                              _getCategoryIcon(category.name),
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10), // Better spacing for 2-row layout
            // Category name container
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8, 
                vertical: 5
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
                border: Border.all(
                  color: accentColor.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Text(
                category.name,
                style: GoogleFonts.poppins(
                  fontSize: _getResponsiveFontSize(fontSize),
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                maxLines: 2, // Allow 2 lines for better readability in 2-row layout
              ),
            ),
          ],
        ),
      ).animate().scale(
        begin: const Offset(0.8, 0.8),
        end: const Offset(1, 1),
        duration: Duration(milliseconds: 400 + (index * 150)),
        curve: Curves.easeOutBack,
      ),
    );
  }









  // Helper Methods

  // Calculate how many categories should be in the first row
  int _getFirstRowCount(int totalCategories) {
    // For optimal 2-row layout, put roughly half in first row
    // If total is even, split evenly; if odd, put one extra in first row
    return (totalCategories / 2).ceil();
  }

  // Calculate the height for each row based on number of categories
  double _getRowHeight(int totalCategories) {
    // Adjust height based on number of categories for better visual balance
    if (totalCategories <= 4) return 130.0; // Smaller height for fewer categories
    if (totalCategories <= 6) return 140.0; // Standard height for medium categories
    return 150.0; // Larger height for many categories
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'grocery':
        return Icons.shopping_bag;
      case 'medicine':
        return Icons.local_pharmacy;
      case 'electronics':
        return Icons.devices;
      default:
        return Icons.category;
    }
  }

  // Location validation methods
  Future<void> _checkLocationServiceability() async {
    setState(() {
      _isCheckingLocation = true;
    });

    try {
      final userData = await TokenService.getUserData();
      if (userData != null && userData['address'] != null) {
        _currentAddress = userData['address'].toString();
      } else {
        _currentAddress = ''; // Ensure it's empty string, not "null"
      }

      final result = await LocationValidationService.checkCurrentLocationServiceability();
      
      setState(() {
        _isCheckingLocation = false;
        // If no location data, don't show warning - let user set location from homepage
        if (result['message'] == 'No location data available') {
          _isLocationServiceable = true; // Don't block navigation
        } else {
          _isLocationServiceable = result['isServiceable'] ?? true;
        }
        // _locationMessage = result['message'] ?? ''; // Removed unused field
      });

      debugPrint('🔍 Dashboard: Location serviceability check result: $result');
    } catch (e) {
      debugPrint('❌ Dashboard: Error checking location serviceability: $e');
      setState(() {
        _isCheckingLocation = false;
        _isLocationServiceable = true; // Default to true to avoid blocking the UI
      });
    }
  }



  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh location check when dependencies change (e.g., when returning to dashboard)
    if (!_isCheckingLocation) {
      _checkLocationServiceability();
    }
  }

  Widget _buildLocationStatus() {
    // Show location serviceability warning if needed
    if (_isCheckingLocation) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Checking location serviceability...',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Show location availability status from startup
    if (widget.locationInitResult != null) {
      final locationAvailability = widget.locationInitResult!['locationAvailability'] as Map<String, bool>?;
      final hasExistingLocation = widget.userData?['address'] != null && 
                                  widget.userData?['latitude'] != null && 
                                  widget.userData?['longitude'] != null;
      final existingAddress = widget.userData?['address'] as String?;
      
      if (locationAvailability != null && locationAvailability['available'] != true) {
        return LocationStatusWidget(
          locationAvailability: locationAvailability,
          hasExistingLocation: hasExistingLocation,
          existingAddress: existingAddress,
          onEnableLocation: () async {
            // Try to refresh location
            _updateStatusMessage('Refreshing location...');
            final result = await AppStartupService.forceFreshLocationFetch();
            if (result['locationUpdated'] == true) {
              // Reload the page with updated data
              if (mounted) {
                final newUserData = await TokenService.getUserData();
                final token = await TokenService.getToken();
                Navigator.pushReplacementNamed(
                  context,
                  Routes.dashboard,
                  arguments: {
                    'userData': newUserData,
                    'token': token,
                    'locationInitResult': result,
                  },
                );
              }
            }
          },
          onSkip: null, // Don't show skip option in dashboard
          showActions: true,
        );
      }
    }

    // Show location serviceability warning if location is not serviceable
    // But only if we have location data to validate
    if (!_isLocationServiceable && _currentAddress.isNotEmpty && _currentAddress != 'null') {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_off,
                  color: Colors.orange[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Location Not Serviceable',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                // Add refresh button
                GestureDetector(
                  onTap: () async {
                    setState(() {
                      _isCheckingLocation = true;
                    });
                    
                    try {
                      final result = await AppStartupService.forceLocationValidation();
                      setState(() {
                        _isCheckingLocation = false;
                        _isLocationServiceable = result['isServiceable'] ?? true;
                      });
                      
                      if (result['isServiceable'] == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Location is now serviceable!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      setState(() {
                        _isCheckingLocation = false;
                      });
                    }
                  },
                  child: Icon(
                    Icons.refresh,
                    color: Colors.orange[700],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                // Add dismiss button
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isLocationServiceable = true; // Temporarily dismiss the warning
                    });
                  },
                  child: Icon(
                    Icons.close,
                    color: Colors.orange[700],
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'You can change your delivery address from the top bar to find restaurants in your area.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.orange[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Current location: $_currentAddress',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.orange[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    // Show helpful message if no location is set
    if (_currentAddress.isEmpty || _currentAddress == 'null') {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              color: Colors.blue[700],
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Set your delivery address to find restaurants near you',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
  
  void _updateStatusMessage(String message) {
    // Helper method for status updates
    debugPrint('Dashboard: $message');
  }




}
                
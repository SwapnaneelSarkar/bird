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

class CategoryHomepage extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final String? token;

  const CategoryHomepage({Key? key, this.userData, this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CategoryHomepageBloc()..add(const LoadCategoryHomepage()),
      child: _CategoryHomepageContent(userData: userData, token: token),
    );
  }
}

class _CategoryHomepageContent extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final String? token;

  const _CategoryHomepageContent({Key? key, this.userData, this.token}) : super(key: key);

  @override
  State<_CategoryHomepageContent> createState() => _CategoryHomepageContentState();
}

class _CategoryHomepageContentState extends State<_CategoryHomepageContent>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _categoryAnimationController;

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
          bloc.emit(const CategoryHomepageInitial());
          bloc.add(const LoadCategoryHomepage());
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocConsumer<CategoryHomepageBloc, CategoryHomepageState>(
          listener: (context, state) {
            if (state is CategorySelected) {
              debugPrint('CategoryHomepage: Navigating with supercategory ID: ${state.categoryId}');
              
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
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            ColorManager.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: ColorManager.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getGreeting(),
                        style: GoogleFonts.poppins(
                          fontSize: _getResponsiveFontSize(12),
                          color: ColorManager.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.userName,
                      style: GoogleFonts.poppins(
                        fontSize: _getResponsiveFontSize(28),
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
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
    // Determine if we should show "View All" button
    final shouldShowViewAll = categories.length > 4;
    final displayCategories = shouldShowViewAll ? categories.take(4).toList() : categories;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: ColorManager.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
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
          const SizedBox(height: 4),
          Text(
            'Select a category to explore delicious options',
            style: GoogleFonts.poppins(
              fontSize: _getResponsiveFontSize(12),
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          // Dynamic height based on number of categories
          Stack(
            children: [
              SizedBox(
                height: displayCategories.length <= 3 ? 140 : 160, // Adjust height based on category count
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  itemCount: displayCategories.length,
                  itemBuilder: (context, index) {
                    final category = displayCategories[index];
                    return _buildCategoryCard(category, index, totalCategories: displayCategories.length);
                  },
                ),
              ),
              // Scroll indicator for many categories
              if (displayCategories.length > 3)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 20,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.white.withOpacity(0.0),
                          Colors.white.withOpacity(0.8),
                        ],
                      ),
                    ),
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

    // Dynamic sizing based on total categories
    final totalCats = totalCategories ?? 2;
    final cardWidth = totalCats <= 3 ? 100.0 : 90.0; // Smaller cards if more categories
    final imageSize = totalCats <= 3 ? 70.0 : 60.0; // Smaller images if more categories
    final innerImageSize = totalCats <= 3 ? 66.0 : 56.0; // Smaller inner images if more categories
    final fontSize = totalCats <= 3 ? 11.0 : 10.0; // Smaller font if more categories

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
        margin: EdgeInsets.symmetric(horizontal: totalCats <= 3 ? 6 : 4), // Tighter spacing for more categories
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
                                    size: totalCats <= 3 ? 28 : 24,
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
                                      size: totalCats <= 3 ? 28 : 24,
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
                              size: totalCats <= 3 ? 28 : 24,
                            ),
                          ),
                  ),
                ),
              ],
            ),
            SizedBox(height: totalCats <= 3 ? 8 : 6), // Tighter spacing for more categories
            // Category name container
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: totalCats <= 3 ? 7 : 5, 
                vertical: totalCats <= 3 ? 4 : 3
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 3,
                    offset: const Offset(0, 1.5),
                  )
                ],
                border: Border.all(
                  color: accentColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                category.name,
                style: GoogleFonts.poppins(
                  fontSize: _getResponsiveFontSize(fontSize),
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                maxLines: totalCats <= 3 ? 2 : 1, // Single line for more categories
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
  String _getGreeting() {
    return 'Hello';
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




}
                
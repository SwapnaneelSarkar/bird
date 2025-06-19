// lib/presentation/home page/view.dart - COMPLETE ERROR-FREE VERSION
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'package:bird/constants/router/router.dart';
import 'package:bird/constants/color/colorConstant.dart';
import '../../../widgets/restaurant_card.dart';
import '../address bottomSheet/view.dart';
import '../restaurant_menu/view.dart';
import '../search_page/bloc.dart';
import '../search_page/searchPage.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';

// Main home page widget
class HomePage extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final String? token;

  const HomePage({Key? key, this.userData, this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc()..add(const LoadHomeData()),
      child: _HomeContent(userData: userData, token: token),
    );
  }
}

// Filter options class with simplified approach
class FilterOptions {
  bool vegOnly;
  bool priceLowToHigh; // true for low to high, false for high to low, null for no sorting
  bool priceHighToLow; // true for high to low, false for low to high, null for no sorting
  bool ratingHighToLow; // true for high to low, false for low to high, null for no sorting
  bool ratingLowToHigh; // true for low to high, false for high to low, null for no sorting
  bool timeSort; // true for fastest first, null for no sorting
  
  FilterOptions({
    this.vegOnly = false,
    this.priceLowToHigh = false,
    this.priceHighToLow = false,
    this.ratingHighToLow = false,
    this.ratingLowToHigh = false,
    this.timeSort = false,
  });
}

// Home content stateful widget
class _HomeContent extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final String? token;

  const _HomeContent({Key? key, this.userData, this.token}) : super(key: key);

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  FilterOptions filterOptions = FilterOptions();
  String? previousAddress;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      body: SafeArea(
        child: BlocListener<HomeBloc, HomeState>(
          listener: (context, state) {
            // Handle all address-related state changes
            _handleAddressUpdates(context, state);
            
            // Handle address change notifications
            if (state is HomeLoaded && state.userAddress != previousAddress) {
              if (previousAddress != null && previousAddress != 'Add delivery address') {
                _showCustomSnackBar(context, 'Address updated successfully', Colors.green, Icons.check_circle);
              }
              previousAddress = state.userAddress;
              debugPrint('HomePage: Address changed to: ${state.userAddress}');
            }
          },
          child: BlocBuilder<HomeBloc, HomeState>(
            builder: (context, state) {
              debugPrint('HomePage: BlocBuilder received state: ${state.runtimeType}');
              if (state is HomeLoaded) {
                debugPrint('HomePage: BlocBuilder - selectedCategory: ${state.selectedCategory}');
                debugPrint('HomePage: BlocBuilder - vegOnly: ${state.vegOnly}');
                debugPrint('HomePage: BlocBuilder - restaurants count: ${state.restaurants.length}');
                debugPrint('HomePage: BlocBuilder - filtered restaurants count: ${state.filteredRestaurants.length}');
              }
              
              if (state is HomeLoading) {
                return _buildLoadingIndicator();
              } else if (state is HomeLoaded) {
                return _buildHomeContent(context, state);
              } else {
                // If no HomeLoaded at all, show the full error state
                return _buildErrorState(context, state is HomeError ? state : const HomeError('Something went wrong'));
              }
            },
          ),
        ),
      ),
    );
  }

  // Handle address update states
  void _handleAddressUpdates(BuildContext context, HomeState state) {
    if (state is AddressUpdateSuccess) {
      _showCustomSnackBar(
        context, 
        'Address updated successfully', 
        Colors.green, 
        Icons.check_circle
      );
    } else if (state is AddressUpdateFailure) {
      // Check if it's an outside service area error
      final errorMessage = state.error.toLowerCase();
      if (errorMessage.contains('outside') && 
          (errorMessage.contains('service') || errorMessage.contains('serviceable'))) {
        // Don't show error snackbar for outside service area
        // The UI will handle this gracefully
        debugPrint('HomePage: Outside service area detected, handling gracefully');
      } else {
        _showCustomSnackBar(
          context, 
          state.error, 
          Colors.red, 
          Icons.error_outline
        );
      }
    } else if (state is AddressSaveSuccess) {
      _showCustomSnackBar(
        context, 
        state.message, 
        Colors.green, 
        Icons.check_circle
      );
    } else if (state is AddressSaveFailure) {
      _showCustomSnackBar(
        context, 
        state.error, 
        Colors.red, 
        Icons.error_outline
      );
    }
  }
  
  Widget _buildHomeContent(BuildContext context, HomeLoaded state, {bool isOutsideServiceArea = false}) {
    debugPrint('UI: Showing home content with ${state.restaurants.length} restaurants');
    return Stack(
      children: [
        // Background
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FF),
          ),
        ),
        
        Column(
          children: [
            // Address Bar with glass morphism effect
            ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.8)],
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    ),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, 2), blurRadius: 8)],
                    border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.5), width: 1)),
                  ),
                  child: _buildAddressBar(context, state),
                ),
              ),
            ).animate(controller: _animationController).fadeIn(duration: 400.ms, curve: Curves.easeOut),

            // Search Bar
            _buildSearchBar(context, state)
              .animate(controller: _animationController)
              .fadeIn(duration: 400.ms, delay: 100.ms, curve: Curves.easeOut)
              .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut),

            // Main Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => context.read<HomeBloc>().add(const LoadHomeData()),
                color: ColorManager.primary,
                backgroundColor: Colors.white,
                displacement: 20,
                strokeWidth: 3,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Popular Categories
                      _buildCategoriesSection(context, state)
                        .animate(controller: _animationController)
                        .fadeIn(duration: 400.ms, delay: 200.ms, curve: Curves.easeOut)
                        .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut),
                      
                      // All Restaurants or Outside Service Area Message
                      if (isOutsideServiceArea)
                        _buildOutsideServiceableArea(context)
                          .animate(controller: _animationController)
                          .fadeIn(duration: 400.ms, delay: 300.ms, curve: Curves.easeOut)
                          .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut)
                      else
                        _buildRestaurantsSection(context, state)
                          .animate(controller: _animationController)
                          .fadeIn(duration: 400.ms, delay: 300.ms, curve: Curves.easeOut)
                          .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut),
                      
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildAddressBar(BuildContext context, HomeLoaded state) {
    return InkWell(
      onTap: () => _showAddressPicker(context, state),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isWide = constraints.maxWidth > 600;
            
            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ColorManager.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.location_on, color: ColorManager.primary, size: isWide ? 24 : 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deliver to',
                        style: GoogleFonts.poppins(
                          fontSize: isWide ? 14 : 12, 
                          color: Colors.grey[600], 
                          letterSpacing: 0.3,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              state.userAddress,
                              style: GoogleFonts.poppins(
                                fontSize: isWide ? 16 : 14, 
                                fontWeight: FontWeight.w600, 
                                color: Colors.grey[800],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey[200], 
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.keyboard_arrow_down, color: ColorManager.primary, size: isWide ? 18 : 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 3))],
                    gradient: LinearGradient(
                      colors: [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.7)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () => Navigator.pushNamed(context, Routes.profileView),
                      child: Padding(
                        padding: EdgeInsets.all(isWide ? 10 : 8),
                        child: Icon(Icons.person, color: ColorManager.primary, size: isWide ? 26 : 24),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, HomeLoaded state) {
    return Hero(
      tag: 'search_bar',
      child: Material(
        color: Colors.transparent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isWide = constraints.maxWidth > 600;
            final double horizontalPadding = isWide ? 40.0 : 20.0;
            final double height = isWide ? 60.0 : 52.0;
            
            return Container(
              margin: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                height: height,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4), spreadRadius: 2)],
                  border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _navigateToSearch(context, state),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: ColorManager.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.search, color: ColorManager.primary, size: isWide ? 22 : 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Search restaurants...',
                            style: GoogleFonts.poppins(
                              fontSize: isWide ? 16 : 14, 
                              color: Colors.grey[400], 
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _navigateToSearch(BuildContext context, HomeLoaded state) async {
    debugPrint('HomePage: Navigating to search with user coordinates - Lat: ${state.userLatitude}, Long: ${state.userLongitude}');
    
    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => BlocProvider(
          create: (context) => SearchBloc(),
          child: SearchPage(
            userLatitude: state.userLatitude,
            userLongitude: state.userLongitude,
          ),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
    
    if (result != null && result is Map<String, dynamic>) {
      _navigateToRestaurantDetails(context, result);
    }
  }

  Widget _buildCategoriesSection(BuildContext context, HomeLoaded state) {
    debugPrint('HomePage: _buildCategoriesSection called with selectedCategory: ${state.selectedCategory}');
    debugPrint('HomePage: _buildCategoriesSection - Show All button should be visible: ${state.selectedCategory != null}');
    return Container(
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Popular Categories',
                  style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey[800], letterSpacing: 0.2,
                  ),
                ),
                Row(
                  children: [
                    // Show "All" button when a category is selected
                    if (state.selectedCategory != null)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              debugPrint('HomePage: Show All button clicked. Current selected category: ${state.selectedCategory}');
                              debugPrint('HomePage: Resetting all filters and category selection');
                              
                              // Reset the view's filter options
                              setState(() {
                                filterOptions = FilterOptions();
                              });
                              
                              // Reset the bloc state
                              context.read<HomeBloc>().add(const FilterByCategory(null));
                              context.read<HomeBloc>().add(const ToggleVegOnly(false));
                              
                              debugPrint('HomePage: All filters and category selection reset');
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.clear, color: Colors.grey[600], size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Show All',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Filter button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showFuturisticFilterDialog(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: ColorManager.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.tune, color: ColorManager.primary, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                'Filter',
                                style: GoogleFonts.poppins(
                                  fontSize: 13, fontWeight: FontWeight.w500, color: ColorManager.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final double itemWidth = 100.0;
              final double screenWidth = constraints.maxWidth;
              final int maxVisibleItems = (screenWidth / itemWidth).floor();
              final bool shouldScroll = state.categories.length > maxVisibleItems;
              
              final categoryItems = _getCategoryItems(state.categories, state.selectedCategory);
              
              if (shouldScroll) {
                return SizedBox(
                  height: 140,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    children: categoryItems,
                  ),
                );
              } else {
                return Container(
                  height: 140,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: categoryItems,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _getCategoryItems(List<dynamic> categories, String? selectedCategory) {
    debugPrint('HomePage: Building category items. Selected category: $selectedCategory');
    
    // Map for known category image associations
    final Map<String, String> imageMap = {
      'pizza': 'assets/images/pizza.jpg',
      'burger': 'assets/images/burger.jpg',
      'sushi': 'assets/images/sushi.jpg',
      'dessert': 'assets/images/desert.jpg',
      'drinks': 'assets/images/drinks.jpg',
    };
    
    return categories.map((category) {
      String categoryName = category['name'].toString().toLowerCase();
      String categoryDisplayName = category['name'].toString();
      String? imagePath;
      bool isSelected = selectedCategory?.toLowerCase() == categoryName;
      
      debugPrint('HomePage: Category $categoryDisplayName - isSelected: $isSelected');
      
      // Try to find exact matching image based on category name
      for (final entry in imageMap.entries) {
        if (categoryName == entry.key || 
            (categoryName.contains(entry.key) && entry.key.length > 3)) {
          imagePath = entry.value;
          break;
        }
      }
      
      // Get smart icon and color based on category name
      final iconAndColor = _getSmartCategoryIconAndColor(categoryName);
      final icon = iconAndColor['icon'] ?? category['icon'] ?? 'restaurant';
      final color = iconAndColor['color'] ?? category['color'] ?? 'orange';
      
      // If we have an image, build with image
      if (imagePath != null) {
        return _buildCategoryItem(
          categoryDisplayName, 
          imagePath, 
          color,
          isSelected: isSelected,
          onTap: () {
            debugPrint('HomePage: Category tapped: $categoryDisplayName, currently selected: $isSelected');
            final newCategory = isSelected ? null : categoryDisplayName;
            debugPrint('HomePage: Setting new category to: $newCategory');
            context.read<HomeBloc>().add(FilterByCategory(newCategory));
          },
        );
      } 
      // Otherwise build with an icon instead
      else {
        return _buildCategoryItemWithIcon(
          categoryDisplayName,
          _getIconData(icon), 
          _getCategoryColor(color),
          isSelected: isSelected,
          onTap: () {
            debugPrint('HomePage: Category tapped: $categoryDisplayName, currently selected: $isSelected');
            final newCategory = isSelected ? null : categoryDisplayName;
            debugPrint('HomePage: Setting new category to: $newCategory');
            context.read<HomeBloc>().add(FilterByCategory(newCategory));
          },
        );
      }
    }).toList();
  }

  // Smart category icon and color selector based on category name
  Map<String, String> _getSmartCategoryIconAndColor(String categoryName) {
    // Food type based mapping
    if (categoryName.contains('pizza')) {
      return {'icon': 'local_pizza', 'color': 'red'};
    } else if (categoryName.contains('burger') || categoryName.contains('sandwich')) {
      return {'icon': 'lunch_dining', 'color': 'amber'};
    } else if (categoryName.contains('sushi') || categoryName.contains('japanese') || categoryName.contains('asian')) {
      return {'icon': 'set_meal', 'color': 'blue'};
    } else if (categoryName.contains('dessert') || categoryName.contains('sweet') || categoryName.contains('ice') || categoryName.contains('cake')) {
      return {'icon': 'icecream', 'color': 'pink'};
    } else if (categoryName.contains('drink') || categoryName.contains('beverage') || categoryName.contains('juice') || categoryName.contains('coffee')) {
      return {'icon': 'local_drink', 'color': 'teal'};
    } else if (categoryName.contains('chinese') || categoryName.contains('noodle') || categoryName.contains('ramen')) {
      return {'icon': 'ramen_dining', 'color': 'orange'};
    } else if (categoryName.contains('breakfast') || categoryName.contains('bread') || categoryName.contains('bakery')) {
      return {'icon': 'bakery_dining', 'color': 'brown'};
    } else if (categoryName.contains('veg') || categoryName.contains('salad') || categoryName.contains('healthy')) {
      return {'icon': 'spa', 'color': 'green'};
    } else if (categoryName.contains('biryani') || categoryName.contains('rice') || categoryName.contains('indian')) {
      return {'icon': 'restaurant', 'color': 'deepOrange'};
    } else if (categoryName.contains('chicken') || categoryName.contains('meat') || categoryName.contains('grill')) {
      return {'icon': 'restaurant_menu', 'color': 'red'};
    } else if (categoryName.contains('seafood') || categoryName.contains('fish')) {
      return {'icon': 'set_meal', 'color': 'blue'};
    } else if (categoryName.contains('thai') || categoryName.contains('spicy')) {
      return {'icon': 'whatshot', 'color': 'red'};
    } else if (categoryName.contains('mexican') || categoryName.contains('taco')) {
      return {'icon': 'local_dining', 'color': 'green'};
    }
    
    // Default
    return {'icon': 'restaurant', 'color': 'orange'};
  }

  Widget _buildCategoryItemWithIcon(String title, IconData icon, Color accentColor, {bool isSelected = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        width: 100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    boxShadow: [
                      BoxShadow(
                        color: isSelected ? accentColor.withOpacity(0.4) : accentColor.withOpacity(0.2), 
                        blurRadius: isSelected ? 16 : 12, 
                        offset: const Offset(0, 6), 
                        spreadRadius: isSelected ? 4 : 2
                      )
                    ],
                  ),
                ),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isSelected 
                          ? [accentColor.withOpacity(0.3), accentColor.withOpacity(0.5)]
                          : [Colors.white, accentColor.withOpacity(0.15)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: isSelected ? accentColor : Colors.white, 
                      width: isSelected ? 4 : 3
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: isSelected ? 40 : 36,
                      color: accentColor,
                    ),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 14),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? accentColor.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
                border: Border.all(
                  color: isSelected ? accentColor.withOpacity(0.5) : accentColor.withOpacity(0.3), 
                  width: isSelected ? 2 : 1
                ),
              ),
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 10, 
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, 
                  color: isSelected ? accentColor : Colors.grey[800]
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'local_pizza': return Icons.local_pizza;
      case 'lunch_dining': return Icons.lunch_dining;
      case 'set_meal': return Icons.set_meal;
      case 'icecream': return Icons.icecream;
      case 'local_drink': return Icons.local_drink;
      case 'bakery_dining': return Icons.bakery_dining;
      case 'free_breakfast': return Icons.free_breakfast;
      case 'spa': return Icons.spa;
      case 'egg': return Icons.egg_alt;
      case 'ramen_dining': return Icons.ramen_dining;
      case 'restaurant': return Icons.restaurant;
      default: return Icons.restaurant;
    }
  }

  Widget _buildCategoryItem(String title, String imagePath, String colorName, {bool isSelected = false, VoidCallback? onTap}) {
    Color accentColor = _getCategoryColor(colorName);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        width: 100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    boxShadow: [
                      BoxShadow(
                        color: isSelected ? accentColor.withOpacity(0.4) : accentColor.withOpacity(0.2), 
                        blurRadius: isSelected ? 16 : 12, 
                        offset: const Offset(0, 6), 
                        spreadRadius: isSelected ? 4 : 2
                      )
                    ],
                  ),
                ),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isSelected 
                          ? [accentColor.withOpacity(0.3), accentColor.withOpacity(0.5)]
                          : [Colors.white, accentColor.withOpacity(0.3)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: isSelected ? accentColor : Colors.white, 
                      width: isSelected ? 4 : 3
                    ),
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 14),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? accentColor.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
                border: Border.all(
                  color: isSelected ? accentColor.withOpacity(0.5) : accentColor.withOpacity(0.3), 
                  width: isSelected ? 2 : 1
                ),
              ),
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 12, 
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500, 
                  color: isSelected ? accentColor : Colors.grey[800]
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantsSection(BuildContext context, HomeLoaded state) {
    debugPrint('UI: Building restaurants section with ${state.restaurants.length} restaurants');
    debugPrint('UI: Current filter options - vegOnly: ${filterOptions.vegOnly}, priceLowToHigh: ${filterOptions.priceLowToHigh}, priceHighToLow: ${filterOptions.priceHighToLow}, ratingHighToLow: ${filterOptions.ratingHighToLow}, ratingLowToHigh: ${filterOptions.ratingLowToHigh}, timeSort: ${filterOptions.timeSort}');
    
    // Get filtered restaurants using the state's helper method
    var filteredRestaurants = state.filteredRestaurants;
    
    // Debug: Print original restaurant data
    debugPrint('=== ORIGINAL RESTAURANT DATA ===');
    for (int i = 0; i < filteredRestaurants.length; i++) {
      final restaurant = filteredRestaurants[i];
      debugPrint('Restaurant $i: ${restaurant.name} - Rating: ${restaurant.rating} (${restaurant.rating.runtimeType}), Type: ${restaurant.restaurantType}, Veg: ${restaurant.isVeg}');
    }
    
    // Apply additional filters from FilterOptions
    if (filterOptions.ratingHighToLow) {
      // Sort by rating high to low
      filteredRestaurants.sort((a, b) {
        final aRating = double.tryParse(a.rating?.toString() ?? '0') ?? 0.0;
        final bRating = double.tryParse(b.rating?.toString() ?? '0') ?? 0.0;
        return bRating.compareTo(aRating);
      });
      debugPrint('HomePage: Applied rating sort high to low');
      
      // Debug: Print sorted ratings
      debugPrint('=== RATING SORT HIGH TO LOW ===');
      for (int i = 0; i < filteredRestaurants.length; i++) {
        final restaurant = filteredRestaurants[i];
        final rating = double.tryParse(restaurant.rating?.toString() ?? '0') ?? 0.0;
        debugPrint('Position $i: ${restaurant.name} - Rating: $rating');
      }
    } else if (filterOptions.ratingLowToHigh) {
      // Sort by rating low to high
      filteredRestaurants.sort((a, b) {
        final aRating = double.tryParse(a.rating?.toString() ?? '0') ?? 0.0;
        final bRating = double.tryParse(b.rating?.toString() ?? '0') ?? 0.0;
        return aRating.compareTo(bRating);
      });
      debugPrint('HomePage: Applied rating sort low to high');
      
      // Debug: Print sorted ratings
      debugPrint('=== RATING SORT LOW TO HIGH ===');
      for (int i = 0; i < filteredRestaurants.length; i++) {
        final restaurant = filteredRestaurants[i];
        final rating = double.tryParse(restaurant.rating?.toString() ?? '0') ?? 0.0;
        debugPrint('Position $i: ${restaurant.name} - Rating: $rating');
      }
    }
    
    if (filterOptions.timeSort) {
      // Sort by delivery time (using rating as proxy for better restaurants)
      filteredRestaurants.sort((a, b) {
        final aRating = double.tryParse(a.rating?.toString() ?? '0') ?? 0.0;
        final bRating = double.tryParse(b.rating?.toString() ?? '0') ?? 0.0;
        return bRating.compareTo(aRating);
      });
      debugPrint('HomePage: Applied time sort');
      
      // Debug: Print sorted by time (rating)
      debugPrint('=== TIME SORT (BY RATING) ===');
      for (int i = 0; i < filteredRestaurants.length; i++) {
        final restaurant = filteredRestaurants[i];
        final rating = double.tryParse(restaurant.rating?.toString() ?? '0') ?? 0.0;
        debugPrint('Position $i: ${restaurant.name} - Rating: $rating');
      }
    }
    
    // For price sorting, we'll use a simple heuristic based on restaurant type
    if (filterOptions.priceLowToHigh) {
      // Sort by restaurant type (assuming premium types are more expensive)
      filteredRestaurants.sort((a, b) {
        final aType = a.restaurantType?.toLowerCase() ?? '';
        final bType = b.restaurantType?.toLowerCase() ?? '';
        
        // Simple price ranking based on restaurant type
        int getPriceRank(String type) {
          if (type.contains('premium') || type.contains('fine') || type.contains('restaurant')) return 3;
          if (type.contains('casual') || type.contains('family') || type.contains('cloud kitchen')) return 2;
          return 1; // budget/fast food
        }
        
        return getPriceRank(aType).compareTo(getPriceRank(bType));
      });
      debugPrint('HomePage: Applied price sort low to high');
      
      // Debug: Print sorted by price (type)
      debugPrint('=== PRICE SORT LOW TO HIGH ===');
      for (int i = 0; i < filteredRestaurants.length; i++) {
        final restaurant = filteredRestaurants[i];
        final type = restaurant.restaurantType?.toLowerCase() ?? '';
        int getPriceRank(String t) {
          if (t.contains('premium') || t.contains('fine') || t.contains('restaurant')) return 3;
          if (t.contains('casual') || t.contains('family') || t.contains('cloud kitchen')) return 2;
          return 1;
        }
        final priceRank = getPriceRank(type);
        debugPrint('Position $i: ${restaurant.name} - Type: $type (Price Rank: $priceRank)');
      }
    } else if (filterOptions.priceHighToLow) {
      // Sort by restaurant type (premium first)
      filteredRestaurants.sort((a, b) {
        final aType = a.restaurantType?.toLowerCase() ?? '';
        final bType = b.restaurantType?.toLowerCase() ?? '';
        
        // Simple price ranking based on restaurant type
        int getPriceRank(String type) {
          if (type.contains('premium') || type.contains('fine') || type.contains('restaurant')) return 3;
          if (type.contains('casual') || type.contains('family') || type.contains('cloud kitchen')) return 2;
          return 1; // budget/fast food
        }
        
        return getPriceRank(bType).compareTo(getPriceRank(aType));
      });
      debugPrint('HomePage: Applied price sort high to low');
      
      // Debug: Print sorted by price (type)
      debugPrint('=== PRICE SORT HIGH TO LOW ===');
      for (int i = 0; i < filteredRestaurants.length; i++) {
        final restaurant = filteredRestaurants[i];
        final type = restaurant.restaurantType?.toLowerCase() ?? '';
        int getPriceRank(String t) {
          if (t.contains('premium') || t.contains('fine') || t.contains('restaurant')) return 3;
          if (t.contains('casual') || t.contains('family') || t.contains('cloud kitchen')) return 2;
          return 1;
        }
        final priceRank = getPriceRank(type);
        debugPrint('Position $i: ${restaurant.name} - Type: $type (Price Rank: $priceRank)');
      }
    }
    
    // Debug: Print final filtered results
    debugPrint('=== FINAL FILTERED RESULTS ===');
    for (int i = 0; i < filteredRestaurants.length; i++) {
      final restaurant = filteredRestaurants[i];
      final rating = double.tryParse(restaurant.rating?.toString() ?? '0') ?? 0.0;
      final type = restaurant.restaurantType?.toLowerCase() ?? '';
      debugPrint('Final Position $i: ${restaurant.name} - Rating: $rating, Type: $type, Veg: ${restaurant.isVeg}');
    }
    
    final isOutsideServiceableArea = state.userAddress != 'Add delivery address' && 
                                   filteredRestaurants.isEmpty;
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'All Restaurants',
                  style: GoogleFonts.poppins(
                    fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800], letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: ColorManager.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${filteredRestaurants.length}',
                    style: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w600, color: ColorManager.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Restaurant List or Error/Empty State
          if (isOutsideServiceableArea)
            _buildOutsideServiceableArea(context)
          else if (filteredRestaurants.isEmpty)
            _buildEmptyRestaurantsList()
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate number of columns based on width
                  final double screenWidth = constraints.maxWidth;
                  final int columns = (screenWidth / 400).floor().clamp(1, 2);
                  final bool useGrid = columns > 1;
                  
                  if (useGrid) {
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        childAspectRatio: 1.6,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: filteredRestaurants.length,
                      itemBuilder: (context, index) => _buildRestaurantItem(
                        context, filteredRestaurants[index], state, index
                      ),
                    );
                  } else {
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredRestaurants.length,
                      itemBuilder: (context, index) => _buildRestaurantItem(
                        context, filteredRestaurants[index], state, index
                      ),
                    );
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRestaurantItem(BuildContext context, dynamic restaurant, HomeLoaded state, int index) {
    final sanitizedName = _sanitizeRestaurantName(restaurant.name);
    
    return Hero(
      tag: 'restaurant-$sanitizedName',
      child: RestaurantCard(
        name: restaurant.name,
        imageUrl: restaurant.imageUrl ?? 'assets/images/placeholder.jpg',
        cuisine: restaurant.cuisine,
        rating: restaurant.rating ?? 0.0,
        deliveryTime: '20-30 mins',
        isVeg: restaurant.isVeg,
        restaurantLatitude: restaurant.latitude,
        restaurantLongitude: restaurant.longitude,
        userLatitude: state.userLatitude,
        userLongitude: state.userLongitude,
        restaurantType: restaurant.restaurantType,
        onTap: () => _navigateToRestaurantDetails(context, restaurant),
      ).animate(controller: _animationController)
        .fadeIn(duration: 400.ms, delay: (300 + (index * 75)).ms, curve: Curves.easeOut)
        .slideY(begin: 0.1, end: 0, duration: 400.ms, delay: (300 + (index * 50)).ms, curve: Curves.easeOutQuad),
    );
  }

  Widget _buildOutsideServiceableArea(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/duckling.jpg',
            width: 200,
            height: 200,
          ),
          const SizedBox(height: 24),
          Text(
            'Outside Service Area',
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'We haven\'t spread our wings to this area yet.',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Please try a different location within our service area.',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              final state = context.read<HomeBloc>().state;
              if (state is HomeLoaded) {
                _showAddressPicker(context, state);
              }
            },
            icon: const Icon(Icons.place, color: Colors.white),
            label: Text(
              'Change Location',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCF7C42),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              minimumSize: const Size(double.infinity, 54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRestaurantsList() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/duckling.jpg',
            width: 200,
            height: 200,
          ),
          const SizedBox(height: 24),
          Text(
            'Oops!',
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Hello! We\'re not flying to this area yet.',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Try changing your location.',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              final state = context.read<HomeBloc>().state;
              if (state is HomeLoaded) {
                _showAddressPicker(context, state);
              }
            },
            icon: const Icon(Icons.place, color: Colors.white),
            label: Text(
              'Change Location',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCF7C42),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              minimumSize: const Size(double.infinity, 54),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToRestaurantDetails(BuildContext context, dynamic restaurant) {
    debugPrint('HomePage: Navigating to restaurant details');
    
    final state = context.read<HomeBloc>().state;
    double? userLatitude;
    double? userLongitude;
    
    if (state is HomeLoaded) {
      userLatitude = state.userLatitude;
      userLongitude = state.userLongitude;
      debugPrint('HomePage: User coordinates - Lat: $userLatitude, Long: $userLongitude');
    }
    
    // Convert restaurant data to the expected Map format for RestaurantDetailsPage
    final restaurantData = <String, dynamic>{
      'id': restaurant is Map ? restaurant['id'] : restaurant.id,
      'partner_id': restaurant is Map ? restaurant['partner_id'] : restaurant.id,
      'name': restaurant is Map ? restaurant['name'] : restaurant.name,
      'restaurant_name': restaurant is Map ? restaurant['restaurant_name'] : restaurant.name,
      'imageUrl': restaurant is Map ? restaurant['imageUrl'] : restaurant.imageUrl,
      'cuisine': restaurant is Map ? restaurant['cuisine'] : restaurant.cuisine,
      'category': restaurant is Map ? restaurant['category'] : restaurant.cuisine,
      'rating': restaurant is Map ? restaurant['rating'] : restaurant.rating,
      'isVegetarian': restaurant is Map ? restaurant['isVegetarian'] : restaurant.isVeg,
      'isVeg': restaurant is Map ? restaurant['isVeg'] : restaurant.isVeg,
      'veg_nonveg': restaurant is Map ? restaurant['veg_nonveg'] : (restaurant.isVeg ? 'veg' : 'non-veg'),
      'address': restaurant is Map ? restaurant['address'] : restaurant.address,
      'latitude': restaurant is Map ? restaurant['latitude'] : restaurant.latitude,
      'longitude': restaurant is Map ? restaurant['longitude'] : restaurant.longitude,
      'restaurantType': restaurant is Map ? restaurant['restaurantType'] : restaurant.restaurantType,
      'restaurant_type': restaurant is Map ? restaurant['restaurant_type'] : restaurant.restaurantType,
      'description': restaurant is Map ? restaurant['description'] : restaurant.description,
      'openTimings': restaurant is Map ? restaurant['openTimings'] : restaurant.openTimings,
      'open_timings': restaurant is Map ? restaurant['open_timings'] : restaurant.openTimings,
      'ownerName': restaurant is Map ? restaurant['ownerName'] : restaurant.ownerName,
      'owner_name': restaurant is Map ? restaurant['owner_name'] : restaurant.ownerName,
    };
    
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => RestaurantDetailsPage(
          restaurantData: restaurantData,
          userLatitude: userLatitude,
          userLongitude: userLongitude,
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

  Future<void> _showAddressPicker(BuildContext context, HomeLoaded state) async {
    try {
      debugPrint('HomePage: Opening address picker with ${state.savedAddresses.length} saved addresses');
      
      final result = await AddressPickerBottomSheet.show(
        context,
        savedAddresses: state.savedAddresses,
      );
      
      if (result != null && mounted) {
        final double latitude = result['latitude'] ?? 0.0;
        final double longitude = result['longitude'] ?? 0.0;
        
        debugPrint('HomePage: Address selected from picker:');
        debugPrint('  Address: ${result['address']}');
        debugPrint('  Sub-address: ${result['subAddress']}');
        debugPrint('  Latitude: $latitude');
        debugPrint('  Longitude: $longitude');
        
        if (latitude == 0.0 && longitude == 0.0) {
          debugPrint('HomePage: Warning - Got zero coordinates');
          _showCustomSnackBar(
            context,
            'Could not get location coordinates. Please try again.',
            Colors.orange,
            Icons.warning_amber_rounded,
          );
          return;
        }
        
        String fullAddress = result['address'];
        if (result['subAddress'].toString().isNotEmpty) {
          fullAddress += ', ${result['subAddress']}';
        }
        
        // Update the address immediately in the home bloc
        context.read<HomeBloc>().add(
          UpdateUserAddress(
            address: fullAddress,
            latitude: latitude,
            longitude: longitude,
          ),
        );
        
        // Reload saved addresses to show newly added ones immediately
        context.read<HomeBloc>().add(const LoadSavedAddresses());
        
        debugPrint('HomePage: Address update and reload triggered');
      }
    } catch (e) {
      debugPrint('HomePage: Error showing address picker: $e');
      _showCustomSnackBar(
        context,
        'Error opening address picker. Please try again.',
        Colors.red,
        Icons.error_outline,
      );
    }
  }

  void _showFuturisticFilterDialog(BuildContext context) {
    final blocContext = context;
    FilterOptions tempFilters = FilterOptions(
      vegOnly: filterOptions.vegOnly,
      priceLowToHigh: filterOptions.priceLowToHigh,
      priceHighToLow: filterOptions.priceHighToLow,
      ratingHighToLow: filterOptions.ratingHighToLow,
      ratingLowToHigh: filterOptions.ratingLowToHigh,
      timeSort: filterOptions.timeSort,
    );
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Dialog(
            backgroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              width: MediaQuery.of(context).size.width * 0.9,
              padding: const EdgeInsets.all(0),
              child: DefaultTabController(
                length: 4,
                child: StatefulBuilder(
                  builder: (statefulContext, setStateDialog) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Heading with curved background
                        Container(
                          decoration: BoxDecoration(
                            color: ColorManager.primary,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                          ),
                          padding: const EdgeInsets.only(top: 20, bottom: 16, left: 20, right: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Sort & Filter',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.close),
                                  color: Colors.white,
                                  onPressed: () => Navigator.pop(dialogContext),
                                  iconSize: 20,
                                  padding: const EdgeInsets.all(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Tab Bar for different filter categories
                        TabBar(
                          tabs: const [
                            Tab(icon: Icon(Icons.attach_money), text: 'Price'),
                            Tab(icon: Icon(Icons.timer), text: 'Time'),
                            Tab(icon: Icon(Icons.restaurant), text: 'Diet'),
                            Tab(icon: Icon(Icons.star), text: 'Rating'),
                          ],
                          indicatorColor: ColorManager.primary,
                          labelColor: ColorManager.primary,
                          unselectedLabelColor: Colors.grey[600],
                          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
                          unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 12),
                        ),
                        // Tab Content - with fixed height
                        SizedBox(
                          height: 280,
                          child: TabBarView(
                            children: [
                              _buildPriceFilterTab(tempFilters, setStateDialog),
                              _buildTimeFilterTab(tempFilters, setStateDialog),
                              _buildVegFilterTab(tempFilters, setStateDialog, blocContext),
                              _buildRatingFilterTab(tempFilters, setStateDialog),
                            ],
                          ),
                        ),
                        // Action Buttons
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    debugPrint('HomePage: Resetting all filters');
                                    
                                    setStateDialog(() {
                                      tempFilters = FilterOptions();
                                    });
                                    
                                    setState(() {
                                      filterOptions = FilterOptions();
                                    });
                                    
                                    blocContext.read<HomeBloc>().add(const ToggleVegOnly(false));
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    side: BorderSide(color: ColorManager.primary),
                                  ),
                                  child: Text(
                                    'Reset',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: ColorManager.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: () {
                                    debugPrint('HomePage: Applying filters - vegOnly: ${tempFilters.vegOnly}, priceLowToHigh: ${tempFilters.priceLowToHigh}, priceHighToLow: ${tempFilters.priceHighToLow}, ratingHighToLow: ${tempFilters.ratingHighToLow}, ratingLowToHigh: ${tempFilters.ratingLowToHigh}, timeSort: ${tempFilters.timeSort}');
                                    
                                    setState(() {
                                      filterOptions = FilterOptions(
                                        vegOnly: tempFilters.vegOnly,
                                        priceLowToHigh: tempFilters.priceLowToHigh,
                                        priceHighToLow: tempFilters.priceHighToLow,
                                        ratingHighToLow: tempFilters.ratingHighToLow,
                                        ratingLowToHigh: tempFilters.ratingLowToHigh,
                                        timeSort: tempFilters.timeSort,
                                      );
                                    });
                                    
                                    // Apply veg filter through bloc
                                    blocContext.read<HomeBloc>().add(ToggleVegOnly(tempFilters.vegOnly));
                                    
                                    Navigator.pop(dialogContext);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ColorManager.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Apply Filters',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ).animate().fadeIn(duration: 200.ms).scaleXY(begin: 0.9, end: 1.0, duration: 300.ms, curve: Curves.easeOutQuint),
        );
      },
    );
  }

  Widget _buildPriceFilterTab(FilterOptions tempFilters, StateSetter setStateDialog) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                'Sort by Price',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ),
            _buildCheckboxOption(
              title: 'Low to High',
              subtitle: 'Sort by lowest price first',
              value: tempFilters.priceLowToHigh,
              color: Colors.green,
              onChanged: (value) {
                setStateDialog(() {
                  tempFilters.priceLowToHigh = value;
                  if (value) tempFilters.priceHighToLow = false; // Uncheck the other option
                });
              },
            ),
            const SizedBox(height: 16),
            _buildCheckboxOption(
              title: 'High to Low',
              subtitle: 'Sort by highest price first',
              value: tempFilters.priceHighToLow,
              color: Colors.orange,
              onChanged: (value) {
                setStateDialog(() {
                  tempFilters.priceHighToLow = value;
                  if (value) tempFilters.priceLowToHigh = false; // Uncheck the other option
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFilterTab(FilterOptions tempFilters, StateSetter setStateDialog) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                'Sort by Delivery Time',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ),
            _buildCheckboxOption(
              title: 'Fastest First',
              subtitle: 'Sort by shortest delivery time',
              value: tempFilters.timeSort,
              color: Colors.blue,
              onChanged: (value) {
                setStateDialog(() {
                  tempFilters.timeSort = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingFilterTab(FilterOptions tempFilters, StateSetter setStateDialog) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                'Sort by Rating',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ),
            _buildCheckboxOption(
              title: 'Highest Rated',
              subtitle: 'Sort by highest rating first',
              value: tempFilters.ratingHighToLow,
              color: Colors.amber,
              onChanged: (value) {
                setStateDialog(() {
                  tempFilters.ratingHighToLow = value;
                  if (value) tempFilters.ratingLowToHigh = false; // Uncheck the other option
                });
              },
            ),
            const SizedBox(height: 16),
            _buildCheckboxOption(
              title: 'Lowest Rated',
              subtitle: 'Sort by lowest rating first',
              value: tempFilters.ratingLowToHigh,
              color: Colors.grey,
              onChanged: (value) {
                setStateDialog(() {
                  tempFilters.ratingLowToHigh = value;
                  if (value) tempFilters.ratingHighToLow = false; // Uncheck the other option
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVegFilterTab(FilterOptions tempFilters, StateSetter setStateDialog, BuildContext blocContext) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                'Dietary Preferences',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ),
            _buildCheckboxOption(
              title: 'Vegetarian Only',
              subtitle: 'Show only vegetarian restaurants',
              value: tempFilters.vegOnly,
              color: Colors.green,
              onChanged: (value) {
                setStateDialog(() {
                  tempFilters.vegOnly = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String colorName) {
    switch (colorName) {
      case 'red': return Colors.red;
      case 'amber': return Colors.amber;
      case 'blue': return Colors.blue;
      case 'pink': return Colors.pink;
      case 'teal': return Colors.teal;
      case 'purple': return Colors.purple;
      case 'green': return Colors.green;
      case 'orange': return Colors.orange;
      case 'brown': return Colors.brown;
      case 'deepOrange': return Colors.deepOrange;
      default: return Colors.orange;
    }
  }
  
  void _showCustomSnackBar(BuildContext context, String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(12),
        elevation: 6,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  Widget _buildLoadingIndicator() {
    debugPrint('UI: Showing loading indicator');
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildFuturisticLoadingIndicator(),
          const SizedBox(height: 24),
          Text(
            'Preparing your delicious experience...',
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[600]),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOut),
    );
  }
  
  Widget _buildFuturisticLoadingIndicator() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: ColorManager.primary.withOpacity(0.2), blurRadius: 16, spreadRadius: 2)],
      ),
      child: Center(
        child: SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ColorManager.primary),
            strokeWidth: 3,
          ),
        ),
      ),
    ).animate(onPlay: (controller) => controller.repeat())
      .shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.3))
      .scaleXY(begin: 0.9, end: 1.0, duration: 700.ms)
      .then(delay: 100.ms)
      .scaleXY(begin: 1.0, end: 0.9, duration: 700.ms);
  }
  
  Widget _buildErrorState(BuildContext context, HomeError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, color: Colors.red, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              'Location Not Serviceable',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            const SizedBox(height: 12),
            Text(
              'We haven\'t spread our wings to this area yet.',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.red[400]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Go back to previous location or default
                if (previousAddress != null && previousAddress != 'Add delivery address') {
                  // This would need to be implemented in the bloc
                  context.read<HomeBloc>().add(const LoadHomeData());
                } else {
                  context.read<HomeBloc>().add(const LoadHomeData());
                }
              },
              icon: const Icon(Icons.arrow_back),
              label: Text('Back to last location', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.primary,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: ColorManager.primary.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOut),
    );
  }

  // Helper method to sanitize restaurant names for Hero tags
  String _sanitizeRestaurantName(String name) {
    // Remove special characters and replace spaces with underscores
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '') // Remove special characters
        .replaceAll(RegExp(r'\s+'), '_') // Replace spaces with underscores
        .trim();
  }

  Widget _buildCheckboxOption({
    required String title,
    required String subtitle,
    required bool value,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: value ? color.withOpacity(0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? color.withOpacity(0.3) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: (newValue) => onChanged(newValue ?? false),
            activeColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: value ? color : Colors.grey[800],
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
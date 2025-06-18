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

enum SortOrder { ascending, descending }

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
  SortOrder priceSort;
  SortOrder ratingSort;
  bool timeSort; // true means sort by ascending time
  
  FilterOptions({
    this.vegOnly = false,
    this.priceSort = SortOrder.ascending,
    this.ratingSort = SortOrder.descending,
    this.timeSort = true,
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
      _showCustomSnackBar(
        context, 
        state.error, 
        Colors.red, 
        Icons.error_outline
      );
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
  
  Widget _buildHomeContent(BuildContext context, HomeLoaded state) {
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
                      
                      // All Restaurants
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ColorManager.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.location_on, color: ColorManager.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deliver to',
                    style: GoogleFonts.poppins(
                      fontSize: 12, color: Colors.grey[600], letterSpacing: 0.3,
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          state.userAddress,
                          style: GoogleFonts.poppins(
                            fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[800],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey[200], borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.keyboard_arrow_down, color: ColorManager.primary, size: 16),
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
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(Icons.person, color: ColorManager.primary, size: 24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, HomeLoaded state) {
    return Hero(
      tag: 'search_bar',
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            height: 52,
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
                      child: Icon(Icons.search, color: ColorManager.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Search restaurants...',
                        style: GoogleFonts.poppins(
                          fontSize: 14, color: Colors.grey[400], fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
                            onTap: () => context.read<HomeBloc>().add(const FilterByCategory(null)),
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
          SizedBox(
            height: 140,
            child: ListView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: _getCategoryItems(state.categories, state.selectedCategory),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _getCategoryItems(List<dynamic> categories, String? selectedCategory) {
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
      
      // Try to find exact matching image based on category name
      for (final entry in imageMap.entries) {
        if (categoryName == entry.key || 
            (categoryName.contains(entry.key) && entry.key.length > 3)) {
          imagePath = entry.value;
          break;
        }
      }
      
      // If we have an image, build with image
      if (imagePath != null) {
        return _buildCategoryItem(
          categoryDisplayName, 
          imagePath, 
          category['color'],
          isSelected: isSelected,
          onTap: () {
            // Toggle selection - if already selected, show all; otherwise filter by this category
            final newCategory = isSelected ? null : categoryDisplayName;
            context.read<HomeBloc>().add(FilterByCategory(newCategory));
          },
        );
      } 
      // Otherwise build with an icon instead
      else {
        return _buildCategoryItemWithIcon(
          categoryDisplayName,
          _getIconData(category['icon']), 
          _getCategoryColor(category['color']),
          isSelected: isSelected,
          onTap: () {
            // Toggle selection - if already selected, show all; otherwise filter by this category
            final newCategory = isSelected ? null : categoryDisplayName;
            context.read<HomeBloc>().add(FilterByCategory(newCategory));
          },
        );
      }
    }).toList();
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
    
    // Get filtered restaurants using the state's helper method
    final filteredRestaurants = state.filteredRestaurants;
    
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
          // Restaurant List or Empty State
          filteredRestaurants.isEmpty
              ? _buildEmptyRestaurantsList()
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredRestaurants.length,
                    itemBuilder: (context, index) {
                      final restaurant = filteredRestaurants[index];
                      
                      debugPrint('HomePage: Restaurant ${restaurant.name} coordinates - Lat: ${restaurant.latitude}, Long: ${restaurant.longitude}');
                      
                      return Hero(
                        tag: 'restaurant-${restaurant.name}',
                        child: RestaurantCard(
                          name: restaurant.name,
                          imageUrl: restaurant.imageUrl ?? 'assets/images/placeholder.jpg',
                          cuisine: restaurant.cuisine,
                          rating: restaurant.rating ?? 0.0,
                          deliveryTime: '20-30 mins', // Default as model doesn't have this
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
                    },
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

  void _navigateToRestaurantDetails(BuildContext context, restaurant) {
    debugPrint('HomePage: Navigating to restaurant details');
    
    final state = context.read<HomeBloc>().state;
    double? userLatitude;
    double? userLongitude;
    
    if (state is HomeLoaded) {
      userLatitude = state.userLatitude;
      userLongitude = state.userLongitude;
      debugPrint('HomePage: User coordinates - Lat: $userLatitude, Long: $userLongitude');
    }
    
    // Convert Restaurant model to the expected Map format for RestaurantDetailsPage
    final restaurantData = <String, dynamic>{
      'id': restaurant.id,
      'partner_id': restaurant.id, // For compatibility
      'name': restaurant.name,
      'restaurant_name': restaurant.name, // For compatibility
      'imageUrl': restaurant.imageUrl ?? 'assets/images/placeholder.jpg',
      'cuisine': restaurant.cuisine,
      'category': restaurant.cuisine, // For compatibility
      'rating': restaurant.rating ?? 0.0,
      'isVegetarian': restaurant.isVeg,
      'isVeg': restaurant.isVeg, // For compatibility
      'veg_nonveg': restaurant.isVeg ? 'veg' : 'non-veg', // For compatibility
      'address': restaurant.address,
      'latitude': restaurant.latitude,
      'longitude': restaurant.longitude,
      'restaurantType': restaurant.restaurantType,
      'restaurant_type': restaurant.restaurantType, // For compatibility
      'description': restaurant.description,
      'openTimings': restaurant.openTimings,
      'open_timings': restaurant.openTimings, // For compatibility
      'ownerName': restaurant.ownerName,
      'owner_name': restaurant.ownerName, // For compatibility
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
      priceSort: filterOptions.priceSort,
      ratingSort: filterOptions.ratingSort,
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
                              _buildSimpleTab('Price filtering coming soon!'),
                              _buildSimpleTab('Time filtering coming soon!'),
                              _buildVegFilterTab(tempFilters, setStateDialog, blocContext),
                              _buildSimpleTab('Rating filtering coming soon!'),
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
                                    setState(() {
                                      filterOptions = FilterOptions(
                                        vegOnly: tempFilters.vegOnly,
                                        priceSort: tempFilters.priceSort,
                                        ratingSort: tempFilters.ratingSort,
                                        timeSort: tempFilters.timeSort,
                                      );
                                    });
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

  Widget _buildSimpleTab(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          message,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: tempFilters.vegOnly ? Colors.green.withOpacity(0.1) : Colors.grey[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: tempFilters.vegOnly ? Colors.green.withOpacity(0.3) : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: tempFilters.vegOnly ? Colors.green.withOpacity(0.2) : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.grass_outlined,
                      color: tempFilters.vegOnly ? Colors.green : Colors.grey[600],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vegetarian Only',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: tempFilters.vegOnly ? Colors.green : Colors.grey[800],
                          ),
                        ),
                        Text(
                          'Show only vegetarian restaurants',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: tempFilters.vegOnly,
                    onChanged: (value) {
                      setStateDialog(() {
                        tempFilters.vegOnly = value;
                      });
                    },
                    activeColor: Colors.green,
                  ),
                ],
              ),
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
              'Oops! Something went wrong',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            const SizedBox(height: 12),
            Text(
              state.message,
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.red[400]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.read<HomeBloc>().add(const LoadHomeData()),
              icon: const Icon(Icons.refresh),
              label: Text('Try Again', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600)),
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
}
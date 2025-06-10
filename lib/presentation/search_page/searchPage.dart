// lib/presentation/screens/search/view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../constants/color/colorConstant.dart';
import '../../../widgets/restaurant_card.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';

class SearchPage extends StatefulWidget {
  final double? userLatitude;
  final double? userLongitude;
  
  const SearchPage({
    Key? key,
    this.userLatitude,
    this.userLongitude,
  }) : super(key: key);
  
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    
    debugPrint('SearchPage: Initialized with user coordinates - Lat: ${widget.userLatitude}, Long: ${widget.userLongitude}');
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    
    // Initialize search bloc
    context.read<SearchBloc>().add(SearchInitialEvent(
      latitude: widget.userLatitude,
      longitude: widget.userLongitude,
    ));
    
    // Auto-focus the search field when the page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  void _filterRestaurants(String query) {
    debugPrint('SearchPage: Query changed to: "$query"');
    context.read<SearchBloc>().add(SearchQueryChangedEvent(
      query: query,
      latitude: widget.userLatitude,
      longitude: widget.userLongitude,
    ));
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(
          backgroundColor: const Color(0xFFF8F9FF),
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
          elevation: 0,
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildResultsHeader(),
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchBar() {
    return Hero(
      tag: 'search_bar',
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
                spreadRadius: 2,
              ),
            ],
            border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
          ),
          child: Row(
            children: [
              // Back button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(50),
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.grey[800],
                      size: 22,
                    ),
                  ),
                ),
              ),
              
              // Search input
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search restaurants or dishes',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.grey[400],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onChanged: _filterRestaurants,
                ),
              ),
              
              // Clear button
              if (_searchController.text.isNotEmpty)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: () {
                      _searchController.clear();
                      context.read<SearchBloc>().add(SearchClearEvent());
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.close,
                        color: Colors.grey[500],
                        size: 18,
                      ),
                    ),
                  ),
                ),
              
              // Filter button
              Container(
                margin: const EdgeInsets.only(right: 4),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: () {
                      // Filter functionality would be implemented here
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.tune,
                        color: ColorManager.primary,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildResultsHeader() {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        String headerText = 'Search Results';
        int? resultCount;
        
        if (state is SearchLoadedState) {
          resultCount = state.restaurants.length + state.menuItems.length;
          headerText = 'Search Results';
        } else if (state is SearchEmptyState && state.query.isNotEmpty) {
          resultCount = 0;
          headerText = 'No Results';
        } else if (state is SearchLoadingState) {
          headerText = 'Searching...';
        }
        
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Text(
                headerText,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                  letterSpacing: 0.2,
                ),
              ),
              if (resultCount != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ColorManager.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$resultCount',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ColorManager.primary,
                    ),
                  ),
                ),
              ],
            ],
          ).animate(controller: _animationController)
           .fadeIn(duration: 400.ms, delay: 150.ms, curve: Curves.easeOut)
           .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),
        );
      },
    );
  }
  
  Widget _buildSearchResults() {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        if (state is SearchLoadingState) {
          return Center(
            child: CircularProgressIndicator(
              color: ColorManager.primary,
            ),
          );
        }
        
        if (state is SearchErrorState) {
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
                  'Something went wrong',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.error,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ).animate(controller: _animationController)
             .fadeIn(duration: 400.ms, delay: 200.ms, curve: Curves.easeOut),
          );
        }
        
        if (state is SearchEmptyState) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  state.query.isEmpty ? Icons.search : Icons.search_off,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  state.query.isEmpty 
                    ? 'Start typing to search'
                    : 'No restaurants found',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  state.query.isEmpty
                    ? 'Search for restaurants, dishes, or cuisines'
                    : 'Try searching with different keywords',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ).animate(controller: _animationController)
             .fadeIn(duration: 400.ms, delay: 200.ms, curve: Curves.easeOut),
          );
        }
        
        if (state is SearchLoadedState) {
          return _buildResultsList(state);
        }
        
        return const SizedBox.shrink();
      },
    );
  }
  
  Widget _buildResultsList(SearchLoadedState state) {
    // Convert SearchRestaurant to the format expected by existing RestaurantCard
    final List<Map<String, dynamic>> convertedRestaurants = state.restaurants.map((restaurant) {
      debugPrint('SearchPage: Converting restaurant ${restaurant.restaurantName} coordinates - Lat: ${restaurant.latitude}, Long: ${restaurant.longitude}');
      
      return {
        'name': restaurant.restaurantName,
        'imageUrl': restaurant.restaurantPhotos.isNotEmpty 
          ? restaurant.restaurantPhotos.first 
          : 'assets/images/placeholder.jpg',
        'cuisine': restaurant.category,
        'rating': restaurant.rating,
        'deliveryTime': '${(restaurant.distance / 1000).toStringAsFixed(1)} km',
        'isVegetarian': false, // This info is not available in the new API response
        'latitude': restaurant.latitude.toString(),
        'longitude': restaurant.longitude.toString(),
        'partner_id': restaurant.partnerId,
      };
    }).toList();

    // If there are also menu items, we could show them separately
    // For now, let's focus on restaurants to keep the original UI
    if (convertedRestaurants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No restaurants found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching with different keywords',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ).animate(controller: _animationController)
         .fadeIn(duration: 400.ms, delay: 200.ms, curve: Curves.easeOut),
      );
    }
    
    // Use the same GridView structure as the original
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1, // Keep as 1 to maintain original UI layout
        childAspectRatio: 1.6, // Same as original
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: convertedRestaurants.length,
      itemBuilder: (context, index) {
        final restaurant = convertedRestaurants[index];
        
        // Extract coordinates for debugging
        final restaurantLat = restaurant['latitude'] != null 
            ? double.tryParse(restaurant['latitude'].toString())
            : null;
        final restaurantLng = restaurant['longitude'] != null 
            ? double.tryParse(restaurant['longitude'].toString())
            : null;
            
        debugPrint('SearchPage: Restaurant ${restaurant['name']} coordinates - Lat: $restaurantLat, Long: $restaurantLng');
        
        // Using the same RestaurantCard as in the original
        return Hero(
          tag: 'restaurant-${restaurant['name']}',
          child: RestaurantCard(
            name: restaurant['name'],
            imageUrl: restaurant['imageUrl'] ?? 'assets/images/placeholder.jpg',
            cuisine: restaurant['cuisine'],
            rating: restaurant['rating'] ?? 0.0,
            deliveryTime: restaurant['deliveryTime'] ?? '30 min',
            isVeg: restaurant['isVegetarian'] as bool? ?? false,
            // Pass restaurant and user coordinates
            restaurantLatitude: restaurantLat,
            restaurantLongitude: restaurantLng,
            userLatitude: widget.userLatitude,
            userLongitude: widget.userLongitude,
            onTap: () => Navigator.pop(context, restaurant),
          ).animate(controller: _animationController)
            .fadeIn(duration: 400.ms, delay: (300 + (index * 75)).ms, curve: Curves.easeOut)
            .slideY(begin: 0.1, end: 0, duration: 400.ms, delay: (300 + (index * 50)).ms, curve: Curves.easeOutQuad),
        );
      },
    );
  }
}
import 'package:bird/constants/color/colorConstant.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/restaurant_card.dart';

class SearchPage extends StatefulWidget {
  final List<Map<String, dynamic>> restaurants;
  final double? userLatitude;
  final double? userLongitude;
  
  const SearchPage({
    Key? key,
    required this.restaurants,
    this.userLatitude,
    this.userLongitude,
  }) : super(key: key);
  
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
  late TextEditingController _searchController;
  late List<Map<String, dynamic>> _filteredRestaurants;
  late FocusNode _searchFocusNode;
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _filteredRestaurants = widget.restaurants;
    
    debugPrint('SearchPage: Initialized with user coordinates - Lat: ${widget.userLatitude}, Long: ${widget.userLongitude}');
    debugPrint('SearchPage: Loaded ${widget.restaurants.length} restaurants');
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    
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
    if (query.isEmpty) {
      setState(() {
        _filteredRestaurants = widget.restaurants;
      });
      return;
    }
    
    debugPrint('SearchPage: Filtering restaurants with query: "$query"');
    
    // Split the search query into individual words
    final queryWords = query.toLowerCase().split(' ');
    
    // Create a map to store relevance scores
    final Map<Map<String, dynamic>, int> scoreMap = {};
    
    // Filter and score restaurants by relevance
    final results = widget.restaurants.where((restaurant) {
      final name = restaurant['name'].toString().toLowerCase();
      final cuisine = restaurant['cuisine'].toString().toLowerCase();
      
      // Calculate a relevance score based on how well the restaurant matches query terms
      int score = 0;
      bool matchesAnyTerm = false;
      
      for (final word in queryWords) {
        if (word.isEmpty) continue;
        
        // Check if restaurant name contains the query word
        if (name.contains(word)) {
          matchesAnyTerm = true;
          // Give higher score if it's an exact match or starts with the query word
          if (name == word) {
            score += 10; // Exact match
          } else if (name.startsWith(word)) {
            score += 8; // Starts with the query word
          } else {
            score += 5; // Contains the query word
          }
        }
        
        // Check if cuisine contains the query word
        if (cuisine.contains(word)) {
          matchesAnyTerm = true;
          score += 3;
        }
      }
      
      if (matchesAnyTerm) {
        scoreMap[restaurant] = score;
      }
      
      return matchesAnyTerm;
    }).toList();
    
    // Sort by relevance score (highest first)
    results.sort((a, b) => (scoreMap[b] ?? 0).compareTo(scoreMap[a] ?? 0));
    
    debugPrint('SearchPage: Found ${results.length} matching restaurants');
    
    setState(() {
      _filteredRestaurants = results;
    });
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
                      _filterRestaurants('');
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Text(
            'Search Results',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
              letterSpacing: 0.2,
            ),
          ),
          if (_searchController.text.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: ColorManager.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '${_filteredRestaurants.length}',
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
  }
  
  Widget _buildSearchResults() {
    if (_filteredRestaurants.isEmpty) {
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
    
    // Use GridView with a higher childAspectRatio to reduce the height of each card
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1, // Keep as 1 to maintain original UI layout
        childAspectRatio: 1.6, // Increased from 1.2 to reduce card height
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: _filteredRestaurants.length,
      itemBuilder: (context, index) {
        final restaurant = _filteredRestaurants[index];
        
        // Extract coordinates for debugging
        final restaurantLat = restaurant['latitude'] != null 
            ? double.tryParse(restaurant['latitude'].toString())
            : null;
        final restaurantLng = restaurant['longitude'] != null 
            ? double.tryParse(restaurant['longitude'].toString())
            : null;
            
        debugPrint('SearchPage: Restaurant ${restaurant['name']} coordinates - Lat: $restaurantLat, Long: $restaurantLng');
        
        // Using the same RestaurantCard as in homepage
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
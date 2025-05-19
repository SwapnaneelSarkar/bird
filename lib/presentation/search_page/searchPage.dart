// Modified SearchPage to use our enhanced RestaurantCard
import 'package:bird/constants/color/colorConstant.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../widgets/restaurant_card.dart'; // Import our restaurant card

class SearchPage extends StatefulWidget {
  final List<Map<String, dynamic>> restaurants;
  
  const SearchPage({
    Key? key,
    required this.restaurants,
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
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
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
    
    setState(() {
      _filteredRestaurants = results;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: AppBar(
          backgroundColor: Colors.grey[50],
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
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Text(
            'All Restaurants',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
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
       .fadeIn(duration: 300.ms, delay: 150.ms)
       .slideY(begin: 0.2, end: 0, duration: 300.ms, curve: Curves.easeOutQuad),
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
         .fadeIn(duration: 300.ms, delay: 200.ms),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredRestaurants.length,
      itemBuilder: (context, index) {
        final restaurant = _filteredRestaurants[index];
        
        // Using our enhanced restaurant card with horizontal layout
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: RestaurantCard(
            name: restaurant['name'] ?? '',
            imageUrl: restaurant['imageUrl'] ?? 'assets/images/placeholder.jpg',
            cuisine: restaurant['cuisine'] ?? 'Restaurant',
            rating: restaurant['rating'] ?? 0.0,
            price: restaurant['price'] ?? '₹200 for two',
            deliveryTime: restaurant['deliveryTime'] ?? '30 min',
            isVeg: restaurant['isVegetarian'] as bool? ?? false,
            onTap: () => Navigator.pop(context, restaurant),
            isHorizontal: true, // Using horizontal layout for search results
          ).animate(controller: _animationController)
           .fadeIn(duration: 300.ms, delay: 100.ms + (index * 50).ms)
           .slideY(begin: 0.1, end: 0, duration: 300.ms, delay: 100.ms + (index * 50).ms, curve: Curves.easeOutQuad),
        );
      },
    );
  }
}
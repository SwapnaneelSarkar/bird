// lib/presentation/screens/search/view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import '../../../constants/color/colorConstant.dart';
import '../../../widgets/restaurant_card.dart';
import '../../../widgets/responsive_text.dart';
import '../restaurant_menu/view.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';

class SearchPage extends StatefulWidget {
  final double? userLatitude;
  final double? userLongitude;
  final String? supercategoryId; // <-- Add this line
  
  const SearchPage({
    Key? key,
    this.userLatitude,
    this.userLongitude,
    this.supercategoryId, // <-- Add this line
  }) : super(key: key);
  
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with SingleTickerProviderStateMixin {
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;
  late AnimationController _animationController;
  
  // Voice search related
  late stt.SpeechToText _speechToText;
  bool _isListening = false;
  bool _speechEnabled = false;
  String _lastWords = '';
  
  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _speechToText = stt.SpeechToText();
    
    debugPrint('SearchPage: Initialized with user coordinates - Lat: ${widget.userLatitude}, Long: ${widget.userLongitude}');
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    
    // Initialize speech
    _initSpeech();
    
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
  
  /// This has to happen only once per app
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onStatus: (val) => debugPrint('Speech status: $val'),
      onError: (val) => debugPrint('Speech error: $val'),
    );
    setState(() {});
  }
  
  /// Each time to start a speech recognition session
  void _startListening() async {
    // Check microphone permission
    final microphoneStatus = await Permission.microphone.status;
    if (microphoneStatus.isDenied) {
      final result = await Permission.microphone.request();
      if (result.isDenied) {
        _showPermissionDialog();
        return;
      }
    }
    
    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: 'en_US',
      cancelOnError: true,
      listenMode: stt.ListenMode.confirmation,
    );
    setState(() {
      _isListening = true;
    });
    
    // Add haptic feedback
    HapticFeedback.mediumImpact();
  }

  /// Manually stop the active speech recognition session
  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
    
    // Add haptic feedback
    HapticFeedback.lightImpact();
  }

  /// This is the callback that the SpeechToText plugin calls when
  /// the platform returns recognized words.
  void _onSpeechResult(result) {
    setState(() {
      _lastWords = result.recognizedWords;
      _searchController.text = _lastWords;
    });
    
    // Trigger search if we have results and speech is final
    if (result.finalResult && _lastWords.isNotEmpty) {
      _filterRestaurants(_lastWords);
      _stopListening();
    }
  }
  
  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: ResponsiveText(
            text: 'Microphone Permission',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
            ),
            maxFontSize: 18,
            minFontSize: 16,
          ),
          content: ResponsiveText(
            text: 'This app needs microphone access to use voice search. Please enable it in your device settings.',
            style: GoogleFonts.poppins(),
            maxFontSize: 16,
            minFontSize: 14,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: ResponsiveText(
                text: 'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                ),
                maxFontSize: 16,
                minFontSize: 14,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: ResponsiveText(
                text: 'Settings',
                style: GoogleFonts.poppins(
                  color: ColorManager.primary,
                  fontWeight: FontWeight.w600,
                ),
                maxFontSize: 16,
                minFontSize: 14,
              ),
            ),
          ],
        );
      },
    );
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
      supercategoryId: widget.supercategoryId, // Add supercategoryId parameter
    ));
  }
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
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
          _buildSearchBar(screenWidth, screenHeight),
          _buildResultsHeader(screenWidth, screenHeight),
          Expanded(
            child: _buildSearchResults(screenWidth, screenHeight),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchBar(double screenWidth, double screenHeight) {
    final searchBarHeight = screenHeight * 0.065; // Responsive height
    final horizontalPadding = screenWidth * 0.05; // Responsive padding
    
    return Hero(
      tag: 'search_bar',
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: EdgeInsets.fromLTRB(horizontalPadding, screenHeight * 0.02, horizontalPadding, screenHeight * 0.01),
          height: searchBarHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(screenWidth * 0.04),
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
                    padding: EdgeInsets.all(screenWidth * 0.03),
                    child: Icon(
                      Icons.arrow_back,
                      color: Colors.grey[800],
                      size: screenWidth * 0.055,
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
                    fontSize: screenWidth * 0.04,
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search Stores',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.04,
                      color: Colors.grey[400],
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                  ),
                  onChanged: _filterRestaurants,
                ),
              ),
              
              // Clear button
              if (_searchController.text.isNotEmpty && !_isListening)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: () {
                      _searchController.clear();
                      context.read<SearchBloc>().add(SearchClearEvent());
                      setState(() {});
                    },
                    child: Container(
                      padding: EdgeInsets.all(screenWidth * 0.02),
                      child: Icon(
                        Icons.close,
                        color: Colors.grey[500],
                        size: screenWidth * 0.045,
                      ),
                    ),
                  ),
                ),
              
              // Voice search button
              Container(
                margin: EdgeInsets.only(right: screenWidth * 0.02),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: _speechEnabled
                        ? (_isListening ? _stopListening : _startListening)
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.all(screenWidth * 0.02),
                      decoration: BoxDecoration(
                        color: _isListening 
                            ? ColorManager.primary.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _isListening
                            ? Icon(
                                Icons.mic,
                                key: const ValueKey('mic_on'),
                                color: ColorManager.primary,
                                size: screenWidth * 0.055,
                              )
                            : Icon(
                                Icons.mic_none,
                                key: const ValueKey('mic_off'),
                                color: _speechEnabled 
                                    ? ColorManager.primary 
                                    : Colors.grey[400],
                                size: screenWidth * 0.055,
                              ),
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
  
  Widget _buildResultsHeader(double screenWidth, double screenHeight) {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        String headerText = 'Search Results';
        int? resultCount;
        
        if (state is SearchLoadedState) {
          // Calculate the number of unique restaurant cards being shown
          // 1. Collect direct restaurant IDs
          final directIds = state.restaurants.map((r) => r.partnerId).toSet();
          // 2. Collect unique menu restaurant IDs not in direct
          final menuIds = state.menuItems
              .map((m) => m.restaurant.id)
              .where((id) => id.isNotEmpty && !directIds.contains(id))
              .toSet();
          resultCount = directIds.length + menuIds.length;
          headerText = 'Search Results';
        } else if (state is SearchEmptyState && state.query.isNotEmpty) {
          resultCount = 0;
          headerText = 'No Results';
        } else if (state is SearchLoadingState) {
          headerText = 'Searching...';
        }
        
        return Padding(
          padding: EdgeInsets.fromLTRB(screenWidth * 0.05, screenHeight * 0.02, screenWidth * 0.05, screenHeight * 0.01),
          child: Row(
            children: [
              Expanded(
                child: ResponsiveText(
                  text: headerText,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                    letterSpacing: 0.2,
                  ),
                  maxFontSize: screenWidth * 0.055,
                  minFontSize: screenWidth * 0.045,
                ),
              ),
              if (resultCount != null) ...[
                SizedBox(width: screenWidth * 0.02),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.025, vertical: screenHeight * 0.005),
                  decoration: BoxDecoration(
                    color: ColorManager.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(screenWidth * 0.04),
                  ),
                  child: ResponsiveText(
                    text: '$resultCount',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: ColorManager.primary,
                    ),
                    maxFontSize: screenWidth * 0.035,
                    minFontSize: screenWidth * 0.03,
                  ),
                ),
              ],
              // Show listening indicator
              if (_isListening) ...[
                SizedBox(width: screenWidth * 0.03),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02, vertical: screenHeight * 0.005),
                  decoration: BoxDecoration(
                    color: ColorManager.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: screenWidth * 0.03,
                        height: screenWidth * 0.03,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            ColorManager.primary,
                          ),
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.015),
                      ResponsiveText(
                        text: 'Listening...',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          color: ColorManager.primary,
                        ),
                        maxFontSize: screenWidth * 0.03,
                        minFontSize: screenWidth * 0.025,
                      ),
                    ],
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
  
  Widget _buildSearchResults(double screenWidth, double screenHeight) {
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
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.05),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: screenWidth * 0.15,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  ResponsiveText(
                    text: 'Something went wrong',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                    maxFontSize: screenWidth * 0.05,
                    minFontSize: screenWidth * 0.04,
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  ResponsiveText(
                    text: state.error,
                    style: GoogleFonts.poppins(
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                    maxFontSize: screenWidth * 0.035,
                    minFontSize: screenWidth * 0.03,
                  ),
                ],
              ).animate(controller: _animationController)
               .fadeIn(duration: 400.ms, delay: 200.ms, curve: Curves.easeOut),
            ),
          );
        }
        
        if (state is SearchEmptyState) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.05),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    state.query.isEmpty ? Icons.search : Icons.search_off,
                    size: screenWidth * 0.15,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: screenHeight * 0.02),
                  ResponsiveText(
                    text: state.query.isEmpty 
                      ? 'Start typing or speak to search'
                      : 'No stores found',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                    maxFontSize: screenWidth * 0.05,
                    minFontSize: screenWidth * 0.04,
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  ResponsiveText(
                    text: state.query.isEmpty
                      ? 'Search for restaurants, dishes, or cuisines\nTap the mic icon to use voice search'
                      : 'Try searching with different keywords',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                    maxFontSize: screenWidth * 0.035,
                    minFontSize: screenWidth * 0.03,
                  ),
                ],
              ).animate(controller: _animationController)
               .fadeIn(duration: 400.ms, delay: 200.ms, curve: Curves.easeOut),
            ),
          );
        }
        
        if (state is SearchLoadedState) {
          return _buildResultsList(state, screenWidth, screenHeight);
        }
        
        return const SizedBox.shrink();
      },
    );
  }
  
  Widget _buildResultsList(SearchLoadedState state, double screenWidth, double screenHeight) {
    // 1. Collect direct restaurants
    final List<Map<String, dynamic>> directRestaurants = state.restaurants.map((restaurant) {
      final categoryString = restaurant.categories.join(', ');
      return {
        'id': restaurant.partnerId,
        'partner_id': restaurant.partnerId,
        'name': restaurant.restaurantName,
        'restaurant_name': restaurant.restaurantName,
        'imageUrl': restaurant.restaurantPhotos.isNotEmpty 
          ? restaurant.restaurantPhotos.first 
          : 'assets/images/placeholder.jpg',
        'cuisine': categoryString,
        'category': categoryString,
        'rating': restaurant.rating,
        'isVegetarian': false,
        'isVeg': false,
        'veg_nonveg': 'non-veg',
        'address': restaurant.address,
        'latitude': restaurant.latitude.toString(),
        'longitude': restaurant.longitude.toString(),
        'distance': restaurant.distance,
        'description': '',
        'open_timings': '',
        'owner_name': '',
        'restaurant_type': '',
        'isAcceptingOrder': 1,
        'supercategory': restaurant.supercategoryId ?? '', // Use the new field
      };
    }).toList();

    // 2. Collect unique restaurants from menu items
    final Map<String, Map<String, dynamic>> menuRestaurantsMap = {};
    for (final menuItem in state.menuItems) {
      final r = menuItem.restaurant;
      if (r.id.isEmpty) continue;
      if (directRestaurants.any((dr) => dr['partner_id'] == r.id)) continue;
      if (menuRestaurantsMap.containsKey(r.id)) continue;
      menuRestaurantsMap[r.id] = {
        'id': r.id,
        'partner_id': r.id,
        'name': r.name,
        'restaurant_name': r.name,
        'imageUrl': r.restaurantPhotos.isNotEmpty 
          ? r.restaurantPhotos.first 
          : 'assets/images/placeholder.jpg',
        'cuisine': r.cuisineType,
        'category': r.cuisineType,
        'rating': r.rating,
        'isVegetarian': false,
        'isVeg': false,
        'veg_nonveg': 'non-veg',
        'address': r.address,
        'latitude': r.latitude.toString(),
        'longitude': r.longitude.toString(),
        'distance': r.distance,
        'description': '',
        'open_timings': '',
        'owner_name': '',
        'restaurant_type': '',
        'isAcceptingOrder': 1,
        'supercategory': r.supercategoryId ?? '', // Use the new field
      };
    }
    final List<Map<String, dynamic>> menuRestaurants = menuRestaurantsMap.values.toList();

    // 3. Merge all unique restaurants
    List<Map<String, dynamic>> allRestaurants = [
      ...directRestaurants,
      ...menuRestaurants,
    ];

    // --- FILTER BY SUPERCATEGORY IF PASSED ---
    if (widget.supercategoryId != null && widget.supercategoryId!.isNotEmpty) {
      allRestaurants = allRestaurants.where((restaurant) {
        final supercat = restaurant['supercategory']?.toString() ?? '';
        return supercat == widget.supercategoryId;
      }).toList();
    }

    if (allRestaurants.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.05),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: screenWidth * 0.15,
                color: Colors.grey[400],
              ),
              SizedBox(height: screenHeight * 0.02),
              ResponsiveText(
                                    text: 'No stores found',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
                maxFontSize: screenWidth * 0.05,
                minFontSize: screenWidth * 0.04,
              ),
              SizedBox(height: screenHeight * 0.01),
              ResponsiveText(
                text: 'Try searching with different keywords',
                style: GoogleFonts.poppins(
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
                maxFontSize: screenWidth * 0.035,
                minFontSize: screenWidth * 0.03,
              ),
            ],
          ).animate(controller: _animationController)
           .fadeIn(duration: 400.ms, delay: 200.ms, curve: Curves.easeOut),
        ),
      );
    }
    
    // 4. Render all restaurants with responsive grid
    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.03, vertical: screenHeight * 0.015),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 1,
        childAspectRatio: 1.8,
        mainAxisSpacing: screenHeight * 0.01,
        crossAxisSpacing: screenWidth * 0.01,
        mainAxisExtent: screenHeight * 0.32, // Increased height for better fit
      ),
      itemCount: allRestaurants.length,
      itemBuilder: (context, index) {
        final restaurant = allRestaurants[index];
        final restaurantLat = restaurant['latitude'] != null 
            ? double.tryParse(restaurant['latitude'].toString())
            : null;
        final restaurantLng = restaurant['longitude'] != null 
            ? double.tryParse(restaurant['longitude'].toString())
            : null;
        final sanitizedName = _sanitizeRestaurantName(restaurant['name']);
        final uniqueHeroTag = 'search-result-${restaurant['partner_id']}-$sanitizedName';
        return Hero(
          tag: uniqueHeroTag,
          child: RestaurantCard(
            name: restaurant['name'],
            imageUrl: restaurant['imageUrl'] ?? 'assets/images/placeholder.jpg',
            cuisine: restaurant['cuisine'],
            rating: restaurant['rating'] ?? 0.0,
            isVeg: restaurant['isVegetarian'] as bool? ?? false,
            restaurantLatitude: restaurantLat,
            restaurantLongitude: restaurantLng,
            userLatitude: widget.userLatitude,
            userLongitude: widget.userLongitude,
            restaurantType: restaurant['restaurant_type'],
            isAcceptingOrder: restaurant['isAcceptingOrder'],
            onTap: () => _navigateToRestaurantDetails(context, restaurant),
          ).animate(controller: _animationController)
            .fadeIn(duration: 400.ms, delay: (300 + (index * 75)).ms, curve: Curves.easeOut)
            .slideY(begin: 0.1, end: 0, duration: 400.ms, delay: (300 + (index * 50)).ms, curve: Curves.easeOutQuad),
        );
      },
    );
  }

  // Helper method to sanitize restaurant names for Hero tags
  String _sanitizeRestaurantName(String name) {
    // Remove special characters and replace spaces with underscores
    // Add 'search-' prefix to ensure uniqueness from home page tags
    return 'search-' + name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '') // Remove special characters
        .replaceAll(RegExp(r'\s+'), '_') // Replace spaces with underscores
        .trim();
  }

  void _navigateToRestaurantDetails(BuildContext context, Map<String, dynamic> restaurant) {
    debugPrint('SearchPage: Navigating to restaurant details');
    
    // Convert restaurant data to the expected Map format for RestaurantDetailsPage
    final restaurantData = <String, dynamic>{
      'id': restaurant['partner_id'],
      'partner_id': restaurant['partner_id'],
      'name': restaurant['name'],
      'restaurant_name': restaurant['name'],
      'imageUrl': restaurant['imageUrl'],
      'cuisine': restaurant['cuisine'],
      'category': restaurant['cuisine'],
      'rating': restaurant['rating'],
      'isVegetarian': restaurant['isVegetarian'],
      'isVeg': restaurant['isVegetarian'],
      'veg_nonveg': restaurant['isVegetarian'] ? 'veg' : 'non-veg',
      'address': restaurant['address'],
      'latitude': restaurant['latitude'],
      'longitude': restaurant['longitude'],
      'restaurantType': restaurant['restaurant_type'],
      'restaurant_type': restaurant['restaurant_type'],
      'description': restaurant['description'],
      'openTimings': restaurant['open_timings'],
      'open_timings': restaurant['open_timings'],
      'ownerName': restaurant['owner_name'],
      'owner_name': restaurant['owner_name'],
      'availableCategories': restaurant['availableCategories'],
      'isAcceptingOrder': restaurant['isAcceptingOrder'],
    };
    
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => RestaurantDetailsPage(
          restaurantData: restaurantData,
          userLatitude: widget.userLatitude,
          userLongitude: widget.userLongitude,
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
}
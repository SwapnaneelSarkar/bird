// presentation/restaurant_menu/view.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bird/constants/color/colorConstant.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/router/router.dart';
import '../../widgets/food_item_card.dart';
import '../../widgets/cart_dialog.dart';
import '../../widgets/item_added_popup.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';
import '../../utils/currency_utils.dart';
import '../../utils/distance_util.dart';
import '../../utils/delivery_time_util.dart';
import '../../service/cart_service.dart';

class RestaurantDetailsPage extends StatelessWidget {
  final Map<String, dynamic> restaurantData;
  final double? userLatitude;
  final double? userLongitude;

  const RestaurantDetailsPage({
    Key? key,
    required this.restaurantData,
    this.userLatitude,
    this.userLongitude,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (restaurantData.isEmpty) {
      return Scaffold(
        appBar: AppBar(
                      title: const Text('Store Details'),
          leading: const BackButton(),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Store data not available', 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Please try selecting a store again', 
                style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text('Go Back')
              ),
            ],
          ),
        ),
      );
    }
    
    debugPrint('RestaurantDetailsPage: Building with user coordinates - Lat: $userLatitude, Long: $userLongitude');
    debugPrint('RestaurantDetailsPage: Restaurant data: $restaurantData');
    
    return BlocProvider(
      create: (context) => RestaurantDetailsBloc()..add(
        LoadRestaurantDetails(
          restaurantData,
          userLatitude: userLatitude,
          userLongitude: userLongitude,
        )),
      child: const _RestaurantDetailsContent(),
    );
  }
}

class _RestaurantDetailsContent extends StatefulWidget {
  const _RestaurantDetailsContent();

  @override
  State<_RestaurantDetailsContent> createState() => _RestaurantDetailsContentState();
}

class _RestaurantDetailsContentState extends State<_RestaurantDetailsContent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortOption = 'none';
  bool _isFilterMenuOpen = false;
  bool _isShowingConflictDialog = false;
  
  // Track previous quantities to detect first-time additions
  final Map<String, int> _previousQuantities = {};
  
  // Track if cart was empty when page loaded
  bool _wasCartEmpty = true;
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // Calculate distance between user and restaurant
  String _calculateDistance(Map<String, dynamic> restaurant) {
    // Get user coordinates from the parent widget
    final userLat = (context.findAncestorWidgetOfExactType<RestaurantDetailsPage>())?.userLatitude;
    final userLng = (context.findAncestorWidgetOfExactType<RestaurantDetailsPage>())?.userLongitude;
    final restaurantLat = restaurant['latitude'] != null 
        ? double.tryParse(restaurant['latitude'].toString())
        : null;
    final restaurantLng = restaurant['longitude'] != null 
        ? double.tryParse(restaurant['longitude'].toString())
        : null;
    
    if (userLat != null && userLng != null && 
        restaurantLat != null && restaurantLng != null) {
      try {
        final distance = DistanceUtil.calculateDistance(
          userLat, userLng, restaurantLat, restaurantLng
        );
        return DistanceUtil.formatDistance(distance);
      } catch (e) {
        debugPrint('Error calculating distance: $e');
        return 'Nearby';
      }
    }
    
    // Fallback to provided distance or default
    return restaurant['calculatedDistance'] ?? 
           restaurant['distance'] != null ? '${restaurant['distance']} km' : 'Nearby';
  }

  // Calculate delivery time based on distance
  String _calculateDeliveryTime(Map<String, dynamic> restaurant) {
    final userLat = (context.findAncestorWidgetOfExactType<RestaurantDetailsPage>())?.userLatitude;
    final userLng = (context.findAncestorWidgetOfExactType<RestaurantDetailsPage>())?.userLongitude;
    final restaurantLat = restaurant['latitude'] != null 
        ? double.tryParse(restaurant['latitude'].toString())
        : null;
    final restaurantLng = restaurant['longitude'] != null 
        ? double.tryParse(restaurant['longitude'].toString())
        : null;
    
    if (userLat != null && userLng != null && 
        restaurantLat != null && restaurantLng != null) {
      try {
        final distance = DistanceUtil.calculateDistance(
          userLat, userLng, restaurantLat, restaurantLng
        );
        return DeliveryTimeUtil.calculateDeliveryTime(distance);
      } catch (e) {
        debugPrint('Error calculating delivery time: $e');
        return '20-30 mins';
      }
    }
    
    // Fallback to default delivery time
    return '20-30 mins';
  }
  
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }
  
  void _toggleFilterMenu() {
    setState(() {
      _isFilterMenuOpen = !_isFilterMenuOpen;
    });
  }

  void _setSortOption(String option) {
    setState(() {
      _sortOption = option;
      _isFilterMenuOpen = false;
    });
  }
  
  List<Map<String, dynamic>> _filterAndSortMenu(List<Map<String, dynamic>> menu) {
    // First filter by search query
    List<Map<String, dynamic>> filteredMenu = _searchQuery.isEmpty
        ? List.from(menu)
        : menu.where((item) => 
            item['name'].toString().toLowerCase().contains(_searchQuery) ||
            (item['description'] != null && 
             item['description'].toString().toLowerCase().contains(_searchQuery))
          ).toList();
    
    // Then sort by price if needed
    if (_sortOption == 'price_asc') {
      filteredMenu.sort((a, b) => 
        (a['price'] as num).compareTo(b['price'] as num));
    } else if (_sortOption == 'price_desc') {
      filteredMenu.sort((a, b) => 
        (b['price'] as num).compareTo(a['price'] as num));
    }
    
    return filteredMenu;
  }

  // Group menu items by category using categories from API
  Map<String, List<Map<String, dynamic>>> _groupMenuByCategory(
    List<Map<String, dynamic>> menu, 
    List<Map<String, dynamic>> categories
  ) {
    final Map<String, List<Map<String, dynamic>>> groupedMenu = {};
    final List<Map<String, dynamic>> otherItems = [];
    
    // Create a map for quick category lookup
    final Map<String, String> categoryMap = {};
    for (final category in categories) {
      categoryMap[category['id']?.toString() ?? ''] = category['name']?.toString() ?? '';
    }
    
    // Group items by category
    for (final item in menu) {
      final categoryId = item['category']?.toString() ?? '';
      final categoryName = categoryMap[categoryId];
      
      if (categoryName != null && categoryName.isNotEmpty) {
        // Add to existing category or create new one
        groupedMenu.putIfAbsent(categoryName, () => []).add(item);
      } else {
        // Category not found, add to others
        otherItems.add(item);
      }
    }
    
    // Add "Others" section if there are items without matching categories
    if (otherItems.isNotEmpty) {
      groupedMenu['Others'] = otherItems;
    }
    
    // Sort categories by display order (preserve the order from API)
    final Map<String, List<Map<String, dynamic>>> sortedGroupedMenu = {};
    
    // First add categories in their API order
    for (final category in categories) {
      final categoryName = category['name']?.toString() ?? '';
      if (groupedMenu.containsKey(categoryName)) {
        sortedGroupedMenu[categoryName] = groupedMenu[categoryName]!;
      }
    }
    
    // Then add "Others" at the end if it exists
    if (groupedMenu.containsKey('Others')) {
      sortedGroupedMenu['Others'] = groupedMenu['Others']!;
    }
    
    return sortedGroupedMenu;
  }

  // Check if item was added for the first time and show popup
  void _checkAndShowPopup(String itemId, int newQuantity, Map<String, dynamic> item) {
    final previousQuantity = _previousQuantities[itemId] ?? 0;
    
    // Show popup only when:
    // 1. Quantity changes from 0 to 1 (first time addition for this item)
    // 2. Cart was empty when page loaded (first item added to empty cart)
    if (previousQuantity == 0 && newQuantity == 1 && _wasCartEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ItemAddedPopup.show(
          context: context,
          item: item,
          onViewCart: () {
            Navigator.pushReplacementNamed(context, Routes.orderConfirmation);
          },
          onContinueShopping: () {
            // Just close the popup, user can continue shopping
          },
        );
      });
      
      // Mark that cart is no longer empty after showing popup
      _wasCartEmpty = false;
    }
    
    // Update the previous quantities
    _previousQuantities[itemId] = newQuantity;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<RestaurantDetailsBloc, RestaurantDetailsState>(
        listener: (context, state) {
          if (state is CartConflictDetected && !_isShowingConflictDialog) {
            // Prevent multiple dialogs
            _isShowingConflictDialog = true;
            // Handle the dialog in the next frame to avoid state conflicts
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showCartConflictDialog(context, state).then((_) {
                _isShowingConflictDialog = false;
              });
            });
          } else if (state is RestaurantDetailsLoaded) {
            // Initialize previous quantities when state is loaded
            if (_previousQuantities.isEmpty) {
              _previousQuantities.addAll(state.cartQuantities);
              
              // Check if cart was empty when page loaded
              _wasCartEmpty = state.cartItemCount == 0;
            } else {
              // Track cart state changes dynamically
              // If cart becomes empty, reset the flag to allow popup on next addition
              if (state.cartItemCount == 0) {
                _wasCartEmpty = true;
              }
            }
          }
        },
        builder: (context, state) {
          debugPrint('🔄 VIEW: Current state type: ${state.runtimeType}');
          
          if (state is RestaurantDetailsLoading) {
            debugPrint('⏳ VIEW: Showing loading state');
            return const Center(child: CircularProgressIndicator());
          } else if (state is RestaurantDetailsLoaded) {
            debugPrint('✅ VIEW: Showing loaded content');
            return _buildUpdatedContent(context, state);
          } else if (state is CartConflictDetected) {
            debugPrint('⚠️ VIEW: Showing cart conflict state');
            // While dialog is being handled, show the previous loaded content
            return _buildUpdatedContent(context, state.previousState);
          } else if (state is RestaurantDetailsError) {
            debugPrint('❌ VIEW: Showing error state: ${state.message}');
            return _buildErrorContent(context, state);
          }
          
          debugPrint('🤷 VIEW: Showing default loading state');
          return const Center(child: CircularProgressIndicator());
        },
      ),
      // Add floating cart button
      floatingActionButton: BlocBuilder<RestaurantDetailsBloc, RestaurantDetailsState>(
        builder: (context, state) {
          if (state is RestaurantDetailsLoaded && state.cartItemCount > 0) {
            return _buildCartFloatingButton(context, state);
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildErrorContent(BuildContext context, RestaurantDetailsError state) {
    final isNetworkError = state.message.toLowerCase().contains('network error');
    if (isNetworkError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, size: 72, color: Colors.orangeAccent),
              const SizedBox(height: 24),
              Text(
                'No Internet Connection',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.orangeAccent,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'We couldn\'t connect to our servers.\nPlease check your Wi-Fi or mobile data and try again.',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () {
                  // Retry by reloading the restaurant details
                  final parent = context.findAncestorWidgetOfExactType<RestaurantDetailsPage>();
                  if (parent != null) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => RestaurantDetailsPage(
                          restaurantData: parent.restaurantData,
                          userLatitude: parent.userLatitude,
                          userLongitude: parent.userLongitude,
                        ),
                      ),
                    );
                  } else {
                    Navigator.of(context).pop();
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(state.message, style: const TextStyle(fontSize: 16, color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('Go Back')
            ),
          ],
        ),
      );
    }
  }

  Future<void> _showCartConflictDialog(BuildContext context, CartConflictDetected state) async {
    try {
      debugPrint('RestaurantDetailsView: Showing cart conflict dialog');
      
      final result = await CartConflictDialog.show(
        context: context,
        currentRestaurant: state.currentRestaurant,
        newRestaurant: state.newRestaurant,
      );
      
      if (result == true) {
        if (mounted) {
          context.read<RestaurantDetailsBloc>().add(
            ReplaceCartWithNewRestaurant(
              item: state.pendingItem,
              quantity: state.pendingQuantity,
            ),
          );
        }
      } else {
        if (mounted) {
          context.read<RestaurantDetailsBloc>().add(const DismissCartConflict());
        }
      }
    } catch (e) {
      debugPrint('RestaurantDetailsView: Error in cart conflict dialog: $e');
      if (mounted) {
        context.read<RestaurantDetailsBloc>().add(const DismissCartConflict());
      }
    }
  }

  Widget _buildUpdatedContent(BuildContext context, RestaurantDetailsLoaded state) {
    debugPrint('🏗️ VIEW: Building updated content');
    debugPrint('🏗️ VIEW: Restaurant data keys: ${state.restaurant.keys.toList()}');
    debugPrint('🏗️ VIEW: Address in state: "${state.restaurant['address']}"');
    
    final restaurant = state.restaurant;
    final filteredAndSortedMenu = _filterAndSortMenu(state.menu);
    final groupedMenu = _groupMenuByCategory(filteredAndSortedMenu, state.categories);
    
    return CustomScrollView(
      slivers: [
        // Scrollable header
        _buildSliverAppBar(context, restaurant),
        
        // Show appropriate message if menu is empty after filtering
        if (filteredAndSortedMenu.isEmpty) 
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    state.menu.isEmpty 
                        ? 'No menu items available'
                        : 'No items match your search',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.menu.isEmpty
                        ? 'This store has not added any items yet'
                        : 'Try a different search term or clear filters',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (state.menu.isNotEmpty && _searchQuery.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: ElevatedButton(
                        onPressed: () {
                          _searchController.clear();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorManager.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Clear Search'),
                      ),
                    ),
                ],
              ),
            ),
          )
        else ...[
          // Menu header with filter option
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Menu',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  GestureDetector(
                    onTap: _toggleFilterMenu,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                        color: _isFilterMenuOpen || _sortOption != 'none' 
                          ? ColorManager.primary.withOpacity(0.1) 
                          : Colors.white,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.filter_list, 
                            color: _sortOption != 'none' ? ColorManager.primary : Colors.grey[700], 
                            size: 18
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Sort', 
                            style: TextStyle(
                              fontSize: 14, 
                              color: _sortOption != 'none' ? ColorManager.primary : Colors.grey[700],
                              fontWeight: _sortOption != 'none' ? FontWeight.bold : FontWeight.normal,
                            )
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Filter dropdown menu
          if (_isFilterMenuOpen)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildFilterOption(
                      'Price: Low to High', 
                      'price_asc', 
                      Icons.arrow_upward
                    ),
                    Divider(height: 1, color: Colors.grey[200]),
                    _buildFilterOption(
                      'Price: High to Low', 
                      'price_desc', 
                      Icons.arrow_downward
                    ),
                    if (_sortOption != 'none') ...[
                      Divider(height: 1, color: Colors.grey[200]),
                      _buildFilterOption(
                        'Clear Sorting', 
                        'none', 
                        Icons.clear
                      ),
                    ],
                  ],
                ),
              ),
            ),
          
          // Menu sections with separators
          ...groupedMenu.entries.map((entry) {
            return [
              // Section header with separator
              SliverToBoxAdapter(
                child: _buildSectionHeader(entry.key, entry.value.length),
              ),
              
              // Menu items for this section
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final menuItem = entry.value[index];
                    final quantity = state.cartQuantities[menuItem['id']] ?? 0;
                    
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: FoodItemCard(
                        item: menuItem,
                        quantity: quantity,
                        onQuantityChanged: (newQuantity, {attributes}) {
                          context.read<RestaurantDetailsBloc>().add(
                            AddItemToCart(
                              item: menuItem,
                              quantity: newQuantity,
                              attributes: attributes,
                            ),
                          );
                          
                          // Check if this is the first time adding this item
                          _checkAndShowPopup(menuItem['id'], newQuantity, menuItem);
                        },
                      ),
                    );
                  },
                  childCount: entry.value.length,
                ),
              ),
            ];
          }).expand((widgets) => widgets).toList(),
          
          // Bottom padding for floating button
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).padding.bottom + 100,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSliverAppBar(BuildContext context, Map<String, dynamic> restaurant) {
    debugPrint('🏛️ VIEW: Building SliverAppBar');
    debugPrint('🏛️ VIEW: Restaurant data in AppBar: ${restaurant.keys.toList()}');
    debugPrint('🏛️ VIEW: Address in AppBar: "${restaurant['address']}"');
    
    return SliverAppBar(
      expandedHeight: 280,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back, color: ColorManager.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: ColorManager.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'restaurant_profile') {
                Navigator.pushNamed(
                  context,
                  Routes.restaurantProfile,
                  arguments: restaurant['id'],
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'restaurant_profile',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: ColorManager.primary, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Store Profile',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                ColorManager.primary,
                ColorManager.primary.withOpacity(0.9),
                Colors.white,
              ],
              stops: const [0.0, 0.3, 1.0],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  
                  // Restaurant info
                  _buildRestaurantInfo(restaurant),
                  
                  const SizedBox(height: 20),
                  
                  // Search bar
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: ColorManager.primary.withOpacity(0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search for dishes, categories...',
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey[500], 
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.search, color: ColorManager.primary, size: 22),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                              onTap: () => _searchController.clear(),
                              child: Container(
                                margin: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.clear, color: Colors.grey[600], size: 16),
                              ),
                            )
                          : null,
                      ),
                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantInfo(Map<String, dynamic> restaurant) {
    final isVeg = restaurant['isVeg'] == true || 
                 restaurant['veg_nonveg'] == 'veg' ||
                 (restaurant['veg_nonveg'] ?? '').toString().toLowerCase() == 'veg';
    
    final distance = _calculateDistance(restaurant);
    final rating = restaurant['rating']?.toString() ?? '0.0';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          restaurant['name'] ?? 'Restaurant',
          style: GoogleFonts.poppins(
            fontSize: 26, 
            fontWeight: FontWeight.bold, 
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(0, 1),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            // Rating
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: ColorManager.yellowAcc,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.white, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    rating,
                    style: GoogleFonts.poppins(
                      fontSize: 13, 
                      color: Colors.white, 
                      fontWeight: FontWeight.w700
                    ),
                  ),
                ],
              ),
            ),
            
            // Distance
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, color: ColorManager.primary, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    distance,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: ColorManager.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            // Delivery Time
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.access_time, color: ColorManager.primary, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    _calculateDeliveryTime(restaurant),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: ColorManager.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            // Veg indicator
            if (isVeg)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Center(
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Pure Veg',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String sectionName, int itemCount) {
    // Determine if this is the "Others" section
    final isOthersSection = sectionName == 'Others';
    
    return Container(
      margin: const EdgeInsets.only(top: 24, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Simple colored line indicator
          Container(
            width: 3,
            height: 20,
            decoration: BoxDecoration(
              color: isOthersSection ? Colors.grey[400] : ColorManager.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Category name
          Expanded(
            child: Text(
              sectionName,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          
          // Item count
          Text(
            '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterOption(String title, String option, IconData icon) {
    final isSelected = _sortOption == option;
    
    return InkWell(
      onTap: () => _setSortOption(option),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        color: isSelected ? ColorManager.primary.withOpacity(0.1) : Colors.transparent,
        child: Row(
          children: [
            Icon(
              icon, 
              size: 16, 
              color: isSelected ? ColorManager.primary : Colors.grey[700],
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: isSelected ? ColorManager.primary : Colors.black,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check, size: 16, color: ColorManager.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildCartFloatingButton(BuildContext context, RestaurantDetailsLoaded state) {
    final screenWidth = MediaQuery.of(context).size.width;
    final currentRestaurantId = state.restaurant['id']?.toString() ?? 
                              state.restaurant['partner_id']?.toString() ?? 
                              state.restaurant['partnerId']?.toString() ?? '';
    
    return FutureBuilder<Map<String, dynamic>?>(
      future: CartService.getCart(),
      builder: (context, cartSnapshot) {
        final cart = cartSnapshot.data;
        final cartPartnerId = cart?['partner_id']?.toString() ?? '';
        final cartHasItems = (cart?['items'] as List?)?.isNotEmpty ?? false;
        final showClear = cartHasItems && cartPartnerId.isNotEmpty && cartPartnerId != currentRestaurantId;
        
        return FutureBuilder<String>(
          future: CurrencyUtils.getCurrencySymbolFromUserLocation(),
          builder: (context, snapshot) {
            final currencySymbol = snapshot.data ?? '₹';
            
            return Container(
              width: screenWidth * 0.96,
              height: 70,
              margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.02, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(color: ColorManager.primary.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  // View Cart button (expanded)
                  Expanded(
                    flex: 3,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, Routes.orderConfirmation);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorManager.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${state.cartItemCount}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            'View Cart',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Text(
                            CurrencyUtils.formatPrice(state.cartTotal, currencySymbol),
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (showClear) ...[
                    const SizedBox(width: 14),
                    // Clear Cart button (icon)
                    SizedBox(
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () => _showClearCartDialog(context),
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        label: Text('Clear', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          foregroundColor: Colors.red,
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showClearCartDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08),
          child: Container(
            padding: EdgeInsets.all(screenWidth * 0.07),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: screenWidth * 0.15,
                  height: screenWidth * 0.15,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.delete_forever_rounded, color: Colors.red, size: screenWidth * 0.09),
                ),
                SizedBox(height: screenHeight * 0.025),
                Text(
                  'Clear All Items?',
                  style: GoogleFonts.poppins(
                    fontSize: screenWidth * 0.052,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.012),
                Text(
                  'Are you sure you want to remove all items from your cart? This action cannot be undone.',
                  style: GoogleFonts.poppins(
                    fontSize: screenWidth * 0.037,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.04),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.018),
                          side: BorderSide(color: Colors.grey[300]!, width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.038,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.04),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: screenHeight * 0.018),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Clear All',
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.038,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed == true && mounted) {
      context.read<RestaurantDetailsBloc>().add(const ClearCart());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.delete_forever_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Cart cleared successfully!')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.all(16),
          elevation: 6,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
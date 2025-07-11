// presentation/restaurant_menu/view.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bird/constants/color/colorConstant.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/font/fontManager.dart';
import '../../constants/router/router.dart';
import '../../widgets/food_item_card.dart';
import '../../widgets/cart_dialog.dart';
import '../../widgets/item_added_popup.dart';
import '../../models/attribute_model.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';
import '../../widgets/menu_item_attributes_dialog.dart';
import '../../utils/currency_utils.dart';

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
          title: const Text('Restaurant Details'),
          leading: const BackButton(),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Restaurant data not available', 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Please try selecting a restaurant again', 
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
      child: _RestaurantDetailsContent(),
    );
  }
}

class _RestaurantDetailsContent extends StatefulWidget {
  @override
  _RestaurantDetailsContentState createState() => _RestaurantDetailsContentState();
}

class _RestaurantDetailsContentState extends State<_RestaurantDetailsContent> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortOption = 'none';
  bool _isFilterMenuOpen = false;
  bool _isShowingConflictDialog = false;
  
  // Track previous quantities to detect first-time additions
  Map<String, int> _previousQuantities = {};
  
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
              _previousQuantities = Map.from(state.cartQuantities);
              
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
          if (state is RestaurantDetailsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is RestaurantDetailsLoaded) {
            return _buildUpdatedContent(context, state);
          } else if (state is CartConflictDetected) {
            // While dialog is being handled, show the previous loaded content
            return _buildUpdatedContent(context, state.previousState);
          } else if (state is RestaurantDetailsError) {
            final isNetworkError = state.message.toLowerCase().contains('network error');
            if (isNetworkError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off, size: 72, color: Colors.orangeAccent),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Future<void> _showCartConflictDialog(BuildContext context, CartConflictDetected state) async {
    try {
      debugPrint('RestaurantDetailsView: Showing cart conflict dialog');
      
      final result = await CartConflictDialog.show(
        context: context,
        currentRestaurant: state.currentRestaurant,
        newRestaurant: state.newRestaurant,
      );
      
      if (result == true) {
        context.read<RestaurantDetailsBloc>().add(
          ReplaceCartWithNewRestaurant(
            item: state.pendingItem,
            quantity: state.pendingQuantity,
          ),
        );
      } else {
        context.read<RestaurantDetailsBloc>().add(const DismissCartConflict());
      }
    } catch (e) {
      debugPrint('RestaurantDetailsView: Error in cart conflict dialog: $e');
      context.read<RestaurantDetailsBloc>().add(const DismissCartConflict());
    }
  }

  Widget _buildUpdatedContent(BuildContext context, RestaurantDetailsLoaded state) {
    Map<String, dynamic> restaurant = state.restaurant;
    List<Map<String, dynamic>> filteredAndSortedMenu = _filterAndSortMenu(state.menu);
    
    return RepaintBoundary(
      child: Column(
        children: [
          _buildSearchBar(context, restaurant),
          _buildRestaurantHeader(context, restaurant),
          
          // Show appropriate message if menu is empty after filtering
          if (filteredAndSortedMenu.isEmpty) 
            Expanded(
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
                          ? 'This restaurant has not added any items yet'
                          : 'Try a different search term or clear filters',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (!state.menu.isEmpty && _searchQuery.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: ElevatedButton(
                          onPressed: () {
                            _searchController.clear();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Clear Search'),
                        ),
                      ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Menu header with filter option
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Menu',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        GestureDetector(
                          onTap: _toggleFilterMenu,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(4),
                              color: _isFilterMenuOpen || _sortOption != 'none' 
                                ? Colors.grey[200] 
                                : Colors.white,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.filter_list, 
                                  color: _sortOption != 'none' ? Colors.black : Colors.grey[700], 
                                  size: 16
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Sort', 
                                  style: TextStyle(
                                    fontSize: 14, 
                                    color: _sortOption != 'none' ? Colors.black : Colors.grey[700],
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
                  
                  // Filter dropdown menu
                  if (_isFilterMenuOpen)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
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
                  
                  // Menu items list - SEAMLESS CART OPERATIONS
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: filteredAndSortedMenu.length,
                      itemBuilder: (context, index) {
                        final menuItem = filteredAndSortedMenu[index];
                        final quantity = state.cartQuantities[menuItem['id']] ?? 0;
                        
                        return RepaintBoundary(
                          child: FoodItemCard(
                            item: menuItem,
                            quantity: quantity,
                            onQuantityChanged: (newQuantity, {attributes}) {
                              // attributes is already List<SelectedAttribute> from FoodItemCard
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
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildFilterOption(String title, String option, IconData icon) {
    bool isSelected = _sortOption == option;
    
    return InkWell(
      onTap: () => _setSortOption(option),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        color: isSelected ? Colors.orangeAccent.withOpacity(0.1) : Colors.transparent,
        child: Row(
          children: [
            Icon(
              icon, 
              size: 16, 
              color: isSelected ? Colors.orangeAccent : Colors.grey[700],
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? Colors.orangeAccent : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check, size: 16, color: Colors.orangeAccent),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSearchBar(BuildContext context, Map<String, dynamic> restaurant) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 0.5)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(4),
                child: const Icon(Icons.arrow_back, size: 24),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search dishes...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: Colors.grey[400], size: 20),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    isDense: true,
                    suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                          },
                          child: Icon(Icons.clear, color: Colors.grey[400], size: 18),
                        )
                      : null,
                  ),
                  style: const TextStyle(fontSize: 16),
                  textAlignVertical: TextAlignVertical.center,
                ),
              ),
            ),
            const SizedBox(width: 12),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.black),
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
                        'Restaurant Profile',
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
          ],
        ),
      ),
    );
  }
  
  Widget _buildRestaurantHeader(BuildContext context, Map<String, dynamic> restaurant) {
    // Extract the veg/non-veg status
    final isVeg = restaurant['isVeg'] == true || 
                 restaurant['veg_nonveg'] == 'veg' ||
                 (restaurant['veg_nonveg'] ?? '').toString().toLowerCase() == 'veg';
    
    // Get the category/cuisine
    final cuisine = restaurant['cuisine'] ?? 
                   restaurant['category'] ?? 
                   'Restaurant';
    
    // Use calculated distance if available, otherwise use default value
    final distance = restaurant['calculatedDistance'] ?? '${restaurant['distance'] ?? 1.2} Kms';
    
    // Get rating or use default
    final rating = restaurant['rating']?.toString() ?? '4.3';
    
    debugPrint('RestaurantHeader: isVeg = $isVeg, cuisine = $cuisine, distance = $distance');
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            restaurant['name'] ?? 'Restaurant',
            style: GoogleFonts.poppins(
              fontSize: 24, 
              fontWeight: FontWeight.bold, 
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          
          const SizedBox(height: 12),
          Row(
            children: [
              // Pure Veg indicator (only show if restaurant is vegetarian)
              if (isVeg)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.eco_outlined, color: Colors.green, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Pure Veg', 
                        style: GoogleFonts.poppins(
                          fontSize: 12, 
                          color: Colors.green, 
                          fontWeight: FontWeight.w500
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Add spacing only if veg indicator is shown
              if (isVeg)
                const SizedBox(width: 12),
              
              // Distance badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.place_outlined, color: Colors.grey[700], size: 14),
                    const SizedBox(width: 4),
                    Text(
                      distance, 
                      style: GoogleFonts.poppins(
                        fontSize: 12, 
                        color: Colors.grey[700], 
                        fontWeight: FontWeight.w500
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Rating badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      rating,
                      style: GoogleFonts.poppins(
                        fontSize: 12, 
                        color: Colors.amber[800], 
                        fontWeight: FontWeight.w500
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCartFloatingButton(BuildContext context, RestaurantDetailsLoaded state) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Get coordinates from the widget's context
    final restaurantDetailsPage = context.findAncestorWidgetOfExactType<RestaurantDetailsPage>();
    final userLatitude = restaurantDetailsPage?.userLatitude;
    final userLongitude = restaurantDetailsPage?.userLongitude;
    
    return FutureBuilder<String>(
      future: CurrencyUtils.getCurrencySymbol(userLatitude, userLongitude),
      builder: (context, snapshot) {
        final currencySymbol = snapshot.data ?? '\$';
        
        return Container(
          width: screenWidth * 0.9,
          height: 56,
          margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, Routes.orderConfirmation);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorManager.primary,
              foregroundColor: Colors.white,
              elevation: 8,
              shadowColor: ColorManager.primary.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
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
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'View Cart',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Text(
                  CurrencyUtils.formatPrice(state.cartTotal, currencySymbol),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../../constants/color/colorConstant.dart';
import '../../constants/router/router.dart';
import '../../utils/responsive_utils.dart';

import '../../service/partner_subcategories_service.dart';
import '../../service/partner_restaurant_service.dart';
import '../../service/non_food_cart_service.dart';
import '../../widgets/non_food_floating_cart_button.dart';
import '../../widgets/item_added_popup.dart';

class ProductListPage extends StatefulWidget {
  final Map<String, dynamic> restaurantData;
  final Map<String, dynamic> categoryData;

  const ProductListPage({
    Key? key,
    required this.restaurantData,
    required this.categoryData,
  }) : super(key: key);

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  List<Map<String, dynamic>> _subcategories = [];
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  Map<String, dynamic>? _selectedSubcategory;
  bool _isLoading = true;
  String? _error;
  Map<String, int> _cartQuantities = {};
  Map<String, int> _previousQuantities = {};
  bool _wasCartEmpty = true;




  @override
  void initState() {
    super.initState();
    _loadData();
    _loadCartData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh cart data when dependencies change (e.g., when returning from cart page)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshCartData();
    });
  }

  Future<void> _loadCartData() async {
    try {
      debugPrint('🛒 ProductListPage: Loading cart data...');
      final cart = await NonFoodCartService.getCart();
      debugPrint('🛒 ProductListPage: Cart data received: $cart');
      
      final quantities = <String, int>{};
      if (cart != null && cart['items'] != null) {
        final items = cart['items'] as List<dynamic>;
        debugPrint('🛒 ProductListPage: Cart items: $items');
        for (final item in items) {
          final menuId = item['menu_id']?.toString() ?? '';
          final quantity = item['quantity'] ?? 0;
          quantities[menuId] = quantity;
          debugPrint('🛒 ProductListPage: Added item - menuId: $menuId, quantity: $quantity');
        }
      }
      
      debugPrint('🛒 ProductListPage: Final quantities map: $quantities');
      
      if (mounted) {
        setState(() {
          _cartQuantities = quantities;
          // Initialize previous quantities and check if cart was empty
          if (_previousQuantities.isEmpty) {
            _previousQuantities.addAll(quantities);
            _wasCartEmpty = quantities.isEmpty || quantities.values.every((qty) => qty == 0);
          }
          debugPrint('🛒 ProductListPage: Updated _cartQuantities: $_cartQuantities');
          debugPrint('🛒 ProductListPage: _wasCartEmpty: $_wasCartEmpty');
        });
      }
    } catch (e) {
      debugPrint('🛒 ProductListPage: Error loading cart data: $e');
    }
  }

  // Method to refresh cart data (can be called when returning from cart page)
  Future<void> _refreshCartData() async {
    await _loadCartData();
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
          item: {
            ...item,
            'imageUrl': item['image_url']?.toString() ?? '',
            'isVeg': item['is_veg'] ?? false,
          },
          onViewCart: () {
            Navigator.pushReplacementNamed(context, Routes.nonFoodOrderConfirmation);
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

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final partnerId = widget.restaurantData['partner_id']?.toString() ?? widget.restaurantData['id']?.toString() ?? '';
      final categoryId = widget.categoryData['id']?.toString() ?? '';

      // Load subcategories and restaurant details in parallel
      final results = await Future.wait([
        PartnerSubcategoriesService.fetchSubcategories(
          partnerId: partnerId,
          categoryId: categoryId,
        ),
        PartnerRestaurantService.fetchRestaurantDetails(
          partnerId: partnerId,
        ),
      ]);

      if (mounted) {
        final subcategories = results[0] as List<Map<String, dynamic>>;
        final restaurantDetails = results[1] as Map<String, dynamic>;
        
        setState(() {
          _subcategories = subcategories;
          _allProducts = List<Map<String, dynamic>>.from(restaurantDetails['products'] ?? []);
          
          // Select first subcategory by default
          if (_subcategories.isNotEmpty) {
            _selectedSubcategory = _subcategories.first;
            _filterProductsBySubcategory();
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _filterProductsBySubcategory() {
    if (_selectedSubcategory == null) {
      setState(() {
        _filteredProducts = [];
      });
      return;
    }
    
    final selectedSubcategoryName = _selectedSubcategory!['name']?.toString() ?? '';
    
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        final productSubcategory = product['subcategory']?['name']?.toString() ?? '';
        return productSubcategory == selectedSubcategoryName;
      }).toList();
    });
  }

  void _onSubcategorySelected(Map<String, dynamic> subcategory) {
    setState(() {
      _selectedSubcategory = subcategory;
    });
    _filterProductsBySubcategory();
  }

  Future<void> _addToCart(Map<String, dynamic> product) async {
    debugPrint('🛒 ProductListPage._addToCart: START');
    debugPrint('🛒 ProductListPage: product: $product');
    
    final productId = product['product_id']?.toString() ?? '';
    final currentQuantity = _cartQuantities[productId] ?? 0;
    final maxQuantity = product['quantity'] ?? 0;
    final isAvailable = product['available'] == true;

    debugPrint('🛒 ProductListPage: productId: $productId');
    debugPrint('🛒 ProductListPage: currentQuantity: $currentQuantity');
    debugPrint('🛒 ProductListPage: maxQuantity: $maxQuantity');
    debugPrint('🛒 ProductListPage: isAvailable: $isAvailable');

    if (!isAvailable) {
      debugPrint('🛒 ProductListPage: Item not available, showing error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This item is currently unavailable'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (currentQuantity >= maxQuantity) {
      debugPrint('🛒 ProductListPage: Max quantity reached, showing error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum quantity ($maxQuantity) reached for this item'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      debugPrint('🛒 ProductListPage: About to call NonFoodCartService.addItemToCart');
      debugPrint('🛒 ProductListPage: partnerId: ${widget.restaurantData['partner_id']?.toString() ?? widget.restaurantData['id']?.toString() ?? ''}');
      debugPrint('🛒 ProductListPage: restaurantName: ${widget.restaurantData['name']?.toString() ?? ''}');
      debugPrint('🛒 ProductListPage: menuId: $productId');
      debugPrint('🛒 ProductListPage: itemName: ${product['name']?.toString() ?? ''}');
      debugPrint('🛒 ProductListPage: price: ${double.tryParse(product['price']?.toString() ?? '0') ?? 0.0}');
      debugPrint('🛒 ProductListPage: quantity: 1');
      debugPrint('🛒 ProductListPage: imageUrl: ${product['image_url']?.toString()}');
      
      final result = await NonFoodCartService.addItemToCart(
        partnerId: widget.restaurantData['partner_id']?.toString() ?? widget.restaurantData['id']?.toString() ?? '',
        restaurantName: widget.restaurantData['name']?.toString() ?? '',
        menuId: productId,
        itemName: product['name']?.toString() ?? '',
        price: double.tryParse(product['price']?.toString() ?? '0') ?? 0.0,
        quantity: 1,
        imageUrl: product['image_url']?.toString(),
      );
      
      debugPrint('🛒 ProductListPage: NonFoodCartService.addItemToCart result: $result');

      if (result['success'] == true) {
        debugPrint('🛒 ProductListPage: Successfully added item to cart');
        final newQuantity = currentQuantity + 1;
        debugPrint('🛒 ProductListPage: New quantity: $newQuantity');
        
        setState(() {
          _cartQuantities[productId] = newQuantity;
        });
        debugPrint('🛒 ProductListPage: Updated _cartQuantities for productId: $productId');

        // Check if we should show the popup
        debugPrint('🛒 ProductListPage: Checking if popup should be shown');
        _checkAndShowPopup(productId, newQuantity, product);

        // Reload cart data to ensure consistency
        debugPrint('🛒 ProductListPage: Reloading cart data');
        await _loadCartData();
        debugPrint('🛒 ProductListPage: Cart data reloaded');
        
        // Cart data updated
      } else {
        debugPrint('🛒 ProductListPage: Failed to add item to cart: ${result['message']}');
        // Failed to add to cart - silently ignore
      }
    } catch (e) {
      debugPrint('🛒 ProductListPage: Error adding to cart: $e');
      debugPrint('🛒 ProductListPage: Error type: ${e.runtimeType}');
      debugPrint('🛒 ProductListPage: Error stack trace: ${StackTrace.current}');
      // Silently handle error
    }
  }

  Future<void> _removeFromCart(Map<String, dynamic> product) async {
    final productId = product['product_id']?.toString() ?? '';
    final currentQuantity = _cartQuantities[productId] ?? 0;

    if (currentQuantity <= 0) return;

    try {
      debugPrint('🛒 ProductListPage: Removing item from cart - productId: $productId, currentQuantity: $currentQuantity');
      
      // Get current cart and update the specific item's quantity
      final cart = await NonFoodCartService.getCart();
      if (cart == null || cart['items'] == null) return;

      final items = List<Map<String, dynamic>>.from(cart['items'] as List);
      final itemIndex = items.indexWhere((item) => item['menu_id']?.toString() == productId);
      
      if (itemIndex >= 0) {
        final item = items[itemIndex];
        final currentItemQuantity = item['quantity'] as int? ?? 0;
        final newItemQuantity = currentItemQuantity - 1;
        
        debugPrint('🛒 ProductListPage: Updating item quantity - current: $currentItemQuantity, new: $newItemQuantity');
        
        if (newItemQuantity <= 0) {
          // Remove item if quantity becomes 0 or less
          items.removeAt(itemIndex);
          debugPrint('🛒 ProductListPage: Item quantity is 0, removing from cart');
        } else {
          // Update item quantity
          items[itemIndex] = {
            ...item,
            'quantity': newItemQuantity,
            'total_price': (item['total_price_per_item'] as double? ?? 0.0) * newItemQuantity,
          };
          debugPrint('🛒 ProductListPage: Updated item quantity to $newItemQuantity');
        }
        
        // Update cart totals
        cart['items'] = items;
        double subtotal = 0.0;
        for (var cartItem in items) {
          subtotal += (cartItem['total_price'] as num).toDouble();
        }
        cart['subtotal'] = subtotal;
        cart['total_price'] = subtotal + (cart['delivery_fees'] as num? ?? 0.0);
        
        // Save updated cart
        await NonFoodCartService.saveCart(cart);
        
        final newQuantity = newItemQuantity > 0 ? newItemQuantity : 0;
        setState(() {
          _cartQuantities[productId] = newQuantity;
        });
        
        // Update the previous quantities
        _previousQuantities[productId] = newQuantity;

        // Reload cart data to ensure consistency
        await _loadCartData();
        
        // Cart data updated
      } else {
        // Item not found in cart - silently ignore
      }
    } catch (e) {
      debugPrint('🛒 ProductListPage: Error removing from cart: $e');
      // Silently handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if cart has items for floating button visibility
    final hasCartItems = _cartQuantities.isNotEmpty && _cartQuantities.values.any((qty) => qty > 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          widget.categoryData['name']?.toString() ?? 'Products',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, small: 14, medium: 16, large: 18),
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: hasCartItems
          ? NonFoodFloatingCartButton(
              key: const ValueKey('cart_button_static'),
              restaurantId: widget.restaurantData['partner_id']?.toString() ?? widget.restaurantData['id']?.toString() ?? '',
              restaurantName: widget.restaurantData['name']?.toString() ?? '',
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load products',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildDesktopLayout(),
    );
  }



  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Sidebar - responsive width
        Container(
          width: ResponsiveUtils.getResponsiveWidth(context, 0.2),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              right: BorderSide(color: Colors.grey, width: 0.5),
            ),
          ),
          child: _buildSidebar(),
        ),
        // Main content - responsive width
        Expanded(
          child: _buildProductsList(),
        ),
      ],
    );
  }



  Widget _buildSidebar() {
    return Column(
      children: [
        // Subcategories list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: _subcategories.length,
            itemBuilder: (context, index) {
              final subcategory = _subcategories[index];
              final isSelected = _selectedSubcategory?['id'] == subcategory['id'];
              
              return _buildSubcategoryItem(subcategory, isSelected);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubcategoryItem(Map<String, dynamic> subcategory, bool isSelected) {
    return InkWell(
      onTap: () => _onSubcategorySelected(subcategory),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? ColorManager.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? ColorManager.primary : Colors.transparent,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Subcategory image
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[100],
              ),
              child: ClipOval(
                child: (subcategory['image'] != null && subcategory['image'].toString().isNotEmpty)
                    ? Image.network(
                        subcategory['image'].toString(),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.category,
                            color: isSelected ? ColorManager.primary : Colors.grey[600],
                            size: 20,
                          );
                        },
                      )
                    : Icon(
                        Icons.category,
                        color: isSelected ? ColorManager.primary : Colors.grey[600],
                        size: 20,
                      ),
              ),
            ),
            const SizedBox(height: 8),
            // Subcategory name
            Text(
              subcategory['name']?.toString() ?? 'Unknown',
              style: GoogleFonts.poppins(
                fontSize: ResponsiveUtils.getResponsiveFontSize(context, small: 10, medium: 11, large: 12),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? ColorManager.primary : Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsList() {
    if (_filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No products available',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting a different category',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    final isTablet = ResponsiveUtils.isTablet(context);
    final isPhone = ResponsiveUtils.isPhone(context);

    return Column(
      children: [
        // Products header
        Container(
          padding: ResponsiveUtils.getResponsivePadding(context, horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: const Border(
              bottom: BorderSide(color: Colors.grey, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.shopping_bag,
                color: ColorManager.primary,
                size: ResponsiveUtils.getResponsiveIconSize(context, small: 18, medium: 20, large: 24),
              ),
              SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, small: 6, medium: 8, large: 12)),
              Text(
                '${_filteredProducts.length} Products',
                style: GoogleFonts.poppins(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, small: 12, medium: 14, large: 16),
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        // Products grid
        Expanded(
          child: GridView.builder(
            padding: ResponsiveUtils.getResponsivePadding(context, horizontal: 12, vertical: 12),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isPhone ? 2 : (isTablet ? 3 : 4),
              childAspectRatio: _getResponsiveAspectRatio(context),
              crossAxisSpacing: ResponsiveUtils.getResponsiveSpacing(context, small: 12, medium: 16, large: 20),
              mainAxisSpacing: ResponsiveUtils.getResponsiveSpacing(context, small: 12, medium: 16, large: 20),
            ),
            itemCount: _filteredProducts.length,
            itemBuilder: (context, index) {
              return _buildProductCard(_filteredProducts[index]);
            },
          ),
        ),
      ],
    );
  }

  double _getResponsiveAspectRatio(BuildContext context) {
    final isTablet = ResponsiveUtils.isTablet(context);
    final isPhone = ResponsiveUtils.isPhone(context);
    final screenHeight = MediaQuery.of(context).size.height;
    
    if (isPhone) {
      // For phones, use a taller aspect ratio to prevent overflow
      return screenHeight < 700 ? 0.75 : 0.8;
    } else if (isTablet) {
      // For tablets, use a balanced aspect ratio
      return 0.85;
    } else {
      // For desktop, use a wider aspect ratio
      return 0.95;
    }
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final productId = product['product_id']?.toString() ?? '';
    final currentQuantity = _cartQuantities[productId] ?? 0;
    final maxQuantity = product['quantity'] ?? 0;
    final isAvailable = product['available'] == true;
    final weight = product['weight']?.toString() ?? '';
    final unit = product['unit']?.toString() ?? '';
    final isTablet = ResponsiveUtils.isTablet(context);
    final isPhone = ResponsiveUtils.isPhone(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveUtils.getResponsiveBorderRadius(context, small: 8, medium: 10, large: 12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          Expanded(
            flex: isPhone ? 2 : (isTablet ? 3 : 4),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(ResponsiveUtils.getResponsiveBorderRadius(context, small: 8, medium: 10, large: 12)),
                ),
                color: Colors.grey[100],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(ResponsiveUtils.getResponsiveBorderRadius(context, small: 8, medium: 10, large: 12)),
                ),
                child: Stack(
                  children: [
                    (product['image_url'] != null && product['image_url'].toString().isNotEmpty)
                        ? Image.network(
                            product['image_url'].toString(),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.grey[400],
                                  size: ResponsiveUtils.getResponsiveIconSize(context, small: 24, medium: 32, large: 40),
                                ),
                              );
                            },
                          )
                        : Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey[400],
                              size: ResponsiveUtils.getResponsiveIconSize(context, small: 24, medium: 32, large: 40),
                            ),
                          ),
                    // Availability badge
                    if (!isAvailable)
                      Positioned(
                        top: ResponsiveUtils.getResponsiveSpacing(context, small: 4, medium: 6, large: 8),
                        right: ResponsiveUtils.getResponsiveSpacing(context, small: 4, medium: 6, large: 8),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtils.getResponsiveSpacing(context, small: 6, medium: 8, large: 10),
                            vertical: ResponsiveUtils.getResponsiveSpacing(context, small: 3, medium: 4, large: 6),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Unavailable',
                            style: GoogleFonts.poppins(
                              fontSize: ResponsiveUtils.getResponsiveFontSize(context, small: 8, medium: 10, large: 12),
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Product details
          Expanded(
            flex: isPhone ? 3 : (isTablet ? 4 : 5),
            child: Padding(
              padding: ResponsiveUtils.getResponsivePadding(context, horizontal: 6, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name and description in one line
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product['name']?.toString() ?? 'Unknown Product',
                          style: GoogleFonts.poppins(
                            fontSize: ResponsiveUtils.getResponsiveFontSize(context, small: 10, medium: 11, large: 13),
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (weight.isNotEmpty && unit.isNotEmpty)
                        Text(
                          '$weight $unit',
                          style: GoogleFonts.poppins(
                            fontSize: ResponsiveUtils.getResponsiveFontSize(context, small: 8, medium: 9, large: 10),
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, small: 1, medium: 2, large: 3)),
                  // Description (if available)
                  if (product['description'] != null && product['description'].toString().isNotEmpty)
                    Text(
                      product['description'].toString(),
                      style: GoogleFonts.poppins(
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, small: 8, medium: 9, large: 10),
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const Spacer(),
                  // Price section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '₹${product['price']?.toString() ?? '0'}',
                        style: GoogleFonts.poppins(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(context, small: 12, medium: 14, large: 16),
                          fontWeight: FontWeight.w700,
                          color: ColorManager.primary,
                        ),
                      ),
                      if (currentQuantity > 0)
                        Text(
                          'Quantity: $currentQuantity',
                          style: GoogleFonts.poppins(
                            fontSize: ResponsiveUtils.getResponsiveFontSize(context, small: 9, medium: 10, large: 11),
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, small: 2, medium: 4, large: 6)),
                  // Enhanced cart button
                  if (isAvailable)
                    Container(
                      width: double.infinity,
                      height: ResponsiveUtils.getResponsiveContainerSize(context, small: 28, medium: 32, large: 36),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: currentQuantity > 0 
                              ? [ColorManager.primary, ColorManager.primary.withOpacity(0.8)]
                              : [ColorManager.primary, ColorManager.primary.withOpacity(0.9)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: ColorManager.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: currentQuantity > 0
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Remove button
                                GestureDetector(
                                  onTap: () => _removeFromCart(product),
                                  child: Container(
                                    width: ResponsiveUtils.getResponsiveContainerSize(context, small: 20, medium: 24, large: 28),
                                    height: ResponsiveUtils.getResponsiveContainerSize(context, small: 20, medium: 24, large: 28),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Icon(
                                      Icons.remove,
                                      color: Colors.white,
                                      size: ResponsiveUtils.getResponsiveIconSize(context, small: 12, medium: 14, large: 16),
                                    ),
                                  ),
                                ),
                                // Quantity display
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: ResponsiveUtils.getResponsiveSpacing(context, small: 8, medium: 10, large: 12),
                                  ),
                                  child: Text(
                                    currentQuantity.toString(),
                                    style: GoogleFonts.poppins(
                                      fontSize: ResponsiveUtils.getResponsiveFontSize(context, small: 12, medium: 14, large: 16),
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                // Add button
                                GestureDetector(
                                  onTap: currentQuantity >= maxQuantity ? null : () => _addToCart(product),
                                  child: Container(
                                    width: ResponsiveUtils.getResponsiveContainerSize(context, small: 20, medium: 24, large: 28),
                                    height: ResponsiveUtils.getResponsiveContainerSize(context, small: 20, medium: 24, large: 28),
                                    decoration: BoxDecoration(
                                      color: currentQuantity >= maxQuantity 
                                          ? Colors.white.withOpacity(0.1)
                                          : Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Icon(
                                      currentQuantity >= maxQuantity ? Icons.block : Icons.add,
                                      color: Colors.white,
                                      size: ResponsiveUtils.getResponsiveIconSize(context, small: 12, medium: 14, large: 16),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : GestureDetector(
                              onTap: () => _addToCart(product),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_shopping_cart,
                                    color: Colors.white,
                                    size: ResponsiveUtils.getResponsiveIconSize(context, small: 14, medium: 16, large: 18),
                                  ),
                                  SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, small: 4, medium: 6, large: 8)),
                                  Text(
                                    'Add to Cart',
                                    style: GoogleFonts.poppins(
                                      fontSize: ResponsiveUtils.getResponsiveFontSize(context, small: 11, medium: 13, large: 15),
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      height: ResponsiveUtils.getResponsiveContainerSize(context, small: 28, medium: 32, large: 36),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.block,
                            color: Colors.grey[600],
                            size: ResponsiveUtils.getResponsiveIconSize(context, small: 14, medium: 16, large: 18),
                          ),
                          SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, small: 4, medium: 6, large: 8)),
                          Text(
                            'Unavailable',
                            style: GoogleFonts.poppins(
                              fontSize: ResponsiveUtils.getResponsiveFontSize(context, small: 11, medium: 13, large: 15),
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 
import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../../constants/color/colorConstant.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/cached_image.dart';
import '../../service/partner_categories_service.dart';
import '../../service/non_food_cart_service.dart';
import '../../widgets/non_food_floating_cart_button.dart';
import 'product_list_page.dart';

class NonFoodMenuPage extends StatefulWidget {
  final Map<String, dynamic> restaurantData;
  const NonFoodMenuPage({Key? key, required this.restaurantData}) : super(key: key);

  @override
  State<NonFoodMenuPage> createState() => _NonFoodMenuPageState();
}

class _NonFoodMenuPageState extends State<NonFoodMenuPage> {
  late Future<List<Map<String, dynamic>>> _categoriesFuture;
  Map<String, int> _cartQuantities = {};
  bool _isLoadingCart = true;

  @override
  void initState() {
    super.initState();
    final partnerId = widget.restaurantData['partner_id']?.toString() ?? widget.restaurantData['id']?.toString() ?? '';
    _categoriesFuture = PartnerCategoriesService.fetchPartnerCategories(partnerId: partnerId);
    _loadCartData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh cart data when dependencies change (e.g., when returning from product list page)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCartData();
    });
  }

  Future<void> _loadCartData() async {
    try {
      debugPrint('🛒 NonFoodMenuPage: Loading cart data...');
      final cart = await NonFoodCartService.getCart();
      debugPrint('🛒 NonFoodMenuPage: Cart data received: $cart');
      
      final quantities = <String, int>{};
      if (cart != null && cart['items'] != null) {
        final items = cart['items'] as List<dynamic>;
        debugPrint('🛒 NonFoodMenuPage: Cart items: $items');
        for (final item in items) {
          final menuId = item['menu_id']?.toString() ?? '';
          final quantity = item['quantity'] ?? 0;
          quantities[menuId] = quantity;
          debugPrint('🛒 NonFoodMenuPage: Added item - menuId: $menuId, quantity: $quantity');
        }
      }
      
      debugPrint('🛒 NonFoodMenuPage: Final quantities map: $quantities');
      
      if (mounted) {
        setState(() {
          _cartQuantities = quantities;
          _isLoadingCart = false;
        });
        debugPrint('🛒 NonFoodMenuPage: Updated _cartQuantities: $_cartQuantities');
        debugPrint('🛒 NonFoodMenuPage: _isLoadingCart: $_isLoadingCart');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCart = false;
        });
      }
      debugPrint('🛒 NonFoodMenuPage: Error loading cart data: $e');
    }
  }

  void _navigateToProductList(Map<String, dynamic> category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductListPage(
          restaurantData: widget.restaurantData,
          categoryData: category,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Check if cart has items for floating button visibility
    final hasCartItems = _cartQuantities.isNotEmpty && _cartQuantities.values.any((qty) => qty > 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(
          widget.restaurantData['name']?.toString() ?? 'Store',
          style: GoogleFonts.poppins(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: ResponsiveUtils.getResponsiveFontSize(context, small: 14, medium: 16, large: 18),
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: hasCartItems && !_isLoadingCart
          ? NonFoodFloatingCartButton(
              key: const ValueKey('cart_button_static'),
              restaurantId: widget.restaurantData['partner_id']?.toString() ?? widget.restaurantData['id']?.toString() ?? '',
              restaurantName: widget.restaurantData['name']?.toString() ?? '',
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load categories',
                style: GoogleFonts.poppins(color: Colors.redAccent),
              ),
            );
          }
          final categories = snapshot.data ?? [];
          if (categories.isEmpty) {
            return Center(
              child: Text(
                'No categories available',
                style: GoogleFonts.poppins(color: Colors.grey[700]),
              ),
            );
          }

          // Build horizontally scrollable grid with 5 rows
          final double cardWidth = 128.0;
          final double cardHeight = 140.0;

          // Chunk categories into columns of 5 (each column is a vertical list), then scroll horizontally
          final List<List<Map<String, dynamic>>> columns = [];
          for (int i = 0; i < categories.length; i += 5) {
            final end = (i + 5 < categories.length) ? i + 5 : categories.length;
            columns.add(categories.sublist(i, end));
          }

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.02),
            itemCount: columns.length,
            itemBuilder: (context, colIndex) {
              final col = columns[colIndex];
              return Container(
                width: cardWidth + 16,
                margin: const EdgeInsets.only(right: 14),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: col.map((cat) {
                    return _CategoryCard(
                      width: cardWidth,
                      height: cardHeight,
                      name: cat['name']?.toString() ?? 'Category',
                      imageUrl: cat['image']?.toString(),
                      onTap: () => _navigateToProductList(cat),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final double width;
  final double height;
  final String name;
  final String? imageUrl;
  final VoidCallback? onTap;

  const _CategoryCard({
    Key? key,
    required this.width,
    required this.height,
    required this.name,
    this.imageUrl,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.10)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: height - 60,
                height: height - 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ColorManager.primary.withOpacity(0.06),
                ),
                child: ClipOval(
                  child: (imageUrl != null && imageUrl!.isNotEmpty)
                      ? (imageUrl!.startsWith('http')
                          ? Image.network(imageUrl!, fit: BoxFit.cover)
                          : CachedImage(imageUrl: imageUrl!, fit: BoxFit.cover))
                      : Icon(Icons.category, color: ColorManager.primary, size: (height - 60) * 0.6),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                name,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(context, small: 11, medium: 12, large: 14),
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


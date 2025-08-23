import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/color/colorConstant.dart';
import '../constants/router/router.dart';
import '../service/non_food_cart_service.dart';
import '../utils/currency_utils.dart';

class NonFoodFloatingCartButton extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;

  const NonFoodFloatingCartButton({
    Key? key,
    required this.restaurantId,
    required this.restaurantName,
  }) : super(key: key);

  @override
  State<NonFoodFloatingCartButton> createState() => _NonFoodFloatingCartButtonState();
}

class _NonFoodFloatingCartButtonState extends State<NonFoodFloatingCartButton> {
  Map<String, dynamic>? _cart;
  int _cartItemCount = 0;
  double _cartTotal = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCartData();
  }

  @override
  void didUpdateWidget(NonFoodFloatingCartButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refresh cart data when widget is updated
    _loadCartData();
  }

  Future<void> _loadCartData() async {
    try {
      debugPrint('🛒 NonFoodFloatingCartButton: Loading cart data...');
      final cart = await NonFoodCartService.getCart();
      debugPrint('🛒 NonFoodFloatingCartButton: Cart data received: $cart');
      
      if (mounted) {
        setState(() {
          _cart = cart;
          // Calculate total quantity from all items
          int totalQuantity = 0;
          if (cart?['items'] != null) {
            final items = cart!['items'] as List<dynamic>;
            debugPrint('🛒 NonFoodFloatingCartButton: Processing ${items.length} cart items');
            for (final item in items) {
              final itemQuantity = item['quantity'] as int? ?? 0;
              totalQuantity += itemQuantity;
              debugPrint('🛒 NonFoodFloatingCartButton: Item ${item['name']} - quantity: $itemQuantity, total so far: $totalQuantity');
            }
          }
          _cartItemCount = totalQuantity;
          _cartTotal = cart?['total_price']?.toDouble() ?? 0.0;
          _isLoading = false;
        });
        debugPrint('🛒 NonFoodFloatingCartButton: Updated - _cartItemCount: $_cartItemCount, _cartTotal: $_cartTotal');
      }
    } catch (e) {
      debugPrint('🛒 NonFoodFloatingCartButton: Error loading cart data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Method to refresh cart data (can be called from parent)
  void refreshCartData() {
    debugPrint('🛒 NonFoodFloatingCartButton: Manually refreshing cart data');
    _loadCartData();
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
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: screenHeight * 0.015),
                Text(
                  'This will remove all items from your cart. This action cannot be undone.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: screenHeight * 0.03),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[400]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'Clear Cart',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
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

    if (confirmed == true) {
      await NonFoodCartService.clearCart();
      await _loadCartData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cart cleared successfully'),
            backgroundColor: ColorManager.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🛒 NonFoodFloatingCartButton: Building widget');
    debugPrint('🛒 NonFoodFloatingCartButton: _isLoading: $_isLoading');
    debugPrint('🛒 NonFoodFloatingCartButton: _cartItemCount: $_cartItemCount');
    debugPrint('🛒 NonFoodFloatingCartButton: _cart: $_cart');
    
    if (_isLoading) {
      debugPrint('🛒 NonFoodFloatingCartButton: Still loading, returning empty widget');
      return const SizedBox.shrink();
    }

    if (_cartItemCount == 0) {
      debugPrint('🛒 NonFoodFloatingCartButton: No cart items, returning empty widget');
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final cartPartnerId = _cart?['partner_id']?.toString() ?? '';
    final showClear = cartPartnerId.isNotEmpty && cartPartnerId != widget.restaurantId;

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
                    debugPrint('🛒 NonFoodFloatingCartButton: Navigate to order confirmation pressed');
                    debugPrint('🛒 NonFoodFloatingCartButton: Current cart item count: $_cartItemCount');
                    debugPrint('🛒 NonFoodFloatingCartButton: Current cart total: $_cartTotal');
                    Navigator.pushReplacementNamed(context, Routes.nonFoodOrderConfirmation);
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
                          '$_cartItemCount',
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
                        CurrencyUtils.formatPrice(_cartTotal, currencySymbol),
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
                        side: BorderSide(color: Colors.red),
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
  }
} 
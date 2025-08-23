import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/color/colorConstant.dart';
import '../utils/currency_utils.dart';

class ItemAddedPopup extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onViewCart;
  final VoidCallback? onContinueShopping;

  const ItemAddedPopup({
    Key? key,
    required this.item,
    this.onViewCart,
    this.onContinueShopping,
  }) : super(key: key);

  static Future<void> show({
    required BuildContext context,
    required Map<String, dynamic> item,
    VoidCallback? onViewCart,
    VoidCallback? onContinueShopping,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return ItemAddedPopup(
          item: item,
          onViewCart: onViewCart,
          onContinueShopping: onContinueShopping,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    const double actionButtonHeight = 48.0;
    
    final itemName = item['name'] ?? 'Item';
    double itemPrice = 0.0;
    final priceRaw = item['price'];
    if (priceRaw is num) {
      itemPrice = priceRaw.toDouble();
    } else if (priceRaw is String) {
      itemPrice = double.tryParse(priceRaw) ?? 0.0;
    }
    final imageUrl = item['imageUrl'];
    final isVeg = item['isVeg'] ?? false;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: screenWidth * 0.85,
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.6,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon and header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  // Success icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Item Added!',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your item has been added to cart',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Item details
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Item image
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[100],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: Colors.grey[200],
                                child: Icon(
                                  Icons.restaurant,
                                  color: Colors.grey[400],
                                  size: 30,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.restaurant,
                              color: Colors.grey[400],
                              size: 30,
                            ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Item info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name and veg indicator
                        Row(
                          children: [
                            // Veg indicator
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: isVeg ? const Color(0xFF3CB043) : const Color(0xFFE53935),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                itemName,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Price
                                FutureBuilder<String>(
          future: CurrencyUtils.getCurrencySymbolFromUserLocation(),
          builder: (context, snapshot) {
            final currencySymbol = snapshot.data ?? '₹';
                            return Text(
                              CurrencyUtils.formatPrice(itemPrice, currencySymbol),
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: ColorManager.primary,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  // Continue Shopping button
                  Expanded(
                    child: SizedBox(
                      height: actionButtonHeight,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onContinueShopping?.call();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorManager.primary.withOpacity(0.9),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: const Size.fromHeight(actionButtonHeight),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: Text(
                          'Continue Shopping',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  
                  const SizedBox(width: 12),
                  
                  // View Cart button
                  Expanded(
                    child: SizedBox(
                      height: actionButtonHeight,
                      child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onViewCart?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorManager.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(actionButtonHeight),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'View Cart',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
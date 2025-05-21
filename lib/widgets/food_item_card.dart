// widgets/food_item_card.dart
import 'package:flutter/material.dart';
import '../constants/color/colorConstant.dart';
import 'cached_image.dart';
import 'package:google_fonts/google_fonts.dart';

class FoodItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final int quantity;
  final Function(int) onQuantityChanged;

  const FoodItemCard({
    Key? key,
    required this.item,
    required this.quantity,
    required this.onQuantityChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isVeg = item['isVeg'] ?? false;
    String? imageUrl = item['imageUrl'];
    String name = item['name'] ?? '';
    num price = item['price'] ?? 0;
    String description = item['description'] ?? '';
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Food image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 100,
              height: 100,
              child: CachedImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                width: 100,
                height: 100,
                placeholder: (context) => Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation<Color>(ColorManager.primary),
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, error) => Container(
                  color: Colors.grey[100],
                  child: Icon(
                    Icons.restaurant,
                    color: Colors.grey[400],
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Food details section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and veg indicator in a row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    // Veg indicator as a simple colored dot
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: isVeg ? const Color(0xFF3CB043) : const Color(0xFFE53935),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isVeg ? const Color(0xFF3CB043) : const Color(0xFFE53935),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isVeg ? const Color(0xFF3CB043).withOpacity(0.3) : const Color(0xFFE53935).withOpacity(0.3),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 6),
                
                // Description
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                
                const SizedBox(height: 12),
                
                // Price and quantity selector in a row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Price
                    Text(
                      '₹${price.toString()}',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    
                    // Quantity selector
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Minus button
                          InkWell(
                            onTap: () => onQuantityChanged(quantity > 0 ? quantity - 1 : 0),
                            borderRadius: BorderRadius.circular(50),
                            child: Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              child: Text(
                                '-',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                          
                          // Quantity text
                          SizedBox(
                            width: 30,
                            child: Text(
                              quantity.toString(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          
                          // Plus button
                          InkWell(
                            onTap: () => onQuantityChanged(quantity + 1),
                            borderRadius: BorderRadius.circular(50),
                            child: Container(
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              child: Text(
                                '+',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  color: ColorManager.primary,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
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
        ],
      ),
    );
  }
}
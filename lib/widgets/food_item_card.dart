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
    
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: screenWidth * 0.03,
        horizontal: screenWidth * 0.04,
      ),
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
              width: screenWidth * 0.24,
              height: screenWidth * 0.24,
              child: CachedImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                width: screenWidth * 0.24,
                height: screenWidth * 0.24,
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
          
          SizedBox(width: screenWidth * 0.03),
          
          // Food details section with absolute positioned dot
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Main content
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name row 
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontSize: screenWidth * 0.045,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: screenWidth * 0.015),
                    
                    // Description
                    if (description.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(bottom: screenWidth * 0.03),
                        child: Text(
                          description,
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.035,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    
                    // Price and quantity selector in a row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Price
                        Text(
                          '₹${price.toString()}',
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                            letterSpacing: -0.5,
                          ),
                        ),
                        
                        // Quantity controls or Add button
                        quantity == 0 
                        ? Container(
                            height: screenWidth * 0.1,
                            margin: EdgeInsets.only(right: screenWidth * 0.025),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  ColorManager.primary,
                                  ColorManager.primary.withOpacity(0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: ColorManager.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => onQuantityChanged(1),
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: screenWidth * 0.04, 
                                    vertical: screenWidth * 0.02
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Add',
                                        style: GoogleFonts.poppins(
                                          fontSize: screenWidth * 0.035,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      SizedBox(width: screenWidth * 0.012),
                                      Icon(
                                        Icons.add_shopping_cart_rounded,
                                        color: Colors.white,
                                        size: screenWidth * 0.04,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Container(
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
                                    width: screenWidth * 0.09,
                                    height: screenWidth * 0.09,
                                    alignment: Alignment.center,
                                    child: Text(
                                      '-',
                                      style: GoogleFonts.poppins(
                                        fontSize: screenWidth * 0.05,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // Quantity text
                                SizedBox(
                                  width: screenWidth * 0.075,
                                  child: Text(
                                    quantity.toString(),
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.poppins(
                                      fontSize: screenWidth * 0.04,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                
                                // Plus button
                                InkWell(
                                  onTap: () => onQuantityChanged(quantity + 1),
                                  borderRadius: BorderRadius.circular(50),
                                  child: Container(
                                    width: screenWidth * 0.09,
                                    height: screenWidth * 0.09,
                                    alignment: Alignment.center,
                                    child: Text(
                                      '+',
                                      style: GoogleFonts.poppins(
                                        fontSize: screenWidth * 0.05,
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
                
                // Veg indicator absolutely positioned at top and centered above button
                Positioned(
                  top: 0,
                  right: quantity == 0 ? screenWidth * 0.15 : screenWidth * 0.135,
                  child: Container(
                    width: screenWidth * 0.04,
                    height: screenWidth * 0.04,
                    decoration: BoxDecoration(
                      color: isVeg ? const Color(0xFF3CB043) : const Color(0xFFE53935),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 1.5,
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
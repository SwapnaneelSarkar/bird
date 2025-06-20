// widgets/food_item_card.dart
import 'package:flutter/material.dart';
import '../constants/color/colorConstant.dart';
import 'cached_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'menu_item_attributes_dialog.dart';
import 'menu_item_details_bottom_sheet.dart';
import '../service/attribute_service.dart';
import '../models/attribute_model.dart';

class FoodItemCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final int quantity;
  final Function(int, {List<SelectedAttribute>? attributes}) onQuantityChanged;

  const FoodItemCard({
    Key? key,
    required this.item,
    required this.quantity,
    required this.onQuantityChanged,
  }) : super(key: key);

  @override
  State<FoodItemCard> createState() => _FoodItemCardState();
}

class _FoodItemCardState extends State<FoodItemCard> {
  List<SelectedAttribute>? _selectedAttributes;

  void _handleAddToCart(BuildContext context, int newQuantity) {
    // Check if the item has attributes by making a quick API call
    final menuId = widget.item['id'];
    if (menuId == null) {
      // If no menu ID, just add directly
      widget.onQuantityChanged(newQuantity);
      return;
    }
    
    // If we already have selected attributes and quantity > 0, use them automatically
    if (_selectedAttributes != null && widget.quantity > 0) {
      debugPrint('FoodItemCard: Using stored attributes for quantity increase');
      widget.onQuantityChanged(newQuantity, attributes: _selectedAttributes);
      return;
    }
    
    // Check if item has attributes
    AttributeService.fetchMenuItemAttributes(menuId).then((attributes) {
      if (attributes.isNotEmpty) {
        // Item has attributes, show the dialog
        debugPrint('FoodItemCard: Item has ${attributes.length} attribute groups, showing dialog');
        MenuItemAttributesDialog.show(
          context: context,
          item: widget.item,
          onAttributesSelected: (selectedAttributes) {
            // Store the selected attributes for future use
            setState(() {
              _selectedAttributes = selectedAttributes;
            });
            widget.onQuantityChanged(newQuantity, attributes: selectedAttributes);
          },
        );
      } else {
        // Item has no attributes, add directly to cart
        debugPrint('FoodItemCard: Item has no attributes, adding directly to cart');
        setState(() {
          _selectedAttributes = null;
        });
        widget.onQuantityChanged(newQuantity);
      }
    }).catchError((error) {
      // If there's an error fetching attributes, add directly to cart
      debugPrint('FoodItemCard: Error fetching attributes: $error, adding directly to cart');
      setState(() {
        _selectedAttributes = null;
      });
      widget.onQuantityChanged(newQuantity);
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isVeg = widget.item['isVeg'] ?? false;
    String? imageUrl = widget.item['imageUrl'];
    String name = widget.item['name'] ?? '';
    num price = widget.item['price'] ?? 0;
    String description = widget.item['description'] ?? '';
    bool isAvailable = widget.item['available'] ?? true;
    
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
          // Food image - Make it tappable to show details
          GestureDetector(
            onTap: () {
              MenuItemDetailsBottomSheet.show(
                context: context,
                item: widget.item,
              );
            },
            child: ClipRRect(
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
          ),
          
          SizedBox(width: screenWidth * 0.03),
          
          // Food details section - Make it tappable to show details
          Expanded(
            child: GestureDetector(
              onTap: () {
                MenuItemDetailsBottomSheet.show(
                  context: context,
                  item: widget.item,
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name row with veg indicator inline
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Veg indicator at the start
                      Container(
                        margin: EdgeInsets.only(top: 2, right: screenWidth * 0.02), 
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
                      
                      // Name text with proper constraints
                      Expanded(
                        child: Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            letterSpacing: -0.5,
                          ),
                          softWrap: true,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: screenWidth * 0.015),
                  
                  // Description
                  if (description.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: screenWidth * 0.03,
                        left: screenWidth * 0.06, // Align with name text
                      ),
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
                      // Price (aligned with name text)
                      Padding(
                        padding: EdgeInsets.only(left: screenWidth * 0.06),
                        child: Text(
                          '₹${price.toString()}',
                          style: GoogleFonts.poppins(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      
                      // Quantity controls or Add button
                      if (!isAvailable)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.04,
                            vertical: screenWidth * 0.02,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Not Available',
                            style: GoogleFonts.poppins(
                              fontSize: screenWidth * 0.035,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      else if (widget.quantity == 0) 
                        Container(
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
                              onTap: () {
                                _handleAddToCart(context, 1);
                              },
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
                      else
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
                                onTap: () {
                                  final newQuantity = widget.quantity - 1;
                                  if (newQuantity == 0) {
                                    // When removing (quantity = 0), pass the stored attributes
                                    widget.onQuantityChanged(newQuantity, attributes: _selectedAttributes);
                                  } else {
                                    // When updating quantity, pass the stored attributes
                                    widget.onQuantityChanged(newQuantity, attributes: _selectedAttributes);
                                  }
                                },
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
                                  widget.quantity.toString(),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: screenWidth * 0.04,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              
                              // Plus button
                              InkWell(
                                onTap: () => _handleAddToCart(context, widget.quantity + 1),
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
            ),
          ),
        ],
      ),
    );
  }
}
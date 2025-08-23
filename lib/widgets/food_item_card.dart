// widgets/food_item_card.dart
import 'package:flutter/material.dart';
import '../constants/color/colorConstant.dart';
import 'cached_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'menu_item_attributes_dialog.dart';
import 'menu_item_details_bottom_sheet.dart';
import '../service/attribute_service.dart';
import '../models/attribute_model.dart';
import '../constants/font/fontManager.dart';
import '../utils/currency_utils.dart';
import '../utils/responsive_utils.dart';
import 'veg_nonveg_icons.dart';

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
    
    // If this is the first time adding the item (quantity was 0), check for attributes
    if (widget.quantity == 0) {
      // First time adding - check if item has attributes and show dialog if it does
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
    } else {
      // Subsequent additions - use stored attributes without showing dialog
      debugPrint('FoodItemCard: Subsequent addition, using stored attributes');
      widget.onQuantityChanged(newQuantity, attributes: _selectedAttributes);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isVeg = widget.item['isVeg'] ?? false;
    String? imageUrl = widget.item['imageUrl'];
    String name = widget.item['name'] ?? '';
    num price = widget.item['price'] ?? 0;
    String description = widget.item['description'] ?? '';
    bool isAvailable = widget.item['available'] ?? true;
    
    // Responsive dimensions
    final imageSize = ResponsiveUtils.getResponsiveWidth(context, 0.22);
    final padding = ResponsiveUtils.getResponsivePadding(context, 
      horizontal: ResponsiveUtils.isSmallScreen(context) ? 12.0 : 16.0,
      vertical: ResponsiveUtils.isSmallHeight(context) ? 8.0 : 12.0,
    );
    final spacing = ResponsiveUtils.getResponsiveSpacing(context, small: 8.0, medium: 12.0, large: 16.0);
    
    return Container(
      padding: padding,
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
            borderRadius: BorderRadius.circular(ResponsiveUtils.getResponsiveBorderRadius(context)),
            child: SizedBox(
              width: imageSize,
              height: imageSize,
              child: CachedImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                width: imageSize,
                height: imageSize,
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
          
          SizedBox(width: spacing),
          
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
                        margin: EdgeInsets.only(
                          top: 2, 
                          right: ResponsiveUtils.getResponsiveSpacing(context, small: 6.0, medium: 8.0, large: 10.0)
                        ), 
                        child: isVeg 
                          ? VegNonVegIcons.vegIcon(
                              size: ResponsiveUtils.getResponsiveIconSize(context, small: 12.0, medium: 16.0, large: 20.0),
                              color: const Color(0xFF3CB043),
                              borderColor: Colors.white,
                            )
                          : VegNonVegIcons.nonVegIcon(
                              size: ResponsiveUtils.getResponsiveIconSize(context, small: 12.0, medium: 16.0, large: 20.0),
                              color: const Color(0xFFE53935),
                              borderColor: Colors.white,
                            ),
                      ),
                      
                      // Name text with proper constraints
                      Expanded(
                        child:                         Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: ResponsiveUtils.getResponsiveFontSize(context, small: 14.0, medium: 16.0, large: 18.0),
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
                  
                  SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, small: 4.0, medium: 6.0, large: 8.0)),
                  
                  // Description
                  if (description.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(
                        bottom: ResponsiveUtils.getResponsiveSpacing(context, small: 8.0, medium: 12.0, large: 16.0),
                        left: ResponsiveUtils.getResponsiveSpacing(context, small: 16.0, medium: 20.0, large: 24.0), // Align with name text
                      ),
                      child: Text(
                        description,
                        style: GoogleFonts.poppins(
                          fontSize: ResponsiveUtils.getResponsiveFontSize(context, small: 12.0, medium: 14.0, large: 16.0),
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
                        padding: EdgeInsets.only(left: ResponsiveUtils.getResponsiveSpacing(context, small: 16.0, medium: 20.0, large: 24.0)),
                        child: FutureBuilder<String>(
                          future: CurrencyUtils.getCurrencySymbolFromUserLocation(),
                          builder: (context, snapshot) {
                            final currencySymbol = snapshot.data ?? '₹';
                            return Text(
                              CurrencyUtils.formatPrice(price.toDouble(), currencySymbol),
                              style: GoogleFonts.poppins(
                                fontSize: ResponsiveUtils.getResponsiveFontSize(context, small: 14.0, medium: 16.0, large: 18.0),
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                                letterSpacing: -0.5,
                              ),
                            );
                          },
                        ),
                      ),
                      
                      // Quantity controls or Add button
                      if (!isAvailable)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResponsiveUtils.getResponsiveSpacing(context, small: 12.0, medium: 16.0, large: 20.0),
                            vertical: ResponsiveUtils.getResponsiveSpacing(context, small: 6.0, medium: 8.0, large: 10.0),
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Not Available',
                            style: GoogleFonts.poppins(
                              fontSize: ResponsiveUtils.getResponsiveFontSize(context, small: 12.0, medium: 14.0, large: 16.0),
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      else if (widget.quantity == 0) 
                        Container(
                          height: ResponsiveUtils.getResponsiveContainerSize(context, small: 36.0, medium: 40.0, large: 44.0),
                          margin: EdgeInsets.only(right: ResponsiveUtils.getResponsiveSpacing(context, small: 8.0, medium: 10.0, large: 12.0)),
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
                                  horizontal: ResponsiveUtils.getResponsiveSpacing(context, small: 12.0, medium: 16.0, large: 20.0), 
                                  vertical: ResponsiveUtils.getResponsiveSpacing(context, small: 6.0, medium: 8.0, large: 10.0)
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Add',
                                      style: GoogleFonts.poppins(
                                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, small: 12.0, medium: 14.0, large: 16.0),
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, small: 4.0, medium: 6.0, large: 8.0)),
                                    Icon(
                                      Icons.add_shopping_cart_rounded,
                                      color: Colors.white,
                                      size: ResponsiveUtils.getResponsiveIconSize(context, small: 14.0, medium: 16.0, large: 18.0),
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
                                    // When removing all items, clear stored attributes
                                    setState(() {
                                      _selectedAttributes = null;
                                    });
                                    widget.onQuantityChanged(newQuantity);
                                  } else {
                                    // When updating quantity, pass the stored attributes
                                    widget.onQuantityChanged(newQuantity, attributes: _selectedAttributes);
                                  }
                                },
                                borderRadius: BorderRadius.circular(50),
                                child: Container(
                                  width: ResponsiveUtils.getResponsiveContainerSize(context, small: 32.0, medium: 36.0, large: 40.0),
                                  height: ResponsiveUtils.getResponsiveContainerSize(context, small: 32.0, medium: 36.0, large: 40.0),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '-',
                                    style: GoogleFonts.poppins(
                                      fontSize: ResponsiveUtils.getResponsiveFontSize(context, small: 16.0, medium: 18.0, large: 20.0),
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                              
                              // Quantity text
                              SizedBox(
                                width: ResponsiveUtils.getResponsiveContainerSize(context, small: 28.0, medium: 32.0, large: 36.0),
                                child: Text(
                                  widget.quantity.toString(),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: ResponsiveUtils.getResponsiveFontSize(context, small: 14.0, medium: 16.0, large: 18.0),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              
                              // Plus button
                              InkWell(
                                onTap: () => _handleAddToCart(context, widget.quantity + 1),
                                borderRadius: BorderRadius.circular(50),
                                child: Container(
                                  width: ResponsiveUtils.getResponsiveContainerSize(context, small: 32.0, medium: 36.0, large: 40.0),
                                  height: ResponsiveUtils.getResponsiveContainerSize(context, small: 32.0, medium: 36.0, large: 40.0),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '+',
                                    style: GoogleFonts.poppins(
                                      fontSize: ResponsiveUtils.getResponsiveFontSize(context, small: 16.0, medium: 18.0, large: 20.0),
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
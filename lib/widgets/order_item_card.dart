import 'package:flutter/material.dart';
import '../constants/color/colorConstant.dart';
import '../constants/font/fontManager.dart';
import '../models/attribute_model.dart';
import '../utils/currency_utils.dart';

class OrderItemCard extends StatelessWidget {
  final String imageUrl;
  final String name;
  final int quantity;
  final double price;
  final String itemId;
  final List<SelectedAttribute> attributes;
  final Function(String itemId, int newQuantity)? onQuantityChanged;

  const OrderItemCard({
    Key? key,
    required this.imageUrl,
    required this.name,
    required this.quantity,
    required this.price,
    required this.itemId,
    this.attributes = const [],
    this.onQuantityChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    debugPrint('=== ORDER ITEM CARD: BUILD START ===');
    debugPrint('ORDER ITEM CARD: Item data:');
    debugPrint('  - Name: $name');
    debugPrint('  - Quantity: $quantity');
    debugPrint('  - Base Price: ₹$price');
    debugPrint('  - Total Price: ₹${price.toStringAsFixed(2)}');
    debugPrint('  - Item ID: $itemId');
    debugPrint('  - Attributes count: ${attributes.length}');
    
    if (attributes.isNotEmpty) {
      for (var attr in attributes) {
        debugPrint('    - ${attr.attributeName}: ${attr.valueName} (+₹${attr.priceAdjustment})');
      }
    }
    
    // Calculate price per item for display
    final pricePerItem = price / quantity;
    debugPrint('ORDER ITEM CARD: Calculated price per item: ₹${pricePerItem.toStringAsFixed(2)}');

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.06,
        vertical: screenHeight * 0.01,
      ),
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Item Image
          Container(
            width: screenWidth * 0.15,
            height: screenWidth * 0.15,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[100],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.restaurant,
                          color: Colors.grey[400],
                          size: screenWidth * 0.06,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.restaurant,
                      color: Colors.grey[400],
                      size: screenWidth * 0.06,
                    ),
            ),
          ),
          
          SizedBox(width: screenWidth * 0.04),
          
          // Item Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: (screenWidth * 0.035).clamp(13.0, 16.0), // Smaller font
                    fontWeight: FontWeightManager.semiBold,
                    fontFamily: FontFamily.Montserrat,
                    color: ColorManager.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                
                SizedBox(height: screenHeight * 0.003), // Reduced spacing
                
                // Price per item
                FutureBuilder<String>(
                  future: CurrencyUtils.getCurrencySymbolFromUserLocation(),
                  builder: (context, snapshot) {
                    final currencySymbol = snapshot.data ?? '₹';
                    return Text(
                      '${CurrencyUtils.formatPrice((price / quantity), currencySymbol)} each',
                      style: TextStyle(
                        fontSize: (screenWidth * 0.03).clamp(11.0, 14.0), // Smaller font
                        fontWeight: FontWeightManager.regular,
                        fontFamily: FontFamily.Montserrat,
                        color: Colors.grey[600],
                      ),
                    );
                  },
                ),

                // Display attributes if any
                if (attributes.isNotEmpty) ...[
                  SizedBox(height: screenHeight * 0.005),
                  ...attributes.map((attr) => FutureBuilder<String>(
                    future: CurrencyUtils.getCurrencySymbolFromUserLocation(),
                    builder: (context, snapshot) {
                      final currencySymbol = snapshot.data ?? '₹';
                      return Padding(
                        padding: EdgeInsets.only(bottom: screenHeight * 0.002),
                        child: Text(
                          '${attr.attributeName}: ${attr.valueName}${attr.priceAdjustment > 0 ? ' (+${CurrencyUtils.formatPrice(attr.priceAdjustment, currencySymbol)})' : ''}',
                          style: TextStyle(
                            fontSize: (screenWidth * 0.025).clamp(10.0, 12.0),
                            fontWeight: FontWeightManager.regular,
                            fontFamily: FontFamily.Montserrat,
                            color: Colors.grey[500],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      );
                    },
                  )).toList(),
                ],
              ],
            ),
          ),
          
          // Quantity controls and total price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Total price
              FutureBuilder<String>(
                future: CurrencyUtils.getCurrencySymbolFromUserLocation(),
                builder: (context, snapshot) {
                  final currencySymbol = snapshot.data ?? '₹';
                  return Text(
                    CurrencyUtils.formatPrice(price, currencySymbol),
                    style: TextStyle(
                      fontSize: (screenWidth * 0.035).clamp(13.0, 16.0), // Smaller font
                      fontWeight: FontWeightManager.semiBold,
                      fontFamily: FontFamily.Montserrat,
                      color: ColorManager.black,
                    ),
                  );
                },
              ),
              
              SizedBox(height: screenHeight * 0.005),
              
              // Quantity controls
              if (onQuantityChanged != null)
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Minus button
                      InkWell(
                        onTap: () {
                          final newQuantity = quantity > 0 ? quantity - 1 : 0;
                          onQuantityChanged!(itemId, newQuantity);
                        },
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          width: screenWidth * 0.08,
                          height: screenWidth * 0.08,
                          alignment: Alignment.center,
                          child: Text(
                            '-',
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
                              color: Colors.grey,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                      
                      // Quantity text
                      SizedBox(
                        width: screenWidth * 0.07,
                        child: Text(
                          quantity.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      
                      // Plus button
                      InkWell(
                        onTap: () {
                          onQuantityChanged!(itemId, quantity + 1);
                        },
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          width: screenWidth * 0.08,
                          height: screenWidth * 0.08,
                          alignment: Alignment.center,
                          child: Text(
                            '+',
                            style: TextStyle(
                              fontSize: screenWidth * 0.045,
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
    );
    
    debugPrint('=== ORDER ITEM CARD: BUILD END ===');
  }
}
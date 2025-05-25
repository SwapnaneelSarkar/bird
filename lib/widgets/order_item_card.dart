import 'package:flutter/material.dart';
import '../constants/color/colorConstant.dart';
import '../constants/font/fontManager.dart';

class OrderItemCard extends StatelessWidget {
  final String imageUrl;
  final String name;
  final int quantity;
  final double price;

  const OrderItemCard({
    Key? key,
    required this.imageUrl,
    required this.name,
    required this.quantity,
    required this.price,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    debugPrint('OrderItemCard: Building card for $name, Qty: $quantity, Price: ₹${price.toStringAsFixed(2)}');

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.005, // Reduced vertical margin
      ),
      padding: EdgeInsets.all(screenWidth * 0.025), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Item Image
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: screenWidth * 0.16, // Slightly smaller image
              height: screenWidth * 0.16,
              color: Colors.grey[200],
              child: imageUrl.startsWith('assets/')
                  ? Image.asset(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderImage(screenWidth);
                      },
                    )
                  : Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildPlaceholderImage(screenWidth);
                      },
                    ),
            ),
          ),
          
          SizedBox(width: screenWidth * 0.035), // Reduced spacing
          
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
                
                Text(
                  'Qty: $quantity',
                  style: TextStyle(
                    fontSize: (screenWidth * 0.03).clamp(11.0, 14.0), // Smaller font
                    fontWeight: FontWeightManager.regular,
                    fontFamily: FontFamily.Montserrat,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          
          // Price with Rupee symbol
          Text(
            '₹${price.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: (screenWidth * 0.035).clamp(13.0, 16.0), // Smaller font
              fontWeight: FontWeightManager.semiBold,
              fontFamily: FontFamily.Montserrat,
              color: ColorManager.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage(double screenWidth) {
    return Container(
      width: screenWidth * 0.16,
      height: screenWidth * 0.16,
      color: Colors.grey[300],
      child: Icon(
        Icons.restaurant,
        color: Colors.grey[500],
        size: screenWidth * 0.07, // Smaller icon
      ),
    );
  }
}
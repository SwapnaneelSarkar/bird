import 'package:flutter/material.dart';
import '../models/order_details_model.dart';
import '../constants/color/colorConstant.dart';
import '../constants/font/fontManager.dart';
import '../utils/currency_utils.dart';

class ChatOrderDetailsWidget extends StatelessWidget {
  final OrderDetails orderDetails;
  final VoidCallback? onCancelOrder;
  final Map<String, Map<String, dynamic>> menuItemDetails;

  const ChatOrderDetailsWidget({
    Key? key,
    required this.orderDetails,
    this.onCancelOrder,
    this.menuItemDetails = const {},
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('ChatOrderDetailsWidget: 🎨 Building compact chat bubble widget');
    debugPrint('ChatOrderDetailsWidget: 📋 Order ID: ${orderDetails.orderId}');
    debugPrint('ChatOrderDetailsWidget: 📋 Restaurant: ${orderDetails.restaurantName}');
    debugPrint('ChatOrderDetailsWidget: 📋 Items count: ${orderDetails.items.length}');
    debugPrint('ChatOrderDetailsWidget: 📋 Menu item details: ${menuItemDetails.length}');
    debugPrint('ChatOrderDetailsWidget: 📅 Created at: ${orderDetails.createdAt}');
    debugPrint('ChatOrderDetailsWidget: 📅 Formatted date: ${orderDetails.formattedCreatedDateTime}');
    
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.01,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with restaurant name and order status
          Container(
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              color: Color(orderDetails.statusBackgroundColor),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(screenWidth * 0.03),
                topRight: Radius.circular(screenWidth * 0.03),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        orderDetails.restaurantName ?? 'Restaurant',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeightManager.bold,
                          fontFamily: FontFamily.Montserrat,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      // Order date and time
                      Text(
                        'Ordered on ${orderDetails.formattedCreatedDateTime}',
                        style: TextStyle(
                          fontSize: screenWidth * 0.032,
                          fontWeight: FontWeightManager.medium,
                          fontFamily: FontFamily.Montserrat,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge with highlighting
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.025,
                    vertical: screenHeight * 0.008,
                  ),
                  decoration: BoxDecoration(
                    color: Color(orderDetails.statusColor),
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    boxShadow: [
                      BoxShadow(
                        color: Color(orderDetails.statusColor).withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    orderDetails.statusDisplayText,
                    style: TextStyle(
                      fontSize: screenWidth * 0.03,
                      fontWeight: FontWeightManager.semiBold,
                      fontFamily: FontFamily.Montserrat,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Order items
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Items',
                  style: TextStyle(
                    fontSize: screenWidth * 0.038,
                    fontWeight: FontWeightManager.semiBold,
                    fontFamily: FontFamily.Montserrat,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                ...orderDetails.items.map((item) {
                  final menuDetails = menuItemDetails[item.menuId];
                  final itemName = menuDetails?['name']?.toString() ?? 
                                 item.itemName ?? 
                                 'Item ${item.menuId}';
                  final itemImage = menuDetails?['image_url']?.toString() ?? 
                                  item.imageUrl;
                  
                  return Container(
                    margin: EdgeInsets.only(bottom: screenHeight * 0.01),
                    child: Row(
                      children: [
                        // Item image
                        if (itemImage != null && itemImage.isNotEmpty)
                          Container(
                            width: screenWidth * 0.12,
                            height: screenWidth * 0.12,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(screenWidth * 0.015),
                              image: DecorationImage(
                                image: NetworkImage(itemImage),
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        else
                          Container(
                            width: screenWidth * 0.12,
                            height: screenWidth * 0.12,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(screenWidth * 0.015),
                            ),
                            child: Icon(
                              Icons.fastfood,
                              color: Colors.grey[400],
                              size: screenWidth * 0.06,
                            ),
                          ),
                        
                        SizedBox(width: screenWidth * 0.025),
                        
                        // Item details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                itemName,
                                style: TextStyle(
                                  fontSize: screenWidth * 0.035,
                                  fontWeight: FontWeightManager.medium,
                                  fontFamily: FontFamily.Montserrat,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: screenHeight * 0.002),
                              Text(
                                'Qty: ${item.quantity} × ${orderDetails.getFormattedPrice(item.itemPrice)}',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.03,
                                  fontWeight: FontWeightManager.regular,
                                  fontFamily: FontFamily.Montserrat,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Item total
                        Text(
                          orderDetails.getFormattedPrice(item.totalPrice),
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            fontWeight: FontWeightManager.semiBold,
                            fontFamily: FontFamily.Montserrat,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                
                // Divider
                Divider(
                  color: Colors.grey[300],
                  height: screenHeight * 0.02,
                ),
                
                // Order summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subtotal',
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeightManager.medium,
                        fontFamily: FontFamily.Montserrat,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      orderDetails.getFormattedPrice(orderDetails.subtotal),
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeightManager.medium,
                        fontFamily: FontFamily.Montserrat,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.005),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Text(
                    //   'Delivery Fee',
                    //   style: TextStyle(
                    //     fontSize: screenWidth * 0.035,
                    //     fontWeight: FontWeightManager.medium,
                    //     fontFamily: FontFamily.Montserrat,
                    //     color: Colors.black54,
                    //   ),
                    // ),
                    Text(
                      orderDetails.getFormattedPrice(orderDetails.deliveryFees),
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeightManager.medium,
                        fontFamily: FontFamily.Montserrat,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.01),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeightManager.bold,
                        fontFamily: FontFamily.Montserrat,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      orderDetails.getFormattedPrice(orderDetails.grandTotal),
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeightManager.bold,
                        fontFamily: FontFamily.Montserrat,
                        color: const Color(0xFFE17A47),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Cancel order button (if order is cancellable)
          if (orderDetails.canBeCancelled && onCancelOrder != null)
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.01,
              ),
              child: ElevatedButton(
                onPressed: onCancelOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red[700],
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                    side: BorderSide(color: Colors.red[200]!),
                  ),
                ),
                child: Text(
                  'Cancel Order',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeightManager.semiBold,
                    fontFamily: FontFamily.Montserrat,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import '../models/order_details_model.dart';
import '../constants/color/colorConstant.dart';
import '../constants/font/fontManager.dart';
import '../utils/currency_utils.dart';

class ChatOrderDetailsBubble extends StatelessWidget {
  final OrderDetails orderDetails;
  final Map<String, Map<String, dynamic>> menuItemDetails;
  final bool isFromCurrentUser;
  final String currentUserId;
  final VoidCallback? onCancelOrder;

  const ChatOrderDetailsBubble({
    Key? key,
    required this.orderDetails,
    this.menuItemDetails = const {},
    required this.isFromCurrentUser,
    required this.currentUserId,
    this.onCancelOrder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      padding: EdgeInsets.only(bottom: screenHeight * 0.012),
      child: Row(
        mainAxisAlignment: isFromCurrentUser 
            ? MainAxisAlignment.end     // User messages on RIGHT
            : MainAxisAlignment.start,  // Partner messages on LEFT
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isFromCurrentUser) const Spacer(),
          Flexible(
            flex: 7,
            child: Column(
              crossAxisAlignment: isFromCurrentUser 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                // Sender type indicator for non-current user messages
                if (!isFromCurrentUser) ...[
                  Padding(
                    padding: EdgeInsets.only(bottom: screenHeight * 0.004),
                    child: Text(
                      'Restaurant',
                      style: TextStyle(
                        fontSize: screenWidth * 0.028,
                        fontWeight: FontWeightManager.medium,
                        color: ColorManager.primary,
                        fontFamily: FontFamily.Montserrat,
                      ),
                    ),
                  ),
                ],
                
                // Order Details Chat Bubble
                Container(
                  constraints: BoxConstraints(
                    maxWidth: screenWidth * 0.75,
                  ),
                  padding: EdgeInsets.all(screenWidth * 0.035),
                  decoration: BoxDecoration(
                    color: isFromCurrentUser 
                        ? ColorManager.primary
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(screenWidth * 0.035),
                      topRight: Radius.circular(screenWidth * 0.035),
                      bottomLeft: Radius.circular(
                        isFromCurrentUser ? screenWidth * 0.035 : screenWidth * 0.01
                      ),
                      bottomRight: Radius.circular(
                        isFromCurrentUser ? screenWidth * 0.01 : screenWidth * 0.035
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Header
                      Row(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            color: isFromCurrentUser ? Colors.white70 : ColorManager.primary,
                            size: screenWidth * 0.04,
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Expanded(
                            child: Text(
                              'Order #${orderDetails.orderId}',
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                fontWeight: FontWeightManager.bold,
                                color: isFromCurrentUser ? Colors.white : ColorManager.black,
                                fontFamily: FontFamily.Montserrat,
                              ),
                            ),
                          ),
                          _buildStatusChip(orderDetails.orderStatus, screenWidth, isFromCurrentUser),
                        ],
                      ),
                      
                      SizedBox(height: screenHeight * 0.008),
                      
                      // Restaurant Name
                      Text(
                        orderDetails.restaurantName ?? 'Restaurant',
                        style: TextStyle(
                          fontSize: screenWidth * 0.032,
                          fontWeight: FontWeightManager.medium,
                          color: isFromCurrentUser ? Colors.white70 : Colors.grey[600],
                          fontFamily: FontFamily.Montserrat,
                        ),
                      ),
                      
                      SizedBox(height: screenHeight * 0.012),
                      
                      // Order Items (Compact)
                      ...orderDetails.items.take(3).map((item) => _buildCompactOrderItem(
                        item, 
                        screenWidth, 
                        screenHeight,
                        menuItemDetails[item.menuId ?? ''] ?? <String, dynamic>{},
                        isFromCurrentUser,
                      )).toList(),
                      
                      // Show "and X more items" if there are more than 3 items
                      if (orderDetails.items.length > 3) ...[
                        SizedBox(height: screenHeight * 0.005),
                        Text(
                          'and ${orderDetails.items.length - 3} more items',
                          style: TextStyle(
                            fontSize: screenWidth * 0.028,
                            fontWeight: FontWeightManager.regular,
                            color: isFromCurrentUser ? Colors.white70 : Colors.grey[500],
                            fontFamily: FontFamily.Montserrat,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      
                      SizedBox(height: screenHeight * 0.012),
                      Divider(
                        color: isFromCurrentUser ? Colors.white24 : Colors.grey[300], 
                        height: 1
                      ),
                      SizedBox(height: screenHeight * 0.012),
                      
                      // Total Amount
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              fontSize: screenWidth * 0.032,
                              fontWeight: FontWeightManager.bold,
                              color: isFromCurrentUser ? Colors.white : ColorManager.black,
                              fontFamily: FontFamily.Montserrat,
                            ),
                          ),
                          FutureBuilder<String>(
                            future: CurrencyUtils.getCurrencySymbolFromUserLocation(),
                            builder: (context, snapshot) {
                              final currencySymbol = snapshot.data ?? '₹';
                              return Text(
                                CurrencyUtils.formatPrice(orderDetails.grandTotal, currencySymbol),
                                style: TextStyle(
                                  fontSize: screenWidth * 0.032,
                                  fontWeight: FontWeightManager.bold,
                                  color: isFromCurrentUser ? Colors.white : ColorManager.black,
                                  fontFamily: FontFamily.Montserrat,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      
                      // Payment Mode if available
                      if (orderDetails.paymentMode != null && orderDetails.paymentMode!.isNotEmpty) ...[
                        SizedBox(height: screenHeight * 0.008),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Payment',
                              style: TextStyle(
                                fontSize: screenWidth * 0.028,
                                fontWeight: FontWeightManager.medium,
                                color: isFromCurrentUser ? Colors.white70 : Colors.grey[600],
                                fontFamily: FontFamily.Montserrat,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.015,
                                vertical: screenWidth * 0.008,
                              ),
                              decoration: BoxDecoration(
                                color: isFromCurrentUser 
                                    ? Colors.white24 
                                    : ColorManager.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(screenWidth * 0.012),
                              ),
                              child: Text(
                                orderDetails.paymentMode!.toUpperCase(),
                                style: TextStyle(
                                  fontSize: screenWidth * 0.024,
                                  fontWeight: FontWeightManager.medium,
                                  color: isFromCurrentUser ? Colors.white : ColorManager.primary,
                                  fontFamily: FontFamily.Montserrat,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      
                      // Cancel Order Button (if order can be cancelled)
                      if (orderDetails.canBeCancelled && onCancelOrder != null) ...[
                        SizedBox(height: screenHeight * 0.012),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: onCancelOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isFromCurrentUser ? Colors.red[400] : Colors.red[600],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.008),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(screenWidth * 0.015),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Cancel Order',
                              style: TextStyle(
                                fontSize: screenWidth * 0.028,
                                fontWeight: FontWeightManager.semiBold,
                                fontFamily: FontFamily.Montserrat,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Time indicator
                SizedBox(height: screenHeight * 0.004),
                Text(
                  'Order Details',
                  style: TextStyle(
                    fontSize: screenWidth * 0.025,
                    fontWeight: FontWeightManager.regular,
                    color: Colors.grey.shade500,
                    fontFamily: FontFamily.Montserrat,
                  ),
                ),
              ],
            ),
          ),
          if (!isFromCurrentUser) const Spacer(),
        ],
      ),
    );
  }

  Widget _buildCompactOrderItem(
    OrderDetailsItem item, 
    double screenWidth, 
    double screenHeight,
    Map<String, dynamic> menuItemData,
    bool isFromCurrentUser,
  ) {
    final itemName = menuItemData['name'] ?? item.itemName ?? 'Unknown Item';
    
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.005),
      child: Row(
        children: [
          // Item name and quantity
          Expanded(
            flex: 3,
            child: Text(
              '${item.quantity}x $itemName',
              style: TextStyle(
                fontSize: screenWidth * 0.03,
                fontWeight: FontWeightManager.medium,
                color: isFromCurrentUser ? Colors.white : ColorManager.black,
                fontFamily: FontFamily.Montserrat,
              ),
            ),
          ),
          // Price
          Expanded(
            flex: 1,
            child: FutureBuilder<String>(
              future: CurrencyUtils.getCurrencySymbolFromUserLocation(),
              builder: (context, snapshot) {
                final currencySymbol = snapshot.data ?? '₹';
                return Text(
                  CurrencyUtils.formatPrice(item.itemPrice * item.quantity, currencySymbol),
                  style: TextStyle(
                    fontSize: screenWidth * 0.03,
                    fontWeight: FontWeightManager.semiBold,
                    color: isFromCurrentUser ? Colors.white : ColorManager.black,
                    fontFamily: FontFamily.Montserrat,
                  ),
                  textAlign: TextAlign.end,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, double screenWidth, bool isFromCurrentUser) {
    Color chipColor;
    Color textColor;
    String statusText;
    
    switch (status.toUpperCase()) {
      case 'PENDING':
        chipColor = isFromCurrentUser ? Colors.orange[300]! : Colors.orange.withOpacity(0.1);
        textColor = isFromCurrentUser ? Colors.white : Colors.orange[700]!;
        statusText = 'Pending';
        break;
      case 'CONFIRMED':
        chipColor = isFromCurrentUser ? Colors.blue[300]! : Colors.blue.withOpacity(0.1);
        textColor = isFromCurrentUser ? Colors.white : Colors.blue[700]!;
        statusText = 'Confirmed';
        break;
      case 'PREPARING':
        chipColor = isFromCurrentUser ? Colors.purple[300]! : Colors.purple.withOpacity(0.1);
        textColor = isFromCurrentUser ? Colors.white : Colors.purple[700]!;
        statusText = 'Preparing';
        break;
      case 'READY_FOR_DELIVERY':
        chipColor = isFromCurrentUser ? Colors.indigo[300]! : Colors.indigo.withOpacity(0.1);
        textColor = isFromCurrentUser ? Colors.white : Colors.indigo[700]!;
        statusText = 'Ready for Delivery';
        break;
      case 'OUT_FOR_DELIVERY':
        chipColor = isFromCurrentUser ? Colors.teal[300]! : Colors.teal.withOpacity(0.1);
        textColor = isFromCurrentUser ? Colors.white : Colors.teal[700]!;
        statusText = 'Out for Delivery';
        break;
      case 'DELIVERED':
        chipColor = isFromCurrentUser ? Colors.green[300]! : Colors.green.withOpacity(0.1);
        textColor = isFromCurrentUser ? Colors.white : Colors.green[700]!;
        statusText = 'Delivered';
        break;
      case 'CANCELLED':
        chipColor = isFromCurrentUser ? Colors.red[300]! : Colors.red.withOpacity(0.1);
        textColor = isFromCurrentUser ? Colors.white : Colors.red[700]!;
        statusText = 'Cancelled';
        break;
      default:
        chipColor = isFromCurrentUser ? Colors.grey[300]! : Colors.grey.withOpacity(0.1);
        textColor = isFromCurrentUser ? Colors.white : Colors.grey[700]!;
        statusText = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.018,
        vertical: screenWidth * 0.006,
      ),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(screenWidth * 0.012),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: screenWidth * 0.022,
          fontWeight: FontWeightManager.medium,
          color: textColor,
          fontFamily: FontFamily.Montserrat,
        ),
      ),
    );
  }
} 
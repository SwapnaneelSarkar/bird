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
    
    debugPrint('ChatOrderDetailsBubble: 🎨 Building chat bubble');
    debugPrint('ChatOrderDetailsBubble: 📋 Order ID: ${orderDetails.orderId}');
    debugPrint('ChatOrderDetailsBubble: 📋 Menu item details count: ${menuItemDetails.length}');
    debugPrint('ChatOrderDetailsBubble: 📋 Menu item details keys: ${menuItemDetails.keys.toList()}');
    for (var item in orderDetails.items) {
      debugPrint('ChatOrderDetailsBubble: 📋 Item menuId: ${item.menuId}, has data: ${menuItemDetails.containsKey(item.menuId)}');
    }

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
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.045, // Match chat bubble padding
                    vertical: screenHeight * 0.014,  // Match chat bubble padding
                  ),
                  decoration: BoxDecoration(
                    color: isFromCurrentUser 
                        ? ColorManager.primary // Original primary color for user messages
                        : Colors.grey.shade200, // Original grey for received messages
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
                        color: Colors.black.withOpacity(0.06), // Softer shadow
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Header (smaller, more subtle)
                      Row(
                        children: [
                          Icon(
                            Icons.receipt_long,
                            color: isFromCurrentUser ? Colors.white70 : ColorManager.primary,
                            size: screenWidth * 0.032, // Smaller icon
                          ),
                          SizedBox(width: screenWidth * 0.012),
                          Expanded(
                            child: Text(
                              'Order #${orderDetails.orderId}',
                              style: TextStyle(
                                fontSize: screenWidth * 0.031, // Slightly smaller
                                fontWeight: FontWeightManager.semiBold,
                                color: isFromCurrentUser ? Colors.white : ColorManager.primary,
                                fontFamily: FontFamily.Montserrat,
                              ),
                            ),
                          ),
                          _buildStatusChip(orderDetails.orderStatus, screenWidth, isFromCurrentUser),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.006),
                      // Restaurant Name (subtle)
                      Text(
                        orderDetails.restaurantName ?? 'Restaurant',
                        style: TextStyle(
                          fontSize: screenWidth * 0.027,
                          fontWeight: FontWeightManager.regular,
                          color: isFromCurrentUser ? Colors.white70 : const Color(0xFF424242),
                          fontFamily: FontFamily.Montserrat,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.008),
                      // Order Items (compact, no divider)
                      ...orderDetails.items.take(3).map((item) => _buildCompactOrderItem(
                        item, 
                        screenWidth, 
                        screenHeight,
                        menuItemDetails[item.menuId ?? ''] ?? <String, dynamic>{},
                        isFromCurrentUser,
                      )).toList(),
                      if (orderDetails.items.length > 3) ...[
                        SizedBox(height: screenHeight * 0.003),
                        Text(
                          'and ${orderDetails.items.length - 3} more items',
                          style: TextStyle(
                            fontSize: screenWidth * 0.025,
                            fontWeight: FontWeightManager.regular,
                            color: isFromCurrentUser ? Colors.white70 : const Color(0xFF757575),
                            fontFamily: FontFamily.Montserrat,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      SizedBox(height: screenHeight * 0.008),
                      // Total Amount (inline, no divider)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              fontSize: screenWidth * 0.027,
                              fontWeight: FontWeightManager.bold,
                              color: isFromCurrentUser ? Colors.white : const Color(0xFF424242),
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
                                  fontSize: screenWidth * 0.027,
                                  fontWeight: FontWeightManager.bold,
                                  color: isFromCurrentUser ? Colors.white : const Color(0xFF424242),
                                  fontFamily: FontFamily.Montserrat,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      // Payment Mode (highlighted section)
                      if (orderDetails.paymentMode != null && orderDetails.paymentMode!.isNotEmpty) ...[
                        SizedBox(height: screenHeight * 0.008),
                        Container(
                          padding: EdgeInsets.all(screenWidth * 0.015),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isFromCurrentUser 
                                  ? [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.08)]
                                  : [ColorManager.primary.withOpacity(0.08), ColorManager.primary.withOpacity(0.04)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(screenWidth * 0.012),
                            border: Border.all(
                              color: isFromCurrentUser 
                                  ? Colors.white.withOpacity(0.2)
                                  : ColorManager.primary.withOpacity(0.15),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Payment',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.024,
                                  fontWeight: FontWeightManager.semiBold,
                                  color: isFromCurrentUser ? Colors.white : ColorManager.primary,
                                  fontFamily: FontFamily.Montserrat,
                                ),
                              ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.015,
                                vertical: screenWidth * 0.008,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isFromCurrentUser 
                                      ? [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.2)]
                                      : [ColorManager.primary.withOpacity(0.2), ColorManager.primary.withOpacity(0.1)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(screenWidth * 0.015),
                                border: Border.all(
                                  color: isFromCurrentUser 
                                      ? Colors.white.withOpacity(0.4)
                                      : ColorManager.primary.withOpacity(0.3),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isFromCurrentUser 
                                        ? Colors.white.withOpacity(0.2)
                                        : ColorManager.primary.withOpacity(0.1),
                                    blurRadius: 4,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                orderDetails.paymentMode!.toUpperCase(),
                                style: TextStyle(
                                  fontSize: screenWidth * 0.021,
                                  fontWeight: FontWeightManager.semiBold,
                                  color: isFromCurrentUser ? Colors.white : ColorManager.primary,
                                  fontFamily: FontFamily.Montserrat,
                                ),
                              ),
                            ),
                          ],
                        ),
                        ),
                      ],
                      // Cancel Order Button (always show if onCancelOrder is provided, but make inactive if not cancellable)
                      if (onCancelOrder != null) ...[
                        SizedBox(height: screenHeight * 0.008),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: orderDetails.canBeCancelled ? Colors.white60 : Colors.grey[300],
                            borderRadius: BorderRadius.circular(screenWidth * 0.015),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                spreadRadius: 0,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: orderDetails.canBeCancelled ? onCancelOrder : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: orderDetails.canBeCancelled ? Colors.black : Colors.grey[600],
                              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.008),
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(screenWidth * 0.015),
                              ),
                            ),
                            child: Text(
                              orderDetails.canBeCancelled ? 'Cancel Order' : 'Order Cannot Be Cancelled',
                              style: TextStyle(
                                fontSize: screenWidth * 0.022,
                                fontWeight: FontWeightManager.semiBold,
                                color: orderDetails.canBeCancelled ? Colors.black : Colors.grey[600],
                                fontFamily: FontFamily.Montserrat,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Remove or make the time indicator very subtle
                SizedBox(height: screenHeight * 0.002),
                // Optionally, remove the "Order Details" label or make it very subtle
                // Text(
                //   'Order Details',
                //   style: TextStyle(
                //     fontSize: screenWidth * 0.021,
                //     fontWeight: FontWeightManager.regular,
                //     color: Colors.grey.shade400,
                //     fontFamily: FontFamily.Montserrat,
                //   ),
                // ),
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
    debugPrint('ChatOrderDetailsBubble: 🔍 Building item for menuId: ${item.menuId}');
    debugPrint('ChatOrderDetailsBubble: 🔍 Menu item data: $menuItemData');
    debugPrint('ChatOrderDetailsBubble: 🔍 Item name from data: ${menuItemData['name']}');
    debugPrint('ChatOrderDetailsBubble: 🔍 Item name from item: ${item.itemName}');
    
    // Try to get item name from multiple sources
    String itemName = 'Unknown Item';
    
    // First try menu item data
    if (menuItemData.isNotEmpty && menuItemData['name'] != null) {
      itemName = menuItemData['name'] as String;
    }
    // Then try item.itemName
    else if (item.itemName != null && item.itemName!.isNotEmpty) {
      itemName = item.itemName!;
    }
    // Finally, if we have a menuId, show a generic name
    else if (item.menuId != null && item.menuId!.isNotEmpty) {
      itemName = 'Item #${item.menuId}';
    }
    
    // If we still don't have a name, show a generic name
    if (itemName.isEmpty || itemName == 'Unknown Item') {
      itemName = 'Item #${item.menuId ?? 'Unknown'}';
    }
    
    debugPrint('ChatOrderDetailsBubble: 🔍 Final item name: $itemName');
    
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
                color: isFromCurrentUser ? Colors.white : const Color(0xFF424242),
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
                    color: isFromCurrentUser ? Colors.white : const Color(0xFF424242),
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
        chipColor = isFromCurrentUser ? ColorManager.yellowAcc : ColorManager.yellowAcc.withOpacity(0.2);
        textColor = isFromCurrentUser ? Colors.white : ColorManager.yellowAcc;
        statusText = 'Pending';
        break;
      case 'CONFIRMED':
        chipColor = isFromCurrentUser ? ColorManager.primary : ColorManager.primary.withOpacity(0.2);
        textColor = isFromCurrentUser ? Colors.white : ColorManager.primary;
        statusText = 'Confirmed';
        break;
      case 'PREPARING':
        chipColor = isFromCurrentUser ? ColorManager.primary.withOpacity(0.8) : ColorManager.primary.withOpacity(0.15);
        textColor = isFromCurrentUser ? Colors.white : ColorManager.primary;
        statusText = 'Preparing';
        break;
      case 'READY_FOR_DELIVERY':
        chipColor = isFromCurrentUser ? ColorManager.primary.withOpacity(0.7) : ColorManager.primary.withOpacity(0.1);
        textColor = isFromCurrentUser ? Colors.white : ColorManager.primary;
        statusText = 'Ready for Delivery';
        break;
      case 'OUT_FOR_DELIVERY':
        chipColor = isFromCurrentUser ? ColorManager.instamartGreen : ColorManager.instamartLightGreen;
        textColor = isFromCurrentUser ? Colors.white : ColorManager.instamartDarkGreen;
        statusText = 'Out for Delivery';
        break;
      case 'DELIVERED':
        chipColor = isFromCurrentUser ? ColorManager.instamartGreen : ColorManager.instamartLightGreen;
        textColor = isFromCurrentUser ? Colors.white : ColorManager.instamartDarkGreen;
        statusText = 'Delivered';
        break;
      case 'CANCELLED':
        chipColor = isFromCurrentUser ? ColorManager.signUpRed : ColorManager.signUpRed.withOpacity(0.2);
        textColor = isFromCurrentUser ? Colors.white : ColorManager.signUpRed;
        statusText = 'Cancelled';
        break;
      default:
        chipColor = isFromCurrentUser ? ColorManager.cardGrey : ColorManager.cardGrey.withOpacity(0.3);
        textColor = isFromCurrentUser ? Colors.white : ColorManager.black;
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
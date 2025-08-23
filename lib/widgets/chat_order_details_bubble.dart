import 'package:flutter/material.dart';
import '../models/order_details_model.dart';
import '../constants/color/colorConstant.dart';
import '../constants/font/fontManager.dart';
import '../utils/currency_utils.dart';

class ChatOrderDetailsBubble extends StatefulWidget {
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
  State<ChatOrderDetailsBubble> createState() => _ChatOrderDetailsBubbleState();
}

class _ChatOrderDetailsBubbleState extends State<ChatOrderDetailsBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Start pulsing animation for certain statuses
    if (widget.orderDetails.orderStatus.toUpperCase() == 'PENDING' ||
        widget.orderDetails.orderStatus.toUpperCase() == 'PREPARING') {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    debugPrint('ChatOrderDetailsBubble: 🎨 Building chat bubble');
    debugPrint('ChatOrderDetailsBubble: 📋 Order ID: ${widget.orderDetails.orderId}');
    debugPrint('ChatOrderDetailsBubble: 📋 Menu item details count: ${widget.menuItemDetails.length}');
    debugPrint('ChatOrderDetailsBubble: 📋 Menu item details keys: ${widget.menuItemDetails.keys.toList()}');
    debugPrint('🚨 ChatOrderDetailsBubble: Checking cancel button conditions');
    debugPrint('🚨 ChatOrderDetailsBubble: onCancelOrder is null: ${widget.onCancelOrder == null}');
    debugPrint('🚨 ChatOrderDetailsBubble: Order status: ${widget.orderDetails.orderStatus}');
    debugPrint('🚨 ChatOrderDetailsBubble: Status lowercase: ${widget.orderDetails.orderStatus.toLowerCase()}');
    debugPrint('🚨 ChatOrderDetailsBubble: Can be cancelled: ${widget.orderDetails.canBeCancelled}');
    for (var item in widget.orderDetails.items) {
      debugPrint('ChatOrderDetailsBubble: 📋 Item menuId: ${item.menuId}, has data: ${widget.menuItemDetails.containsKey(item.menuId)}');
    }

    return Container(
      padding: EdgeInsets.only(bottom: screenHeight * 0.012),
      child: Row(
        mainAxisAlignment: widget.isFromCurrentUser 
            ? MainAxisAlignment.end     // User messages on RIGHT
            : MainAxisAlignment.start,  // Partner messages on LEFT
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isFromCurrentUser) const Spacer(),
          Flexible(
            flex: 7,
            child: Column(
              crossAxisAlignment: widget.isFromCurrentUser 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                // Sender type indicator for non-current user messages
                if (!widget.isFromCurrentUser) ...[
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
                    color: widget.isFromCurrentUser 
                        ? ColorManager.primary // Original primary color for user messages
                        : Colors.grey.shade200, // Original grey for received messages
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(screenWidth * 0.035),
                      topRight: Radius.circular(screenWidth * 0.035),
                      bottomLeft: Radius.circular(
                        widget.isFromCurrentUser ? screenWidth * 0.035 : screenWidth * 0.01
                      ),
                      bottomRight: Radius.circular(
                        widget.isFromCurrentUser ? screenWidth * 0.01 : screenWidth * 0.035
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
                            color: widget.isFromCurrentUser ? Colors.white70 : ColorManager.primary,
                            size: screenWidth * 0.032, // Smaller icon
                          ),
                          SizedBox(width: screenWidth * 0.012),
                          Expanded(
                            child: Text(
                              'Order #${widget.orderDetails.orderId}',
                              style: TextStyle(
                                fontSize: screenWidth * 0.031, // Slightly smaller
                                fontWeight: FontWeightManager.semiBold,
                                color: widget.isFromCurrentUser ? Colors.white : ColorManager.primary,
                                fontFamily: FontFamily.Montserrat,
                              ),
                            ),
                          ),
                          _buildStatusChip(widget.orderDetails.orderStatus, screenWidth, widget.isFromCurrentUser),
                        ],
                      ),
                      SizedBox(height: screenHeight * 0.006),
                      // Restaurant Name (subtle)
                      Text(
                        widget.orderDetails.restaurantName ?? 'Restaurant',
                        style: TextStyle(
                          fontSize: screenWidth * 0.027,
                          fontWeight: FontWeightManager.regular,
                          color: widget.isFromCurrentUser ? Colors.white70 : const Color(0xFF424242),
                          fontFamily: FontFamily.Montserrat,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.008),
                      // Order Items (compact, no divider)
                      ...widget.orderDetails.items.take(3).map((item) => _buildCompactOrderItem(
                        item, 
                        screenWidth, 
                        screenHeight,
                        widget.menuItemDetails[item.menuId ?? ''] ?? <String, dynamic>{},
                        widget.isFromCurrentUser,
                      )).toList(),
                      if (widget.orderDetails.items.length > 3) ...[
                        SizedBox(height: screenHeight * 0.003),
                        Text(
                          'and ${widget.orderDetails.items.length - 3} more items',
                          style: TextStyle(
                            fontSize: screenWidth * 0.025,
                            fontWeight: FontWeightManager.regular,
                            color: widget.isFromCurrentUser ? Colors.white70 : const Color(0xFF757575),
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
                              color: widget.isFromCurrentUser ? Colors.white : const Color(0xFF424242),
                              fontFamily: FontFamily.Montserrat,
                            ),
                          ),
                          Text(
                            widget.orderDetails.getFormattedPrice(widget.orderDetails.grandTotal),
                            style: TextStyle(
                              fontSize: screenWidth * 0.027,
                              fontWeight: FontWeightManager.bold,
                              color: widget.isFromCurrentUser ? Colors.white : const Color(0xFF424242),
                              fontFamily: FontFamily.Montserrat,
                            ),
                          ),
                        ],
                      ),
                      // Payment Mode (highlighted section)
                      if (widget.orderDetails.paymentMode != null && widget.orderDetails.paymentMode!.isNotEmpty) ...[
                        SizedBox(height: screenHeight * 0.008),
                        Container(
                          padding: EdgeInsets.all(screenWidth * 0.015),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: widget.isFromCurrentUser 
                                  ? [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.08)]
                                  : [ColorManager.primary.withOpacity(0.08), ColorManager.primary.withOpacity(0.04)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(screenWidth * 0.012),
                            border: Border.all(
                              color: widget.isFromCurrentUser 
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
                                  color: widget.isFromCurrentUser ? Colors.white : ColorManager.primary,
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
                                  colors: widget.isFromCurrentUser 
                                      ? [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.2)]
                                      : [ColorManager.primary.withOpacity(0.2), ColorManager.primary.withOpacity(0.1)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(screenWidth * 0.015),
                                border: Border.all(
                                  color: widget.isFromCurrentUser 
                                      ? Colors.white.withOpacity(0.4)
                                      : ColorManager.primary.withOpacity(0.3),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.isFromCurrentUser 
                                        ? Colors.white.withOpacity(0.2)
                                        : ColorManager.primary.withOpacity(0.1),
                                    blurRadius: 4,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                widget.orderDetails.paymentMode!.toUpperCase(),
                                style: TextStyle(
                                  fontSize: screenWidth * 0.021,
                                  fontWeight: FontWeightManager.semiBold,
                                  color: widget.isFromCurrentUser ? Colors.white : ColorManager.primary,
                                  fontFamily: FontFamily.Montserrat,
                                ),
                              ),
                            ),
                          ],
                        ),
                        ),
                      ],
                      // Cancel Order Button (only show if status is confirmed or pending)
                      if (widget.onCancelOrder != null && 
                          (widget.orderDetails.orderStatus.toLowerCase() == 'confirmed' || 
                           widget.orderDetails.orderStatus.toLowerCase() == 'pending')) ...[
                        SizedBox(height: screenHeight * 0.008),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white60,
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
                            onPressed: widget.onCancelOrder,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.black,
                              padding: EdgeInsets.symmetric(vertical: screenHeight * 0.008),
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(screenWidth * 0.015),
                              ),
                            ),
                            child: Text(
                              'Cancel Order',
                              style: TextStyle(
                                fontSize: screenWidth * 0.022,
                                fontWeight: FontWeightManager.semiBold,
                                color: Colors.black,
                                fontFamily: FontFamily.Montserrat,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Time and status (similar to normal chat messages)
                SizedBox(height: screenHeight * 0.004),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.orderDetails.formattedCreatedTime,
                      style: TextStyle(
                        fontSize: screenWidth * 0.028,
                        fontWeight: FontWeightManager.regular,
                        color: Colors.grey.shade500,
                        fontFamily: FontFamily.Montserrat,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!widget.isFromCurrentUser) const Spacer(),
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
            child: Text(
              widget.orderDetails.getFormattedPrice(item.itemPrice * item.quantity),
              style: TextStyle(
                fontSize: screenWidth * 0.03,
                fontWeight: FontWeightManager.semiBold,
                color: isFromCurrentUser ? Colors.white : const Color(0xFF424242),
                fontFamily: FontFamily.Montserrat,
              ),
              textAlign: TextAlign.end,
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
    IconData? statusIcon;
    
    switch (status.toUpperCase()) {
      case 'PENDING':
        chipColor = isFromCurrentUser ? ColorManager.yellowAcc : ColorManager.yellowAcc.withOpacity(0.2);
        textColor = isFromCurrentUser ? Colors.white : ColorManager.yellowAcc;
        statusText = 'Pending';
        statusIcon = Icons.schedule;
        break;
      case 'CONFIRMED':
        chipColor = isFromCurrentUser ? ColorManager.primary : ColorManager.primary.withOpacity(0.2);
        textColor = isFromCurrentUser ? Colors.white : ColorManager.primary;
        statusText = 'Confirmed';
        statusIcon = Icons.check_circle;
        break;
      case 'PREPARING':
        chipColor = isFromCurrentUser ? ColorManager.primary.withOpacity(0.8) : ColorManager.primary.withOpacity(0.15);
        textColor = isFromCurrentUser ? Colors.white : ColorManager.primary;
        statusText = 'Preparing';
        statusIcon = Icons.restaurant;
        break;
      case 'READY_FOR_DELIVERY':
        chipColor = isFromCurrentUser ? ColorManager.primary.withOpacity(0.7) : ColorManager.primary.withOpacity(0.1);
        textColor = isFromCurrentUser ? Colors.white : ColorManager.primary;
        statusText = 'Ready for Delivery';
        statusIcon = Icons.delivery_dining;
        break;
      case 'OUT_FOR_DELIVERY':
        chipColor = isFromCurrentUser ? ColorManager.instamartGreen : ColorManager.instamartLightGreen;
        textColor = isFromCurrentUser ? Colors.white : ColorManager.instamartDarkGreen;
        statusText = 'Out for Delivery';
        statusIcon = Icons.local_shipping;
        break;
      case 'DELIVERED':
        chipColor = isFromCurrentUser ? ColorManager.instamartGreen : ColorManager.instamartLightGreen;
        textColor = isFromCurrentUser ? Colors.white : ColorManager.instamartDarkGreen;
        statusText = 'Delivered';
        statusIcon = Icons.done_all;
        break;
      case 'CANCELLED':
        chipColor = isFromCurrentUser ? ColorManager.signUpRed : ColorManager.signUpRed.withOpacity(0.2);
        textColor = isFromCurrentUser ? Colors.white : ColorManager.signUpRed;
        statusText = 'Cancelled';
        statusIcon = Icons.cancel;
        break;
      default:
        chipColor = isFromCurrentUser ? ColorManager.cardGrey : ColorManager.cardGrey.withOpacity(0.3);
        textColor = isFromCurrentUser ? Colors.white : ColorManager.black;
        statusText = status;
        statusIcon = Icons.info;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.02,
        vertical: screenWidth * 0.012,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            chipColor,
            chipColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(screenWidth * 0.02),
        border: Border.all(
          color: textColor.withOpacity(0.4),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: chipColor.withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (statusIcon != null) ...[
            Container(
              padding: EdgeInsets.all(screenWidth * 0.008),
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                statusIcon,
                size: screenWidth * 0.028,
                color: textColor,
              ),
            ),
            SizedBox(width: screenWidth * 0.01),
          ],
          Text(
            statusText,
            style: TextStyle(
              fontSize: screenWidth * 0.024,
              fontWeight: FontWeightManager.bold,
              color: textColor,
              fontFamily: FontFamily.Montserrat,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
} 
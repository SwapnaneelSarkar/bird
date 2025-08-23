import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../constants/color/colorConstant.dart';
import '../constants/font/fontManager.dart';
import '../models/order_details_model.dart';
import '../service/order_status_sse_service.dart';

class ChatOrderStatusBubble extends StatelessWidget {
  final OrderDetails orderDetails;
  final bool isFromCurrentUser;
  final String currentUserId;
  final OrderStatusUpdate? latestStatusUpdate;

  const ChatOrderStatusBubble({
    Key? key,
    required this.orderDetails,
    required this.isFromCurrentUser,
    required this.currentUserId,
    this.latestStatusUpdate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Use latest status update if available, otherwise use order details
    final status = latestStatusUpdate?.status ?? orderDetails.orderStatus;
    final message = latestStatusUpdate?.message ?? 'Order status updated';
    final timestamp = latestStatusUpdate?.timestamp ?? '';
    
    return Container(
      margin: EdgeInsets.only(
        bottom: screenHeight * 0.012,
        left: isFromCurrentUser ? screenWidth * 0.2 : 0,
        right: isFromCurrentUser ? 0 : screenWidth * 0.2,
      ),
      child: Row(
        mainAxisAlignment: isFromCurrentUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isFromCurrentUser) ...[
            CircleAvatar(
              radius: screenWidth * 0.04,
              backgroundColor: ColorManager.primary,
              child: Icon(
                Icons.restaurant,
                color: Colors.white,
                size: screenWidth * 0.045,
              ),
            ),
            SizedBox(width: screenWidth * 0.025),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.all(screenWidth * 0.035),
              decoration: BoxDecoration(
                color: isFromCurrentUser 
                    ? ColorManager.primary.withOpacity(0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(screenWidth * 0.035),
                border: Border.all(
                  color: isFromCurrentUser 
                      ? ColorManager.primary.withOpacity(0.3)
                      : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Simple status display
                  Row(
                    children: [
                      Icon(
                        _getStatusIcon(status),
                        color: _getStatusColor(status),
                        size: screenWidth * 0.045,
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Expanded(
                        child: Text(
                          orderDetails.restaurantName ?? 'Restaurant',
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            fontWeight: FontWeightManager.semiBold,
                            color: ColorManager.black,
                            fontFamily: FontFamily.Montserrat,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  
                  // Status text
                  Text(
                    'Status: ${_getStatusDisplayText(status)}',
                    style: TextStyle(
                      fontSize: screenWidth * 0.032,
                      fontWeight: FontWeightManager.medium,
                      color: _getStatusColor(status),
                      fontFamily: FontFamily.Montserrat,
                    ),
                  ),
                  
                  if (message.isNotEmpty) ...[
                    SizedBox(height: screenHeight * 0.01),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: screenWidth * 0.032,
                        fontWeight: FontWeightManager.regular,
                        color: Colors.grey.shade700,
                        fontFamily: FontFamily.Montserrat,
                      ),
                    ),
                  ],
                  
                  // Simple order info
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    'Order ID: ${orderDetails.orderId}',
                    style: TextStyle(
                      fontSize: screenWidth * 0.03,
                      fontWeight: FontWeightManager.regular,
                      color: Colors.grey.shade600,
                      fontFamily: FontFamily.Montserrat,
                    ),
                  ),
                  Text(
                    'Total: ₹${orderDetails.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: screenWidth * 0.03,
                      fontWeight: FontWeightManager.regular,
                      color: Colors.grey.shade600,
                      fontFamily: FontFamily.Montserrat,
                    ),
                  ),
                  
                  // Timestamp
                  if (timestamp.isNotEmpty) ...[
                    SizedBox(height: screenHeight * 0.008),
                    Text(
                      _formatTimestamp(timestamp),
                      style: TextStyle(
                        fontSize: screenWidth * 0.028,
                        fontWeight: FontWeightManager.regular,
                        color: Colors.grey.shade500,
                        fontFamily: FontFamily.Montserrat,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (isFromCurrentUser) ...[
            SizedBox(width: screenWidth * 0.025),
            CircleAvatar(
              radius: screenWidth * 0.04,
              backgroundColor: ColorManager.primary,
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: screenWidth * 0.045,
              ),
            ),
          ],
        ],
      ),
    );
  }



  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'confirmed':
        return Icons.check_circle;
      case 'preparing':
        return Icons.restaurant;
      case 'ready':
      case 'ready_for_delivery':
        return Icons.done_all;
      case 'on_the_way':
      case 'out_for_delivery':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.check_circle_outline;
      case 'cancelled':
      case 'canceled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.indigo;
      case 'ready':
      case 'ready_for_delivery':
        return Colors.green;
      case 'on_the_way':
      case 'out_for_delivery':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
      case 'canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplayText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Order Placed';
      case 'confirmed':
        return 'Order Confirmed';
      case 'preparing':
        return 'Preparing Your Order';
      case 'ready':
      case 'ready_for_delivery':
        return 'Ready for Pickup';
      case 'on_the_way':
      case 'out_for_delivery':
        return 'On the Way';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
      case 'canceled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} minutes ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} hours ago';
      } else {
        return '${difference.inDays} days ago';
      }
    } catch (e) {
      return 'Recently';
    }
  }
} 
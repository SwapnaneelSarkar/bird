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
    
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.01,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cancel Button at the top (if order can be cancelled)
          if (orderDetails.canBeCancelled && onCancelOrder != null)
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: screenHeight * 0.01),
              child: ElevatedButton(
                onPressed: onCancelOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: screenHeight * 0.012),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  ),
                  elevation: 0,
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
          
          // Chat Bubble Container
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(screenWidth * 0.025),
              border: Border.all(
                color: ColorManager.primary.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header - Order ID and Restaurant
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.035),
                  decoration: BoxDecoration(
                    color: ColorManager.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(screenWidth * 0.025),
                      topRight: Radius.circular(screenWidth * 0.025),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        color: ColorManager.primary,
                        size: screenWidth * 0.045,
                      ),
                      SizedBox(width: screenWidth * 0.025),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Order #${orderDetails.orderId}',
                              style: TextStyle(
                                fontSize: screenWidth * 0.038,
                                fontWeight: FontWeightManager.bold,
                                color: ColorManager.black,
                                fontFamily: FontFamily.Montserrat,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.003),
                            Text(
                              orderDetails.restaurantName ?? 'Restaurant',
                              style: TextStyle(
                                fontSize: screenWidth * 0.032,
                                fontWeight: FontWeightManager.medium,
                                color: Colors.grey[600],
                                fontFamily: FontFamily.Montserrat,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusChip(orderDetails.orderStatus, screenWidth),
                    ],
                  ),
                ),
                
                // Order Items - Compact List
                Padding(
                  padding: EdgeInsets.all(screenWidth * 0.035),
                  child: Column(
                    children: [
                      // Items List
                      ...orderDetails.items.map((item) => _buildCompactOrderItem(
                        item, 
                        screenWidth, 
                        screenHeight,
                        menuItemDetails[item.menuId ?? ''] ?? <String, dynamic>{},
                      )).toList(),
                      
                      SizedBox(height: screenHeight * 0.015),
                      Divider(color: Colors.grey[200], height: 1),
                      SizedBox(height: screenHeight * 0.015),
                      
                      // Compact Price Breakdown
                      _buildCompactPriceBreakdown(screenWidth, screenHeight),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactOrderItem(
    OrderDetailsItem item, 
    double screenWidth, 
    double screenHeight,
    Map<String, dynamic> menuItemData,
  ) {
    final itemName = menuItemData['name'] ?? item.itemName ?? 'Unknown Item';
    
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.008),
      child: Row(
        children: [
          // Item name and quantity
          Expanded(
            flex: 3,
            child: Text(
              '${item.quantity}x $itemName',
              style: TextStyle(
                fontSize: screenWidth * 0.032,
                fontWeight: FontWeightManager.medium,
                color: ColorManager.black,
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
                    fontSize: screenWidth * 0.032,
                    fontWeight: FontWeightManager.semiBold,
                    color: ColorManager.black,
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

  Widget _buildCompactPriceBreakdown(double screenWidth, double screenHeight) {
    return Column(
      children: [
        _buildCompactPriceRow('Subtotal', orderDetails.subtotal, screenWidth),
        SizedBox(height: screenHeight * 0.005),
        _buildCompactPriceRow('Delivery', orderDetails.deliveryFees, screenWidth),
        SizedBox(height: screenHeight * 0.008),
        Divider(color: Colors.grey[200], height: 1),
        SizedBox(height: screenHeight * 0.008),
        _buildCompactPriceRow('Total', orderDetails.grandTotal, screenWidth, isTotal: true),
        
        // Payment mode if available
        if (orderDetails.paymentMode != null && orderDetails.paymentMode!.isNotEmpty) ...[
          SizedBox(height: screenHeight * 0.008),
          Divider(color: Colors.grey[200], height: 1),
          SizedBox(height: screenHeight * 0.008),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment',
                style: TextStyle(
                  fontSize: screenWidth * 0.03,
                  fontWeight: FontWeightManager.medium,
                  color: Colors.grey[600],
                  fontFamily: FontFamily.Montserrat,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.018,
                  vertical: screenWidth * 0.01,
                ),
                decoration: BoxDecoration(
                  color: ColorManager.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(screenWidth * 0.012),
                ),
                child: Text(
                  orderDetails.paymentMode!.toUpperCase(),
                  style: TextStyle(
                    fontSize: screenWidth * 0.026,
                    fontWeight: FontWeightManager.medium,
                    color: ColorManager.primary,
                    fontFamily: FontFamily.Montserrat,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCompactPriceRow(String label, double amount, double screenWidth, {bool isTotal = false}) {
    return FutureBuilder<String>(
      future: CurrencyUtils.getCurrencySymbolFromUserLocation(),
      builder: (context, snapshot) {
        final currencySymbol = snapshot.data ?? '₹';
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: screenWidth * 0.03,
                fontWeight: isTotal ? FontWeightManager.bold : FontWeightManager.medium,
                color: isTotal ? ColorManager.black : Colors.grey[600],
                fontFamily: FontFamily.Montserrat,
              ),
            ),
            Text(
              CurrencyUtils.formatPrice(amount, currencySymbol),
              style: TextStyle(
                fontSize: screenWidth * 0.03,
                fontWeight: isTotal ? FontWeightManager.bold : FontWeightManager.semiBold,
                color: isTotal ? ColorManager.black : ColorManager.black,
                fontFamily: FontFamily.Montserrat,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusChip(String status, double screenWidth) {
    Color chipColor;
    Color textColor;
    String statusText;
    
    switch (status.toLowerCase()) {
      case 'pending':
        chipColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange[700]!;
        statusText = 'Pending';
        break;
      case 'confirmed':
        chipColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue[700]!;
        statusText = 'Confirmed';
        break;
      case 'preparing':
        chipColor = Colors.purple.withOpacity(0.1);
        textColor = Colors.purple[700]!;
        statusText = 'Preparing';
        break;
      case 'ready':
      case 'ready_for_delivery':
        chipColor = Colors.indigo.withOpacity(0.1);
        textColor = Colors.indigo[700]!;
        statusText = 'Ready';
        break;
      case 'on_the_way':
      case 'out_for_delivery':
        chipColor = Colors.teal.withOpacity(0.1);
        textColor = Colors.teal[700]!;
        statusText = 'On the Way';
        break;
      case 'delivered':
        chipColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green[700]!;
        statusText = 'Delivered';
        break;
      case 'cancelled':
      case 'canceled':
        chipColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red[700]!;
        statusText = 'Cancelled';
        break;
      default:
        chipColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey[700]!;
        statusText = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.02,
        vertical: screenWidth * 0.008,
      ),
      decoration: BoxDecoration(
        color: chipColor,
        borderRadius: BorderRadius.circular(screenWidth * 0.015),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: screenWidth * 0.025,
          fontWeight: FontWeightManager.medium,
          color: textColor,
          fontFamily: FontFamily.Montserrat,
        ),
      ),
    );
  }
} 
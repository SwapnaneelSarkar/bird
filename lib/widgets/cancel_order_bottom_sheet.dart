// ui_components/cancel_order_bottom_sheet.dart
import 'package:bird/constants/color/colorConstant.dart';
import 'package:bird/constants/font/fontManager.dart';
import 'package:flutter/material.dart';


class CancelOrderBottomSheet extends StatefulWidget {
  final String orderId;
  final Function(String) onCancel;

  const CancelOrderBottomSheet({
    Key? key,
    required this.orderId,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<CancelOrderBottomSheet> createState() => _CancelOrderBottomSheetState();
}

class _CancelOrderBottomSheetState extends State<CancelOrderBottomSheet> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(screenWidth * 0.05),
          topRight: Radius.circular(screenWidth * 0.05),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: screenWidth * 0.12,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: screenHeight * 0.025),

          // Title
          Text(
            'Cancel Order',
            style: TextStyle(
              fontSize: screenWidth * 0.055,
              fontWeight: FontWeightManager.bold,
              color: ColorManager.black,
              fontFamily: FontFamily.Montserrat,
            ),
          ),
          SizedBox(height: screenHeight * 0.015),

          // Order ID
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order ID',
                  style: TextStyle(
                    fontSize: screenWidth * 0.032,
                    fontWeight: FontWeightManager.medium,
                    color: Colors.grey.shade600,
                    fontFamily: FontFamily.Montserrat,
                  ),
                ),
                SizedBox(height: screenHeight * 0.005),
                Text(
                  '#${widget.orderId}',
                  style: TextStyle(
                    fontSize: screenWidth * 0.038,
                    fontWeight: FontWeightManager.semiBold,
                    color: ColorManager.black,
                    fontFamily: FontFamily.Montserrat,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: screenHeight * 0.02),

          // Warning message
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
              border: Border.all(
                color: Colors.red.shade200,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red.shade600,
                  size: screenWidth * 0.05,
                ),
                SizedBox(width: screenWidth * 0.03),
                Expanded(
                  child: Text(
                    'Are you sure you want to cancel this order? This action cannot be undone.',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeightManager.regular,
                      color: Colors.red.shade700,
                      fontFamily: FontFamily.Montserrat,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: screenHeight * 0.03),

          // Buttons
          Row(
            children: [
              // Keep Order button
              Expanded(
                child: GestureDetector(
                  onTap: _isLoading ? null : () => Navigator.pop(context),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.018,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(screenWidth * 0.025),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Keep Order',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeightManager.semiBold,
                          color: ColorManager.black,
                          fontFamily: FontFamily.Montserrat,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.04),

              // Cancel Order button
              Expanded(
                child: GestureDetector(
                  onTap: _isLoading ? null : _handleCancelOrder,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: screenHeight * 0.018,
                    ),
                    decoration: BoxDecoration(
                      color: _isLoading 
                          ? Colors.red.shade300 
                          : Colors.red.shade600,
                      borderRadius: BorderRadius.circular(screenWidth * 0.025),
                    ),
                    child: Center(
                      child: _isLoading
                          ? SizedBox(
                              width: screenWidth * 0.05,
                              height: screenWidth * 0.05,
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Cancel Order',
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeightManager.semiBold,
                                color: Colors.white,
                                fontFamily: FontFamily.Montserrat,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Add bottom safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom + screenHeight * 0.02),
        ],
      ),
    );
  }

  Future<void> _handleCancelOrder() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onCancel(widget.orderId);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

// Helper function to show the bottom sheet
void showCancelOrderBottomSheet({
  required BuildContext context,
  required String orderId,
  required Function(String) onCancel,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => CancelOrderBottomSheet(
      orderId: orderId,
      onCancel: onCancel,
    ),
  );
}
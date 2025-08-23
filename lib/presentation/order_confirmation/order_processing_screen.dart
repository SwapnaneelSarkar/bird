import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../constants/color/colorConstant.dart';
import '../../constants/font/fontManager.dart';
import 'bloc.dart';
import 'state.dart';

class OrderProcessingScreen extends StatelessWidget {
  const OrderProcessingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocListener<OrderConfirmationBloc, OrderConfirmationState>(
        listener: (context, state) {
          debugPrint('OrderProcessingScreen: State changed to ${state.runtimeType}');
          
          if (state is OrderConfirmationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
            
            debugPrint('🚨🚨🚨 ORDER PROCESSING: Navigating to chat for order: ${state.orderId} 🚨🚨🚨');
            print('🚨🚨🚨 ORDER PROCESSING: Navigating to chat for order: ${state.orderId} 🚨🚨🚨');
            Navigator.of(context).pushReplacementNamed('/chat', arguments: {
              'orderId': state.orderId,
              'isNewlyPlacedOrder': true,
            });
          } else if (state is ChatRoomCreated) {
            debugPrint('🚨🚨🚨 ORDER PROCESSING: Chat room created, navigating to chat... 🚨🚨🚨');
            print('🚨🚨🚨 ORDER PROCESSING: Chat room created, navigating to chat... 🚨🚨🚨');
            debugPrint('🚨🚨🚨 ORDER PROCESSING: Order ID being passed: ${state.orderId} 🚨🚨🚨');
            print('🚨🚨🚨 ORDER PROCESSING: Order ID being passed: ${state.orderId} 🚨🚨🚨');
            Navigator.of(context).pushReplacementNamed('/chat', arguments: {
              'orderId': state.orderId,
              'isNewlyPlacedOrder': true,
            });
          } else if (state is OrderConfirmationError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
            // Navigate back to order confirmation page
            Navigator.of(context).pop();
          }
        },
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated loading indicator
                Container(
                  width: screenWidth * 0.2,
                  height: screenWidth * 0.2,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(ColorManager.primary),
                  ),
                ),
                
                SizedBox(height: screenHeight * 0.04),
                
                // Main title
                Text(
                  'Processing Your Order',
                  style: TextStyle(
                    fontSize: screenWidth * 0.06,
                    fontWeight: FontWeightManager.bold,
                    fontFamily: FontFamily.Montserrat,
                    color: ColorManager.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: screenHeight * 0.02),
                
                // Subtitle
                Text(
                  'Please wait while we place your order',
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeightManager.regular,
                    fontFamily: FontFamily.Montserrat,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: screenHeight * 0.03),
                
                // Progress steps
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      _buildProgressStep(
                        'Validating order details',
                        Icons.check_circle,
                        Colors.green,
                        screenWidth,
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      _buildProgressStep(
                        'Processing payment',
                        Icons.payment,
                        ColorManager.primary,
                        screenWidth,
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      _buildProgressStep(
                        'Confirming with restaurant',
                        Icons.restaurant,
                        Colors.orange,
                        screenWidth,
                      ),
                      SizedBox(height: screenHeight * 0.015),
                      _buildProgressStep(
                        'Creating chat room',
                        Icons.chat_bubble,
                        Colors.blue,
                        screenWidth,
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: screenHeight * 0.04),
                
                // Cancel button
                TextButton(
                  onPressed: () {
                    // Show confirmation dialog before canceling
                    _showCancelConfirmationDialog(context);
                  },
                  child: Text(
                    'Cancel Order',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeightManager.medium,
                      fontFamily: FontFamily.Montserrat,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressStep(String text, IconData icon, Color color, double screenWidth) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: screenWidth * 0.05,
        ),
        SizedBox(width: screenWidth * 0.03),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              fontWeight: FontWeightManager.medium,
              fontFamily: FontFamily.Montserrat,
              color: ColorManager.black,
            ),
          ),
        ),
      ],
    );
  }

  void _showCancelConfirmationDialog(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Cancel Order?',
            style: TextStyle(
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeightManager.bold,
              fontFamily: FontFamily.Montserrat,
            ),
          ),
          content: Text(
            'Are you sure you want to cancel this order? This action cannot be undone.',
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              fontFamily: FontFamily.Montserrat,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'No, Continue',
                style: TextStyle(
                  color: ColorManager.primary,
                  fontWeight: FontWeightManager.medium,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to order confirmation
              },
              child: Text(
                'Yes, Cancel',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeightManager.medium,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
} 
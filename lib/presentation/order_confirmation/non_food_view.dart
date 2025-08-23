import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../constants/color/colorConstant.dart';
import '../../constants/font/fontManager.dart';
import '../../widgets/order_item_card.dart';
import '../../models/payment_mode.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';
import 'order_processing_screen.dart';


class NonFoodOrderConfirmationView extends StatelessWidget {
  final String? orderId;

  const NonFoodOrderConfirmationView({
    Key? key,
    this.orderId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('NonFoodOrderConfirmationView: Building with orderId: $orderId');
    
    return BlocProvider(
      create: (context) {
        debugPrint('NonFoodOrderConfirmationView: Creating bloc and adding LoadOrderConfirmationData event');
        final bloc = OrderConfirmationBloc();
        bloc.add(LoadOrderConfirmationData(orderId: orderId, isNonFood: true));
        return bloc;
      },
      child: _NonFoodOrderConfirmationContent(),
    );
  }
}

class _NonFoodOrderConfirmationContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    debugPrint('_NonFoodOrderConfirmationContent: Building content');

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: ColorManager.black,
            size: screenWidth * 0.06,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Order Confirmation',
          style: TextStyle(
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeightManager.bold,
            fontFamily: FontFamily.Montserrat,
            color: ColorManager.black,
          ),
        ),
        centerTitle: false,
      ),
      body: BlocConsumer<OrderConfirmationBloc, OrderConfirmationState>(
        listener: (context, state) {
          debugPrint('_NonFoodOrderConfirmationContent: State changed to ${state.runtimeType}');
          
          if (state is OrderConfirmationProcessing) {
            debugPrint('_NonFoodOrderConfirmationContent: Order is being processed, navigating to processing screen');
            final orderBloc = context.read<OrderConfirmationBloc>();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => BlocProvider.value(
                  value: orderBloc,
                  child: const OrderProcessingScreen(),
                ),
              ),
            );
          } else if (state is OrderConfirmationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
            
            debugPrint('🚨🚨🚨 NON-FOOD ORDER CONFIRMATION: Navigating to chat for order: ${state.orderId} 🚨🚨🚨');
            print('🚨🚨🚨 NON-FOOD ORDER CONFIRMATION: Navigating to chat for order: ${state.orderId} 🚨🚨🚨');
            Navigator.of(context).pushReplacementNamed('/chat', arguments: {
              'orderId': state.orderId,
              'isNewlyPlacedOrder': true,
            });
          } else if (state is ChatRoomCreated) {
            debugPrint('🚨🚨🚨 NON-FOOD ORDER CONFIRMATION: Chat room created, navigating to chat... 🚨🚨🚨');
            print('🚨🚨🚨 NON-FOOD ORDER CONFIRMATION: Chat room created, navigating to chat... 🚨🚨🚨');
            debugPrint('🚨🚨🚨 NON-FOOD ORDER CONFIRMATION: Order ID being passed: ${state.orderId} 🚨🚨🚨');
            print('🚨🚨🚨 NON-FOOD ORDER CONFIRMATION: Order ID being passed: ${state.orderId} 🚨🚨🚨');
            
            Navigator.of(context).pushReplacementNamed('/chat', arguments: {
              'orderId': state.orderId,
              'roomId': state.roomId,
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
          }
        },
        builder: (context, state) {
          debugPrint('_NonFoodOrderConfirmationContent: Building with state: ${state.runtimeType}');
          
          if (state is OrderConfirmationLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (state is OrderConfirmationError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error',
                    style: TextStyle(
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeightManager.bold,
                      fontFamily: FontFamily.Montserrat,
                      color: ColorManager.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.message,
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      fontFamily: FontFamily.Montserrat,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.read<OrderConfirmationBloc>().add(LoadOrderConfirmationData(isNonFood: true));
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (state is OrderConfirmationLoaded || state is PaymentMethodsLoaded) {
            final orderSummary = state is OrderConfirmationLoaded 
                ? state.orderSummary 
                : (state as PaymentMethodsLoaded).orderSummary;
            final cartMetadata = state is OrderConfirmationLoaded 
                ? state.cartMetadata 
                : (state as PaymentMethodsLoaded).cartMetadata;
            final selectedPaymentMode = state is OrderConfirmationLoaded 
                ? state.selectedPaymentMode 
                : (state as PaymentMethodsLoaded).selectedPaymentMode;
            final paymentMethods = state is PaymentMethodsLoaded 
                ? state.methods 
                : <PaymentMethod>[];

            return SingleChildScrollView(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant Info
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cartMetadata['restaurant_name'] ?? 'Restaurant',
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeightManager.bold,
                            fontFamily: FontFamily.Montserrat,
                            color: ColorManager.black,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.01),
                        Text(
                          'Non-Food Items',
                          style: TextStyle(
                            fontSize: screenWidth * 0.035,
                            fontFamily: FontFamily.Montserrat,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: screenHeight * 0.02),
                  
                  // Order Items
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Items',
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeightManager.bold,
                            fontFamily: FontFamily.Montserrat,
                            color: ColorManager.black,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        ...orderSummary.items.map((item) => OrderItemCard(
                          imageUrl: item.imageUrl,
                          name: item.name,
                          quantity: item.quantity,
                          price: item.totalPrice,
                          itemId: item.id,
                          attributes: item.attributes,
                          onQuantityChanged: (itemId, quantity) {
                            context.read<OrderConfirmationBloc>().add(
                              UpdateOrderQuantity(
                                itemId: itemId,
                                newQuantity: quantity,
                              ),
                            );
                          },
                        )),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: screenHeight * 0.02),
                  
                  // Order Summary (without delivery fees)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(screenWidth * 0.04),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Summary',
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeightManager.bold,
                            fontFamily: FontFamily.Montserrat,
                            color: ColorManager.black,
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Subtotal',
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                fontFamily: FontFamily.Montserrat,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              '₹${orderSummary.subtotal.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                fontFamily: FontFamily.Montserrat,
                                color: ColorManager.black,
                              ),
                            ),
                          ],
                        ),
                        if (orderSummary.taxAmount > 0) ...[
                          SizedBox(height: screenHeight * 0.01),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Tax',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.035,
                                  fontFamily: FontFamily.Montserrat,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '₹${orderSummary.taxAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.035,
                                  fontFamily: FontFamily.Montserrat,
                                  color: ColorManager.black,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (orderSummary.discountAmount > 0) ...[
                          SizedBox(height: screenHeight * 0.01),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Discount',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.035,
                                  fontFamily: FontFamily.Montserrat,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '-₹${orderSummary.discountAmount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.035,
                                  fontFamily: FontFamily.Montserrat,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                        Divider(height: screenHeight * 0.03),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeightManager.bold,
                                fontFamily: FontFamily.Montserrat,
                                color: ColorManager.black,
                              ),
                            ),
                            Text(
                              '₹${orderSummary.subtotal.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeightManager.bold,
                                fontFamily: FontFamily.Montserrat,
                                color: ColorManager.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: screenHeight * 0.04),
                  
                  // Place Order Button (same as food items)
                  SizedBox(
                    width: double.infinity,
                    height: screenHeight * 0.06,
                    child: ElevatedButton(
                      onPressed: () {
                        debugPrint('NonFoodOrderConfirmationView: Place order button pressed');
                        _showPaymentModeDialog(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorManager.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Place Order',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeightManager.bold,
                          fontFamily: FontFamily.Montserrat,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: screenHeight * 0.02),
                ],
              ),
            );
          }
          
          return const Center(
            child: Text('Unknown state'),
          );
        },
      ),
    );
  }

  void _showPaymentModeDialog(BuildContext context) {
    debugPrint('NonFoodPaymentDialog: Opening payment mode dialog');
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final orderBloc = context.read<OrderConfirmationBloc>();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: BlocProvider.value(
            value: orderBloc,
            child: BlocBuilder<OrderConfirmationBloc, OrderConfirmationState>(
              builder: (context, state) {
                debugPrint('NonFoodPaymentDialog: Current state: ${state.runtimeType}');
                
                // Trigger API call to load payment methods if not already loaded
                if (state is! PaymentMethodsLoaded) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      debugPrint('NonFoodPaymentDialog: Triggering LoadPaymentMethods');
                      context.read<OrderConfirmationBloc>().add(LoadPaymentMethods());
                    }
                  });
                }

                return Container(
                  padding: EdgeInsets.all(screenWidth * 0.06),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Select Payment Mode',
                        style: TextStyle(
                          fontSize: screenWidth * 0.05,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.03),

                      // Show loading state while fetching payment methods
                      if (state is OrderConfirmationError)
                        Column(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: screenWidth * 0.1,
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Text(
                              'Failed to load payment methods',
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.01),
                            Text(
                              'Please try again',
                              style: TextStyle(
                                fontSize: screenWidth * 0.035,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            ElevatedButton(
                              onPressed: () {
                                context.read<OrderConfirmationBloc>().add(LoadPaymentMethods());
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        )
                      else if (state is! PaymentMethodsLoaded)
                        Column(
                          children: [
                            const CircularProgressIndicator(),
                            SizedBox(height: screenHeight * 0.02),
                            Text(
                              'Loading payment methods...',
                              style: TextStyle(
                                fontSize: screenWidth * 0.04,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        )
                      else
                        // Show payment methods from API
                        ...state.methods.map((method) {
                          final icon = _getPaymentIcon(method.id);
                          final color = _getPaymentColor(method.id);
                          return Column(
                            children: [
                              _buildPaymentOption(
                                context: dialogContext,
                                orderBloc: orderBloc,
                                icon: icon,
                                title: method.displayName,
                                subtitle: method.description,
                                color: color,
                                screenWidth: screenWidth,
                                screenHeight: screenHeight,
                                paymentId: method.id,
                              ),
                              SizedBox(height: screenHeight * 0.015),
                            ],
                          );
                        }).toList(),

                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  IconData _getPaymentIcon(String id) {
    switch (id) {
      case 'cash':
        return Icons.money;
      case 'card':
        return Icons.credit_card;
      case 'upi':
        return Icons.account_balance_wallet;
      default:
        return Icons.payment;
    }
  }

  Color _getPaymentColor(String id) {
    switch (id) {
      case 'cash':
        return const Color(0xFF4CAF50);
      case 'card':
        return const Color(0xFF9C27B0);
      case 'upi':
        return const Color(0xFF2196F3);
      default:
        return Colors.orange;
    }
  }

  Widget _buildPaymentOption({
    required BuildContext context,
    required OrderConfirmationBloc orderBloc,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required double screenWidth,
    required double screenHeight,
    required String paymentId,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            debugPrint('NonFoodPaymentDialog: Selected payment method: $paymentId');
            Navigator.of(context).pop();
            orderBloc.add(PlaceOrder(paymentMode: paymentId));
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Row(
              children: [
                Container(
                  width: screenWidth * 0.12,
                  height: screenWidth * 0.12,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: screenWidth * 0.06,
                  ),
                ),
                SizedBox(width: screenWidth * 0.04),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeight.bold,
                          color: ColorManager.black,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: screenWidth * 0.04,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../constants/color/colorConstant.dart';
import '../../constants/font/fontManager.dart';
import '../../widgets/order_item_card.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';

class OrderConfirmationView extends StatelessWidget {
  final String? orderId;

  const OrderConfirmationView({
    Key? key,
    this.orderId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('OrderConfirmationView: Building with orderId: $orderId');
    
    return BlocProvider(
      create: (context) {
        debugPrint('OrderConfirmationView: Creating bloc and adding LoadOrderConfirmationData event');
        final bloc = OrderConfirmationBloc();
        bloc.add(LoadOrderConfirmationData(orderId: orderId));
        return bloc;
      },
      child: _OrderConfirmationContent(),
    );
  }
}

class _OrderConfirmationContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    debugPrint('_OrderConfirmationContent: Building content');

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
          debugPrint('_OrderConfirmationContent: State changed to ${state.runtimeType}');
          
          if (state is OrderConfirmationProcessing) {
            debugPrint('_OrderConfirmationContent: Order is being processed, showing loading dialog');
            _showProcessingDialog(context);
          } else if (state is OrderConfirmationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
            
            debugPrint('🚨🚨🚨 ORDER CONFIRMATION: Navigating to chat for order: ${state.orderId} 🚨🚨🚨');
            print('🚨🚨🚨 ORDER CONFIRMATION: Navigating to chat for order: ${state.orderId} 🚨🚨🚨');
            Navigator.of(context).pushReplacementNamed('/chat', arguments: state.orderId);
          } else if (state is ChatRoomCreated) {
            debugPrint('🚨🚨🚨 ORDER CONFIRMATION: Chat room created, navigating to chat... 🚨🚨🚨');
            print('🚨🚨🚨 ORDER CONFIRMATION: Chat room created, navigating to chat... 🚨🚨🚨');
            debugPrint('🚨🚨🚨 ORDER CONFIRMATION: Order ID being passed: ${state.orderId} 🚨🚨🚨');
            print('🚨🚨🚨 ORDER CONFIRMATION: Order ID being passed: ${state.orderId} 🚨🚨🚨');
            Navigator.of(context).pushReplacementNamed('/chat', arguments: state.orderId);
          } else if (state is OrderConfirmationError) {
            // Dismiss processing dialog if it's showing
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          } else if (state is OrderConfirmationSuccess || state is ChatRoomCreated) {
            // Dismiss processing dialog if it's showing
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          }
        },
        builder: (context, state) {
          debugPrint('_OrderConfirmationContent: Building for state: ${state.runtimeType}');
          
          if (state is OrderConfirmationLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          if (state is OrderConfirmationError) {
            return _buildErrorView(context, state.message, screenWidth, screenHeight);
          }
          
          if (state is OrderConfirmationLoaded) {
            debugPrint('_OrderConfirmationContent: Showing loaded view with ${state.orderSummary.items.length} items');
            return _buildLoadedView(context, state, screenWidth, screenHeight);
          }
          
          if (state is PaymentMethodsLoaded) {
            debugPrint('_OrderConfirmationContent: Payment methods loaded, but should not show this state in main view');
            // This state should only be shown in the payment dialog, not in the main view
            // If we reach here, it means the payment dialog was closed without selection
            // So we should show the normal loaded view
            final orderState = OrderConfirmationLoaded(
              orderSummary: state.orderSummary,
              cartMetadata: state.cartMetadata,
              selectedPaymentMode: state.selectedPaymentMode,
            );
            return _buildLoadedView(context, orderState, screenWidth, screenHeight);
          }
          
          if (state is OrderConfirmationProcessing) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Processing your order...'),
                ],
              ),
            );
          }
          
          return const Center(
            child: Text('Something went wrong'),
          );
        },
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message, double screenWidth, double screenHeight) {
    // Check if the error is related to delivery address
    final isDeliveryAddressError = message.toLowerCase().contains('delivery address') || 
                                   message.toLowerCase().contains('address is required');
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.06),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isDeliveryAddressError ? Icons.location_on : Icons.error_outline,
              size: screenWidth * 0.2,
              color: isDeliveryAddressError ? ColorManager.primary : Colors.red,
            ),
            SizedBox(height: screenHeight * 0.03),
            Text(
              isDeliveryAddressError ? 'Delivery Address Required' : 'Error',
              style: TextStyle(
                fontSize: screenWidth * 0.06,
                fontWeight: FontWeightManager.bold,
                fontFamily: FontFamily.Montserrat,
                color: ColorManager.black,
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeightManager.regular,
                fontFamily: FontFamily.Montserrat,
                color: Colors.grey[600],
              ),
            ),
            if (isDeliveryAddressError) ...[
              SizedBox(height: screenHeight * 0.02),
              Text(
                'You can add your delivery address and return here to complete your order.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeightManager.regular,
                  fontFamily: FontFamily.Montserrat,
                  color: Colors.grey[500],
                ),
              ),
            ],
            SizedBox(height: screenHeight * 0.04),
            if (isDeliveryAddressError) ...[
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushNamed('/address', arguments: true).then((_) {
                    // Reload order confirmation data after returning from address page
                    context.read<OrderConfirmationBloc>().add(LoadOrderConfirmationData());
                  });
                },
                icon: const Icon(Icons.add_location),
                label: const Text('Add Delivery Address'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
            ],
            ElevatedButton(
              onPressed: () {
                context.read<OrderConfirmationBloc>().add(LoadOrderConfirmationData());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDeliveryAddressError ? Colors.grey[300] : ColorManager.primary,
                foregroundColor: isDeliveryAddressError ? Colors.grey[600] : Colors.white,
              ),
              child: Text(isDeliveryAddressError ? 'Try Again' : 'Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedView(
    BuildContext context,
    OrderConfirmationLoaded state,
    double screenWidth,
    double screenHeight,
  ) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRestaurantInfo(state, screenWidth, screenHeight),
          SizedBox(height: screenHeight * 0.02),
          _buildOrderItems(context, state, screenWidth, screenHeight),
          SizedBox(height: screenHeight * 0.02),
          _buildOrderSummary(state, screenWidth, screenHeight),
          SizedBox(height: screenHeight * 0.04),
          _buildPlaceOrderButton(context, state, screenWidth, screenHeight),
        ],
      ),
    );
  }

  Widget _buildRestaurantInfo(
    OrderConfirmationLoaded state,
    double screenWidth,
    double screenHeight,
  ) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: screenWidth * 0.15,
            height: screenWidth * 0.15,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[100],
            ),
            child: Icon(
              Icons.restaurant,
              color: Colors.grey[400],
              size: screenWidth * 0.08,
            ),
          ),
          SizedBox(width: screenWidth * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.cartMetadata['restaurant_name'] ?? 'Restaurant',
                  style: TextStyle(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeightManager.bold,
                    fontFamily: FontFamily.Montserrat,
                    color: ColorManager.black,
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
                Text(
                  'Partner ID: ${state.cartMetadata['partner_id'] ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeightManager.regular,
                    fontFamily: FontFamily.Montserrat,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItems(
    BuildContext context,
    OrderConfirmationLoaded state,
    double screenWidth,
    double screenHeight,
  ) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 0,
            blurRadius: 8,
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
          ...state.orderSummary.items.map((item) {
            debugPrint('OrderConfirmationView: Rendering item ${state.orderSummary.items.indexOf(item)}: ${item.name}, Price: ₹${item.price}, Qty: ${item.quantity}, Total: ₹${item.totalPrice}');
            return OrderItemCard(
              imageUrl: item.imageUrl,
              name: item.name,
              quantity: item.quantity,
              price: item.totalPrice,
              itemId: item.id,
              attributes: item.attributes,
              onQuantityChanged: (itemId, newQuantity) {
                context.read<OrderConfirmationBloc>().add(
                  UpdateOrderQuantity(itemId: itemId, newQuantity: newQuantity),
                );
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildOrderSummary(
    OrderConfirmationLoaded state,
    double screenWidth,
    double screenHeight,
  ) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 0,
            blurRadius: 8,
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
          _buildSummaryRow('Subtotal', '₹${state.orderSummary.subtotal.toStringAsFixed(2)}', screenWidth),
          if (state.orderSummary.taxAmount > 0)
            _buildSummaryRow('Tax', '₹${state.orderSummary.taxAmount.toStringAsFixed(2)}', screenWidth),
          if (state.orderSummary.discountAmount > 0)
            _buildSummaryRow('Discount', '-₹${state.orderSummary.discountAmount.toStringAsFixed(2)}', screenWidth),
          Divider(height: screenHeight * 0.02),
          _buildSummaryRow(
            'Total',
            '₹${state.orderSummary.total.toStringAsFixed(2)}',
            screenWidth,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
    double screenWidth, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              fontWeight: isTotal ? FontWeightManager.bold : FontWeightManager.regular,
              fontFamily: FontFamily.Montserrat,
              color: isTotal ? ColorManager.black : Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              fontWeight: isTotal ? FontWeightManager.bold : FontWeightManager.medium,
              fontFamily: FontFamily.Montserrat,
              color: isTotal ? ColorManager.black : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceOrderButton(
    BuildContext context,
    OrderConfirmationLoaded state,
    double screenWidth,
    double screenHeight,
  ) {
    return Container(
      width: double.infinity,
      height: screenHeight * 0.06,
      child: ElevatedButton(
        onPressed: () {
          debugPrint('OrderConfirmationView: Place order button pressed');
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
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeightManager.bold,
            fontFamily: FontFamily.Montserrat,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _showPaymentModeDialog(BuildContext context) {
    debugPrint('PaymentDialog: Opening payment mode dialog');
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final orderBloc = context.read<OrderConfirmationBloc>();
    
    // Auto-place order timer (8 seconds)
    Timer? autoPlaceTimer;
    autoPlaceTimer = Timer(const Duration(seconds: 8), () {
      if (context.mounted) {
        debugPrint('PaymentDialog: Auto-place order timeout reached, using default payment method');
        Navigator.of(context).pop();
        orderBloc.add(const PlaceOrder(paymentMode: 'cash'));
      }
    });

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
                debugPrint('PaymentDialog: Current state: ${state.runtimeType}');
                

                
                // Always trigger LoadPaymentMethods when dialog opens, unless already loaded
                if (state is! PaymentMethodsLoaded) {
                  debugPrint('PaymentDialog: Triggering LoadPaymentMethods');
                  context.read<OrderConfirmationBloc>().add(LoadPaymentMethods());
                  return const Center(child: CircularProgressIndicator());
                }

                // At this point, state is guaranteed to be PaymentMethodsLoaded
                final paymentState = state as PaymentMethodsLoaded;
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

                      ...paymentState.methods.map((method) {
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
                              autoPlaceTimer: autoPlaceTimer,
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
    Timer? autoPlaceTimer,
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
            debugPrint('PaymentDialog: Selected payment method: $paymentId');
            autoPlaceTimer?.cancel();
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

  void _showProcessingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  'Processing your order...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: ColorManager.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait while we place your order',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../widgets/custom_button_large.dart';
import '../../constants/color/colorConstant.dart';
import '../../constants/font/fontManager.dart';
import '../../widgets/order_item_card.dart';
import '../../utils/currency_utils.dart';
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
          
          if (state is OrderConfirmationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
            
            debugPrint('OrderConfirmationView: Navigating to chat for order: ${state.orderId}');
            Navigator.of(context).pushReplacementNamed('/chat', arguments: state.orderId);
          } else if (state is ChatRoomCreated) {
            debugPrint('OrderConfirmationView: Chat room created, navigating to chat...');
            Navigator.of(context).pushReplacementNamed('/chat', arguments: state.orderId);
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
          debugPrint('_OrderConfirmationContent: Building for state: ${state.runtimeType}');
          
          if (state is OrderConfirmationLoading) {
            debugPrint('_OrderConfirmationContent: Showing loading view');
            return _buildLoadingView(screenWidth, screenHeight);
          } else if (state is OrderConfirmationLoaded) {
            debugPrint('_OrderConfirmationContent: Showing loaded view with ${state.orderSummary.items.length} items');
            return _buildLoadedView(context, state, screenWidth, screenHeight);
          } else if (state is OrderConfirmationProcessing) {
            debugPrint('_OrderConfirmationContent: Showing processing view');
            return _buildProcessingView(screenWidth, screenHeight);
          } else if (state is OrderConfirmationError) {
            debugPrint('_OrderConfirmationContent: Showing error view: ${state.message}');
            return _buildErrorView(context, state, screenWidth, screenHeight);
          } else {
            debugPrint('_OrderConfirmationContent: Unknown state: ${state.runtimeType}, showing loading');
            return _buildLoadingView(screenWidth, screenHeight);
          }
        },
      ),
    );
  }

  Widget _buildLoadingView(double screenWidth, double screenHeight) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ColorManager.black),
          ),
          SizedBox(height: screenHeight * 0.02),
          Text(
            'Loading order details...',
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeightManager.regular,
              fontFamily: FontFamily.Montserrat,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingView(double screenWidth, double screenHeight) {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          padding: EdgeInsets.all(screenWidth * 0.08),
          margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.1),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(ColorManager.black),
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                'Processing your order...',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeightManager.medium,
                  fontFamily: FontFamily.Montserrat,
                  color: ColorManager.black,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorView(
    BuildContext context,
    OrderConfirmationError state,
    double screenWidth,
    double screenHeight,
  ) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.08),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: screenWidth * 0.2,
              color: Colors.red,
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              state.message,
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeightManager.regular,
                fontFamily: FontFamily.Montserrat,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenHeight * 0.03),
            CustomLargeButton(
              text: 'Retry',
              onPressed: () {
                context.read<OrderConfirmationBloc>().add(
                  const LoadOrderConfirmationData(),
                );
              },
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
    return Column(
      children: [
        // Selected Items Section
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Title
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    screenWidth * 0.06, 
                    screenWidth * 0.04, 
                    screenWidth * 0.06, 
                    screenWidth * 0.03
                  ),
                  child: Text(
                    'Selected Items',
                    style: TextStyle(
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeightManager.bold,
                      fontFamily: FontFamily.Montserrat,
                      color: ColorManager.black,
                    ),
                  ),
                ),

                // Items List
                ...state.orderSummary.items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  
                  debugPrint('OrderConfirmationView: Rendering item $index: ${item.name}, Price: ₹${item.price}, Qty: ${item.quantity}, Total: ₹${item.totalPrice}');
                  
                  return OrderItemCard(
                    imageUrl: item.imageUrl,
                    name: item.name,
                    quantity: item.quantity,
                    price: item.totalPrice,
                    itemId: item.id,
                    attributes: item.attributes,
                    onQuantityChanged: (itemId, newQuantity) {
                      debugPrint('OrderConfirmationView: Quantity changed for item $itemId to $newQuantity');
                      context.read<OrderConfirmationBloc>().add(
                        UpdateOrderQuantity(
                          itemId: itemId,
                          newQuantity: newQuantity,
                        ),
                      );
                    },
                  );
                }).toList(),

                SizedBox(height: screenHeight * 0.02),

                // Order Summary
                _buildOrderSummary(state, screenWidth, screenHeight),

                SizedBox(height: screenHeight * 0.015),
              ],
            ),
          ),
        ),

        // Bottom Button
        _buildBottomButton(context, state, screenWidth, screenHeight),
      ],
    );
  }

  Widget _buildOrderSummary(
    OrderConfirmationLoaded state,
    double screenWidth,
    double screenHeight,
  ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05,
        vertical: screenHeight * 0.02,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Subtotal
          FutureBuilder<String>(
            future: CurrencyUtils.getCurrencySymbolFromUserLocation(),
            builder: (context, snapshot) {
              final currencySymbol = snapshot.data ?? '₹';
              return _buildSummaryRow(
                'Subtotal',
                CurrencyUtils.formatPrice(state.orderSummary.subtotal, currencySymbol),
                screenWidth,
                isTotal: false,
              );
            },
          ),
          
          SizedBox(height: screenHeight * 0.01),
          
          // (Delivery Fee row removed)
          SizedBox(height: screenHeight * 0.015),
          
          // Divider
          Divider(
            color: Colors.grey[200],
            thickness: 1,
            height: 1,
          ),
          
          SizedBox(height: screenHeight * 0.015),
          
          // Total
          FutureBuilder<String>(
            future: CurrencyUtils.getCurrencySymbolFromUserLocation(),
            builder: (context, snapshot) {
              final currencySymbol = snapshot.data ?? '₹';
              return _buildSummaryRow(
                'Total',
                CurrencyUtils.formatPrice(state.orderSummary.total, currencySymbol),
                screenWidth,
                isTotal: true,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String amount,
    double screenWidth, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? screenWidth * 0.04 : screenWidth * 0.035,
              fontWeight: isTotal ? FontWeightManager.bold : FontWeightManager.regular,
              fontFamily: FontFamily.Montserrat,
              color: isTotal ? ColorManager.black : Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            amount,
            style: TextStyle(
              fontSize: isTotal ? screenWidth * 0.042 : screenWidth * 0.035,
              fontWeight: isTotal ? FontWeightManager.bold : FontWeightManager.semiBold,
              fontFamily: FontFamily.Montserrat,
              color: isTotal ? const Color(0xFFD2691E) : ColorManager.black,
            ),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButton(
    BuildContext context,
    OrderConfirmationLoaded state,
    double screenWidth,
    double screenHeight,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        screenWidth * 0.06,
        screenHeight * 0.015,
        screenWidth * 0.06,
        screenHeight * 0.015,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 0,
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: screenHeight * 0.065,
          child: ElevatedButton(
            onPressed: () => _showPaymentModeDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD2691E),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Place Order  →',
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeightManager.semiBold,
                fontFamily: FontFamily.Montserrat,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showPaymentModeDialog(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Store reference to the bloc before showing dialog
    final orderBloc = context.read<OrderConfirmationBloc>();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(screenWidth * 0.06),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  'Select Payment Mode',
                  style: TextStyle(
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeightManager.bold,
                    fontFamily: FontFamily.Montserrat,
                    color: ColorManager.black,
                  ),
                ),
                
                SizedBox(height: screenHeight * 0.03),
                
                // Payment Options
                _buildPaymentOption(
                  context: dialogContext,
                  orderBloc: orderBloc,
                  icon: Icons.money,
                  title: 'Cash on Delivery',
                  subtitle: 'Pay when your order arrives',
                  color: const Color(0xFF4CAF50),
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                ),
                
                SizedBox(height: screenHeight * 0.015),
                
                // UPI Payment option removed
                // _buildPaymentOption(
                //   context: dialogContext,
                //   orderBloc: orderBloc,
                //   icon: Icons.account_balance_wallet,
                //   title: 'UPI Payment',
                //   subtitle: 'Pay using UPI apps',
                //   color: const Color(0xFF2196F3),
                //   screenWidth: screenWidth,
                //   screenHeight: screenHeight,
                // ),
                // 
                // SizedBox(height: screenHeight * 0.015),
                
                _buildPaymentOption(
                  context: dialogContext,
                  orderBloc: orderBloc,
                  icon: Icons.credit_card,
                  title: 'Card Payment',
                  subtitle: 'Pay using debit/credit card',
                  color: const Color(0xFF9C27B0),
                  screenWidth: screenWidth,
                  screenHeight: screenHeight,
                ),
                
                SizedBox(height: screenHeight * 0.02),
                
                // Cancel Button
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeightManager.medium,
                      fontFamily: FontFamily.Montserrat,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(context).pop(); // Close dialog
            debugPrint('Payment mode selected: $title');
            
            // Map payment option titles to API values
            String paymentMode;
            switch (title) {
              case 'Cash on Delivery':
                paymentMode = 'cash';
                break;
              case 'UPI Payment':
                paymentMode = 'upi';
                break;
              case 'Card Payment':
                paymentMode = 'card';
                break;
              default:
                paymentMode = 'cash';
            }
            
            // Select payment mode and proceed to chat
            orderBloc.add(SelectPaymentMode(paymentMode: paymentMode));
            orderBloc.add(const ProceedToChat());
          },
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.04,
              vertical: screenHeight * 0.02,
            ),
            child: Row(
              children: [
                // Icon Container
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.025),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: screenWidth * 0.06,
                  ),
                ),
                
                SizedBox(width: screenWidth * 0.04),
                
                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeightManager.semiBold,
                          fontFamily: FontFamily.Montserrat,
                          color: ColorManager.black,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.003),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          fontWeight: FontWeightManager.regular,
                          fontFamily: FontFamily.Montserrat,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Arrow Icon
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
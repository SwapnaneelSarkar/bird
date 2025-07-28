// lib/presentation/order_details/view.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/custom_button_large.dart';
import '../../widgets/review_rating_widget.dart';
import '../../constants/color/colorConstant.dart';
import '../../constants/font/fontManager.dart';
import '../../models/order_details_model.dart';
import '../../models/menu_model.dart';
import '../../service/currency_service.dart';
import '../../utils/currency_utils.dart';
import '../../utils/timezone_utils.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';

class OrderDetailsView extends StatelessWidget {
  final String orderId;

  const OrderDetailsView({
    Key? key,
    required this.orderId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('OrderDetailsView: Building with orderId: $orderId');
    
    return BlocProvider(
      create: (context) {
        debugPrint('OrderDetailsView: Creating bloc and loading order details');
        final bloc = OrderDetailsBloc();
        bloc.add(LoadOrderDetails(orderId));
        return bloc;
      },
      child: _OrderDetailsContent(orderId: orderId),
    );
  }
}

class _OrderDetailsContent extends StatelessWidget {
  final String orderId;

  const _OrderDetailsContent({required this.orderId});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
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
          onPressed: () => Navigator.of(context).pop(true),
        ),
        title: Text(
          'Order Details',
          style: TextStyle(
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeightManager.bold,
            fontFamily: FontFamily.Montserrat,
            color: ColorManager.black,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: ColorManager.black,
              size: screenWidth * 0.06,
            ),
            onPressed: () {
              context.read<OrderDetailsBloc>().add(RefreshOrderDetails(orderId));
            },
          ),
        ],
      ),
      body: BlocConsumer<OrderDetailsBloc, OrderDetailsState>(
        listener: (context, state) {
          if (state is OrderCancelled) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          } else if (state is OrderDetailsError) {
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
          if (state is OrderDetailsLoading) {
            return _buildLoadingView(screenWidth, screenHeight);
          } else if (state is OrderDetailsLoaded) {
            return _buildLoadedView(context, state.orderDetails, state.menuItems, screenWidth, screenHeight);
          } else if (state is OrderCancelling) {
            return _buildCancellingView(screenWidth, screenHeight);
          } else if (state is OrderDetailsError) {
            return _buildErrorView(context, state.message, screenWidth, screenHeight);
          }
          
          return _buildLoadingView(screenWidth, screenHeight);
        },
      ),
    );
  }

  Widget _buildLoadingView(double screenWidth, double screenHeight) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: screenWidth * 0.12,
            height: screenWidth * 0.12,
            child: CircularProgressIndicator(
              color: ColorManager.black,
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          Text(
            'Loading order details...',
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              fontFamily: FontFamily.Montserrat,
              color: ColorManager.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancellingView(double screenWidth, double screenHeight) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: screenWidth * 0.12,
            height: screenWidth * 0.12,
            child: CircularProgressIndicator(
              color: Colors.orange,
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: screenHeight * 0.02),
          Text(
            'Cancelling order...',
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              fontFamily: FontFamily.Montserrat,
              color: ColorManager.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message, double screenWidth, double screenHeight) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.06),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: screenWidth * 0.15,
              color: Colors.red,
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              'Error',
              style: TextStyle(
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeightManager.bold,
                fontFamily: FontFamily.Montserrat,
                color: ColorManager.black,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                fontFamily: FontFamily.Montserrat,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            CustomLargeButton(
              text: 'Retry',
              onPressed: () {
                context.read<OrderDetailsBloc>().add(LoadOrderDetails(orderId));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedView(BuildContext context, OrderDetails orderDetails, Map<String, MenuItem> menuItems, double screenWidth, double screenHeight) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<OrderDetailsBloc>().add(RefreshOrderDetails(orderId));
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Status Card
            _buildOrderStatusCard(context, orderDetails, screenWidth, screenHeight),
            
            SizedBox(height: screenHeight * 0.02),
            
            // Order Summary Card
            _buildOrderSummaryCard(orderDetails, screenWidth, screenHeight),
            
            SizedBox(height: screenHeight * 0.02),
            
            // Items List Card
            _buildOrderItemsCard(orderDetails, menuItems, screenWidth, screenHeight),
            
            SizedBox(height: screenHeight * 0.02),
            
            // Delivery Information Card
            if (orderDetails.deliveryAddress != null)
              _buildDeliveryInfoCard(orderDetails, screenWidth, screenHeight),
            
            SizedBox(height: screenHeight * 0.02),
            
            // Review & Rating Section
            ReviewRatingWidget(
              orderId: orderDetails.orderId,
              partnerId: orderDetails.partnerId ?? '',
              canReview: orderDetails.orderStatus.toLowerCase() == 'delivered',
            ),
                        
            SizedBox(height: screenHeight * 0.02),
            
            // Track Order Button - Only show for ongoing orders
            if (orderDetails.orderStatus.toLowerCase() != 'delivered' && 
                orderDetails.orderStatus.toLowerCase() != 'cancelled' &&
                orderDetails.orderStatus.toLowerCase() != 'canceled')
              _buildTrackOrderButton(context, orderDetails, screenWidth, screenHeight),
            
            SizedBox(height: screenHeight * 0.02),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatusCard(BuildContext context, OrderDetails orderDetails, double screenWidth, double screenHeight) {
    Color statusColor;
    IconData statusIcon;
    
    switch (orderDetails.orderStatus.toLowerCase()) {
      case 'pending':
        statusColor = ColorManager.primary;
        statusIcon = Icons.schedule;
        break;
      case 'confirmed':
        statusColor = ColorManager.primary;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'preparing':
        statusColor = ColorManager.primary;
        statusIcon = Icons.restaurant;
        break;
      case 'ready_for_delivery':
        statusColor = ColorManager.primary;
        statusIcon = Icons.check_circle;
        break;
      case 'ready':
        statusColor = ColorManager.primary;
        statusIcon = Icons.check_circle;
        break;
      case 'on_the_way':
        statusColor = ColorManager.primary;
        statusIcon = Icons.delivery_dining;
        break;
      case 'out_for_delivery':
        statusColor = ColorManager.primary;
        statusIcon = Icons.delivery_dining;
        break;
      case 'delivered':
        statusColor = ColorManager.primary;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'canceled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = ColorManager.primary;
        statusIcon = Icons.info;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                statusIcon,
                color: statusColor,
                size: screenWidth * 0.06,
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Status',
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        fontFamily: FontFamily.Montserrat,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      orderDetails.statusDisplayText,
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeightManager.bold,
                        fontFamily: FontFamily.Montserrat,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.015),
          Divider(color: Colors.grey[200]),
          SizedBox(height: screenHeight * 0.015),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order ID',
                    style: TextStyle(
                      fontSize: screenWidth * 0.03,
                      fontFamily: FontFamily.Montserrat,
                      color: Colors.grey[600],
                    ),
                  ),
                  GestureDetector(
                    onLongPress: () async {
                      await Clipboard.setData(ClipboardData(text: orderDetails.orderId));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Order ID copied to clipboard'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: Text(
                      orderDetails.orderId,
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeightManager.medium,
                        fontFamily: FontFamily.Montserrat,
                        color: ColorManager.black,
                      ),
                    ),
                  ),
                ],
              ),
              if (orderDetails.createdAt != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Order Date',
                      style: TextStyle(
                        fontSize: screenWidth * 0.03,
                        fontFamily: FontFamily.Montserrat,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      TimezoneUtils.formatDateOnly(orderDetails.createdAt!),
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeightManager.medium,
                        fontFamily: FontFamily.Montserrat,
                        color: ColorManager.black,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          // Add payment mode information if available
          if (orderDetails.paymentMode != null && orderDetails.paymentMode!.isNotEmpty) ...[
            SizedBox(height: screenHeight * 0.015),
            Divider(color: Colors.grey[200]),
            SizedBox(height: screenHeight * 0.015),
            Row(
              children: [
                Icon(
                  Icons.payment,
                  size: screenWidth * 0.045,
                  color: Colors.grey[600],
                ),
                SizedBox(width: screenWidth * 0.02),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Method',
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          fontFamily: FontFamily.Montserrat,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        _getPaymentModeDisplayText(orderDetails.paymentMode!),
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeightManager.medium,
                          fontFamily: FontFamily.Montserrat,
                          color: ColorManager.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard(OrderDetails orderDetails, double screenWidth, double screenHeight) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
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
          SizedBox(height: screenHeight * 0.015),
          if (orderDetails.restaurantName != null) ...[
            Row(
              children: [
                Icon(
                  Icons.restaurant,
                  size: screenWidth * 0.045,
                  color: Colors.grey[600],
                ),
                SizedBox(width: screenWidth * 0.02),
                Expanded(
                  child: Text(
                    orderDetails.restaurantName!,
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeightManager.medium,
                      fontFamily: FontFamily.Montserrat,
                      color: ColorManager.black,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.015),
          ],
          Divider(color: Colors.grey[200]),
          SizedBox(height: screenHeight * 0.015),
          FutureBuilder<String>(
            future: CurrencyUtils.getCurrencySymbolFromUserLocation(),
            builder: (context, snapshot) {
              final currencySymbol = snapshot.data ?? '₹';
              return _buildSummaryRow('Subtotal', CurrencyUtils.formatPrice(orderDetails.subtotal, currencySymbol), screenWidth, false);
            },
          ),
          SizedBox(height: screenHeight * 0.01),
          FutureBuilder<String>(
            future: CurrencyUtils.getCurrencySymbolFromUserLocation(),
            builder: (context, snapshot) {
              final currencySymbol = snapshot.data ?? '₹';
              return _buildSummaryRow('Delivery Fee', CurrencyUtils.formatPrice(orderDetails.deliveryFees, currencySymbol), screenWidth, false);
            },
          ),
          SizedBox(height: screenHeight * 0.015),
          Divider(color: Colors.grey[200]),
          SizedBox(height: screenHeight * 0.015),
          FutureBuilder<String>(
            future: CurrencyUtils.getCurrencySymbolFromUserLocation(),
            builder: (context, snapshot) {
              final currencySymbol = snapshot.data ?? '₹';
              return _buildSummaryRow('Total Amount', CurrencyUtils.formatPrice(orderDetails.grandTotal, currencySymbol), screenWidth, true);
            },
          ),
          
          // Add payment mode display
          if (orderDetails.paymentMode != null && orderDetails.paymentMode!.isNotEmpty) ...[
            SizedBox(height: screenHeight * 0.015),
            Divider(color: Colors.grey[200]),
            SizedBox(height: screenHeight * 0.015),
            _buildPaymentModeRow(orderDetails.paymentMode!, screenWidth),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, double screenWidth, bool isTotal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: screenWidth * (isTotal ? 0.042 : 0.038),
            fontWeight: isTotal ? FontWeightManager.bold : FontWeightManager.medium,
            fontFamily: FontFamily.Montserrat,
            color: ColorManager.black,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: screenWidth * (isTotal ? 0.042 : 0.038),
            fontWeight: isTotal ? FontWeightManager.bold : FontWeightManager.medium,
            fontFamily: FontFamily.Montserrat,
            color: isTotal ? ColorManager.black : Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentModeRow(String paymentMode, double screenWidth) {
    // Map payment mode to display text and icon
    String displayText;
    IconData icon;
    Color iconColor;
    
    switch (paymentMode.toLowerCase()) {
      case 'cash':
        displayText = 'Cash on Delivery';
        icon = Icons.money;
        iconColor = const Color(0xFF4CAF50);
        break;
      case 'upi':
        displayText = 'UPI Payment';
        icon = Icons.account_balance_wallet;
        iconColor = const Color(0xFF2196F3);
        break;
      case 'card':
        displayText = 'Card Payment';
        icon = Icons.credit_card;
        iconColor = const Color(0xFF9C27B0);
        break;
      default:
        displayText = paymentMode;
        icon = Icons.payment;
        iconColor = Colors.grey[600]!;
    }
    
    return Row(
      children: [
        Icon(
          icon,
          size: screenWidth * 0.045,
          color: iconColor,
        ),
        SizedBox(width: screenWidth * 0.02),
        Expanded(
          child: Text(
            'Payment Method',
            style: TextStyle(
              fontSize: screenWidth * 0.038,
              fontWeight: FontWeightManager.medium,
              fontFamily: FontFamily.Montserrat,
              color: ColorManager.black,
            ),
          ),
        ),
        Text(
          displayText,
          style: TextStyle(
            fontSize: screenWidth * 0.038,
            fontWeight: FontWeightManager.medium,
            fontFamily: FontFamily.Montserrat,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  String _getPaymentModeDisplayText(String paymentMode) {
    switch (paymentMode.toLowerCase()) {
      case 'cash':
        return 'Cash on Delivery';
      case 'upi':
        return 'UPI Payment';
      case 'card':
        return 'Card Payment';
      default:
        return paymentMode;
    }
  }

  Widget _buildOrderItemsCard(OrderDetails orderDetails, Map<String, MenuItem> menuItems, double screenWidth, double screenHeight) {
    // Validate that order prices are being displayed correctly
    debugPrint('OrderDetailsView: Order items validation:');
    debugPrint('  - Total items: ${orderDetails.items.length}');
    debugPrint('  - Order subtotal (items only): ₹${orderDetails.subtotal}');
    debugPrint('  - Delivery fees: ₹${orderDetails.deliveryFees}');
    debugPrint('  - Grand total (subtotal + delivery): ₹${orderDetails.grandTotal}');
    
    double calculatedSubtotal = 0.0;
    for (var item in orderDetails.items) {
      calculatedSubtotal += item.totalPrice;
      debugPrint('    - Item ${item.menuId}: ₹${item.itemPrice} × ${item.quantity} = ₹${item.totalPrice}');
    }
    debugPrint('  - Calculated subtotal: ₹$calculatedSubtotal');
    debugPrint('  - Subtotal match: ${calculatedSubtotal == orderDetails.subtotal ? '✓' : '✗'}');
    debugPrint('  - Expected grand total: ₹${calculatedSubtotal + orderDetails.deliveryFees}');
    debugPrint('  - Grand total match: ${(calculatedSubtotal + orderDetails.deliveryFees) == orderDetails.grandTotal ? '✓' : '✗'}');
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Items (${orderDetails.items.length})',
            style: TextStyle(
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeightManager.bold,
              fontFamily: FontFamily.Montserrat,
              color: ColorManager.black,
            ),
          ),
          SizedBox(height: screenHeight * 0.015),
          ...orderDetails.items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            
            return Column(
              children: [
                if (index > 0) Divider(color: Colors.grey[200]),
                if (index > 0) SizedBox(height: screenHeight * 0.01),
                _buildOrderItemRow(item, menuItems, screenWidth, screenHeight),
                if (index < orderDetails.items.length - 1) SizedBox(height: screenHeight * 0.01),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildOrderItemRow(OrderDetailsItem item, Map<String, MenuItem> menuItems, double screenWidth, double screenHeight) {
    // Get the real menu item name from the fetched data
    final menuItem = item.menuId != null ? menuItems[item.menuId!] : null;
    final itemName = menuItem?.name ?? item.itemName ?? 'Menu Item';
    final isLoadingMenuItem = item.menuId != null && item.menuId!.isNotEmpty && menuItem == null;
    
    // Debug logging for price comparison
    debugPrint('OrderDetailsView: Price comparison for item ${item.menuId}:');
    debugPrint('  - Order item price (at time of ordering): ₹${item.itemPrice}');
    debugPrint('  - Current menu item price: ₹${menuItem?.price ?? 'N/A'}');
    debugPrint('  - Total price for quantity ${item.quantity}: ₹${item.totalPrice}');
    
    return Row(
      children: [
        // Item Image
        Container(
          width: screenWidth * 0.12,
          height: screenWidth * 0.12,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
            image: item.imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(item.imageUrl!),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {
                      debugPrint('OrderDetailsView: Error loading image: $exception');
                    },
                  )
                : null,
          ),
          child: item.imageUrl == null
              ? Icon(
                  Icons.fastfood,
                  color: Colors.grey[500],
                  size: screenWidth * 0.06,
                )
              : null,
        ),
        SizedBox(width: screenWidth * 0.03),
        
        // Item Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item Name with loading indicator
              Row(
                children: [
                  Expanded(
                    child: Text(
                      itemName,
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeightManager.medium,
                        fontFamily: FontFamily.Montserrat,
                        color: ColorManager.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Show loading indicator while fetching menu item name
                  if (isLoadingMenuItem)
                    Container(
                      margin: EdgeInsets.only(left: screenWidth * 0.02),
                      width: screenWidth * 0.04,
                      height: screenWidth * 0.04,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.grey[400],
                      ),
                    ),
                ],
              ),
              SizedBox(height: screenHeight * 0.005),
              
              // Quantity and Price - Using order price (not current menu price)
              Row(
                children: [
                  Text(
                    'Qty: ${item.quantity}',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      fontFamily: FontFamily.Montserrat,
                      color: Colors.grey[600],
                    ),
                  ),
                  FutureBuilder<String>(
                    future: CurrencyUtils.getCurrencySymbolFromUserLocation(),
                    builder: (context, snapshot) {
                      final currencySymbol = snapshot.data ?? '₹';
                      return Text(
                        ' × ${CurrencyUtils.formatPrice(item.itemPrice, currencySymbol)}',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          fontFamily: FontFamily.Montserrat,
                          color: Colors.grey[600],
                        ),
                      );
                    },
                  ),
                ],
              ),
              
              // Show description if available from menu item
              if (menuItem?.description != null && menuItem!.description!.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(top: screenHeight * 0.005),
                  child: Text(
                    menuItem.description!,
                    style: TextStyle(
                      fontSize: screenWidth * 0.03,
                      fontFamily: FontFamily.Montserrat,
                      color: Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
        
        // Total Price - Using order price calculation
                        FutureBuilder<String>(
                  future: CurrencyUtils.getCurrencySymbolFromUserLocation(),
                  builder: (context, snapshot) {
                    final currencySymbol = snapshot.data ?? '₹';
                    return Text(
                      CurrencyUtils.formatPrice(item.totalPrice, currencySymbol),
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeightManager.bold,
                fontFamily: FontFamily.Montserrat,
                color: ColorManager.black,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDeliveryInfoCard(OrderDetails orderDetails, double screenWidth, double screenHeight) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delivery Information',
            style: TextStyle(
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeightManager.bold,
              fontFamily: FontFamily.Montserrat,
              color: ColorManager.black,
            ),
          ),
          SizedBox(height: screenHeight * 0.015),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on,
                color: Colors.grey[600],
                size: screenWidth * 0.05,
              ),
              SizedBox(width: screenWidth * 0.02),
              Expanded(
                child: Text(
                  orderDetails.deliveryAddress!,
                  style: TextStyle(
                    fontSize: screenWidth * 0.038,
                    fontFamily: FontFamily.Montserrat,
                    color: ColorManager.black,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrackOrderButton(BuildContext context, OrderDetails orderDetails, double screenWidth, double screenHeight) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorManager.primary.withOpacity(0.05),
            ColorManager.primary.withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        border: Border.all(
          color: ColorManager.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth * 0.02),
                decoration: BoxDecoration(
                  color: ColorManager.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
                child: Icon(
                  Icons.location_on,
                  color: ColorManager.primary,
                  size: screenWidth * 0.05,
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Track Your Order',
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeightManager.bold,
                        fontFamily: FontFamily.Montserrat,
                        color: ColorManager.black,
                      ),
                    ),
                    Text(
                      'Get real-time updates on your order status and delivery progress',
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        fontFamily: FontFamily.Montserrat,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          SizedBox(
            width: double.infinity,
            height: screenHeight * 0.055,
            child: ElevatedButton(
              onPressed: () {
                _showTrackingDialog(context, orderDetails, screenWidth, screenHeight);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.primary,
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: ColorManager.primary.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.025),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.track_changes,
                    size: screenWidth * 0.045,
                    color: Colors.white,
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Text(
                    'Track Order',
                    style: TextStyle(
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeightManager.semiBold,
                      fontFamily: FontFamily.Montserrat,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTrackingDialog(BuildContext context, OrderDetails orderDetails, double screenWidth, double screenHeight) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.04),
          ),
          child: Container(
            width: screenWidth * 0.9,
            constraints: BoxConstraints(
              maxHeight: screenHeight * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.05),
                  decoration: BoxDecoration(
                    color: ColorManager.primary,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(screenWidth * 0.04),
                      topRight: Radius.circular(screenWidth * 0.04),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: screenWidth * 0.06,
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      Expanded(
                        child: Text(
                          'Order Tracking',
                          style: TextStyle(
                            fontSize: screenWidth * 0.05,
                            fontWeight: FontWeightManager.bold,
                            fontFamily: FontFamily.Montserrat,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: screenWidth * 0.05,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Order ID
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(screenWidth * 0.04),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(screenWidth * 0.03),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order ID',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.035,
                                  fontFamily: FontFamily.Montserrat,
                                  color: Colors.grey[600],
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.005),
                              Text(
                                '#${orderDetails.orderId}',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.04,
                                  fontWeight: FontWeightManager.semiBold,
                                  fontFamily: FontFamily.Montserrat,
                                  color: ColorManager.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: screenHeight * 0.03),
                        
                        // Current Status
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(screenWidth * 0.04),
                          decoration: BoxDecoration(
                            color: ColorManager.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(screenWidth * 0.03),
                            border: Border.all(color: ColorManager.primary.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _getStatusIcon(orderDetails.orderStatus),
                                color: ColorManager.primary,
                                size: screenWidth * 0.05,
                              ),
                              SizedBox(width: screenWidth * 0.03),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Current Status',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.035,
                                        fontWeight: FontWeightManager.medium,
                                        fontFamily: FontFamily.Montserrat,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      orderDetails.statusDisplayText,
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.04,
                                        fontWeight: FontWeightManager.bold,
                                        fontFamily: FontFamily.Montserrat,
                                        color: ColorManager.primary,
                                      ),
                                    ),
                                    Text(
                                      'Raw: ${orderDetails.orderStatus}',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.03,
                                        fontFamily: FontFamily.Montserrat,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: screenHeight * 0.03),
                        
                        // Tracking Timeline
                        Text(
                          'Order Progress',
                          style: TextStyle(
                            fontSize: screenWidth * 0.045,
                            fontWeight: FontWeightManager.bold,
                            fontFamily: FontFamily.Montserrat,
                            color: ColorManager.black,
                          ),
                        ),
                        
                        SizedBox(height: screenHeight * 0.02),
                        
                        // Timeline items
                        _buildTimelineItem(
                          'Order Placed',
                          'Your order has been confirmed and is being prepared',
                          Icons.shopping_cart,
                          ColorManager.primary,
                          _isStatusCompleted(orderDetails.orderStatus, 'pending'),
                          screenWidth,
                          screenHeight,
                        ),
                        
                        _buildTimelineItem(
                          'Confirmed',
                          'Your order has been confirmed by the restaurant',
                          Icons.check_circle_outline,
                          ColorManager.primary,
                          _isStatusCompleted(orderDetails.orderStatus, 'confirmed'),
                          screenWidth,
                          screenHeight,
                        ),
                        
                        _buildTimelineItem(
                          'Preparing',
                          'The restaurant is preparing your order',
                          Icons.restaurant,
                          ColorManager.primary,
                          _isStatusCompleted(orderDetails.orderStatus, 'preparing'),
                          screenWidth,
                          screenHeight,
                        ),
                        
                        _buildTimelineItem(
                          'Ready for Delivery',
                          'Your order is ready and waiting for delivery',
                          Icons.check_circle,
                          ColorManager.primary,
                          _isStatusCompleted(orderDetails.orderStatus, 'ready_for_delivery'),
                          screenWidth,
                          screenHeight,
                        ),
                        
                        _buildTimelineItem(
                          'Out for Delivery',
                          'Your order is on the way to you',
                          Icons.delivery_dining,
                          ColorManager.primary,
                          _isStatusCompleted(orderDetails.orderStatus, 'out_for_delivery'),
                          screenWidth,
                          screenHeight,
                        ),
                        
                        _buildTimelineItem(
                          'Delivered',
                          'Your order has been delivered successfully',
                          Icons.home,
                          ColorManager.primary,
                          _isStatusCompleted(orderDetails.orderStatus, 'delivered'),
                          screenWidth,
                          screenHeight,
                        ),
                        
                        SizedBox(height: screenHeight * 0.03),
                        
                        // Estimated delivery time
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(screenWidth * 0.04),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                ColorManager.primary.withOpacity(0.1),
                                ColorManager.primary.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(screenWidth * 0.03),
                            border: Border.all(color: ColorManager.primary.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(screenWidth * 0.02),
                                decoration: BoxDecoration(
                                  color: ColorManager.primary,
                                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                                ),
                                child: Icon(
                                  Icons.access_time,
                                  color: Colors.white,
                                  size: screenWidth * 0.04,
                                ),
                              ),
                              SizedBox(width: screenWidth * 0.03),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Estimated Delivery',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.035,
                                        fontWeight: FontWeightManager.medium,
                                        fontFamily: FontFamily.Montserrat,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      '20-30 minutes',
                                      style: TextStyle(
                                        fontSize: screenWidth * 0.04,
                                        fontWeight: FontWeightManager.bold,
                                        fontFamily: FontFamily.Montserrat,
                                        color: ColorManager.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: screenHeight * 0.03),
                      ],
                    ),
                  ),
                ),
                
                // Close button
                Container(
                  padding: EdgeInsets.all(screenWidth * 0.05),
                  child: SizedBox(
                    width: double.infinity,
                    height: screenHeight * 0.055,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorManager.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.025),
                        ),
                      ),
                      child: Text(
                        'Close',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeightManager.semiBold,
                          fontFamily: FontFamily.Montserrat,
                        ),
                      ),
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

  IconData _getStatusIcon(String orderStatus) {
    switch (orderStatus.toLowerCase()) {
      case 'pending':
        return Icons.schedule;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'preparing':
        return Icons.restaurant;
      case 'ready_for_delivery':
        return Icons.check_circle;
      case 'ready':
        return Icons.check_circle;
      case 'on_the_way':
        return Icons.delivery_dining;
      case 'out_for_delivery':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.check_circle_outline;
      case 'cancelled':
        return Icons.cancel;
      case 'canceled':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  Widget _buildTimelineItem(
    String title,
    String description,
    IconData icon,
    Color color,
    bool isCompleted,
    double screenWidth,
    double screenHeight,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.02),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline dot with line
          Column(
            children: [
              Container(
                width: screenWidth * 0.05,
                height: screenWidth * 0.05,
                decoration: BoxDecoration(
                  color: isCompleted ? color : Colors.grey[300],
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted ? color : Colors.grey[400]!,
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? Icon(
                        Icons.check,
                        color: Colors.white,
                        size: screenWidth * 0.025,
                      )
                    : null,
              ),
              if (title != 'Delivered') // Don't show line for last item
                Container(
                  width: 2,
                  height: screenHeight * 0.04,
                  color: isCompleted ? color : Colors.grey[300],
                ),
            ],
          ),
          
          SizedBox(width: screenWidth * 0.04),
          
          // Content
          Expanded(
            child: Container(
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                color: isCompleted 
                    ? color.withOpacity(0.1) 
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                border: Border.all(
                  color: isCompleted 
                      ? color.withOpacity(0.3) 
                      : Colors.grey[200]!,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(screenWidth * 0.015),
                        decoration: BoxDecoration(
                          color: isCompleted 
                              ? color.withOpacity(0.2) 
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        ),
                        child: Icon(
                          icon,
                          color: isCompleted ? color : Colors.grey[500],
                          size: screenWidth * 0.04,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.03),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeightManager.semiBold,
                            fontFamily: FontFamily.Montserrat,
                            color: isCompleted ? ColorManager.black : Colors.grey[600],
                          ),
                        ),
                      ),
                      if (isCompleted)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.02,
                            vertical: screenHeight * 0.005,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(screenWidth * 0.015),
                          ),
                          child: Text(
                            '✓',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.03,
                              fontWeight: FontWeightManager.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.01),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      fontFamily: FontFamily.Montserrat,
                      color: Colors.grey[600],
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isStatusCompleted(String? orderStatus, String status) {
    if (orderStatus == null) return false;
    
    final currentStatus = orderStatus.toLowerCase();
    final targetStatus = status.toLowerCase();
    
    debugPrint('OrderDetailsView: Checking status completion');
    debugPrint('OrderDetailsView: Current status: $currentStatus');
    debugPrint('OrderDetailsView: Target status: $targetStatus');
    
    // Map API statuses to our timeline statuses
    final statusMapping = {
      'pending': 'pending',
      'confirmed': 'confirmed',
      'preparing': 'preparing', 
      'ready_for_delivery': 'ready',
      'ready': 'ready',
      'on_the_way': 'on_the_way',
      'out_for_delivery': 'on_the_way',
      'delivered': 'delivered',
      'cancelled': 'cancelled',
      'canceled': 'cancelled',
    };
    
    // Define the order of statuses
    final statusOrder = ['pending', 'confirmed', 'preparing', 'ready', 'on_the_way', 'delivered'];
    
    // Map current status to our timeline status
    final mappedCurrentStatus = statusMapping[currentStatus] ?? currentStatus;
    final mappedTargetStatus = statusMapping[targetStatus] ?? targetStatus;
    
    debugPrint('OrderDetailsView: Mapped current status: $mappedCurrentStatus');
    debugPrint('OrderDetailsView: Mapped target status: $mappedTargetStatus');
    
    final currentIndex = statusOrder.indexOf(mappedCurrentStatus);
    final targetIndex = statusOrder.indexOf(mappedTargetStatus);
    
    debugPrint('OrderDetailsView: Current index: $currentIndex');
    debugPrint('OrderDetailsView: Target index: $targetIndex');
    
    // Status is completed if current status is at or beyond the target status
    // If current status is not in the order list, check if it's a final status
    bool isCompleted;
    if (currentIndex < 0) {
      // Current status not in order list, check if it's a final status
      isCompleted = ['delivered', 'cancelled'].contains(mappedCurrentStatus);
    } else {
      isCompleted = currentIndex >= targetIndex;
    }
    debugPrint('OrderDetailsView: Is completed: $isCompleted');
    
    return isCompleted;
  }
}
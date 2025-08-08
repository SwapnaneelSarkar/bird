// lib/presentation/order_details/view.dart - Optimized version
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import '../../widgets/custom_button_large.dart';
import '../../widgets/review_rating_widget.dart';
import '../../constants/color/colorConstant.dart';
import '../../constants/font/fontManager.dart';
import '../../models/order_details_model.dart';
import '../../models/menu_model.dart';
import '../../service/reorder_service.dart';
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
    return BlocProvider(
      create: (context) {
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
      appBar: _buildAppBar(context, screenWidth),
      body: BlocConsumer<OrderDetailsBloc, OrderDetailsState>(
        listener: _handleStateChanges,
        builder: (context, state) => _buildBody(context, state, screenWidth, screenHeight),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, double screenWidth) {
    return AppBar(
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
    );
  }

  void _handleStateChanges(BuildContext context, OrderDetailsState state) {
    if (state is OrderCancelled) {
      _showSnackBar(context, state.message, Colors.orange);
    } else if (state is OrderDetailsError) {
      _showSnackBar(context, state.message, Colors.red);
    }
  }

  void _showSnackBar(BuildContext context, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildBody(BuildContext context, OrderDetailsState state, double screenWidth, double screenHeight) {
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
            _buildOrderStatusCard(context, orderDetails, screenWidth, screenHeight),
            SizedBox(height: screenHeight * 0.02),
            _buildOrderSummaryCard(orderDetails, screenWidth, screenHeight),
            SizedBox(height: screenHeight * 0.02),
            _buildOrderItemsCard(orderDetails, menuItems, screenWidth, screenHeight),
            SizedBox(height: screenHeight * 0.02),
            if (orderDetails.deliveryAddress != null)
              _buildDeliveryInfoCard(orderDetails, screenWidth, screenHeight),
            SizedBox(height: screenHeight * 0.02),
            _buildReviewSection(orderDetails),
            SizedBox(height: screenHeight * 0.02),
            if (_shouldShowReorderButton(orderDetails))
              _buildReorderButton(context, orderDetails, screenWidth, screenHeight),
            if (_shouldShowReorderButton(orderDetails))
              SizedBox(height: screenHeight * 0.02),
            if (_shouldShowTrackOrderButton(orderDetails))
              _buildTrackOrderButton(context, orderDetails, screenWidth, screenHeight),
            if (_shouldShowTrackOrderButton(orderDetails))
              SizedBox(height: screenHeight * 0.02),
            _buildChatButton(context, orderDetails, screenWidth, screenHeight),
            SizedBox(height: screenHeight * 0.02),
          ],
        ),
      ),
    );
  }

  bool _shouldShowReorderButton(OrderDetails orderDetails) {
    return orderDetails.orderStatus.toUpperCase() == 'DELIVERED' || 
           orderDetails.orderStatus.toUpperCase() == 'COMPLETED';
  }

  bool _shouldShowTrackOrderButton(OrderDetails orderDetails) {
    return orderDetails.orderStatus.toUpperCase() != 'DELIVERED' && 
           orderDetails.orderStatus.toUpperCase() != 'CANCELLED' &&
           orderDetails.orderStatus.toUpperCase() != 'CANCELED';
  }

  Widget _buildReviewSection(OrderDetails orderDetails) {
    return ReviewRatingWidget(
      orderId: orderDetails.orderId,
      partnerId: orderDetails.partnerId ?? '',
      canReview: orderDetails.orderStatus.toUpperCase() == 'DELIVERED',
    );
  }

  Widget _buildReorderButton(BuildContext context, OrderDetails orderDetails, double screenWidth, double screenHeight) {
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
                Icons.replay,
                color: const Color(0xFF4CAF50),
                size: screenWidth * 0.06,
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reorder',
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeightManager.bold,
                        fontFamily: FontFamily.Montserrat,
                        color: ColorManager.black,
                      ),
                    ),
                    Text(
                      'Order the same items again',
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
              onPressed: () => _handleReorder(context, orderDetails),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: const Color(0xFF4CAF50).withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.025),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart,
                    size: screenWidth * 0.045,
                    color: Colors.white,
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Text(
                    'Reorder Items',
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

  Future<void> _handleReorder(BuildContext context, OrderDetails orderDetails) async {
    try {
      _showLoadingDialog(context);
      
      final result = await ReorderService.reorderFromHistory(
        orderId: orderDetails.orderId,
        partnerId: orderDetails.partnerId ?? '',
      );

      _hideLoadingDialog(context);

      if (result['success']) {
        _showSnackBar(context, result['message'] ?? 'Items added to cart successfully', Colors.green);
        Navigator.of(context).pushNamed('/cart');
      } else {
        _showSnackBar(context, result['message'] ?? 'Failed to reorder', Colors.red);
      }
    } catch (e) {
      _hideLoadingDialog(context);
      _showSnackBar(context, 'An error occurred while reordering', Colors.red);
    }
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF4CAF50),
          ),
        );
      },
    );
  }

  void _hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  // Keep existing methods but optimize them
  Widget _buildOrderStatusCard(BuildContext context, OrderDetails orderDetails, double screenWidth, double screenHeight) {
    final statusInfo = _getStatusInfo(orderDetails.orderStatus);
    
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
                statusInfo.icon,
                color: statusInfo.color,
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
                        color: statusInfo.color,
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
          _buildOrderInfoRow(orderDetails, screenWidth, screenHeight),
          if (orderDetails.paymentMode != null && orderDetails.paymentMode!.isNotEmpty)
            _buildPaymentInfoRow(orderDetails, screenWidth, screenHeight),
        ],
      ),
    );
  }

  _StatusInfo _getStatusInfo(String orderStatus) {
    final status = orderStatus.toUpperCase();
    switch (status) {
      case 'PENDING':
        return _StatusInfo(ColorManager.primary, Icons.schedule);
      case 'CONFIRMED':
        return _StatusInfo(ColorManager.primary, Icons.check_circle_outline);
      case 'PREPARING':
        return _StatusInfo(ColorManager.primary, Icons.restaurant);
      case 'READY_FOR_DELIVERY':
      case 'READY':
        return _StatusInfo(ColorManager.primary, Icons.check_circle);
      case 'ON_THE_WAY':
      case 'OUT_FOR_DELIVERY':
        return _StatusInfo(ColorManager.primary, Icons.delivery_dining);
      case 'DELIVERED':
        return _StatusInfo(ColorManager.primary, Icons.check_circle_outline);
      case 'CANCELLED':
      case 'CANCELED':
        return _StatusInfo(Colors.red, Icons.cancel);
      default:
        return _StatusInfo(ColorManager.primary, Icons.info);
    }
  }

  Widget _buildOrderInfoRow(OrderDetails orderDetails, double screenWidth, double screenHeight) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildInfoColumn('Order ID', orderDetails.orderId, screenWidth, screenHeight, true),
        if (orderDetails.createdAt != null)
          _buildInfoColumn('Order Date', TimezoneUtils.formatDateOnly(orderDetails.createdAt!), screenWidth, screenHeight, false),
      ],
    );
  }

  Widget _buildInfoColumn(String label, String value, double screenWidth, double screenHeight, bool isOrderId) {
    return Column(
      crossAxisAlignment: isOrderId ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: screenWidth * 0.03,
            fontFamily: FontFamily.Montserrat,
            color: Colors.grey[600],
          ),
        ),
        if (isOrderId)
          GestureDetector(
            onLongPress: () => _copyToClipboard(value),
            child: Text(
              value,
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeightManager.medium,
                fontFamily: FontFamily.Montserrat,
                color: ColorManager.black,
              ),
            ),
          )
        else
          Text(
            value,
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              fontWeight: FontWeightManager.medium,
              fontFamily: FontFamily.Montserrat,
              color: ColorManager.black,
            ),
          ),
      ],
    );
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  Widget _buildPaymentInfoRow(OrderDetails orderDetails, double screenWidth, double screenHeight) {
    return Column(
      children: [
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

  // Keep the rest of the existing methods but optimize them
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
            _buildRestaurantInfo(orderDetails, screenWidth),
            SizedBox(height: screenHeight * 0.015),
          ],
          if (orderDetails.restaurantAddress != null && orderDetails.restaurantAddress!.isNotEmpty) ...[
            _buildRestaurantAddress(orderDetails, screenWidth),
            SizedBox(height: screenHeight * 0.015),
          ],
          if (orderDetails.rating != null) ...[
            _buildRestaurantRating(orderDetails, screenWidth),
            SizedBox(height: screenHeight * 0.015),
          ],
          Divider(color: Colors.grey[200]),
          SizedBox(height: screenHeight * 0.015),
          _buildPriceBreakdown(orderDetails, screenWidth, screenHeight),
        ],
      ),
    );
  }

  Widget _buildRestaurantInfo(OrderDetails orderDetails, double screenWidth) {
    return Row(
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
    );
  }

  Widget _buildRestaurantAddress(OrderDetails orderDetails, double screenWidth) {
    return Row(
      children: [
        Icon(
          Icons.location_on,
          size: screenWidth * 0.045,
          color: Colors.grey[600],
        ),
        SizedBox(width: screenWidth * 0.02),
        Expanded(
          child: Text(
            orderDetails.restaurantAddress!,
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              fontWeight: FontWeightManager.medium,
              fontFamily: FontFamily.Montserrat,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRestaurantRating(OrderDetails orderDetails, double screenWidth) {
    return Row(
      children: [
        Icon(
          Icons.star,
          size: screenWidth * 0.045,
          color: Colors.amber,
        ),
        SizedBox(width: screenWidth * 0.02),
        Text(
          '${orderDetails.rating!.toStringAsFixed(1)}',
          style: TextStyle(
            fontSize: screenWidth * 0.035,
            fontWeight: FontWeightManager.medium,
            fontFamily: FontFamily.Montserrat,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceBreakdown(OrderDetails orderDetails, double screenWidth, double screenHeight) {
    return FutureBuilder<String>(
      future: CurrencyUtils.getCurrencySymbolFromUserLocation(),
      builder: (context, snapshot) {
        final currencySymbol = snapshot.data ?? '₹';
        return Column(
          children: [
            _buildSummaryRow('Subtotal', CurrencyUtils.formatPrice(orderDetails.subtotal, currencySymbol), screenWidth, false),
            SizedBox(height: screenHeight * 0.01),
            _buildSummaryRow('Delivery Fee', CurrencyUtils.formatPrice(orderDetails.deliveryFees, currencySymbol), screenWidth, false),
            SizedBox(height: screenHeight * 0.015),
            Divider(color: Colors.grey[200]),
            SizedBox(height: screenHeight * 0.015),
            _buildSummaryRow('Total Amount', CurrencyUtils.formatPrice(orderDetails.grandTotal, currencySymbol), screenWidth, true),
          ],
        );
      },
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

  // Keep existing methods for order items, delivery info, and track order button
  Widget _buildOrderItemsCard(OrderDetails orderDetails, Map<String, MenuItem> menuItems, double screenWidth, double screenHeight) {
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
    final menuItem = item.menuId.isNotEmpty ? menuItems[item.menuId] : null;
    final itemName = menuItem?.name ?? item.itemName ?? 'Menu Item';
    
    return Row(
      children: [
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                itemName,
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeightManager.medium,
                  fontFamily: FontFamily.Montserrat,
                  color: ColorManager.black,
                ),
              ),
              SizedBox(height: screenHeight * 0.005),
              Text(
                'Qty: ${item.quantity}',
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  fontFamily: FontFamily.Montserrat,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
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
            children: [
              Icon(
                Icons.location_on,
                size: screenWidth * 0.045,
                color: Colors.grey[600],
              ),
              SizedBox(width: screenWidth * 0.02),
              Expanded(
                child: Text(
                  orderDetails.deliveryAddress!,
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontFamily: FontFamily.Montserrat,
                    color: ColorManager.black,
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
                Icons.track_changes,
                color: ColorManager.primary,
                size: screenWidth * 0.06,
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Track Order',
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
              onPressed: () => _showTrackingDialog(context, orderDetails, screenWidth, screenHeight),
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

  Widget _buildChatButton(BuildContext context, OrderDetails orderDetails, double screenWidth, double screenHeight) {
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
                Icons.chat,
                color: const Color(0xFFE17A47),
                size: screenWidth * 0.06,
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chat wit the Restaurant',
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeightManager.bold,
                        fontFamily: FontFamily.Montserrat,
                        color: ColorManager.black,
                      ),
                    ),
                    Text(
                      'Get help with your order or ask questions',
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
              onPressed: () => _handleChat(context, orderDetails),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE17A47),
                foregroundColor: Colors.white,
                elevation: 2,
                shadowColor: const Color(0xFFE17A47).withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.025),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat,
                    size: screenWidth * 0.045,
                    color: Colors.white,
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Text(
                    'Chat',
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

  void _handleChat(BuildContext context, OrderDetails orderDetails) {
    if (orderDetails.orderId.isNotEmpty) {
      Navigator.of(context).pushNamed('/chat', arguments: orderDetails.orderId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open chat: Order ID missing'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showTrackingDialog(BuildContext context, OrderDetails orderDetails, double screenWidth, double screenHeight) {
    // Keep existing tracking dialog implementation
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
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(screenWidth * 0.05),
                    child: Column(
                      children: [
                        _buildTrackingStep('Order Placed', 'Your order has been placed successfully', true, screenWidth, screenHeight),
                        _buildTrackingStep('Confirmed', 'Restaurant has confirmed your order', _isStatusCompleted(orderDetails.orderStatus, 'confirmed'), screenWidth, screenHeight),
                        _buildTrackingStep('Preparing', 'Your food is being prepared', _isStatusCompleted(orderDetails.orderStatus, 'preparing'), screenWidth, screenHeight),
                        _buildTrackingStep('Ready', 'Your order is ready for delivery', _isStatusCompleted(orderDetails.orderStatus, 'ready'), screenWidth, screenHeight),
                        _buildTrackingStep('On the Way', 'Your order is on its way to you', _isStatusCompleted(orderDetails.orderStatus, 'on_the_way'), screenWidth, screenHeight),
                        _buildTrackingStep('Delivered', 'Your order has been delivered', _isStatusCompleted(orderDetails.orderStatus, 'delivered'), screenWidth, screenHeight),
                      ],
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

  Widget _buildTrackingStep(String title, String description, bool isCompleted, double screenWidth, double screenHeight) {
    final color = isCompleted ? ColorManager.primary : Colors.grey[400]!;
    
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.02),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: screenWidth * 0.08,
            height: screenWidth * 0.08,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
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
                  title,
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    fontWeight: FontWeightManager.semiBold,
                    fontFamily: FontFamily.Montserrat,
                    color: isCompleted ? ColorManager.black : Colors.grey[600],
                  ),
                ),
                SizedBox(height: screenHeight * 0.005),
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
        ],
      ),
    );
  }

  bool _isStatusCompleted(String? orderStatus, String status) {
    if (orderStatus == null) return false;
    
    final currentStatus = orderStatus.toUpperCase();
    final targetStatus = status.toUpperCase();
    
    final statusMapping = {
      'PENDING': 'PENDING',
      'CONFIRMED': 'CONFIRMED',
      'PREPARING': 'PREPARING', 
      'READY_FOR_DELIVERY': 'READY',
      'READY': 'READY',
      'ON_THE_WAY': 'ON_THE_WAY',
      'OUT_FOR_DELIVERY': 'ON_THE_WAY',
      'DELIVERED': 'DELIVERED',
      'CANCELLED': 'CANCELLED',
      'CANCELED': 'CANCELLED',
    };
    
    final statusOrder = ['PENDING', 'CONFIRMED', 'PREPARING', 'READY', 'ON_THE_WAY', 'DELIVERED'];
    
    final mappedCurrentStatus = statusMapping[currentStatus] ?? currentStatus;
    final mappedTargetStatus = statusMapping[targetStatus] ?? targetStatus;
    
    final currentIndex = statusOrder.indexOf(mappedCurrentStatus);
    final targetIndex = statusOrder.indexOf(mappedTargetStatus);
    
    bool isCompleted;
    if (currentIndex < 0) {
      isCompleted = ['DELIVERED', 'CANCELLED'].contains(mappedCurrentStatus);
    } else {
      isCompleted = currentIndex >= targetIndex;
    }
    
    return isCompleted;
  }
}

class _StatusInfo {
  final Color color;
  final IconData icon;

  _StatusInfo(this.color, this.icon);
}
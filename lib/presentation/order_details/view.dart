// lib/presentation/order_details/view.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../widgets/custom_button_large.dart';
import '../../constants/color/colorConstant.dart';
import '../../constants/font/fontManager.dart';
import '../../models/order_details_model.dart';
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
          onPressed: () => Navigator.of(context).pop(),
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
            return _buildLoadedView(context, state.orderDetails, screenWidth, screenHeight);
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

  Widget _buildLoadedView(BuildContext context, OrderDetails orderDetails, double screenWidth, double screenHeight) {
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
            _buildOrderStatusCard(orderDetails, screenWidth, screenHeight),
            
            SizedBox(height: screenHeight * 0.02),
            
            // Order Summary Card
            _buildOrderSummaryCard(orderDetails, screenWidth, screenHeight),
            
            SizedBox(height: screenHeight * 0.02),
            
            // Items List Card
            _buildOrderItemsCard(orderDetails, screenWidth, screenHeight),
            
            SizedBox(height: screenHeight * 0.02),
            
            // Delivery Information Card
            if (orderDetails.deliveryAddress != null)
              _buildDeliveryInfoCard(orderDetails, screenWidth, screenHeight),
            
            SizedBox(height: screenHeight * 0.03),
            
            // Action Buttons
            _buildActionButtons(context, orderDetails, screenWidth, screenHeight),
            
            SizedBox(height: screenHeight * 0.02),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatusCard(OrderDetails orderDetails, double screenWidth, double screenHeight) {
    Color statusColor;
    IconData statusIcon;
    
    switch (orderDetails.orderStatus.toLowerCase()) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.schedule;
        break;
      case 'preparing':
        statusColor = Colors.blue;
        statusIcon = Icons.restaurant;
        break;
      case 'ready':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'on_the_way':
        statusColor = Colors.purple;
        statusIcon = Icons.delivery_dining;
        break;
      case 'delivered':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
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
                  Text(
                    orderDetails.orderId,
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeightManager.medium,
                      fontFamily: FontFamily.Montserrat,
                      color: ColorManager.black,
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
                      '${orderDetails.createdAt!.day}/${orderDetails.createdAt!.month}/${orderDetails.createdAt!.year}',
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
          _buildSummaryRow('Subtotal', '₹${orderDetails.subtotal.toStringAsFixed(2)}', screenWidth, false),
          SizedBox(height: screenHeight * 0.01),
          _buildSummaryRow('Delivery Fee', '₹${orderDetails.deliveryFees.toStringAsFixed(2)}', screenWidth, false),
          SizedBox(height: screenHeight * 0.015),
          Divider(color: Colors.grey[200]),
          SizedBox(height: screenHeight * 0.015),
          _buildSummaryRow('Total Amount', '₹${orderDetails.totalAmount.toStringAsFixed(2)}', screenWidth, true),
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

  Widget _buildOrderItemsCard(OrderDetails orderDetails, double screenWidth, double screenHeight) {
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
                _buildOrderItemRow(item, screenWidth, screenHeight),
                if (index < orderDetails.items.length - 1) SizedBox(height: screenHeight * 0.01),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildOrderItemRow(OrderDetailsItem item, double screenWidth, double screenHeight) {
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.itemName ?? 'Menu Item',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeightManager.medium,
                  fontFamily: FontFamily.Montserrat,
                  color: ColorManager.black,
                ),
              ),
              SizedBox(height: screenHeight * 0.005),
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
                  Text(
                    ' × ₹${item.itemPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      fontFamily: FontFamily.Montserrat,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Text(
          '₹${item.totalPrice.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeightManager.bold,
            fontFamily: FontFamily.Montserrat,
            color: ColorManager.black,
          ),
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

  Widget _buildActionButtons(BuildContext context, OrderDetails orderDetails, double screenWidth, double screenHeight) {
    return Column(
      children: [
        // Track Order Button (always visible for non-cancelled orders)
        if (orderDetails.orderStatus.toLowerCase() != 'cancelled' && 
            orderDetails.orderStatus.toLowerCase() != 'delivered')
          CustomLargeButton(
            text: 'Track Order',
            onPressed: () {
              context.read<OrderDetailsBloc>().add(TrackOrder(orderDetails.orderId));
            },
          ),
        
        // Cancel Order Button (only for pending/preparing orders)
        if (orderDetails.canBeCancelled) ...[
          if (orderDetails.orderStatus.toLowerCase() != 'cancelled' && 
              orderDetails.orderStatus.toLowerCase() != 'delivered')
            SizedBox(height: screenHeight * 0.015),
          SizedBox(
            width: double.infinity,
            height: screenHeight * 0.06,
            child: OutlinedButton(
              onPressed: () {
                _showCancelOrderDialog(context, orderDetails.orderId);
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
              ),
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
          ),
        ],
        
        // Reorder Button (for delivered orders)
        if (orderDetails.orderStatus.toLowerCase() == 'delivered') ...[
          SizedBox(height: screenHeight * 0.015),
          SizedBox(
            width: double.infinity,
            height: screenHeight * 0.06,
            child: OutlinedButton(
              onPressed: () {
                // Navigate to restaurant or add items to cart
                _showReorderDialog(context);
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: ColorManager.black, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
              ),
              child: Text(
                'Reorder',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeightManager.medium,
                  fontFamily: FontFamily.Montserrat,
                  color: ColorManager.black,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showCancelOrderDialog(BuildContext context, String orderId) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
          ),
          title: Text(
            'Cancel Order',
            style: TextStyle(
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeightManager.bold,
              fontFamily: FontFamily.Montserrat,
              color: ColorManager.black,
            ),
          ),
          content: Text(
            'Are you sure you want to cancel this order? This action cannot be undone.',
            style: TextStyle(
              fontSize: screenWidth * 0.038,
              fontFamily: FontFamily.Montserrat,
              color: Colors.grey[700],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'No, Keep Order',
                style: TextStyle(
                  fontSize: screenWidth * 0.038,
                  fontFamily: FontFamily.Montserrat,
                  color: Colors.grey[600],
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<OrderDetailsBloc>().add(CancelOrder(orderId));
              },
              child: Text(
                'Yes, Cancel',
                style: TextStyle(
                  fontSize: screenWidth * 0.038,
                  fontWeight: FontWeightManager.medium,
                  fontFamily: FontFamily.Montserrat,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showReorderDialog(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
          ),
          title: Text(
            'Reorder',
            style: TextStyle(
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeightManager.bold,
              fontFamily: FontFamily.Montserrat,
              color: ColorManager.black,
            ),
          ),
          content: Text(
            'This will add all items from this order to your cart. Continue?',
            style: TextStyle(
              fontSize: screenWidth * 0.038,
              fontFamily: FontFamily.Montserrat,
              color: Colors.grey[700],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: screenWidth * 0.038,
                  fontFamily: FontFamily.Montserrat,
                  color: Colors.grey[600],
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Implement reorder functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reorder functionality will be implemented'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              child: Text(
                'Add to Cart',
                style: TextStyle(
                  fontSize: screenWidth * 0.038,
                  fontWeight: FontWeightManager.medium,
                  fontFamily: FontFamily.Montserrat,
                  color: ColorManager.black,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
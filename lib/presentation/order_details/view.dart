// lib/presentation/order_details/view.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
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
      create: (context) => OrderDetailsBloc()..add(LoadOrderDetails(orderId)),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F8F8),
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: BlocBuilder<OrderDetailsBloc, OrderDetailsState>(
                  builder: (context, state) {
                    if (state is OrderDetailsLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFE17A47),
                        ),
                      );
                    } else if (state is OrderDetailsLoaded) {
                      return _buildOrderDetailsContent(context, state);
                    } else if (state is OrderDetailsError) {
                      return _buildErrorState(context, state);
                    }
                    
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      height: screenWidth * 0.14,
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE5E5E5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: screenWidth * 0.08,
              height: screenWidth * 0.08,
              alignment: Alignment.center,
              child: Icon(
                Icons.arrow_back_ios,
                size: screenWidth * 0.04,
                color: const Color(0xFF2D2D2D),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Order Details',
                style: TextStyle(
                  fontSize: screenWidth * 0.042,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D2D2D),
                  fontFamily: 'Roboto',
                ),
              ),
            ),
          ),
          SizedBox(width: screenWidth * 0.08),
        ],
      ),
    );
  }

  Widget _buildOrderDetailsContent(BuildContext context, OrderDetailsLoaded state) {
    final screenWidth = MediaQuery.of(context).size.width;
    final orderDetails = state.orderDetails;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(screenWidth * 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderSummaryCard(context, orderDetails),
          SizedBox(height: screenWidth * 0.04),
          _buildOrderItemsCard(context, orderDetails, state.menuItemDetails),
          SizedBox(height: screenWidth * 0.04),
          _buildPaymentSummaryCard(context, orderDetails),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard(BuildContext context, Map<String, dynamic> orderDetails) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${orderDetails['order_id'] ?? 'N/A'}',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D2D2D),
                  fontFamily: 'Roboto',
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.03,
                  vertical: screenWidth * 0.015,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(orderDetails['order_status'] ?? ''),
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
                child: Text(
                  _getStatusDisplayText(orderDetails['order_status'] ?? 'UNKNOWN'),
                  style: TextStyle(
                    fontSize: screenWidth * 0.03,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    fontFamily: 'Roboto',
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.02),
          Text(
            'User ID: ${orderDetails['user_id'] ?? 'N/A'}',
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF666666),
              fontFamily: 'Roboto',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsCard(BuildContext context, Map<String, dynamic> orderDetails, Map<String, MenuItemDetail> menuItemDetails) {
    final screenWidth = MediaQuery.of(context).size.width;
    final items = orderDetails['items'] as List<dynamic>? ?? [];
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D2D2D),
              fontFamily: 'Roboto',
            ),
          ),
          SizedBox(height: screenWidth * 0.03),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final menuId = item['menu_id'] as String? ?? '';
            final menuItem = menuItemDetails[menuId];
            
            return Column(
              children: [
                if (index > 0) 
                  Divider(
                    color: const Color(0xFFE5E5E5),
                    height: screenWidth * 0.06,
                  ),
                _buildOrderItem(context, item, menuItem),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildOrderItem(BuildContext context, Map<String, dynamic> item, MenuItemDetail? menuItem) {
    final screenWidth = MediaQuery.of(context).size.width;
    final quantity = item['quantity'] ?? 1;
    final itemPrice = item['item_price'] ?? 0;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: screenWidth * 0.1,
          height: screenWidth * 0.1,
          decoration: BoxDecoration(
            color: const Color(0xFFE17A47).withOpacity(0.1),
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
          ),
          child: Center(
            child: Text(
              '${quantity}x',
              style: TextStyle(
                fontSize: screenWidth * 0.03,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFE17A47),
                fontFamily: 'Roboto',
              ),
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.03),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                menuItem?.name ?? 'Loading...',
                style: TextStyle(
                  fontSize: screenWidth * 0.038,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF2D2D2D),
                  fontFamily: 'Roboto',
                ),
              ),
              if (menuItem?.description != null && menuItem!.description.isNotEmpty) ...[
                SizedBox(height: screenWidth * 0.01),
                Text(
                  menuItem.description,
                  style: TextStyle(
                    fontSize: screenWidth * 0.032,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF666666),
                    fontFamily: 'Roboto',
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              SizedBox(height: screenWidth * 0.01),
              Text(
                'Price per item: ₹${itemPrice.toString()}',
                style: TextStyle(
                  fontSize: screenWidth * 0.03,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF888888),
                  fontFamily: 'Roboto',
                ),
              ),
            ],
          ),
        ),
        Text(
          '₹${(itemPrice * quantity).toString()}',
          style: TextStyle(
            fontSize: screenWidth * 0.038,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2D2D2D),
            fontFamily: 'Roboto',
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSummaryCard(BuildContext context, Map<String, dynamic> orderDetails) {
    final screenWidth = MediaQuery.of(context).size.width;
    final totalAmount = orderDetails['total_amount'] ?? '0.00';
    final deliveryFees = orderDetails['delivery_fees'] ?? '0.00';
    
    // Calculate subtotal (total - delivery fees)
    final totalAmountDouble = double.tryParse(totalAmount.toString()) ?? 0.0;
    final deliveryFeesDouble = double.tryParse(deliveryFees.toString()) ?? 0.0;
    final subtotal = totalAmountDouble - deliveryFeesDouble;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Summary',
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D2D2D),
              fontFamily: 'Roboto',
            ),
          ),
          SizedBox(height: screenWidth * 0.03),
          _buildPaymentRow('Subtotal', subtotal.toStringAsFixed(2), screenWidth),
          _buildPaymentRow('Delivery Fee', deliveryFees.toString(), screenWidth),
          Divider(
            color: const Color(0xFFE5E5E5),
            height: screenWidth * 0.06,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D2D2D),
                  fontFamily: 'Roboto',
                ),
              ),
              Text(
                '₹${totalAmount}',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFE17A47),
                  fontFamily: 'Roboto',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String amount, double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.01),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF666666),
              fontFamily: 'Roboto',
            ),
          ),
          Text(
            '₹${amount}',
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF2D2D2D),
              fontFamily: 'Roboto',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, OrderDetailsError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Colors.grey.shade600,
                fontFamily: 'Montserrat',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<OrderDetailsBloc>().add(LoadOrderDetails(orderId));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE17A47),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
      case 'PREPARING':
        return const Color(0xFFFF9800);
      case 'DELIVERED':
      case 'COMPLETED':
        return const Color(0xFF4CAF50);
      case 'CANCELLED':
        return const Color(0xFFF44336);
      case 'CONFIRMED':
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFF666666);
    }
  }

  String _getStatusDisplayText(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Pending';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'PREPARING':
        return 'Preparing';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      case 'COMPLETED':
        return 'Completed';
      default:
        return status;
    }
  }
}
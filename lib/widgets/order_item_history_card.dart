import 'package:flutter/material.dart';
import '../constants/color/colorConstant.dart';
import '../constants/font/fontManager.dart';
import '../presentation/order_history/state.dart';

class OrderItemCard extends StatelessWidget {
  final OrderItem order;
  final VoidCallback onViewDetails;

  const OrderItemCard({
    Key? key,
    required this.order,
    required this.onViewDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      margin: EdgeInsets.only(bottom: screenWidth * 0.04),
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildOrderImage(context),
          SizedBox(width: screenWidth * 0.04),
          Expanded(
            child: _buildOrderInfo(context),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderImage(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      width: screenWidth * 0.17,
      height: screenWidth * 0.17,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(screenWidth * 0.03),
        child: _buildImageWidget(context),
      ),
    );
  }

  Widget _buildImageWidget(BuildContext context) {
    // Using realistic food images based on the photo
    switch (order.name) {
      case 'Chicken Burger Combo':
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
            image: const DecorationImage(
              image: NetworkImage('https://images.unsplash.com/photo-1568901346375-23c9450c58cd?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80'),
              fit: BoxFit.cover,
            ),
          ),
        );
      case 'Grilled Chicken Salad':
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
            image: const DecorationImage(
              image: NetworkImage('https://images.unsplash.com/photo-1512621776951-a57141f2eefd?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80'),
              fit: BoxFit.cover,
            ),
          ),
        );
      case 'Pasta Carbonara':
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
            image: const DecorationImage(
              image: NetworkImage('https://images.unsplash.com/photo-1621996346565-e3dbc353d2e5?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80'),
              fit: BoxFit.cover,
            ),
          ),
        );
      case 'Margherita Pizza':
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
            image: const DecorationImage(
              image: NetworkImage('https://images.unsplash.com/photo-1574071318508-1cdbab80d002?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80'),
              fit: BoxFit.cover,
            ),
          ),
        );
      case 'Sushi Platter':
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
            image: const DecorationImage(
              image: NetworkImage('https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=1000&q=80'),
              fit: BoxFit.cover,
            ),
          ),
        );
      default:
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.03),
            color: Colors.grey.shade300,
          ),
          child: Center(
            child: Icon(
              Icons.restaurant,
              color: Colors.white,
              size: MediaQuery.of(context).size.width * 0.06,
            ),
          ),
        );
    }
  }

  Widget _buildOrderInfo(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.name,
                    style: TextStyle(
                      fontSize: screenWidth * 0.038,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2D2D2D),
                      fontFamily: 'Roboto',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: screenWidth * 0.008),
                  Text(
                    '${order.restaurantName} • ${order.date}',
                    style: TextStyle(
                      fontSize: screenWidth * 0.032,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF8E8E93),
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '\$${order.price.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: screenWidth * 0.038,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFE17A47),
                fontFamily: 'Roboto',
              ),
            ),
          ],
        ),
        SizedBox(height: screenWidth * 0.035),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatusChip(context),
            _buildViewDetailsButton(context),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    Color statusColor;
    
    switch (order.status.toLowerCase()) {
      case 'delivered':
      case 'completed':
        statusColor = const Color(0xFF4CAF50);
        break;
      case 'cancelled':
        statusColor = const Color(0xFFF44336);
        break;
      case 'ongoing':
      case 'preparing':
        statusColor = const Color(0xFFFF9800);
        break;
      default:
        statusColor = const Color(0xFF9E9E9E);
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.025,
        vertical: screenWidth * 0.015,
      ),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(screenWidth * 0.015),
      ),
      child: Text(
        order.status,
        style: TextStyle(
          fontSize: screenWidth * 0.032,
          fontWeight: FontWeight.w500,
          color: statusColor,
          fontFamily: 'Roboto',
        ),
      ),
    );
  }

  Widget _buildViewDetailsButton(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return GestureDetector(
      onTap: onViewDetails,
      child: Text(
        'View Details',
        style: TextStyle(
          fontSize: screenWidth * 0.032,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFE17A47),
          fontFamily: 'Roboto',
        ),
      ),
    );
  }
}
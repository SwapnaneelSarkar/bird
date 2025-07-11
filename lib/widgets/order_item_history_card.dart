// lib/widgets/order_item_history_card.dart - Updated with Chat Support button
import 'package:flutter/material.dart';
import '../presentation/order_history/state.dart';
import '../constants/api_constant.dart';

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
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.015),
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
            children: [
              // Order Image
              Container(
                width: screenWidth * 0.15,
                height: screenWidth * 0.15,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  color: Colors.grey.shade200,
                ),
                child: order.imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        child: Image.network(
                          _getFullImageUrl(order.imageUrl),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.fastfood,
                              color: Colors.grey.shade500,
                              size: screenWidth * 0.08,
                            );
                          },
                        ),
                      )
                    : Icon(
                        Icons.fastfood,
                        color: Colors.grey.shade500,
                        size: screenWidth * 0.08,
                      ),
              ),
              
              SizedBox(width: screenWidth * 0.03),
              
              // Order Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.restaurantName,
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2D2D2D),
                        fontFamily: 'Roboto',
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    _buildItemsDisplay(order.items, screenWidth),
                    SizedBox(height: screenHeight * 0.005),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            order.date,
                            style: TextStyle(
                              fontSize: screenWidth * 0.03,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF999999),
                              fontFamily: 'Roboto',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.02,
                              vertical: screenHeight * 0.003,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(order.status),
                              borderRadius: BorderRadius.circular(screenWidth * 0.01),
                            ),
                            child: Text(
                              order.status,
                              style: TextStyle(
                                fontSize: screenWidth * 0.025,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                                fontFamily: 'Roboto',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Price
              Text(
                '₹${order.price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2D2D2D),
                  fontFamily: 'Roboto',
                ),
              ),
            ],
          ),
          
          SizedBox(height: screenHeight * 0.015),
          
          // Action Buttons Row - REPLACED CHAT SUPPORT BUTTON WITH ICON
          Row(
            children: [
              // View Details Button
              Expanded(
                child: GestureDetector(
                  onTap: onViewDetails,
                  child: Container(
                    height: screenHeight * 0.045,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(screenWidth * 0.02),
                      border: Border.all(
                        color: const Color(0xFFE17A47),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFE17A47),
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              // Chat Icon Button - REPLACEMENT
              Container(
                height: screenHeight * 0.045,
                width: screenHeight * 0.045,
                decoration: BoxDecoration(
                  color: const Color(0xFFE17A47),
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                ),
                child: IconButton(
                  icon: Icon(Icons.chat, color: Colors.white, size: screenWidth * 0.06),
                  tooltip: 'Chat',
                  onPressed: () {
                    debugPrint('OrderItemCard: Opening chat for order:  order.id');
                    if (order.id.isNotEmpty) {
                      Navigator.of(context).pushNamed('/chat', arguments: order.id);
                    } else {
                      debugPrint('OrderItemCard: Order ID is empty, cannot open chat');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Unable to open chat: Order ID missing'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to build items display
  Widget _buildItemsDisplay(List<Map<String, dynamic>> items, double screenWidth) {
    if (items.isEmpty) {
      return Text(
        'No items',
        style: TextStyle(
          fontSize: screenWidth * 0.035,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF666666),
          fontFamily: 'Roboto',
        ),
      );
    }

    // Create a map to group items by name and sum their quantities
    Map<String, int> itemCounts = {};
    for (var item in items) {
      String itemName = item['name']?.toString() ?? 'Unknown Item';
      int quantity = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
      itemCounts[itemName] = (itemCounts[itemName] ?? 0) + quantity;
    }

    // Convert to list and sort by quantity (descending)
    List<MapEntry<String, int>> sortedItems = itemCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Show first 2 items, then "more" if there are more
    if (sortedItems.length <= 2) {
      // Show all items
      String displayText = sortedItems.map((entry) => '${entry.value}x${entry.key}').join(', ');
      return Text(
        displayText,
        style: TextStyle(
          fontSize: screenWidth * 0.035,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF666666),
          fontFamily: 'Roboto',
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    } else {
      // Show first 2 items + "more"
      String firstTwoItems = sortedItems.take(2).map((entry) => '${entry.value}x${entry.key}').join(', ');
      return Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onViewDetails,
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$firstTwoItems, ',
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF666666),
                        fontFamily: 'Roboto',
                      ),
                    ),
                    TextSpan(
                      text: 'more',
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFE17A47),
                        fontFamily: 'Roboto',
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
      case 'completed':
        return Colors.green;
      case 'cancelled':
      case 'canceled':
        return Colors.red;
      case 'preparing':
      case 'pending':
      case 'ongoing':
      case 'in_progress':
      case 'processing':
        return Colors.orange;
      case 'confirmed':
      case 'accepted':
        return Colors.blue;
      case 'out_for_delivery':
      case 'on_the_way':
        return Colors.purple;
      default:
        return const Color(0xFFE17A47);
    }
  }

  // Helper method to get the full image URL
  String _getFullImageUrl(String imagePath) {
    if (imagePath.isEmpty) {
      return '';
    }
    
    // Handle JSON-encoded URLs (remove quotes and brackets if present)
    String cleanPath = imagePath;
    if (cleanPath.startsWith('["') && cleanPath.endsWith('"]')) {
      cleanPath = cleanPath.substring(2, cleanPath.length - 2);
    } else if (cleanPath.startsWith('"') && cleanPath.endsWith('"')) {
      cleanPath = cleanPath.substring(1, cleanPath.length - 1);
    }
    
    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      return cleanPath;
    }
    return '${ApiConstants.baseUrl}/api/${cleanPath.startsWith('/') ? cleanPath.substring(1) : cleanPath}';
  }
}
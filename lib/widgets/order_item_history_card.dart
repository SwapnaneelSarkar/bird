// lib/widgets/order_item_history_card.dart - Optimized version
import 'package:flutter/material.dart';
import '../presentation/order_history/state.dart';
import '../constants/api_constant.dart';
import '../utils/currency_utils.dart';
import '../service/reorder_service.dart';

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
          _buildOrderHeader(context, screenWidth, screenHeight),
          SizedBox(height: screenHeight * 0.015),
          _buildActionButtons(context, screenWidth, screenHeight),
        ],
      ),
    );
  }

  Widget _buildOrderHeader(BuildContext context, double screenWidth, double screenHeight) {
    return Row(
      children: [
        _buildOrderImage(screenWidth),
        SizedBox(width: screenWidth * 0.03),
        Expanded(
          child: _buildOrderDetails(context, screenWidth, screenHeight),
        ),
        _buildOrderPrice(context, screenWidth),
      ],
    );
  }

  Widget _buildOrderImage(double screenWidth) {
    return Container(
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
    );
  }

  Widget _buildOrderDetails(BuildContext context, double screenWidth, double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRestaurantNameAndStatus(screenWidth, screenHeight),
        SizedBox(height: screenHeight * 0.005),
        if (order.restaurantAddress != null && order.restaurantAddress!.isNotEmpty)
          _buildRestaurantAddress(screenWidth),
        SizedBox(height: screenHeight * 0.005),
        _buildItemsDisplay(order.items, screenWidth),
        SizedBox(height: screenHeight * 0.005),
        if (order.rating != null) _buildRating(screenWidth),
        SizedBox(height: screenHeight * 0.005),
        _buildDateAndDeliveryAddress(screenWidth, screenHeight),
      ],
    );
  }

  Widget _buildRestaurantNameAndStatus(double screenWidth, double screenHeight) {
    return Row(
      children: [
        Expanded(
          child: Text(
            order.restaurantName,
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D2D2D),
              fontFamily: 'Roboto',
            ),
          ),
        ),
        SizedBox(width: screenWidth * 0.02),
        Container(
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
      ],
    );
  }

  Widget _buildRestaurantAddress(double screenWidth) {
    return Text(
      order.restaurantAddress!,
      style: TextStyle(
        fontSize: screenWidth * 0.03,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF666666),
        fontFamily: 'Roboto',
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildRating(double screenWidth) {
    return Row(
      children: [
        Icon(
          Icons.star,
          size: screenWidth * 0.03,
          color: Colors.amber,
        ),
        SizedBox(width: screenWidth * 0.01),
        Text(
          '${order.rating!.toStringAsFixed(1)}',
          style: TextStyle(
            fontSize: screenWidth * 0.03,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF666666),
            fontFamily: 'Roboto',
          ),
        ),
      ],
    );
  }

  Widget _buildDateAndDeliveryAddress(double screenWidth, double screenHeight) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          order.date,
          style: TextStyle(
            fontSize: screenWidth * 0.03,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF999999),
            fontFamily: 'Roboto',
          ),
          overflow: TextOverflow.ellipsis,
        ),
        if (order.deliveryAddress != null && order.deliveryAddress!.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: screenHeight * 0.003),
            child: Text(
              '📍 ${order.deliveryAddress!}',
              style: TextStyle(
                fontSize: screenWidth * 0.03,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF666666),
                fontFamily: 'Roboto',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _buildOrderPrice(BuildContext context, double screenWidth) {
    return FutureBuilder<String>(
      future: CurrencyUtils.getCurrencySymbolFromUserLocation(),
      builder: (context, snapshot) {
        final currencySymbol = snapshot.data ?? '₹';
        return Text(
          CurrencyUtils.formatPrice(order.price, currencySymbol),
          style: TextStyle(
            fontSize: screenWidth * 0.04,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2D2D2D),
            fontFamily: 'Roboto',
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context, double screenWidth, double screenHeight) {
    return Row(
      children: [
        _buildViewDetailsButton(screenWidth, screenHeight),
        SizedBox(width: screenWidth * 0.03),
        if (_shouldShowReorderButton()) _buildReorderButton(context, screenWidth, screenHeight),
        if (_shouldShowReorderButton()) SizedBox(width: screenWidth * 0.03),
        _buildChatButton(context, screenWidth, screenHeight),
      ],
    );
  }

  Widget _buildViewDetailsButton(double screenWidth, double screenHeight) {
    return Expanded(
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
    );
  }

  Widget _buildReorderButton(BuildContext context, double screenWidth, double screenHeight) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _handleReorder(context),
        child: Container(
          height: screenHeight * 0.045,
          decoration: BoxDecoration(
            color: const Color(0xFF4CAF50),
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
          ),
          child: Center(
            child: Text(
              'Reorder',
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                fontFamily: 'Roboto',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatButton(BuildContext context, double screenWidth, double screenHeight) {
    return Container(
      height: screenHeight * 0.045,
      width: screenHeight * 0.045,
      decoration: BoxDecoration(
        color: const Color(0xFFE17A47),
        borderRadius: BorderRadius.circular(screenWidth * 0.02),
      ),
      child: IconButton(
        icon: Icon(Icons.chat, color: Colors.white, size: screenWidth * 0.06),
        tooltip: 'Chat',
        onPressed: () => _handleChat(context),
      ),
    );
  }

  bool _shouldShowReorderButton() {
    return order.status.toUpperCase() == 'DELIVERED' || order.status.toUpperCase() == 'COMPLETED';
  }

  void _handleChat(BuildContext context) {
    if (order.id.isNotEmpty) {
      Navigator.of(context).pushNamed('/chat', arguments: order.id);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open chat: Order ID missing'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleReorder(BuildContext context) async {
    try {
      _showLoadingDialog(context);
      
      final result = await ReorderService.reorderFromOrderData(
        items: order.items,
        partnerId: order.restaurantId,
      );

      _hideLoadingDialog(context);

      if (result['success']) {
        _showSuccessMessage(context, result['message']);
        Navigator.of(context).pushNamed('/cart');
      } else {
        _showErrorMessage(context, result['message']);
      }
    } catch (e) {
      _hideLoadingDialog(context);
      _showErrorMessage(context, 'An error occurred while reordering');
    }
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFE17A47),
          ),
        );
      },
    );
  }

  void _hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _showSuccessMessage(BuildContext context, String? message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? 'Items added to cart successfully'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorMessage(BuildContext context, String? message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message ?? 'Failed to reorder'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

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

    final itemCounts = _getItemCounts(items);
    final sortedItems = _getSortedItems(itemCounts);

    if (sortedItems.length <= 2) {
      return _buildSimpleItemsDisplay(sortedItems, screenWidth);
    } else {
      return _buildComplexItemsDisplay(sortedItems, screenWidth);
    }
  }

  Map<String, int> _getItemCounts(List<Map<String, dynamic>> items) {
    final Map<String, int> itemCounts = {};
    for (var item in items) {
      final itemName = item['item_name']?.toString() ?? item['name']?.toString() ?? 'Unknown Item';
      final quantity = int.tryParse(item['quantity']?.toString() ?? '1') ?? 1;
      itemCounts[itemName] = (itemCounts[itemName] ?? 0) + quantity;
    }
    return itemCounts;
  }

  List<MapEntry<String, int>> _getSortedItems(Map<String, int> itemCounts) {
    final sortedItems = itemCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedItems;
  }

  Widget _buildSimpleItemsDisplay(List<MapEntry<String, int>> sortedItems, double screenWidth) {
    final displayText = sortedItems.map((entry) => '${entry.value}x${entry.key}').join(', ');
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
  }

  Widget _buildComplexItemsDisplay(List<MapEntry<String, int>> sortedItems, double screenWidth) {
    final firstTwoItems = sortedItems.take(2).map((entry) => '${entry.value}x${entry.key}').join(', ');
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

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DELIVERED':
      case 'COMPLETED':
        return Colors.green;
      case 'CANCELLED':
      case 'CANCELED':
        return Colors.red;
      case 'PREPARING':
      case 'PENDING':
      case 'ONGOING':
      case 'IN_PROGRESS':
      case 'PROCESSING':
        return Colors.orange;
      case 'CONFIRMED':
      case 'ACCEPTED':
        return Colors.blue;
      case 'OUT_FOR_DELIVERY':
      case 'ON_THE_WAY':
        return Colors.purple;
      default:
        return const Color(0xFFE17A47);
    }
  }

  String _getFullImageUrl(String imagePath) {
    if (imagePath.isEmpty) return '';
    
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
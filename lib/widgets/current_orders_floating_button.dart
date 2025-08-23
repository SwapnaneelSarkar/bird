import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/color/colorConstant.dart';
import '../constants/router/router.dart';
import '../service/current_orders_sse_service.dart';
import '../utils/currency_utils.dart';
import '../utils/timezone_utils.dart';

class CurrentOrdersFloatingButton extends StatefulWidget {
  final String? token;
  final String? selectedSupercategoryId;
  final Function(bool isVisible)? onVisibilityChanged; // Add callback for visibility changes

  const CurrentOrdersFloatingButton({
    Key? key,
    this.token,
    this.selectedSupercategoryId,
    this.onVisibilityChanged, // Add callback parameter
  }) : super(key: key);

  @override
  State<CurrentOrdersFloatingButton> createState() => _CurrentOrdersFloatingButtonState();
}

class _CurrentOrdersFloatingButtonState extends State<CurrentOrdersFloatingButton>
    with TickerProviderStateMixin {
  final CurrentOrdersSSEService _sseService = CurrentOrdersSSEService();
  CurrentOrdersUpdate? _currentOrdersUpdate;
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    debugPrint('🎯 CurrentOrdersFloatingButton: Initializing widget');
    debugPrint('🎯 CurrentOrdersFloatingButton: Token provided: ${widget.token != null ? 'Yes (${widget.token!.length} chars)' : 'No'}');
    debugPrint('🎯 CurrentOrdersFloatingButton: Selected supercategory: ${widget.selectedSupercategoryId ?? 'None'}');
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    if (widget.token != null) {
      debugPrint('🎯 CurrentOrdersFloatingButton: Token available, connecting to SSE...');
      debugPrint('🎯 CurrentOrdersFloatingButton: Token length: ${widget.token!.length}');
      _connectToSSE();
    } else {
      debugPrint('🎯 CurrentOrdersFloatingButton: No token provided, skipping SSE connection');
      debugPrint('🎯 CurrentOrdersFloatingButton: widget.token is null');
    }
  }

  @override
  void dispose() {
    debugPrint('🎯 CurrentOrdersFloatingButton: Disposing widget');
    _animationController.dispose();
    _sseService.dispose();
    super.dispose();
    debugPrint('🎯 CurrentOrdersFloatingButton: Widget disposed');
  }

  Future<void> _connectToSSE() async {
    debugPrint('🎯 CurrentOrdersFloatingButton: Starting SSE connection...');
    try {
      await _sseService.connect(widget.token!);
      debugPrint('🎯 CurrentOrdersFloatingButton: SSE connection established');
      
              _sseService.ordersStream.listen(
          (update) {
            debugPrint('🎯 CurrentOrdersFloatingButton: Received order update');
            debugPrint('🎯 CurrentOrdersFloatingButton: hasCurrentOrders: ${update.hasCurrentOrders}');
            debugPrint('🎯 CurrentOrdersFloatingButton: ordersCount: ${update.ordersCount}');
            debugPrint('🎯 CurrentOrdersFloatingButton: orders.length: ${update.orders.length}');
            
            if (update.orders.isNotEmpty) {
              debugPrint('🎯 CurrentOrdersFloatingButton: First order ID: ${update.orders.first.orderId}');
              debugPrint('🎯 CurrentOrdersFloatingButton: First order status: ${update.orders.first.orderStatus}');
            }
            
            setState(() {
              _currentOrdersUpdate = update;
            });
            
            debugPrint('🎯 CurrentOrdersFloatingButton: State updated with new order data');
            debugPrint('🎯 CurrentOrdersFloatingButton: Will rebuild widget with orders');
          },
          onError: (error) {
            debugPrint('❌ CurrentOrdersFloatingButton: SSE stream error: $error');
          },
        );
      
      debugPrint('🎯 CurrentOrdersFloatingButton: SSE stream listener set up successfully');
    } catch (e) {
      debugPrint('❌ CurrentOrdersFloatingButton: Failed to connect to SSE: $e');
    }
  }

  void _toggleExpanded() {
    debugPrint('🎯 CurrentOrdersFloatingButton: Toggling expanded state from $_isExpanded to ${!_isExpanded}');
    
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      debugPrint('🎯 CurrentOrdersFloatingButton: Starting expand animation');
      _animationController.forward();
    } else {
      debugPrint('🎯 CurrentOrdersFloatingButton: Starting collapse animation');
      _animationController.reverse();
    }
  }

  void _navigateToOrderDetails(String orderId) {
    debugPrint('🎯 CurrentOrdersFloatingButton: Navigating to order details for order ID: $orderId');
    Navigator.pushNamed(
      context,
      Routes.orderDetails,
      arguments: orderId,
    );
  }

  void _showOrdersModal() {
    debugPrint('🎯 CurrentOrdersFloatingButton: Showing orders modal');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildOrdersModal(),
    );
  }

  Widget _buildOrdersModal() {
    final filteredOrders = _getFilteredOrders();
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorManager.primary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.delivery_dining,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Current Orders (${filteredOrders.length})',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          // Orders list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: filteredOrders.length,
              itemBuilder: (context, index) {
                final order = filteredOrders[index];
                return _buildOrderCard(order, index == filteredOrders.length - 1);
              },
            ),
          ),
        ],
      ),
    );
  }

  List<CurrentOrder> _getFilteredOrders() {
    debugPrint('🎯 CurrentOrdersFloatingButton: Getting filtered orders');
    debugPrint('🎯 CurrentOrdersFloatingButton: Current orders update: ${_currentOrdersUpdate != null ? 'Available' : 'None'}');
    
    if (_currentOrdersUpdate?.orders == null) {
      debugPrint('🎯 CurrentOrdersFloatingButton: No orders available');
      return [];
    }
    
    debugPrint('🎯 CurrentOrdersFloatingButton: Total orders: ${_currentOrdersUpdate!.orders.length}');
    debugPrint('🎯 CurrentOrdersFloatingButton: Selected supercategory: ${widget.selectedSupercategoryId ?? 'None'}');
    
    if (widget.selectedSupercategoryId == null || widget.selectedSupercategoryId!.isEmpty) {
      debugPrint('🎯 CurrentOrdersFloatingButton: No supercategory filter, returning all orders');
      return _currentOrdersUpdate!.orders;
    }
    
    final filteredOrders = _currentOrdersUpdate!.orders
        .where((order) => order.supercategory == widget.selectedSupercategoryId)
        .toList();
    
    debugPrint('🎯 CurrentOrdersFloatingButton: Filtered orders count: ${filteredOrders.length}');
    if (filteredOrders.isNotEmpty) {
      debugPrint('🎯 CurrentOrdersFloatingButton: First filtered order ID: ${filteredOrders.first.orderId}');
    }
    
    return filteredOrders;
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🎯 CurrentOrdersFloatingButton: Building widget');
    debugPrint('🎯 CurrentOrdersFloatingButton: _currentOrdersUpdate is null: ${_currentOrdersUpdate == null}');
    
    final filteredOrders = _getFilteredOrders();
    final hasOrders = _currentOrdersUpdate?.hasCurrentOrders == true && filteredOrders.isNotEmpty;
    final hasToken = widget.token != null;
    final hasSSEData = _currentOrdersUpdate != null;
    
    debugPrint('🎯 CurrentOrdersFloatingButton: hasCurrentOrders: ${_currentOrdersUpdate?.hasCurrentOrders}');
    debugPrint('🎯 CurrentOrdersFloatingButton: filteredOrders.isNotEmpty: ${filteredOrders.isNotEmpty}');
    debugPrint('🎯 CurrentOrdersFloatingButton: hasOrders: $hasOrders');
    debugPrint('🎯 CurrentOrdersFloatingButton: hasToken: $hasToken');
    debugPrint('🎯 CurrentOrdersFloatingButton: hasSSEData: $hasSSEData');
    debugPrint('🎯 CurrentOrdersFloatingButton: filteredOrders.length: ${filteredOrders.length}');
    debugPrint('🎯 CurrentOrdersFloatingButton: _isExpanded: $_isExpanded');

    // Notify parent about visibility change
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Determine if button should be visible for padding purposes
      bool shouldShowPadding = hasToken && (hasSSEData ? hasOrders : true);
      widget.onVisibilityChanged?.call(shouldShowPadding);
    });

    // Show placeholder button when no token (user not logged in)
    if (!hasToken) {
      debugPrint('🎯 CurrentOrdersFloatingButton: No token, showing placeholder button');
      return Container(
        width: MediaQuery.of(context).size.width * 0.6,
        height: 56,
        child: FloatingActionButton.extended(
          onPressed: () {
            debugPrint('🎯 CurrentOrdersFloatingButton: Placeholder button pressed');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Please login to view current orders',
                  style: GoogleFonts.poppins(),
                ),
                duration: const Duration(seconds: 2),
                backgroundColor: ColorManager.primary,
              ),
            );
          },
          backgroundColor: ColorManager.primary,
          label: Text(
            'Current Orders',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
          icon: Icon(
            Icons.delivery_dining,
            color: Colors.white,
            size: 20,
          ),
        ),
      );
    }

    // Hide button when we explicitly know there are no current orders
    if (hasSSEData && !hasOrders) {
      debugPrint('🎯 CurrentOrdersFloatingButton: SSE data available and no current orders, hiding button');
      return const SizedBox.shrink();
    }

    // Show loading state when we have token but no SSE data yet
    if (hasToken && !hasSSEData) {
      debugPrint('🎯 CurrentOrdersFloatingButton: Token available but no SSE data yet, showing loading button');
      return Container(
        width: MediaQuery.of(context).size.width * 0.6,
        height: 56,
        child: FloatingActionButton.extended(
          onPressed: () {
            debugPrint('🎯 CurrentOrdersFloatingButton: Loading button pressed');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Loading current orders...',
                  style: GoogleFonts.poppins(),
                ),
                duration: const Duration(seconds: 2),
                backgroundColor: ColorManager.primary,
              ),
            );
          },
          backgroundColor: ColorManager.primary,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Loading Orders...',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show the actual button when we have current orders
    debugPrint('🎯 CurrentOrdersFloatingButton: Building actual button with orders');
    return Container(
      width: MediaQuery.of(context).size.width * 0.6,
      height: 56,
      child: FloatingActionButton.extended(
        onPressed: () {
          debugPrint('🎯 CurrentOrdersFloatingButton: Main button pressed, showing modal');
          _showOrdersModal();
        },
        backgroundColor: ColorManager.primary,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.delivery_dining,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Current Orders (${filteredOrders.length})',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
        
  }

  Widget _buildOrderCard(CurrentOrder order, bool isLast) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 1),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: isLast ? BorderSide.none : BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _toggleExpanded();
            _navigateToOrderDetails(order.orderId);
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Status indicator
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getOrderStatusColor(order.orderStatus),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                // Order details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.restaurantName,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Order #${order.orderId}',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Add date and time in IST
                      Text(
                        _formatOrderDateTime(order.createdAt),
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                                                     FutureBuilder<String>(
                             future: _formatPrice(order.totalPrice),
                             builder: (context, snapshot) {
                               return Text(
                                 snapshot.data ?? order.totalPrice,
                                 style: GoogleFonts.poppins(
                                   fontSize: 11,
                                   fontWeight: FontWeight.w600,
                                   color: ColorManager.primary,
                                 ),
                               );
                             },
                           ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getOrderStatusColor(order.orderStatus).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _formatOrderStatus(order.orderStatus),
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                                color: _getOrderStatusColor(order.orderStatus),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getOrderStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING': return const Color(0xFFFF9800);
      case 'CONFIRMED': return const Color(0xFF4CAF50);
      case 'PREPARING': return const Color(0xFF2196F3);
      case 'OUT_FOR_DELIVERY': return const Color(0xFF9C27B0);
      case 'DELIVERED': return const Color(0xFF4CAF50);
      case 'CANCELLED': return const Color(0xFFF44336);
      default: return Colors.grey;
    }
  }

  String _formatOrderStatus(String status) {
    switch (status.toUpperCase()) {
      case 'OUT_FOR_DELIVERY': return 'Out for Delivery';
      case 'PENDING': return 'Pending';
      case 'CONFIRMED': return 'Confirmed';
      case 'PREPARING': return 'Preparing';
      case 'DELIVERED': return 'Delivered';
      case 'CANCELLED': return 'Cancelled';
      default: return status;
    }
  }

  Future<String> _formatPrice(String priceString) async {
    try {
      final price = double.tryParse(priceString);
      if (price != null) {
        return await CurrencyUtils.formatPriceWithUserCurrency(price);
      }
    } catch (e) {
      print('Error formatting price: $e');
    }
    return priceString;
  }

  // Add method to format order date and time in IST
  String _formatOrderDateTime(String dateTimeString) {
    try {
      final dateTime = TimezoneUtils.parseToIST(dateTimeString);
      return TimezoneUtils.formatOrderDateTime(dateTime);
    } catch (e) {
      debugPrint('Error formatting order date time: $e');
      return 'Date not available';
    }
  }
} 
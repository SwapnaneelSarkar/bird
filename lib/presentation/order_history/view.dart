// lib/presentation/order_history/view.dart - Updated with navigation to order details
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../constants/color/colorConstant.dart';
import '../../constants/font/fontManager.dart';
import '../../widgets/order_item_history_card.dart';
import '../order_details/view.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';

class OrderHistoryView extends StatelessWidget {
  const OrderHistoryView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrderHistoryBloc()..add(const LoadOrderHistory()),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F8F8),
        body: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: BlocBuilder<OrderHistoryBloc, OrderHistoryState>(
                  builder: (context, state) {
                    if (state is OrderHistoryLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFE17A47),
                        ),
                      );
                    } else if (state is OrderHistoryLoaded) {
                      return _buildOrderHistoryContent(context, state);
                    } else if (state is OrderHistoryError) {
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
                'Order History',
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

  Widget _buildOrderHistoryContent(BuildContext context, OrderHistoryLoaded state) {
    return Column(
      children: [
        _buildFilterTabs(context, state),
        Expanded(
          child: _buildOrdersList(context, state),
        ),
      ],
    );
  }

  Widget _buildFilterTabs(BuildContext context, OrderHistoryLoaded state) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      height: screenWidth * 0.2,
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.05, 
        vertical: screenWidth * 0.04
      ),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: state.filterTabs.map((filter) {
                  final isSelected = filter == state.selectedFilter;
                  return GestureDetector(
                    onTap: () {
                      context.read<OrderHistoryBloc>().add(
                        FilterOrdersByStatus(filter),
                      );
                    },
                    child: Container(
                      margin: EdgeInsets.only(right: screenWidth * 0.04),
                      padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.05,
                        vertical: screenWidth * 0.03,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? const Color(0xFFE17A47) 
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(screenWidth * 0.06),
                        border: Border.all(
                          color: isSelected 
                              ? const Color(0xFFE17A47) 
                              : const Color(0xFFE0E0E0),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          fontWeight: isSelected 
                              ? FontWeight.w500 
                              : FontWeight.w400,
                          color: isSelected 
                              ? Colors.white 
                              : const Color(0xFF666666),
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(BuildContext context, OrderHistoryLoaded state) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (state.filteredOrders.isEmpty) {
      return _buildEmptyState(context, state.selectedFilter);
    }

    return ListView.builder(
      padding: EdgeInsets.all(screenWidth * 0.05),
      itemCount: state.filteredOrders.length,
      itemBuilder: (context, index) {
        final order = state.filteredOrders[index];
        return OrderItemCard(
          order: order,
          onViewDetails: () {
            context.read<OrderHistoryBloc>().add(
              ViewOrderDetails(order.id),
            );
            // Navigate to order details page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderDetailsView(orderId: order.id),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, String selectedFilter) {
    String emptyMessage;
    switch (selectedFilter) {
      case 'Preparing':
        emptyMessage = 'No preparing orders';
        break;
      case 'Completed':
        emptyMessage = 'No completed orders';
        break;
      case 'Cancelled':
        emptyMessage = 'No cancelled orders';
        break;
      default:
        emptyMessage = 'No orders found';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            emptyMessage,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
              fontFamily: 'Montserrat',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your orders will appear here',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.grey.shade500,
              fontFamily: 'Montserrat',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, OrderHistoryError state) {
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
                context.read<OrderHistoryBloc>().add(const LoadOrderHistory());
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
              child: Text(
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
}
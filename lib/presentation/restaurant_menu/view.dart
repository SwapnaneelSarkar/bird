// presentation/restaurant_menu/view.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bird/constants/color/colorConstant.dart';
import '../../constants/font/fontManager.dart';
import '../../constants/router/router.dart';
import '../../widgets/food_item_card.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';

class RestaurantDetailsPage extends StatelessWidget {
  final Map<String, dynamic> restaurantData;

  const RestaurantDetailsPage({
    Key? key,
    required this.restaurantData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (restaurantData.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Restaurant Details'),
          leading: const BackButton(),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Restaurant data not available', 
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Please try selecting a restaurant again', 
                style: TextStyle(fontSize: 14, color: Colors.grey[600])),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text('Go Back')
              ),
            ],
          ),
        ),
      );
    }
    
    return BlocProvider(
      create: (context) => RestaurantDetailsBloc()..add(LoadRestaurantDetails(restaurantData)),
      child: _RestaurantDetailsContent(),
    );
  }
}

class _RestaurantDetailsContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<RestaurantDetailsBloc, RestaurantDetailsState>(
        listener: (context, state) {
          if (state is CartUpdateSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message), 
                backgroundColor: Colors.green, 
                duration: const Duration(seconds: 2)
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is RestaurantDetailsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is RestaurantDetailsLoaded) {
            return _buildUpdatedContent(context, state);
          } else if (state is RestaurantDetailsError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message, style: const TextStyle(fontSize: 16, color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context), 
                    child: const Text('Go Back')
                  ),
                ],
              ),
            );
          }
          
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
  
  Widget _buildUpdatedContent(BuildContext context, RestaurantDetailsLoaded state) {
    Map<String, dynamic> restaurant = state.restaurant;
    
    return Column(
      children: [
        _buildSearchBar(context, restaurant),
        _buildRestaurantHeader(context, restaurant),
        _buildRecommendedHeader(),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: state.menu.length,
            itemBuilder: (context, index) {
              final menuItem = state.menu[index];
              final cartItem = state.cartItems.firstWhere(
                (item) => item['id'] == menuItem['id'],
                orElse: () => {"quantity": 0},
              );
              final quantity = cartItem['quantity'] ?? 0;
              
              return FoodItemCard(
                item: menuItem,
                quantity: quantity,
                onQuantityChanged: (newQuantity) {
                  context.read<RestaurantDetailsBloc>().add(
                    AddItemToCart(
                      item: menuItem,
                      quantity: newQuantity,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildSearchBar(BuildContext context, Map<String, dynamic> restaurant) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 0.5)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.arrow_back, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Colors.grey[400], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Search dishes...',
                      style: TextStyle(
                        color: Colors.grey[400], 
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.black),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  Routes.restaurantProfile,
                  arguments: restaurant['id'],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRestaurantHeader(BuildContext context, Map<String, dynamic> restaurant) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            restaurant['name'] ?? 'Restaurant',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.eco_outlined, color: Colors.green, size: 14),
                    const SizedBox(width: 4),
                    const Text('Pure Veg', 
                      style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${restaurant['distance'] ?? 1.2} Kms', 
                  style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500)
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      restaurant['rating']?.toString() ?? '4.3',
                      style: TextStyle(fontSize: 12, color: Colors.amber[800], fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecommendedHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Recommended for you', 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Icon(Icons.filter_list, color: Colors.grey[700], size: 16),
                const SizedBox(width: 2),
                Text('Filter', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
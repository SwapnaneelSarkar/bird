import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bird/constants/router/router.dart';
import 'package:bird/constants/color/colorConstant.dart';
import '../../../service/token_service.dart';
import '../../../widgets/restaurant_card.dart';
import '../address bottomSheet/view.dart';
import '../restaurant_menu/view.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';

class HomePage extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final String? token;

  const HomePage({
    Key? key,
    this.userData,
    this.token,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc()..add(const LoadHomeData()),
      child: _HomeContent(
        userData: userData,
        token: token,
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final String? token;

  const _HomeContent({
    Key? key,
    this.userData,
    this.token,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    debugPrint('HomePage - User Data: $userData');
    debugPrint('HomePage - Token: $token');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocConsumer<HomeBloc, HomeState>(
          listener: (context, state) {
            if (state is AddressUpdateSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Address updated to: ${state.address}'),
                  backgroundColor: Colors.green,
                ),
              );
            } else if (state is AddressUpdateFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.error),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is HomeLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (state is HomeLoaded) {
              return _buildHomeContent(context, state);
            } else if (state is HomeError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      state.message,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<HomeBloc>().add(const LoadHomeData());
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            } else if (state is AddressUpdating) {
              return Stack(
                children: [
                  _buildHomeContentPlaceholder(),
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ],
              );
            }
            
            // Initial state
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildHomeContentPlaceholder() {
    return Column(
      children: [
        Container(
          height: 80,
          color: Colors.grey[200],
        ),
        Expanded(
          child: Container(
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildHomeContent(BuildContext context, HomeLoaded state) {
    return Column(
      children: [
        // Address Bar
        _buildAddressBar(context, state),

        // Search Bar
        _buildSearchBar(context, state),

        // Main Content
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              context.read<HomeBloc>().add(const LoadHomeData());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Popular Categories
                  _buildCategoriesSection(context, state),
                  
                  // All Restaurants
                  _buildRestaurantsSection(context, state),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildAddressBar(BuildContext context, HomeLoaded state) {
    return InkWell(
      onTap: () => _showAddressPicker(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              color: ColorManager.primary,
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Deliver to',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          state.userAddress,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey[600],
                        size: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.account_circle_outlined),
              color: Colors.black87,
              iconSize: 26,
              onPressed: () {
                Navigator.pushNamed(context, Routes.profileView);
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSearchBar(BuildContext context, HomeLoaded state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: Colors.grey[500],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search restaurants...',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              Switch(
                value: state.vegOnly,
                onChanged: (value) {
                  context.read<HomeBloc>().add(ToggleVegOnly(value));
                },
                activeColor: Colors.green,
                activeTrackColor: Colors.green.withOpacity(0.5),
              ),
              const Text(
                'Veg Only',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoriesSection(BuildContext context, HomeLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
          child: Text(
            'Popular Categories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: state.categories.map((category) {
              return _buildCategoryItem(
                category['name'], 
                category['icon'],
                category['color'],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
  
  Widget _buildRestaurantsSection(BuildContext context, HomeLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header remains the same
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Restaurants',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Icon(
                Icons.filter_list,
                color: Colors.black87,
              ),
            ],
          ),
        ),
        
        // Restaurant List
        if (state.restaurants.isEmpty)
          _buildEmptyRestaurantsList()
        else
          ...state.restaurants.map((restaurant) {
            return RestaurantCard(
              name: restaurant['name'],
              imageUrl: restaurant['imageUrl'],
              cuisine: restaurant['cuisine'],
              rating: restaurant['rating'],
              price: restaurant['price'],
              deliveryTime: restaurant['deliveryTime'],
            onTap: () {
            debugPrint('Restaurant tapped: ${restaurant['name']}');
            debugPrint('Restaurant data: ${restaurant.toString()}');
            
            // DIRECT NAVIGATION: Skip named routes which might be causing the issue
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => RestaurantDetailsPage(
                  restaurantData: Map<String, dynamic>.from(restaurant),
                ),
              ),
            );
          },
            );
          }).toList(),
      ],
    );
  }
  
  Widget _buildEmptyRestaurantsList() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No restaurants available',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try changing your filters or location',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryItem(String title, String iconName, String colorName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                _getIconData(iconName),
                size: 30,
                color: _getCategoryColor(colorName),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'local_pizza':
        return Icons.local_pizza;
      case 'lunch_dining':
        return Icons.lunch_dining;
      case 'set_meal':
        return Icons.set_meal;
      case 'icecream':
        return Icons.icecream;
      case 'local_drink':
        return Icons.local_drink;
      default:
        return Icons.restaurant;
    }
  }
  
  Color _getCategoryColor(String colorName) {
    switch (colorName) {
      case 'red':
        return Colors.red;
      case 'amber':
        return Colors.amber;
      case 'blue':
        return Colors.blue;
      case 'pink':
        return Colors.pink;
      case 'teal':
        return Colors.teal;
      default:
        return Colors.orange;
    }
  }
  
  Future<void> _showAddressPicker(BuildContext context) async {
    try {
      debugPrint('HomePage: Opening address picker');
      
      // Show the address picker bottom sheet
      final result = await AddressPickerBottomSheet.show(context);
      
      if (result != null) {
        // Validate that we have coordinates
        final double latitude = result['latitude'] ?? 0.0;
        final double longitude = result['longitude'] ?? 0.0;
        
        debugPrint('HomePage: Address selected:');
        debugPrint('  Address: ${result['address']}');
        debugPrint('  Sub-address: ${result['subAddress']}');
        debugPrint('  Latitude: $latitude');
        debugPrint('  Longitude: $longitude');
        
        // Make sure we have valid coordinates
        if (latitude == 0.0 && longitude == 0.0) {
          debugPrint('HomePage: Warning - Got zero coordinates');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not get location coordinates. Please try again.'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        
        // Format the full address
        String fullAddress = result['address'];
        if (result['subAddress'].toString().isNotEmpty) {
          fullAddress += ', ${result['subAddress']}';
        }
        
        // Update the address through the bloc
        context.read<HomeBloc>().add(
          UpdateUserAddress(
            address: fullAddress,
            latitude: latitude,
            longitude: longitude,
          ),
        );
      }
    } catch (e) {
      debugPrint('HomePage: Error showing address picker: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error opening address picker. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
import 'package:flutter/material.dart';
import 'package:bird/constants/router/router.dart';
import 'package:bird/constants/color/colorConstant.dart';
import '../../service/token_service.dart';
import '../../service/profile_get_service.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final String? token;

  const HomePage({
    Key? key,
    this.userData,
    this.token,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool vegOnly = false;
  String _userAddress = '';
  bool _isAddressLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserAddress();
  }

  Future<void> _loadUserAddress() async {
    setState(() {
      _isAddressLoading = true;
    });

    try {
      // Get user ID and token
      final userId = await TokenService.getUserId();
      final token = await TokenService.getToken();

      if (userId != null && token != null) {
        // Create an instance of ProfileApiService
        final profileService = ProfileApiService();
        
        // Fetch user profile data
        final result = await profileService.getUserProfile(
          token: token,
          userId: userId,
        );

        if (result['success'] == true) {
          final userData = result['data'] as Map<String, dynamic>;
          
          setState(() {
            _userAddress = userData['address'] ?? 'Add delivery address';
            _isAddressLoading = false;
          });
          
          debugPrint('User address loaded: $_userAddress');
        } else {
          setState(() {
            _userAddress = 'Add delivery address';
            _isAddressLoading = false;
          });
          debugPrint('Failed to load address: ${result['message']}');
        }
      } else {
        setState(() {
          _userAddress = 'Add delivery address';
          _isAddressLoading = false;
        });
        debugPrint('User ID or token is null');
      }
    } catch (e) {
      setState(() {
        _userAddress = 'Add delivery address';
        _isAddressLoading = false;
      });
      debugPrint('Error loading user address: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('HomePage - User Data: ${widget.userData}');
    debugPrint('HomePage - Token: ${widget.token}');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Address Bar
            Padding(
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
                            _isAddressLoading
                            ? SizedBox(
                                width: 100,
                                child: Text(
                                  'Loading...',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              )
                            : Expanded(
                                child: Text(
                                  _userAddress,
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

            // Search Bar
            Padding(
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
                        value: vegOnly,
                        onChanged: (value) {
                          setState(() {
                            vegOnly = value;
                          });
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
            ),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Popular Categories
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
                        children: [
                          _buildCategoryItem('Pizza', 'assets/pizza.png'),
                          _buildCategoryItem('Burger', 'assets/burger.png'),
                          _buildCategoryItem('Sushi', 'assets/sushi.png'),
                          _buildCategoryItem('Desserts', 'assets/desserts.png'),
                          _buildCategoryItem('Drinks', 'assets/drinks.png'),
                        ],
                      ),
                    ),
                    
                    // All Restaurants
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
                    _buildRestaurantCard(
                      name: 'The Gourmet Kitchen',
                      imageUrl: 'assets/restaurant1.jpg',
                      cuisine: 'Italian, Continental',
                      rating: 4.8,
                      price: '₹200 for two',
                      deliveryTime: '20-25 mins',
                    ),
                    _buildRestaurantCard(
                      name: 'Cafe Bistro',
                      imageUrl: 'assets/restaurant2.jpg',
                      cuisine: 'Cafe, Continental',
                      rating: 4.5,
                      price: '₹150 for two',
                      deliveryTime: '15-20 mins',
                    ),
                    _buildRestaurantCard(
                      name: 'Sushi Master',
                      imageUrl: 'assets/restaurant3.jpg',
                      cuisine: 'Japanese, Asian',
                      rating: 4.7,
                      price: '₹300 for two',
                      deliveryTime: '25-30 mins',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String title, String imagePath) {
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
              child: Image.asset(
                imagePath,
                width: 40,
                height: 40,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    getIconData(title),
                    size: 30,
                    color: getCategoryColor(title),
                  );
                },
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

  IconData getIconData(String category) {
    switch (category.toLowerCase()) {
      case 'pizza':
        return Icons.local_pizza;
      case 'burger':
        return Icons.lunch_dining;
      case 'sushi':
        return Icons.set_meal;
      case 'desserts':
        return Icons.icecream;
      case 'drinks':
        return Icons.local_drink;
      default:
        return Icons.restaurant;
    }
  }

  Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'pizza':
        return Colors.red;
      case 'burger':
        return Colors.amber;
      case 'sushi':
        return Colors.blue;
      case 'desserts':
        return Colors.pink;
      case 'drinks':
        return Colors.teal;
      default:
        return Colors.orange;
    }
  }

  Widget _buildRestaurantCard({
    required String name,
    required String imageUrl,
    required String cuisine,
    required double rating,
    required String price,
    required String deliveryTime,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Restaurant Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.asset(
              imageUrl,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 180,
                  width: double.infinity,
                  color: Colors.grey[200],
                  child: Center(
                    child: Icon(
                      Icons.restaurant,
                      size: 50,
                      color: Colors.grey[400],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Restaurant Info
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Text(
                            rating.toString(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: Colors.yellow,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  cuisine,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      deliveryTime,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
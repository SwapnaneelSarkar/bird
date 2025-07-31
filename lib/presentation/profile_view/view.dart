import 'package:bird/presentation/order_history/view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../../constants/api_constant.dart';
import '../../constants/router/router.dart';
import '../privacy_policy/view.dart';
import '../terms_conditions/view.dart';
import '../address bottomSheet/view.dart';
import '../address bottomSheet/bloc.dart';
import '../address bottomSheet/state.dart';
import '../address bottomSheet/event.dart';
import '../order_details/view.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';
import 'package:share_plus/share_plus.dart';
import '../../constants/color/colorConstant.dart';
import '../../utils/timezone_utils.dart';

const List<BoxShadow> softBoxShadow = [
  BoxShadow(
    color: Color(0x0D000000), // black with 5% opacity
    blurRadius: 4,
    spreadRadius: 0.5,
    offset: Offset(0, 2),
  ),
];

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        // Tab index changed
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return BlocProvider(
      create: (_) => ProfileBloc()..add(LoadProfile()),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F8F8),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          title: const Text('Profile', style: TextStyle(color: Colors.black)),
          leading: const BackButton(color: Colors.black),
          actions: [
            BlocBuilder<ProfileBloc, ProfileState>(
              builder: (context, state) {
                if (state is ProfileLoaded) {
                  return IconButton(
                    icon: const Icon(
                      Icons.logout,
                      color: Colors.red,
                      size: 24,
                    ),
                    onPressed: () {
                      _showLogoutDialog(context);
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is ProfileLoggedOut) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            }
            if (state is ProfileError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is ProfileLoading || state is ProfileInitial) {
              return _buildLoadingView(w);
            }
            
            if (state is ProfileLoaded) {
              return _buildProfileContent(context, state, w);
            }
            
            // Error State UI
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Something went wrong'),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      context.read<ProfileBloc>().add(LoadProfile());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingView(double w) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Profile Header Card Shimmer
          _buildProfileHeaderShimmer(w),
          const SizedBox(height: 20),
          // Tab Bar Shimmer
          _buildTabBarShimmer(),
          const SizedBox(height: 20),
          // Content Shimmer
          _buildContentShimmer(),
        ],
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, ProfileLoaded state, double w) {
    final userData = state.userData;
    
    return Column(
      children: [
        // Static Profile Header
        _buildProfileHeader(context, userData, w),
        
        // Tab Bar
        _buildTabBar(),
        
        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Orders Tab
              _buildOrdersTab(context, state),
              
              // Addresses Tab
              _buildAddressesTab(context, state),
              
              // Legal Tab
              _buildLegalTab(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(BuildContext context, Map<String, dynamic> userData, double w) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorManager.primary,
            ColorManager.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE67E22).withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pushNamed(context, Routes.settings);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Profile Avatar with Icon
                Container(
                  width: w * 0.22,
                  height: w * 0.22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.person,
                    size: w * 0.11,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userData['username'] ?? 'User',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone,
                            size: 16,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              userData['mobile'] ?? userData['phone'] ?? 'No mobile number',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.edit,
                  color: Colors.white70,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: softBoxShadow,
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: ColorManager.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'Orders'),
          Tab(text: 'Addresses'),
          Tab(text: 'Legal'),
        ],
      ),
    );
  }

  Widget _buildOrdersTab(BuildContext context, ProfileLoaded state) {
    final orderHistory = state.orderHistory;
    
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: softBoxShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Your Orders',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => OrderHistoryView()),
                    );
                  },
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      color: Color(0xFFE67E22),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: orderHistory.isNotEmpty
                ? ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: orderHistory.length,
                    itemBuilder: (context, index) {
                      final order = orderHistory[index];
                      return _OrderTile(
                        orderId: order['order_id'] ?? '',
                        image: order['restaurant_picture'],
                        title: order['restaurant_name'] ?? 'Unknown Restaurant',
                        date: _formatDate(order['datetime']),
                        price: '${order['total_price']}',
                        status: order['order_status'],
                      );
                    },
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No orders yet',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Your orders will appear here',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressesTab(BuildContext context, ProfileLoaded state) {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: softBoxShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text(
                  'Saved Addresses',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () async {
                    final result = await AddressPickerBottomSheet.show(context);
                    if (result != null && mounted) {
                      // Refresh the profile to show new address
                      context.read<ProfileBloc>().add(LoadProfile());
                    }
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text(
                    'Add New',
                    style: TextStyle(
                      color: Color(0xFFE67E22),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: BlocProvider(
              create: (context) => AddressPickerBloc()..add(LoadSavedAddressesEvent()),
              child: BlocBuilder<AddressPickerBloc, AddressPickerState>(
                builder: (context, addressState) {
                  if (addressState is AddressPickerLoadSuccess || addressState is SavedAddressesLoaded) {
                    final addresses = addressState is AddressPickerLoadSuccess
                        ? addressState.savedAddresses
                        : (addressState as SavedAddressesLoaded).savedAddresses;
                    
                    if (addresses.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No saved addresses',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Add your first address',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: addresses.length,
                      itemBuilder: (context, index) {
                        final address = addresses[index];
                        return _buildAddressItem(context, address);
                      },
                    );
                  }
                  
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFE67E22),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressItem(BuildContext context, SavedAddress address) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: address.isDefault ? ColorManager.primary.withOpacity(0.05) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: address.isDefault ? ColorManager.primary : Colors.grey[300]!,
          width: address.isDefault ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: address.isDefault ? ColorManager.primary : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  address.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: address.isDefault ? ColorManager.primary : Colors.black,
                  ),
                ),
              ),
              if (address.isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: ColorManager.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Default',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            address.addressLine1,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showEditAddressDialog(context, address);
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorManager.primary,
                    side: BorderSide(color: ColorManager.primary),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _showDeleteAddressDialog(context, address);
                  },
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegalTab(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: softBoxShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Legal Information',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildLegalItem(
                  context,
                  'Terms & Conditions',
                  Icons.description,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TermsConditionsPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildLegalItem(
                  context,
                  'Privacy Policy',
                  Icons.privacy_tip,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacyPolicyPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildLegalItem(
                  context,
                  'Share App',
                  Icons.share,
                  () async {
                    await Share.share(
                      'Check out Bird App for food delivery! Download now: https://play.google.com/store/apps/details?id=com.birduser.app',
                      subject: 'Bird App - Food Delivery',
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegalItem(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ListTile(
        leading: Icon(icon, color: ColorManager.primary, size: 24),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  // Helper methods
  String _formatDate(String datetime) {
    try {
      final date = TimezoneUtils.parseToIST(datetime);
      return TimezoneUtils.formatOrderDate(date);
    } catch (e) {
      return 'Unknown date';
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<ProfileBloc>().add(LogoutRequested());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showEditAddressDialog(BuildContext context, SavedAddress address) {
    // This would open the address picker in edit mode
    // For now, we'll show a simple dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Address'),
        content: const Text('Address editing functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAddressDialog(BuildContext context, SavedAddress address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: Text('Are you sure you want to delete "${address.displayName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<AddressPickerBloc>().add(
                DeleteSavedAddressEvent(addressId: address.addressId),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Shimmer loading widgets
  Widget _buildProfileHeaderShimmer(double w) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: double.infinity,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildTabBarShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildContentShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: double.infinity,
        height: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final String orderId;
  final String? image;
  final String title;
  final String date;
  final String price;
  final String? status;

  const _OrderTile({
    required this.orderId,
    required this.image,
    required this.title,
    required this.date,
    required this.price,
    this.status,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (orderId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailsView(orderId: orderId),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            // Restaurant image
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[300],
              ),
              child: image != null && image!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _getFullImageUrl(image!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.restaurant, color: Colors.grey);
                        },
                      ),
                    )
                  : const Icon(Icons.restaurant, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹$price',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE67E22),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getStatusText(),
                style: TextStyle(
                  color: _getStatusColor(),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (status?.toUpperCase()) {
      case 'PENDING':
        return Colors.orange;
      case 'CONFIRMED':
        return Colors.blue;
      case 'PREPARING':
        return Colors.purple;
      case 'READY':
        return Colors.green;
      case 'DELIVERED':
        return Colors.green;
      case 'CANCELLED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText() {
    switch (status?.toUpperCase()) {
      case 'PENDING':
        return 'Pending';
      case 'CONFIRMED':
        return 'Confirmed';
      case 'PREPARING':
        return 'Preparing';
      case 'READY':
        return 'Ready';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return 'Processing';
    }
  }

  String _getFullImageUrl(String imagePath) {
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
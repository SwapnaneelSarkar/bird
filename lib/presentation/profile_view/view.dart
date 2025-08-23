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

    return Scaffold(
        backgroundColor: const Color(0xFFF8F8F8),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          title: const Text('Profile', style: TextStyle(color: Colors.black)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                Routes.dashboard,
                (route) => false, // Remove all previous routes
              );
            },
          ),
          actions: [
            BlocBuilder<ProfileBloc, ProfileState>(
              builder: (context, state) {
                if (state is ProfileLoaded) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Heart icon for favorites
                      IconButton(
                        icon: const Text(
                          '❤️',
                          style: TextStyle(fontSize: 24),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, Routes.favorites);
                        },
                      ),
                      // Logout button
                      IconButton(
                        icon: const Icon(
                          Icons.logout,
                          color: Colors.red,
                          size: 24,
                        ),
                        onPressed: () {
                          _showLogoutDialog(context);
                        },
                      ),
                    ],
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
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Edit button
              Container(
                decoration: BoxDecoration(
                  color: ColorManager.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () {
                    _showEditAddressDialog(context, address);
                  },
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: ColorManager.primary,
                  ),
                  tooltip: 'Edit Address',
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              // Share button
              Container(
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () {
                    _showShareAddressDialog(context, address);
                  },
                  icon: Icon(
                    Icons.share_outlined,
                    size: 20,
                    color: Colors.green[700],
                  ),
                  tooltip: 'Share Address',
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              // Delete button
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () {
                    _showDeleteAddressDialog(context, address);
                  },
                  icon: Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Colors.red[700],
                  ),
                  tooltip: 'Delete Address',
                  style: IconButton.styleFrom(
                    padding: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                    await SharePlus.instance.share(
                      ShareParams(
                        text: 'Check out Bird App for food delivery! Download now: https://play.google.com/store/apps/details?id=com.birduser.app',
                        subject: 'Bird App - Food Delivery',
                      ),
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
      return TimezoneUtils.formatOrderDateTime(date);
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
    final addressNameController = TextEditingController(text: address.addressLine2);
    final cityController = TextEditingController(text: address.city);
    final stateController = TextEditingController(text: address.state);
    final postalCodeController = TextEditingController(text: address.postalCode);
    final countryController = TextEditingController(text: address.country);
    bool isDefault = address.isDefault;
    final latitude = address.latitude;
    final longitude = address.longitude;
    
    // Helper function to check if "home" name exists (excluding current address)
    bool _isHomeNameExistsExcludingCurrent() {
      final bloc = context.read<AddressPickerBloc>();
      final state = bloc.state;
      
      if (state is AddressPickerLoadSuccess || state is SavedAddressesLoaded) {
        final addresses = state is AddressPickerLoadSuccess
            ? state.savedAddresses
            : (state as SavedAddressesLoaded).savedAddresses;
            
        return addresses
          .where((a) => a.addressId != address.addressId) // Exclude current address
          .any((a) => a.addressLine2.toLowerCase() == 'home');
      }
      return false;
    }
    
    // Parse existing address to extract house/flat and apartment/road parts
    String existingAddress = address.addressLine1;
    String houseFlat = '';
    String apartmentRoad = '';
    
    // Simple parsing logic - this can be improved based on your data format
    if (existingAddress.isNotEmpty) {
      List<String> parts = existingAddress.split(', ');
      if (parts.length >= 2) {
        houseFlat = parts[0];
        apartmentRoad = parts[1];
      } else if (parts.length == 1) {
        apartmentRoad = parts[0];
      }
    }
    
    final houseFlatController = TextEditingController(text: houseFlat);
    final apartmentRoadController = TextEditingController(text: apartmentRoad);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            'Edit Address',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ColorManager.primary,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Address Name',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ColorManager.black,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: addressNameController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Home, Office',
                    filled: true,
                    fillColor: ColorManager.otpField,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'A detailed address will help our Delivery Partner reach your doorstep easily',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'HOUSE / FLAT / FLOOR NO.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ColorManager.black,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: houseFlatController,
                  decoration: InputDecoration(
                    hintText: 'e.g., Flat 101, House No. 123',
                    filled: true,
                    fillColor: ColorManager.otpField,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'APARTMENT / ROAD / AREA (RECOMMENDED)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ColorManager.black,
                  ),
                ),
                SizedBox(height: 8),
                TextField(
                  controller: apartmentRoadController,
                  decoration: InputDecoration(
                    hintText: 'e.g., ABC Apartment, Main Road',
                    filled: true,
                    fillColor: ColorManager.otpField,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'City',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: ColorManager.black,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: cityController,
                            decoration: InputDecoration(
                              hintText: 'City',
                              filled: true,
                              fillColor: ColorManager.otpField,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'State',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: ColorManager.black,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: stateController,
                            decoration: InputDecoration(
                              hintText: 'State',
                              filled: true,
                              fillColor: ColorManager.otpField,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Postal Code',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: ColorManager.black,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: postalCodeController,
                            decoration: InputDecoration(
                              hintText: 'Postal Code',
                              filled: true,
                              fillColor: ColorManager.otpField,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Country',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: ColorManager.black,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: countryController,
                            decoration: InputDecoration(
                              hintText: 'Country',
                              filled: true,
                              fillColor: ColorManager.otpField,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: isDefault,
                      onChanged: (value) {
                        setState(() {
                          isDefault = value ?? false;
                        });
                      },
                      activeColor: ColorManager.primary,
                    ),
                    const Text('Set as default address'),
                  ],
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: ColorManager.primary,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final addressName = addressNameController.text.trim();
                final houseFlat = houseFlatController.text.trim();
                final apartmentRoad = apartmentRoadController.text.trim();
                final city = cityController.text.trim();
                final state = stateController.text.trim();
                final postalCode = postalCodeController.text.trim();
                final country = countryController.text.trim();

                // Only require state as essential field
                if (state.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in state.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // Special validation for "home" name - only one address can have "home" name
                final lowerName = addressName.toLowerCase();
                if (lowerName == 'home' && _isHomeNameExistsExcludingCurrent()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('An address with "Home" name already exists. Only one address can be named "Home".'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Combine house/flat and apartment/road into a single address string
                String combinedAddress = '';
                List<String> addressParts = [];
                if (houseFlat.isNotEmpty) addressParts.add(houseFlat);
                if (apartmentRoad.isNotEmpty) addressParts.add(apartmentRoad);
                
                combinedAddress = addressParts.join(', ');

                Navigator.of(dialogContext).pop();
                // Use the AddressPickerBloc from context
                context.read<AddressPickerBloc>().add(
                  UpdateAddressEvent(
                    addressId: address.addressId,
                    addressLine1: combinedAddress,
                    addressLine2: addressName,
                    city: city,
                    state: state,
                    postalCode: postalCode,
                    country: country,
                    latitude: latitude,
                    longitude: longitude,
                    isDefault: isDefault,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareAddressDialog(BuildContext context, SavedAddress address) {
    final addressName = address.displayName;
    final fullAddress = address.fullAddress;
    
    // Get screen dimensions for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final textScale = screenWidth / 375; // Base scale factor
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.6,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20 * textScale),
            topRight: Radius.circular(20 * textScale),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Padding(
              padding: EdgeInsets.only(top: 12.0 * textScale),
              child: Container(
                width: 40 * textScale,
                height: 4 * textScale,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2 * textScale),
                ),
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24 * textScale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Icon(
                          Icons.share,
                          size: 24 * textScale,
                          color: ColorManager.primary,
                        ),
                        SizedBox(width: 12 * textScale),
                        Expanded(
                          child: Text(
                            'Share Address',
                            style: TextStyle(
                              fontSize: 20 * textScale,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8 * textScale),
                    Text(
                      'Choose how you want to share this address',
                      style: TextStyle(
                        fontSize: 14 * textScale,
                        color: Colors.grey[600],
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    SizedBox(height: 24 * textScale),
                    
                    // Address preview card
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20 * textScale),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16 * textScale),
                        border: Border.all(
                          color: Colors.grey[200]!,
                          width: 1,
                        ),
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
                              Icon(
                                Icons.location_on,
                                size: 20 * textScale,
                                color: ColorManager.primary,
                              ),
                              SizedBox(width: 8 * textScale),
                              Expanded(
                                child: Text(
                                  addressName,
                                  style: TextStyle(
                                    fontSize: 16 * textScale,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8 * textScale),
                          Text(
                            fullAddress,
                            style: TextStyle(
                              fontSize: 14 * textScale,
                              color: Colors.grey[600],
                              fontFamily: 'Montserrat',
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32 * textScale),
                    
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _shareAddress(fullAddress);
                            },
                            icon: Icon(
                              Icons.share,
                              size: 18 * textScale,
                            ),
                            label: Text(
                              'Share Address',
                              style: TextStyle(
                                fontSize: 16 * textScale,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorManager.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                vertical: 16 * textScale,
                                horizontal: 24 * textScale,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12 * textScale),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16 * textScale),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.grey[600],
                              side: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1.5,
                              ),
                              padding: EdgeInsets.symmetric(
                                vertical: 16 * textScale,
                                horizontal: 24 * textScale,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12 * textScale),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16 * textScale,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Montserrat',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Bottom padding for safe area
                    SizedBox(height: 16 * textScale),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _shareAddress(String address) {
    SharePlus.instance.share(ShareParams(text: address));
  }

  void _showDeleteAddressDialog(BuildContext context, SavedAddress address) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Delete Address',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${address.displayName}"? This action cannot be undone.',
          style: TextStyle(
            fontSize: 14,
            color: ColorManager.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            style: TextButton.styleFrom(
              foregroundColor: ColorManager.primary,
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AddressPickerBloc>().add(
                DeleteSavedAddressEvent(addressId: address.addressId),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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
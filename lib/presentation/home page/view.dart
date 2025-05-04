import 'package:flutter/material.dart';
import 'package:bird/constants/router/router.dart';
import 'package:bird/constants/color/colorConstant.dart';
import '../../service/token_service.dart';

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
    debugPrint('HomePage - User Data: $userData');
    debugPrint('HomePage - Token: $token');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Image.asset(
          'assets/logo.png',
          height: 40,
          color: ColorManager.primary,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            color: ColorManager.primary,
            iconSize: 28,
            onPressed: () {
              Navigator.pushNamed(context, Routes.profileView);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: ColorManager.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome Back!',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: ColorManager.primary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'What would you like to do today?',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.waving_hand,
                            size: 50,
                            color: ColorManager.primary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Quick Actions
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.5,
                      children: [
                        _buildQuickActionCard(
                          icon: Icons.local_shipping_outlined,
                          title: 'Track Order',
                          color: Colors.blue,
                          onTap: () {
                            debugPrint('Track Order tapped');
                          },
                        ),
                        _buildQuickActionCard(
                          icon: Icons.history,
                          title: 'Order History',
                          color: Colors.green,
                          onTap: () {
                            debugPrint('Order History tapped');
                          },
                        ),
                        _buildQuickActionCard(
                          icon: Icons.location_on_outlined,
                          title: 'Saved Addresses',
                          color: Colors.orange,
                          onTap: () {
                            debugPrint('Saved Addresses tapped');
                          },
                        ),
                        _buildQuickActionCard(
                          icon: Icons.support_agent,
                          title: 'Support',
                          color: Colors.purple,
                          onTap: () {
                            debugPrint('Support tapped');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Recent Orders Section
                    Text(
                      'Recent Orders',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No recent orders',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your order history will appear here',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Logout Button at Bottom
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    // Handle logout
                    debugPrint('Logging out...');
                    final logoutSuccess = await TokenService.clearAll();
                    
                    if (logoutSuccess) {
                      debugPrint('Logout successful');
                      Navigator.pushReplacementNamed(context, Routes.login);
                    } else {
                      debugPrint('Logout failed');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Logout failed. Please try again.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.red, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
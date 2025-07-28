// lib/presentation/category_homepage/view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/color/colorConstant.dart';
import '../../constants/router/router.dart';
import '../../utils/currency_utils.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';
import '../home page/view.dart';
import '../home page/bloc.dart';
import '../home page/event.dart';

class CategoryHomepage extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final String? token;

  const CategoryHomepage({Key? key, this.userData, this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CategoryHomepageBloc()..add(const LoadCategoryHomepage()),
      child: _CategoryHomepageContent(userData: userData, token: token),
    );
  }
}

class _CategoryHomepageContent extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final String? token;

  const _CategoryHomepageContent({Key? key, this.userData, this.token}) : super(key: key);

  @override
  State<_CategoryHomepageContent> createState() => _CategoryHomepageContentState();
}

class _CategoryHomepageContentState extends State<_CategoryHomepageContent>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _categoryAnimationController;
  late AnimationController _ordersAnimationController;

  @override
  void initState() {
    super.initState();
    
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _categoryAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _ordersAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Start animations in sequence
    _headerAnimationController.forward().then((_) {
      _categoryAnimationController.forward().then((_) {
        _ordersAnimationController.forward();
      });
    });
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _categoryAnimationController.dispose();
    _ordersAnimationController.dispose();
    super.dispose();
  }

  double _getResponsiveFontSize(double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 320) return baseSize * 0.8;
    if (screenWidth < 480) return baseSize * 0.9;
    if (screenWidth < 768) return baseSize;
    if (screenWidth < 1024) return baseSize * 1.1;
    return baseSize * 1.2;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final bloc = context.read<CategoryHomepageBloc>();
        // If not already loading, reset to initial and reload
        if (bloc.state is! CategoryHomepageLoading) {
          bloc.emit(const CategoryHomepageInitial());
          bloc.add(const LoadCategoryHomepage());
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocConsumer<CategoryHomepageBloc, CategoryHomepageState>(
          listener: (context, state) {
            if (state is CategorySelected) {
              debugPrint('CategoryHomepage: Navigating with supercategory ID: ${state.categoryId}');
              bool homeFound = false;
              Navigator.popUntil(context, (route) {
                if (route.settings.name == Routes.home) {
                  homeFound = true;
                  return true;
                }
                return false;
              });
              if (homeFound) {
                // Optionally, use a global event or a callback to update the HomePage's category
                // For now, do nothing (the HomePage should listen for a global event or refresh itself)
              } else {
                Navigator.of(context).pushAndRemoveUntil(
                  PageRouteBuilder(
                    settings: RouteSettings(name: Routes.home),
                    pageBuilder: (context, animation, secondaryAnimation) => BlocProvider(
                      create: (_) => HomeBloc(
                        selectedSupercategoryId: state.categoryId,
                      )..add(const LoadHomeData()),
                      child: HomePage(
                        userData: widget.userData,
                        token: widget.token,
                      ),
                    ),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.easeInOut;
                      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                      return SlideTransition(
                        position: animation.drive(tween),
                        child: child,
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 400),
                  ),
                  (route) => false,
                );
              }
            }
          },
          builder: (context, state) {
            if (state is CategoryHomepageLoading) {
              return _buildLoadingState();
            } else if (state is CategoryHomepageError) {
              return _buildErrorState(state.message);
            } else if (state is CategoryHomepageLoaded) {
              return _buildLoadedState(state);
            }
            return _buildLoadingState();
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFD2691E)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading categories...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<CategoryHomepageBloc>().add(const RefreshCategoryHomepage());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorManager.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadedState(CategoryHomepageLoaded state) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          context.read<CategoryHomepageBloc>().add(const RefreshCategoryHomepage());
        },
        color: ColorManager.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Header Section
            SliverToBoxAdapter(
              child: _buildHeader(state).animate().slideY(
                begin: -0.3,
                end: 0,
                duration: 600.ms,
                curve: Curves.easeOutCubic,
              ).fadeIn(duration: 600.ms),
            ),
            
            // Categories Section
            SliverToBoxAdapter(
              child: _buildCategoriesSection(state.categories).animate().slideY(
                begin: 0.3,
                end: 0,
                duration: 800.ms,
                curve: Curves.easeOutCubic,
              ).fadeIn(delay: 200.ms, duration: 600.ms),
            ),
                        // Recent Orders Section
            if (state.recentOrders.isNotEmpty)
              SliverToBoxAdapter(
                child: _buildRecentOrdersSection(state.recentOrders).animate().slideY(
                  begin: 0.3,
                  end: 0,
                  duration: 800.ms,
                  curve: Curves.easeOutCubic,
                ).fadeIn(delay: 600.ms, duration: 600.ms),
              ),
            

            // Quick Actions Section
            SliverToBoxAdapter(
              child: _buildQuickActionsSection().animate().slideY(
                begin: 0.3,
                end: 0,
                duration: 800.ms,
                curve: Curves.easeOutCubic,
              ).fadeIn(delay: 400.ms, duration: 600.ms),
            ),
            
            // Bottom spacing
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(CategoryHomepageLoaded state) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            ColorManager.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: ColorManager.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getGreeting(),
                        style: GoogleFonts.poppins(
                          fontSize: _getResponsiveFontSize(12),
                          color: ColorManager.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.userName,
                      style: GoogleFonts.poppins(
                        fontSize: _getResponsiveFontSize(28),
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'What would you like to order today?',
                      style: GoogleFonts.poppins(
                        fontSize: _getResponsiveFontSize(14),
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pushNamed(context, Routes.profileView);
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        ColorManager.primary.withOpacity(0.1),
                        ColorManager.primary.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: ColorManager.primary.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: ColorManager.primary.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: ColorManager.primary,
                    size: 32,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Container(
          //   padding: const EdgeInsets.all(16),
          //   decoration: BoxDecoration(
          //     color: Colors.white.withOpacity(0.8),
          //     borderRadius: BorderRadius.circular(16),
          //     border: Border.all(
          //       color: Colors.grey[200]!,
          //       width: 1,
          //     ),
          //   ),
          //   // child: Row(
          //   //   children: [
          //   //     Container(
          //   //       padding: const EdgeInsets.all(8),
          //   //       decoration: BoxDecoration(
          //   //         color: ColorManager.primary.withOpacity(0.1),
          //   //         borderRadius: BorderRadius.circular(10),
          //   //       ),
          //   //       child: Icon(
          //   //         Icons.location_on,
          //   //         color: ColorManager.primary,
          //   //         size: 20,
          //   //       ),
          //   //     ),
          //   //     const SizedBox(width: 12),
          //   //     Expanded(
          //   //       child: Column(
          //   //         crossAxisAlignment: CrossAxisAlignment.start,
          //   //         children: [
          //   //           Text(
          //   //             'Delivering to',
          //   //             style: GoogleFonts.poppins(
          //   //               fontSize: _getResponsiveFontSize(12),
          //   //               color: Colors.grey[600],
          //   //               fontWeight: FontWeight.w500,
          //   //             ),
          //   //           ),
          //   //           const SizedBox(height: 2),
          //   //           Text(
          //   //             state.userAddress,
          //   //             style: GoogleFonts.poppins(
          //   //               fontSize: _getResponsiveFontSize(14),
          //   //               color: Colors.black87,
          //   //               fontWeight: FontWeight.w600,
          //   //             ),
          //   //             maxLines: 1,
          //   //             overflow: TextOverflow.ellipsis,
          //   //           ),
          //   //         ],
          //   //       ),
          //   //     ),
          //   //     Icon(
          //   //       Icons.keyboard_arrow_down_rounded,
          //   //       color: Colors.grey[500],
          //   //       size: 24,
          //   //     ),
          //   //   ],
          //   // ),
          // ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(List<CategoryModel> categories) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose your favorite',
            style: GoogleFonts.poppins(
              fontSize: _getResponsiveFontSize(22),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select a category to explore delicious options',
            style: GoogleFonts.poppins(
              fontSize: _getResponsiveFontSize(14),
              color: Colors.grey[600],
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryCard(category, index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(CategoryModel category, int index) {
    final gradients = [
      [const Color(0xFFFFE0B2), ColorManager.primary],
      [const Color(0xFFE8F5E8), const Color(0xFF4CAF50)],
      [const Color(0xFFE3F2FD), const Color(0xFF2196F3)],
      [const Color(0xFFFCE4EC), const Color(0xFFE91E63)],
      [const Color(0xFFF3E5F5), const Color(0xFF9C27B0)],
      [const Color(0xFFE0F2F1), const Color(0xFF009688)],
    ];
    
    final gradient = gradients[index % gradients.length];

    // Debug print to verify what is being passed
    debugPrint('Dashboard: Showing card for ${category.name} (id: ${category.id})');
    final supercategoryId = category.id;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.read<CategoryHomepageBloc>().add(
          SelectCategory(
            categoryId: supercategoryId,
            categoryName: category.name,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradient[1].withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  gradient[0],
                  gradient[1].withOpacity(0.8),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Background pattern circles
                Positioned(
                  top: -30,
                  right: -30,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -20,
                  left: -20,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                
                // Content - Fixed layout to prevent overflow
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon container
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          _getCategoryIcon(category.name),
                          color: gradient[1],
                          size: 28,
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Category name - Fixed to prevent overflow
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              category.name,
                              style: GoogleFonts.poppins(
                                fontSize: _getResponsiveFontSize(16),
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            
                            const SizedBox(height: 4),
                            
                            // Bottom row with subtitle and arrow
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Explore ${category.name.toLowerCase()}',
                                    style: GoogleFonts.poppins(
                                      fontSize: _getResponsiveFontSize(10),
                                      color: Colors.white.withOpacity(0.9),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ).animate().scale(
        begin: const Offset(0.8, 0.8),
        end: const Offset(1, 1),
        duration: Duration(milliseconds: 400 + (index * 150)),
        curve: Curves.easeOutBack,
      ).fadeIn(
        duration: Duration(milliseconds: 600 + (index * 100)),
        curve: Curves.easeOut,
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.poppins(
              fontSize: _getResponsiveFontSize(18),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.history,
                  title: 'Order History',
                  subtitle: 'View past orders',
                  onTap: () => Navigator.pushNamed(context, Routes.orderHistory),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionCard(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  subtitle: 'Manage account',
                  onTap: () => Navigator.pushNamed(context, Routes.settings),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: ColorManager.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: ColorManager.primary,
                size: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: _getResponsiveFontSize(14),
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: _getResponsiveFontSize(12),
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrdersSection(List<RecentOrderModel> recentOrders) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Orders',
                style: GoogleFonts.poppins(
                  fontSize: _getResponsiveFontSize(18),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, Routes.orderHistory),
                child: Text(
                  'View All',
                  style: GoogleFonts.poppins(
                    fontSize: _getResponsiveFontSize(14),
                    color: ColorManager.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: recentOrders.take(5).length,
              itemBuilder: (context, index) {
                final order = recentOrders[index];
                return _buildRecentOrderCard(order, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrderCard(RecentOrderModel order, int index) {
    final statusColor = _getOrderStatusColor(order.orderStatus);
    
    return Container(
      width: 280,
      margin: EdgeInsets.only(right: index < 4 ? 12 : 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _getCategoryColor(order.supercategoryName).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getCategoryIcon(order.supercategoryName),
                  color: _getCategoryColor(order.supercategoryName),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.supercategoryName,
                      style: GoogleFonts.poppins(
                        fontSize: _getResponsiveFontSize(14),
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      _formatOrderDate(order.createdAt),
                      style: GoogleFonts.poppins(
                        fontSize: _getResponsiveFontSize(12),
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatOrderStatus(order.orderStatus),
                  style: GoogleFonts.poppins(
                    fontSize: _getResponsiveFontSize(10),
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FutureBuilder<String>(
                future: CurrencyUtils.getCurrencySymbolFromUserLocation(),
                builder: (context, snapshot) {
                  final currencySymbol = snapshot.data ?? '₹';
                  return Text(
                    CurrencyUtils.formatPrice(double.tryParse(order.totalPrice) ?? 0, currencySymbol),
                    style: GoogleFonts.poppins(
                      fontSize: _getResponsiveFontSize(16),
                      fontWeight: FontWeight.bold,
                      color: ColorManager.primary,
                    ),
                  );
                },
              ),
              // Only show reorder if the order is delivered/completed
              if (order.orderStatus.toUpperCase() == 'DELIVERED')
                GestureDetector(
                  onTap: () {
                    // Navigate to order details for potential reorder
                    Navigator.pushNamed(context, Routes.orderHistory);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: ColorManager.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Reorder',
                      style: GoogleFonts.poppins(
                        fontSize: _getResponsiveFontSize(12),
                        fontWeight: FontWeight.w600,
                        color: ColorManager.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ).animate().slideX(
      begin: 0.3,
      end: 0,
      duration: Duration(milliseconds: 300 + (index * 100)),
      curve: Curves.easeOutCubic,
    );
  }

  // Helper Methods
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'grocery':
        return Icons.shopping_bag;
      case 'medicine':
        return Icons.local_pharmacy;
      case 'electronics':
        return Icons.devices;
      default:
        return Icons.category;
    }
  }

  Color _getCategoryColor(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'food':
        return ColorManager.primary;
      case 'grocery':
        return const Color(0xFF4CAF50);
      case 'medicine':
        return const Color(0xFF2196F3);
      case 'electronics':
        return const Color(0xFFE91E63);
      default:
        return ColorManager.primary;
    }
  }

  Color _getOrderStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return const Color(0xFFFF9800);
      case 'PREPARING':
        return const Color(0xFF2196F3);
      case 'OUT_FOR_DELIVERY':
        return const Color(0xFF9C27B0);
      case 'DELIVERED':
        return const Color(0xFF4CAF50);
      case 'CANCELLED':
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }

  String _formatOrderStatus(String status) {
    switch (status.toUpperCase()) {
      case 'OUT_FOR_DELIVERY':
        return 'Out for Delivery';
      case 'PENDING':
        return 'Pending';
      case 'PREPARING':
        return 'Preparing';
      case 'DELIVERED':
        return 'Delivered';
      case 'CANCELLED':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _formatOrderDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date).inDays;

      if (difference == 0) {
        return 'Today';
      } else if (difference == 1) {
        return 'Yesterday';
      } else if (difference < 7) {
        return '$difference days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Unknown date';
    }
  }
}
                
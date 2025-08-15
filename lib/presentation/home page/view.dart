// lib/presentation/home page/view.dart - COMPLETE ERROR-FREE VERSION
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'dart:async';
import 'package:bird/constants/router/router.dart';
import 'package:bird/constants/color/colorConstant.dart';
import '../../../widgets/restaurant_card.dart';
import '../address bottomSheet/view.dart';
import '../restaurant_menu/view.dart';
import '../search_page/bloc.dart';
import '../search_page/searchPage.dart';
import '../../utils/currency_utils.dart';
import '../../models/recent_order_model.dart';
import '../../service/app_startup_service.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';
import 'home_favorites_bloc.dart';
import '../../service/firebase_services.dart';
// import '../favorites/view.dart'; // No longer needed - using shared preferences
import 'package:shared_preferences/shared_preferences.dart';

// Responsive text utility function
double getResponsiveFontSize(BuildContext context, double baseSize) {
  final screenWidth = MediaQuery.of(context).size.width;
  if (screenWidth < 320) return baseSize * 0.8; // Small phones
  if (screenWidth < 480) return baseSize * 0.9; // Medium phones
  if (screenWidth < 768) return baseSize; // Large phones
  if (screenWidth < 1024) return baseSize * 1.1; // Tablets
  return baseSize * 1.2; // Large tablets/desktop
}

// Add at the top of the file (after imports):
bool isFoodSupercategory(String? id) {
  return id == null || id == 'food' || id == '1' || id == '7acc47a2fa5a4eeb906a753b3'; // Add more ids if needed
}

// Global callback for favorites refresh
class FavoritesRefreshCallback {
  static Function? _callback;
  
  static void setCallback(Function callback) {
    _callback = callback;
  }
  
  static void triggerRefresh() {
    if (_callback != null) {
      _callback!();
    }
  }
  
  static void clearCallback() {
    _callback = null;
  }
}

// Main home page widget
class HomePage extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final String? token;

  const HomePage({Key? key, this.userData, this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Do NOT create a new BlocProvider here!
    // The router should provide the HomeBloc with the correct selectedSupercategoryId.
    return MultiBlocProvider(
      providers: [
        BlocProvider<HomeFavoritesBloc>(
          create: (context) => HomeFavoritesBloc(),
        ),
      ],
      child: _HomeContent(userData: userData, token: token),
    );
  }
}

// Filter options class with simplified approach
class FilterOptions {
  bool vegOnly;
  bool priceLowToHigh; // true for low to high, false for high to low, null for no sorting
  bool priceHighToLow; // true for high to low, false for low to high, null for no sorting
  bool ratingHighToLow; // true for high to low, false for low to high, null for no sorting
  bool ratingLowToHigh; // true for low to high, false for high to low, null for no sorting
  bool timeSort; // true for fastest first, null for no sorting
  
  FilterOptions({
    this.vegOnly = false,
    this.priceLowToHigh = false,
    this.priceHighToLow = false,
    this.ratingHighToLow = false,
    this.ratingLowToHigh = false,
    this.timeSort = false,
  });
}

// Home content stateful widget
class _HomeContent extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final String? token;

  const _HomeContent({Key? key, this.userData, this.token}) : super(key: key);

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _animationController;
  FilterOptions filterOptions = FilterOptions();
  String? previousAddress;
  String? get selectedSupercategoryId => context.read<HomeBloc>().selectedSupercategoryId;
  
  // Add debounce mechanism to prevent double-taps
  DateTime? _lastFilterTap;
  static const Duration _filterDebounceTime = Duration(milliseconds: 300);
  
  // Track if favorites have been refreshed to avoid multiple refreshes
  bool _favoritesRefreshed = false;
  
  // Track if we've checked for favorites changes in this build cycle
  bool _favoritesChangeChecked = false;
  

  
  // Timer for periodic favorites refresh
  Timer? _favoritesRefreshTimer;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    
    // Start periodic favorites refresh timer (every 2 minutes)
    _favoritesRefreshTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (mounted) {
        // Always refresh favorites periodically
        _forceRefreshFavorites();
        debugPrint('HomePage: Periodic favorites refresh triggered');
      }
    });
    
    // Register callback for favorites refresh
    FavoritesRefreshCallback.setCallback(() {
      debugPrint('HomePage: Global callback triggered - refreshing favorites');
      if (mounted) {
        _forceRefreshFavorites();
      }
    });
    
    debugPrint('HomePage: Registered global callback for favorites refresh');
    
    // Always refresh favorites when page initializes
    // Use a small delay to ensure the page is fully loaded
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _forceRefreshFavorites();
      }
    });
    
    // Add a listener to detect when the page becomes visible again
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupVisibilityListener();
    });
    
    // Register device token after login/registration
    if (widget.userData != null && widget.token != null) {
      debugPrint('[DeviceToken] Attempting to register device token after login/registration...');
      NotificationService().registerDeviceTokenIfNeeded();
    } else {
      debugPrint('[DeviceToken] Not calling registerDeviceTokenIfNeeded: userData or token is null');
    }
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _favoritesRefreshTimer?.cancel();
    _animationController.dispose();
    
    // Clear the global callback
    FavoritesRefreshCallback.clearCallback();
    debugPrint('HomePage: Cleared global callback');
    
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.paused) {
      // Reset the flag when app is paused so we can refresh when resumed
      _favoritesRefreshed = false;
      _favoritesChangeChecked = false;
      debugPrint('HomePage: App paused - resetting favorites refresh flags');
    } else if (state == AppLifecycleState.resumed) {
      // When the app becomes active (user returns to the app), refresh favorites
      debugPrint('HomePage: App resumed - refreshing favorites');
      _favoritesChangeChecked = false;
      _favoritesRefreshed = false;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _forceRefreshFavorites();
        }
      });
    } else if (state == AppLifecycleState.inactive) {
      // Reset flag when app becomes inactive (user navigates away)
      _favoritesRefreshed = false;
      _favoritesChangeChecked = false;
      debugPrint('HomePage: App inactive - resetting favorites refresh flags');
    }
  }

  // Add a method to manually refresh favorites (can be called from other pages)
  void refreshFavoritesOnReturn() {
    debugPrint('HomePage: Manual favorites refresh triggered');
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _forceRefreshFavorites();
      }
    });
  }

  // Setup visibility listener to detect when page becomes visible again
  void _setupVisibilityListener() {
    // This will be called when the page becomes visible again
    debugPrint('HomePage: Setting up visibility listener');
  }



  void _refreshFavoritesData() {
    // Refresh favorites data when returning to the homepage
    debugPrint('HomePage: _refreshFavoritesData called');
    try {
      final favoritesBloc = context.read<HomeFavoritesBloc>();
      favoritesBloc.add(RefreshHomeFavoriteCache());
      debugPrint('HomePage: Favorites refresh triggered');
      
      // Force a rebuild after a short delay to ensure UI updates
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() {});
          debugPrint('HomePage: Forced rebuild after favorites refresh');
        }
      });
    } catch (e) {
      debugPrint('HomePage: Error in _refreshFavoritesData: $e');
    }
  }

  Future<void> _checkAndRefreshFavoritesIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesChanged = prefs.getBool('favorites_changed') ?? false;
      final wasOnFavoritesPage = prefs.getBool('on_favorites_page') ?? false;
      final timestamp = prefs.getInt('favorites_changed_timestamp') ?? 0;
      
      debugPrint('HomePage: Checking favorites flags - favorites_changed: $favoritesChanged, wasOnFavoritesPage: $wasOnFavoritesPage');
      debugPrint('HomePage: Flag timestamp: $timestamp, current time: ${DateTime.now().millisecondsSinceEpoch}');
      
      // Always refresh favorites when dependencies change (page becomes visible)
      debugPrint('HomePage: Dependencies changed - always refreshing favorites');
      _refreshFavoritesData();
      
      // Clear any existing flags
      if (favoritesChanged || wasOnFavoritesPage) {
        await prefs.remove('favorites_changed');
        await prefs.remove('favorites_changed_timestamp');
        await prefs.remove('on_favorites_page');
        debugPrint('HomePage: Cleared all favorites flags');
      }
    } catch (e) {
      debugPrint('HomePage: Error checking favorites flags: $e');
      // Fallback to normal refresh on error
      _refreshFavoritesData();
    }
  }

  // Add a more aggressive refresh method that forces a complete cache refresh
  void _forceRefreshFavorites() {
    debugPrint('HomePage: Force refreshing favorites');
    try {
      final favoritesBloc = context.read<HomeFavoritesBloc>();
      favoritesBloc.add(RefreshHomeFavoriteCache());
      debugPrint('HomePage: Force favorites refresh triggered');
      
      // Force a rebuild after a short delay to ensure UI updates
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {});
          debugPrint('HomePage: Forced rebuild after force favorites refresh');
        }
      });
    } catch (e) {
      debugPrint('HomePage: Error in _forceRefreshFavorites: $e');
    }
  }





  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only refresh favorites when dependencies change (page becomes visible)
    if (!_favoritesRefreshed) {
      _favoritesRefreshed = true;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          debugPrint('HomePage: Dependencies changed - refreshing favorites only');
          _forceRefreshFavorites();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only refresh favorites once per build cycle
    if (!_favoritesChangeChecked) {
      _favoritesChangeChecked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Add a longer delay to ensure the page is fully loaded and stable
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            debugPrint('HomePage: Post-frame callback - refreshing favorites only');
            _forceRefreshFavorites();
          }
        });
      });
    }
    
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          // Refresh favorites when user navigates back
          debugPrint('HomePage: User navigated back - refreshing favorites');
          _favoritesRefreshed = false; // Reset flag to allow refresh
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) {
              _forceRefreshFavorites();
            }
          });
          return;
        }
        Navigator.pushReplacementNamed(
          context,
          Routes.dashboard,
          arguments: {
            'userData': widget.userData,
            'token': widget.token,
          },
        );
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FF),
        body: SafeArea(
          child: MultiBlocListener(
            listeners: [
              BlocListener<HomeBloc, HomeState>(
                listener: (context, state) {
                  // Handle all address-related state changes
                  _handleAddressUpdates(context, state);
                  
                  // Handle address change notifications
                  if (state is HomeLoaded && state.userAddress != previousAddress) {
                    if (previousAddress != null && previousAddress != 'Add delivery address') {
                      _showCustomSnackBar(context, 'Address updated successfully', Colors.green, Icons.check_circle);
                    }
                    previousAddress = state.userAddress;
                    debugPrint('HomePage: Address changed to: ${state.userAddress}');
                    // Initialize currency when coordinates are available
                    if (state.userLatitude != null && state.userLongitude != null) {
                      CurrencyUtils.getCurrencySymbolFromUserLocation();
                    }
                  }
                },
              ),
              BlocListener<HomeFavoritesBloc, HomeFavoritesState>(
                listener: (context, state) {
                  if (state is HomeFavoriteToggleError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ],
            child: BlocBuilder<HomeBloc, HomeState>(
              buildWhen: (previous, current) {
                // Always rebuild when state type changes
                if (previous.runtimeType != current.runtimeType) return true;
                // For HomeLoaded states, rebuild when important fields change
                if (previous is HomeLoaded && current is HomeLoaded) {
                  return previous.selectedFoodTypeId != current.selectedFoodTypeId ||
                         previous.selectedCategoryId != current.selectedCategoryId ||
                         previous.vegOnly != current.vegOnly ||
                         previous.restaurants.length != current.restaurants.length ||
                         previous.userAddress != current.userAddress ||
                         previous.userLatitude != current.userLatitude ||
                         previous.userLongitude != current.userLongitude;
                }
                return true;
              },
              builder: (context, state) {
                debugPrint('HomePage: BlocBuilder received state: ${state.runtimeType}');
                if (state is HomeLoaded) {
                  debugPrint('HomePage: BlocBuilder - selectedCategoryId: ${state.selectedCategoryId}');
                  debugPrint('HomePage: BlocBuilder - vegOnly: ${state.vegOnly}');
                  debugPrint('HomePage: BlocBuilder - selectedFoodTypeId: ${state.selectedFoodTypeId}');
                  debugPrint('HomePage: BlocBuilder - restaurants count: ${state.restaurants.length}');
                  debugPrint('HomePage: BlocBuilder - filtered restaurants count: ${state.filteredRestaurants.length}');
                  
                  // Additional debugging for state consistency
                  debugPrint('HomePage: State consistency check - selectedCategoryId: ${state.selectedCategoryId}, selectedFoodTypeId: ${state.selectedFoodTypeId}');
                }
                if (state is HomeLoading) {
                  return _buildLoadingWithTimeout(context);
                } else if (state is HomeLoaded) {
                  return _buildHomeContent(context, state);
                } else {
                  // If no HomeLoaded at all, show the full error state
                  return _buildErrorState(context, state is HomeError ? state : const HomeError('Something went wrong'));
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWithTimeout(BuildContext context) {
    return FutureBuilder(
      future: Future.delayed(const Duration(seconds: 10)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text('Something went wrong. Please try again.', style: TextStyle(color: Colors.red, fontSize: 16)),
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
        }
        return _buildLoadingIndicator();
      },
    );
  }

  // Handle address update states
  void _handleAddressUpdates(BuildContext context, HomeState state) {
    if (state is AddressUpdateSuccess) {
      _showCustomSnackBar(
        context, 
        'Address updated successfully', 
        Colors.green, 
        Icons.check_circle
      );
    } else if (state is AddressUpdateFailure) {
      // Check if it's an outside service area error
      final errorMessage = state.error.toLowerCase();
      if (errorMessage.contains('outside') && 
          (errorMessage.contains('service') || errorMessage.contains('serviceable'))) {
        // Don't show error snackbar for outside service area
        // The UI will handle this gracefully
        debugPrint('HomePage: Outside service area detected, handling gracefully');
      } else {
        _showCustomSnackBar(
          context, 
          state.error, 
          Colors.red, 
          Icons.error_outline
        );
      }
    } else if (state is AddressSaveSuccess) {
      _showCustomSnackBar(
        context, 
        state.message, 
        Colors.green, 
        Icons.check_circle
      );
    } else if (state is AddressSaveFailure) {
      _showCustomSnackBar(
        context, 
        state.error, 
        Colors.red, 
        Icons.error_outline
      );
    }
  }
  
  // --- ADDED: Location update from home page ---
  Future<void> _updateLocationFromHome(BuildContext context) async {
    try {
      debugPrint('HomePage: Manual location update triggered from home page');
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );
      
      // Force ultra fresh location fetch
      final result = await AppStartupService.forceUltraFreshLocationFetch();
      
      // Hide loading indicator
      Navigator.of(context).pop();
      
      if (result['success'] == true) {
        debugPrint('HomePage: Ultra fresh location update successful');
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location updated successfully! ${result['isUltraFresh'] == true ? '(Ultra Fresh)' : ''}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Reload home data with fresh location
        context.read<HomeBloc>().add(LoadHomeData());
        
      } else {
        debugPrint('HomePage: Location update failed: ${result['message']}');
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update location: ${result['message']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('HomePage: Error during location update: $e');
      
      // Hide loading indicator if still showing
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error updating location. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
  // --- END ADDED ---
  
  Widget _buildHomeContent(BuildContext context, HomeLoaded state) {
    debugPrint('UI: Showing home content with \\${state.restaurants.length} restaurants');
    
    // Determine if we're outside service area
    // Only hide categories/toggles if there are NO restaurants at all for this location
    // NOT when filters result in no restaurants
    final isOutsideServiceableArea = state.userAddress != 'Add delivery address' && 
                                   state.restaurants.isEmpty &&
                                   !state.isLocationServiceable;
    
    return Stack(
      children: [
        // Background
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FF),
          ),
        ),
        
        Column(
          children: [
            // Address Bar with glass morphism effect
            ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.8)],
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    ),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, 2), blurRadius: 8)],
                    border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.5), width: 1)),
                  ),
                  child: _buildAddressBar(context, state),
                ),
              ),
            ).animate(controller: _animationController).fadeIn(duration: 400.ms, curve: Curves.easeOut),

            // Search Bar
            _buildSearchBar(context, state, isStore: !isFoodSupercategory(selectedSupercategoryId))
              .animate(controller: _animationController)
              .fadeIn(duration: 400.ms, delay: 100.ms, curve: Curves.easeOut)
              .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut),

            // Main Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  // Refresh both home data and favorites
                  context.read<HomeBloc>().add(const LoadHomeData());
                  await Future.delayed(const Duration(milliseconds: 100));
                  _forceRefreshFavorites();
                },
                color: ColorManager.primary,
                backgroundColor: Colors.white,
                displacement: 20,
                strokeWidth: 3,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Popular Categories - Only show if not outside service area
                      if (!isOutsideServiceableArea)
                        _buildCategoriesSection(context, state, isStore: !isFoodSupercategory(selectedSupercategoryId))
                          .animate(controller: _animationController)
                          .fadeIn(duration: 400.ms, delay: 200.ms, curve: Curves.easeOut)
                          .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut),
                      
                      // Food Type Filters (only for food supercategory) - Only show if not outside service area
                      if (!isOutsideServiceableArea && isFoodSupercategory(selectedSupercategoryId) && state.foodTypes.isNotEmpty)
                        _buildFoodTypeFiltersSection(context, state)
                          .animate(controller: _animationController)
                          .fadeIn(duration: 400.ms, delay: 250.ms, curve: Curves.easeOut)
                          .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut),
                      
                      // Recent Orders Section - Only show if not outside service area and has recent orders
                              if (!isOutsideServiceableArea && state.recentOrders.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildRecentOrdersSection(context, state)
              .animate(controller: _animationController)
              .fadeIn(duration: 400.ms, delay: 275.ms, curve: Curves.easeOut)
              .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut),
          ),
                      
                      // All Restaurants or Outside Service Area Message
                      if (isOutsideServiceableArea)
                        _buildOutsideServiceableArea(context)
                          .animate(controller: _animationController)
                          .fadeIn(duration: 400.ms, delay: 300.ms, curve: Curves.easeOut)
                          .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut)
                      else
                        _buildRestaurantsSection(context, state, isStore: !isFoodSupercategory(selectedSupercategoryId))
                          .animate(controller: _animationController)
                          .fadeIn(duration: 400.ms, delay: 300.ms, curve: Curves.easeOut)
                          .slideY(begin: 0.2, end: 0, duration: 400.ms, curve: Curves.easeOut),
                      
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildAddressBar(BuildContext context, HomeLoaded state) {
    // For food supercategory, use original styling
    final isFood = isFoodSupercategory(selectedSupercategoryId);
    
    return InkWell(
      onTap: () => _showAddressPicker(context, state),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isWide = constraints.maxWidth > 600;
            
            return Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isFood ? ColorManager.primary.withOpacity(0.1) : ColorManager.instamartGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.location_on, color: isFood ? ColorManager.primary : ColorManager.instamartGreen, size: isWide ? 24 : 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deliver to',
                        style: GoogleFonts.poppins(
                          fontSize: getResponsiveFontSize(context, 12), 
                          color: Colors.grey[600], 
                          letterSpacing: 0.3,
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              state.userAddress,
                              style: GoogleFonts.poppins(
                                fontSize: getResponsiveFontSize(context, 14), 
                                fontWeight: FontWeight.w600, 
                                color: Colors.grey[800],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Ultra fresh location update button
                          GestureDetector(
                            onTap: () => _updateLocationFromHome(context),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.grey[200], 
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.my_location, color: ColorManager.primary, size: isWide ? 18 : 16),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey[200], 
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.keyboard_arrow_down, color: ColorManager.primary, size: isWide ? 18 : 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 3))],
                    gradient: LinearGradient(
                      colors: [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.7)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () => Navigator.pushNamed(context, Routes.profileView),
                      child: Padding(
                        padding: EdgeInsets.all(isWide ? 10 : 8),
                        child: Icon(Icons.person, color: ColorManager.primary, size: isWide ? 26 : 24),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, HomeLoaded state, {bool isStore = false}) {
    return Hero(
      tag: 'search_bar',
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isStore ? ColorManager.instamartGreen.withOpacity(0.2) : Colors.grey[200]!,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.search, 
                color: isStore ? ColorManager.instamartGreen : Colors.grey[500],
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  readOnly: true,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                  decoration: InputDecoration.collapsed(
                    hintText: isStore ? 'Search for groceries, fruits & more...' : 'Search stores or dishes...',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.grey[500],
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider(
                          create: (_) => SearchBloc(),
                          child: SearchPage(
                            userLatitude: state.userLatitude,
                            userLongitude: state.userLongitude,
                            supercategoryId: selectedSupercategoryId,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (isStore)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: ColorManager.instamartGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.search,
                    color: ColorManager.instamartGreen,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }



Widget _buildCategoriesSection(BuildContext context, HomeLoaded state, {bool isStore = false}) {
  debugPrint('HomePage: _buildCategoriesSection called with selectedCategoryId: ${state.selectedCategoryId}');
  debugPrint('HomePage: _buildCategoriesSection - Show All button should be visible: ${state.selectedCategoryId != null}');
  
  final sortedCategories = List<Map<String, dynamic>>.from(state.categories)
    ..sort((a, b) => (a['display_order'] ?? 999).compareTo(b['display_order'] ?? 999));

  return Container(
    margin: const EdgeInsets.only(top: 12),
    child: Padding(
      padding: EdgeInsets.only(right:MediaQuery.of(context).size.width*0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final double maxWidth = constraints.maxWidth;
              final double scale = (maxWidth / 400).clamp(0.7, 1.0);
      
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: 16 * scale),
                    child: Text(
                      isStore ? 'Categories' : 'Popular Categories',
                      style: GoogleFonts.poppins(
                        fontSize: getResponsiveFontSize(context, 18 * scale),
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (state.selectedCategoryId != null)
                        Container(
                          margin: EdgeInsets.only(right: 8 * scale),
                          child: GestureDetector(
                            onTap: () {
                              debugPrint('HomePage: Clear button pressed to clear category filter');
                              context.read<HomeBloc>().add(const FilterByCategory(null));
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 12 * scale, vertical: 6 * scale),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(16 * scale),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.close, color: Colors.grey[600], size: 14 * scale),
                                  SizedBox(width: 4 * scale),
                                  Text(
                                    'Clear',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12 * scale,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      GestureDetector(
                        onTap: () => _showFuturisticFilterDialog(context),
                        child: Container(
                          padding: EdgeInsets.all(8 * scale),
                          decoration: BoxDecoration(
                            color: isStore ? ColorManager.instamartGreen.withOpacity(0.1) : ColorManager.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8 * scale),
                            border: Border.all(
                              color: isStore ? ColorManager.instamartGreen.withOpacity(0.3) : ColorManager.primary.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.tune,
                            color: isStore ? ColorManager.instamartGreen : ColorManager.primary,
                            size: 18 * scale,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final double maxWidth = constraints.maxWidth;
              final double scale = (maxWidth / 400).clamp(0.7, 1.0);
              final double itemWidth = isStore ? 80.0 * scale : 90.0 * scale;
              final double itemHeight = isStore ? 90.0 * scale : 110.0 * scale;
              final double screenWidth = constraints.maxWidth;
              final int maxVisibleItems = (screenWidth / itemWidth).floor();
              final bool shouldScroll = sortedCategories.length > maxVisibleItems;
      
              final categoryItems = _getCategoryItems(
                sortedCategories,
                state.selectedCategoryId,
                scale: scale,
                itemWidth: itemWidth,
                itemHeight: itemHeight,
                isStore: isStore,
              );
      
              if (shouldScroll) {
                return SizedBox(
                  height: itemHeight,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 8 * scale),
                    children: categoryItems,
                  ),
                );
              } else {
                return Container(
                  height: itemHeight,
                  padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 8 * scale),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: categoryItems,
                  ),
                );
              }
            },
          ),
        ],
      ),
    ),
  );
}

    Widget _buildFoodTypeFiltersSection(BuildContext context, HomeLoaded state) {
    debugPrint('HomePage: _buildFoodTypeFiltersSection called with selectedFoodTypeId: \\${state.selectedFoodTypeId}');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final double maxWidth = constraints.maxWidth;
            final double scale = (maxWidth / 400).clamp(0.8, 1.2);
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 20 * scale, vertical: 12 * scale),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6 * scale),
                    decoration: BoxDecoration(
                      color: ColorManager.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6 * scale),
                    ),
                    child: Icon(
                      Icons.restaurant_menu,
                      color: ColorManager.primary,
                      size: 14 * scale,
                    ),
                  ),
                  SizedBox(width: 10 * scale),
                  Text(
                    'Food Types', // Only shown for food supercategory
                    style: GoogleFonts.poppins(
                      fontSize: getResponsiveFontSize(context, 14 * scale), 
                      fontWeight: FontWeight.w600, 
                      color: Colors.grey[800], 
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final double maxWidth = constraints.maxWidth;
            final double scale = (maxWidth / 400).clamp(0.8, 1.2);
            final double itemHeight = 90.0 * scale;
            final foodTypeItems = _getFoodTypeItems(state.foodTypes, state.selectedFoodTypeId, scale: scale, itemHeight: itemHeight);
            
            return SizedBox(
              height: itemHeight,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 16 * scale),
                children: foodTypeItems,
              ),
            );
          },
        ),
      ],
    );
  }
  
  List<Widget> _getCategoryItems(List<dynamic> categories, String? selectedCategoryId, {double scale = 1.0, double itemWidth = 90.0, double itemHeight = 120.0, bool isStore = false}) {
    debugPrint('HomePage: Building category items. Selected categoryId: $selectedCategoryId');
    final Map<String, String> imageMap = {
      'pizza': 'assets/images/pizza.jpg',
      'burger': 'assets/images/burger.jpg',
      'sushi': 'assets/images/sushi.jpg',
      'dessert': 'assets/images/desert.jpg',
      'drinks': 'assets/images/drinks.jpg',
    };
    return categories.map((category) {
      String categoryId = category['id']?.toString() ?? '';
      String categoryDisplayName = category['name'].toString();
      String? imagePath;
      bool isSelected = selectedCategoryId == categoryId;
      debugPrint('HomePage: Category $categoryDisplayName (id: $categoryId) - isSelected: $isSelected');
      // Use API image if available
      if (category['image'] != null && (category['image'] as String).isNotEmpty) {
        imagePath = category['image'];
      } else {
        for (final entry in imageMap.entries) {
          if (categoryId == entry.key || (categoryId.contains(entry.key) && entry.key.length > 3)) {
            imagePath = entry.value;
            break;
          }
        }
      }
      final iconAndColor = _getSmartCategoryIconAndColor(categoryDisplayName);
      final icon = iconAndColor['icon'] ?? category['icon'] ?? 'restaurant';
      final color = iconAndColor['color'] ?? category['color'] ?? 'orange';
      
      // Enhanced image handling for stores
      if (isStore) {
        // For stores, always use icon-based design for consistency
        return _buildStoreCategoryItem(categoryDisplayName, _getIconData(icon), _getCategoryColor(color), isSelected: isSelected, onTap: () {
          if (mounted && _shouldProcessFilterTap()) {
            final newCategoryId = isSelected ? null : categoryId;
            debugPrint('Category filter: $categoryDisplayName (id: $categoryId) - wasSelected: $isSelected, newCategoryId: $newCategoryId');
            context.read<HomeBloc>().add(FilterByCategory(newCategoryId));
          }
        }, scale: scale, itemWidth: itemWidth, itemHeight: itemHeight);
      } else {
        // For food, use image if available and valid, otherwise icon
        if (imagePath != null && imagePath.isNotEmpty && imagePath.startsWith('http')) {
          return _buildCategoryItemWithNetworkImage(categoryDisplayName, imagePath, color, isSelected: isSelected, onTap: () {
            if (mounted && _shouldProcessFilterTap()) {
              final newCategoryId = isSelected ? null : categoryId;
              debugPrint('Category filter: $categoryDisplayName (id: $categoryId) - wasSelected: $isSelected, newCategoryId: $newCategoryId');
              context.read<HomeBloc>().add(FilterByCategory(newCategoryId));
            }
          }, scale: scale, itemWidth: itemWidth, itemHeight: itemHeight);
        } else {
          return _buildCategoryItemWithIcon(categoryDisplayName, _getIconData(icon), _getCategoryColor(color), isSelected: isSelected, onTap: () {
            if (mounted && _shouldProcessFilterTap()) {
              final newCategoryId = isSelected ? null : categoryId;
              debugPrint('Category filter: $categoryDisplayName (id: $categoryId) - wasSelected: $isSelected, newCategoryId: $newCategoryId');
              context.read<HomeBloc>().add(FilterByCategory(newCategoryId));
            }
          }, scale: scale, itemWidth: itemWidth, itemHeight: itemHeight);
        }
      }
    }).toList();
  }

  List<Widget> _getFoodTypeItems(List<Map<String, dynamic>> foodTypes, String? selectedFoodTypeId, {double scale = 1.0, double itemHeight = 50.0}) {
    debugPrint('HomePage: Building food type items. Selected food type ID: $selectedFoodTypeId');
    debugPrint('HomePage: _getFoodTypeItems called with selectedFoodTypeId: $selectedFoodTypeId');
    return foodTypes.map((foodType) {
      final foodTypeId = foodType['restaurant_food_type_id']?.toString() ?? '';
      final foodTypeName = foodType['name']?.toString() ?? 'Unknown';
      final isSelected = selectedFoodTypeId == foodTypeId;
      
      debugPrint('HomePage: Food type $foodTypeName (ID: $foodTypeId) - isSelected: $isSelected');
      
      return _buildFoodTypeItem(
        foodTypeName,
        foodTypeId,
        isSelected: isSelected,
        onTap: () {
          // Prevent double-tap issues with debounce
          if (mounted && _shouldProcessFilterTap()) {
            final newFoodTypeId = isSelected ? null : foodTypeId;
            debugPrint('Food type filter: $foodTypeName (id: $foodTypeId) - wasSelected: $isSelected, newFoodTypeId: $newFoodTypeId');
            context.read<HomeBloc>().add(FilterByFoodType(newFoodTypeId));
          }
        },
        scale: scale,
        itemHeight: itemHeight,
      );
    }).toList();
  }

  Widget _buildFoodTypeItem(String title, String foodTypeId, {bool isSelected = false, VoidCallback? onTap, double scale = 1.0, double itemHeight = 50.0}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 6 * scale),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Toggle Switch - Compact and clean
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: 48 * scale,
              height: 28 * scale,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14 * scale),
                color: isSelected ? ColorManager.primary : Colors.grey[400],
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: ColorManager.primary.withOpacity(0.3),
                    blurRadius: 4 * scale,
                    offset: Offset(0, 2 * scale),
                  ),
                ] : [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 3 * scale,
                    offset: Offset(0, 1 * scale),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Toggle Circle
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    left: isSelected ? (22 * scale) : (2 * scale),
                    top: 2 * scale,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      width: 24 * scale,
                      height: 24 * scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 3 * scale,
                            offset: Offset(0, 1 * scale),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12 * scale),
            // Food Type Name
            Flexible(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.poppins(
                  fontSize: getResponsiveFontSize(context, 13 * scale),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? ColorManager.primary : Colors.grey[800],
                ),
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreCategoryItem(String title, IconData icon, Color color, {bool isSelected = false, VoidCallback? onTap, double scale = 1.0, double itemWidth = 80.0, double itemHeight = 100.0}) {
    return Container(
      width: itemWidth,
      margin: EdgeInsets.only(right: 10 * scale),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50 * scale,
              height: 50 * scale,
              decoration: BoxDecoration(
                color: isSelected ? ColorManager.instamartGreen : Colors.white,
                borderRadius: BorderRadius.circular(10 * scale),
                border: Border.all(
                  color: isSelected ? ColorManager.instamartGreen : Colors.grey[300]!,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : color,
                  size: 20 * scale,
                ),
              ),
            ),
            SizedBox(height: 6 * scale),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 10 * scale,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? ColorManager.instamartGreen : Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItemWithNetworkImage(String title, String imageUrl, String colorName, {bool isSelected = false, VoidCallback? onTap, double scale = 1.0, double itemWidth = 90.0, double itemHeight = 120.0}) {
    Color accentColor = _getCategoryColor(colorName);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 6 * scale),
        width: itemWidth,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 60 * scale,
                  height: 60 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    boxShadow: [
                      BoxShadow(
                        color: isSelected ? accentColor.withOpacity(0.4) : accentColor.withOpacity(0.2),
                        blurRadius: isSelected ? 12 * scale : 8 * scale,
                        offset: Offset(0, 4 * scale),
                        spreadRadius: isSelected ? 3 * scale : 1.5 * scale,
                      )
                    ],
                  ),
                ),
                Container(
                  width: 56 * scale,
                  height: 56 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? accentColor : Colors.white,
                      width: isSelected ? 3 * scale : 2 * scale,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: isSelected
                                  ? [accentColor.withOpacity(0.3), accentColor.withOpacity(0.5)]
                                  : [Colors.white, accentColor.withOpacity(0.15)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Icon(
                            _getIconData('restaurant'),
                            size: isSelected ? 28 * scale : 24 * scale,
                            color: accentColor,
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: isSelected
                                  ? [accentColor.withOpacity(0.3), accentColor.withOpacity(0.5)]
                                  : [Colors.white, accentColor.withOpacity(0.15)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                              strokeWidth: 2,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 18 * scale,
                      height: 18 * scale,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5 * scale),
                      ),
                      child: Icon(Icons.check, color: Colors.white, size: 10 * scale),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8 * scale),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 7 * scale, vertical: 4 * scale),
              decoration: BoxDecoration(
                color: isSelected ? accentColor.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(10 * scale),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 3 * scale, offset: Offset(0, 1.5 * scale))],
                border: Border.all(
                  color: isSelected ? accentColor.withOpacity(0.5) : accentColor.withOpacity(0.3),
                  width: isSelected ? 1.5 * scale : 1 * scale,
                ),
              ),
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: getResponsiveFontSize(context, 11 * scale),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? accentColor : Colors.grey[800],
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItemWithIcon(String title, IconData icon, Color accentColor, {bool isSelected = false, VoidCallback? onTap, double scale = 1.0, double itemWidth = 90.0, double itemHeight = 120.0}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 6 * scale),
        width: itemWidth,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 60 * scale,
                  height: 60 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    boxShadow: [
                      BoxShadow(
                        color: isSelected ? accentColor.withOpacity(0.4) : accentColor.withOpacity(0.2),
                        blurRadius: isSelected ? 12 * scale : 8 * scale,
                        offset: Offset(0, 4 * scale),
                        spreadRadius: isSelected ? 3 * scale : 1.5 * scale,
                      )
                    ],
                  ),
                ),
                Container(
                  width: 56 * scale,
                  height: 56 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isSelected
                          ? [accentColor.withOpacity(0.3), accentColor.withOpacity(0.5)]
                          : [Colors.white, accentColor.withOpacity(0.15)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: isSelected ? accentColor : Colors.white,
                      width: isSelected ? 3 * scale : 2 * scale,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      size: isSelected ? 28 * scale : 24 * scale,
                      color: accentColor,
                    ),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 18 * scale,
                      height: 18 * scale,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5 * scale),
                      ),
                      child: Icon(Icons.check, color: Colors.white, size: 10 * scale),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8 * scale),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 7 * scale, vertical: 4 * scale),
              decoration: BoxDecoration(
                color: isSelected ? accentColor.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(10 * scale),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 3 * scale, offset: Offset(0, 1.5 * scale))],
                border: Border.all(
                  color: isSelected ? accentColor.withOpacity(0.5) : accentColor.withOpacity(0.3),
                  width: isSelected ? 1.5 * scale : 1 * scale,
                ),
              ),
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: getResponsiveFontSize(context, 11 * scale),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? accentColor : Colors.grey[800],
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryItem(String title, String imagePath, String colorName, {bool isSelected = false, VoidCallback? onTap, double scale = 1.0, double itemWidth = 90.0, double itemHeight = 120.0}) {
    Color accentColor = _getCategoryColor(colorName);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 6 * scale),
        width: itemWidth,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 60 * scale,
                  height: 60 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    boxShadow: [
                      BoxShadow(
                        color: isSelected ? accentColor.withOpacity(0.4) : accentColor.withOpacity(0.2),
                        blurRadius: isSelected ? 12 * scale : 8 * scale,
                        offset: Offset(0, 4 * scale),
                        spreadRadius: isSelected ? 3 * scale : 1.5 * scale,
                      )
                    ],
                  ),
                ),
                Container(
                  width: 56 * scale,
                  height: 56 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover),
                    border: Border.all(color: Colors.white, width: isSelected ? 3 * scale : 2 * scale),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 18 * scale,
                      height: 18 * scale,
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5 * scale),
                      ),
                      child: Icon(Icons.check, color: Colors.white, size: 10 * scale),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8 * scale),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 7 * scale, vertical: 4 * scale),
              decoration: BoxDecoration(
                color: isSelected ? accentColor.withOpacity(0.1) : Colors.white,
                borderRadius: BorderRadius.circular(10 * scale),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 3 * scale, offset: Offset(0, 1.5 * scale))],
                border: Border.all(
                  color: isSelected ? accentColor.withOpacity(0.5) : accentColor.withOpacity(0.3),
                  width: isSelected ? 1.5 * scale : 1 * scale,
                ),
              ),
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: getResponsiveFontSize(context, 11 * scale),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? accentColor : Colors.grey[800],
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantsSection(BuildContext context, HomeLoaded state, {bool isStore = false}) {
    debugPrint('UI: Building restaurants section with \\${state.restaurants.length} restaurants');
    debugPrint('UI: Current filter options - vegOnly: \\${filterOptions.vegOnly}, priceLowToHigh: \\${filterOptions.priceLowToHigh}, priceHighToLow: \\${filterOptions.priceHighToLow}, ratingHighToLow: \\${filterOptions.ratingHighToLow}, ratingLowToHigh: \\${filterOptions.ratingLowToHigh}, timeSort: \\${filterOptions.timeSort}');
    
    // Get filtered restaurants using the state's helper method
    var filteredRestaurants = state.filteredRestaurants;
    
    // Debug: Print original restaurant data
    debugPrint('=== ORIGINAL RESTAURANT DATA ===');
    for (int i = 0; i < filteredRestaurants.length; i++) {
      final restaurant = filteredRestaurants[i];
      debugPrint('Restaurant $i: \\${restaurant.name} - Rating: \\${restaurant.rating} (\\${restaurant.rating.runtimeType}), Type: \\${restaurant.restaurantType}, Veg: \\${restaurant.isVeg}');
    }
    
    // Apply additional filters from FilterOptions
    if (filterOptions.ratingHighToLow) {
      // Sort by rating high to low
      filteredRestaurants.sort((a, b) {
        final aRating = double.tryParse(a.rating?.toString() ?? '0') ?? 0.0;
        final bRating = double.tryParse(b.rating?.toString() ?? '0') ?? 0.0;
        return bRating.compareTo(aRating);
      });
      debugPrint('HomePage: Applied rating sort high to low');
      
      // Debug: Print sorted ratings
      debugPrint('=== RATING SORT HIGH TO LOW ===');
      for (int i = 0; i < filteredRestaurants.length; i++) {
        final restaurant = filteredRestaurants[i];
        final rating = double.tryParse(restaurant.rating?.toString() ?? '0') ?? 0.0;
        debugPrint('Position $i: ${restaurant.name} - Rating: $rating');
      }
    } else if (filterOptions.ratingLowToHigh) {
      // Sort by rating low to high
      filteredRestaurants.sort((a, b) {
        final aRating = double.tryParse(a.rating?.toString() ?? '0') ?? 0.0;
        final bRating = double.tryParse(b.rating?.toString() ?? '0') ?? 0.0;
        return aRating.compareTo(bRating);
      });
      debugPrint('HomePage: Applied rating sort low to high');
      
      // Debug: Print sorted ratings
      debugPrint('=== RATING SORT LOW TO HIGH ===');
      for (int i = 0; i < filteredRestaurants.length; i++) {
        final restaurant = filteredRestaurants[i];
        final rating = double.tryParse(restaurant.rating?.toString() ?? '0') ?? 0.0;
        debugPrint('Position $i: ${restaurant.name} - Rating: $rating');
      }
    }
    
    if (filterOptions.timeSort) {
      // Sort by delivery time (using rating as proxy for better restaurants)
      filteredRestaurants.sort((a, b) {
        final aRating = double.tryParse(a.rating?.toString() ?? '0') ?? 0.0;
        final bRating = double.tryParse(b.rating?.toString() ?? '0') ?? 0.0;
        return bRating.compareTo(aRating);
      });
      debugPrint('HomePage: Applied time sort');
      
      // Debug: Print sorted by time (rating)
      debugPrint('=== TIME SORT (BY RATING) ===');
      for (int i = 0; i < filteredRestaurants.length; i++) {
        final restaurant = filteredRestaurants[i];
        final rating = double.tryParse(restaurant.rating?.toString() ?? '0') ?? 0.0;
        debugPrint('Position $i: ${restaurant.name} - Rating: $rating');
      }
    }
    
    // For price sorting, we'll use a simple heuristic based on restaurant type
    if (filterOptions.priceLowToHigh) {
      // Sort by restaurant type (assuming premium types are more expensive)
      filteredRestaurants.sort((a, b) {
        final aType = a.restaurantType?.toLowerCase() ?? '';
        final bType = b.restaurantType?.toLowerCase() ?? '';
        
        // Simple price ranking based on restaurant type
        int getPriceRank(String type) {
          if (type.contains('premium') || type.contains('fine') || type.contains('restaurant')) return 3;
          if (type.contains('casual') || type.contains('family') || type.contains('cloud kitchen')) return 2;
          return 1; // budget/fast food
        }
        
        return getPriceRank(aType).compareTo(getPriceRank(bType));
      });
      debugPrint('HomePage: Applied price sort low to high');
      
      // Debug: Print sorted by price (type)
      debugPrint('=== PRICE SORT LOW TO HIGH ===');
      for (int i = 0; i < filteredRestaurants.length; i++) {
        final restaurant = filteredRestaurants[i];
        final type = restaurant.restaurantType?.toLowerCase() ?? '';
        int getPriceRank(String t) {
          if (t.contains('premium') || t.contains('fine') || t.contains('restaurant')) return 3;
          if (t.contains('casual') || t.contains('family') || t.contains('cloud kitchen')) return 2;
          return 1;
        }
        final priceRank = getPriceRank(type);
        debugPrint('Position $i: ${restaurant.name} - Type: $type (Price Rank: $priceRank)');
      }
    } else if (filterOptions.priceHighToLow) {
      // Sort by restaurant type (premium first)
      filteredRestaurants.sort((a, b) {
        final aType = a.restaurantType?.toLowerCase() ?? '';
        final bType = b.restaurantType?.toLowerCase() ?? '';
        
        // Simple price ranking based on restaurant type
        int getPriceRank(String type) {
          if (type.contains('premium') || type.contains('fine') || type.contains('restaurant')) return 3;
          if (type.contains('casual') || type.contains('family') || type.contains('cloud kitchen')) return 2;
          return 1; // budget/fast food
        }
        
        return getPriceRank(bType).compareTo(getPriceRank(aType));
      });
      debugPrint('HomePage: Applied price sort high to low');
      
      // Debug: Print sorted by price (type)
      debugPrint('=== PRICE SORT HIGH TO LOW ===');
      for (int i = 0; i < filteredRestaurants.length; i++) {
        final restaurant = filteredRestaurants[i];
        final type = restaurant.restaurantType?.toLowerCase() ?? '';
        int getPriceRank(String t) {
          if (t.contains('premium') || t.contains('fine') || t.contains('restaurant')) return 3;
          if (t.contains('casual') || t.contains('family') || t.contains('cloud kitchen')) return 2;
          return 1;
        }
        final priceRank = getPriceRank(type);
        debugPrint('Position $i: ${restaurant.name} - Type: $type (Price Rank: $priceRank)');
      }
    }
    
    // Debug: Print final filtered results
    debugPrint('=== FINAL FILTERED RESULTS ===');
    for (int i = 0; i < filteredRestaurants.length; i++) {
      final restaurant = filteredRestaurants[i];
      final rating = double.tryParse(restaurant.rating?.toString() ?? '0') ?? 0.0;
      final type = restaurant.restaurantType?.toLowerCase() ?? '';
      debugPrint('Final Position $i: ${restaurant.name} - Rating: $rating, Type: $type, Veg: ${restaurant.isVeg}');
    }
    
          String title = isStore ? 'All Stores' : 'All Stores';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: getResponsiveFontSize(context, 16),
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
             
            ],
          ),
        ),
        // Restaurant List or No Results Message
        if (filteredRestaurants.isEmpty)
          _buildNoResultsMessage(context, state)
        else if (isStore)
          // Grid layout for stores (2 per row)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
              ),
              itemCount: filteredRestaurants.length,
              itemBuilder: (context, index) => _buildStoreGridItem(
                context, filteredRestaurants[index], state, index
              ),
            ),
          )
        else
          // List layout for restaurants (original)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredRestaurants.length,
            itemBuilder: (context, index) => _buildRestaurantItem(
              context, filteredRestaurants[index], state, index, isStore: isStore
            ),
          ),
      ],
    );
  }

  Widget _buildStoreGridItem(BuildContext context, dynamic store, HomeLoaded state, int index) {
    final sanitizedName = _sanitizeRestaurantName(store.name);
    
    return Hero(
      tag: 'store-$sanitizedName',
      child: BlocBuilder<HomeFavoritesBloc, HomeFavoritesState>(
        builder: (context, favoritesState) {
          bool isFavorite = false;
          bool isLoading = false;
          
                  // Get cached status first
        final cachedStatus = context.read<HomeFavoritesBloc>().getCachedFavoriteStatus(store.id);
        if (cachedStatus != null) {
          isFavorite = cachedStatus;
        } else {
          // If no cached status, assume not favorite to avoid showing wrong state
          isFavorite = false;
        }
          
          // Check if this store's favorite status has been checked
          if (favoritesState is HomeFavoriteStatusChecked && 
              favoritesState.partnerId == store.id) {
            isFavorite = favoritesState.isFavorite;
          } else if (favoritesState is HomeFavoriteToggled && 
                     favoritesState.partnerId == store.id) {
            isFavorite = favoritesState.isNowFavorite;
          } else if (favoritesState is HomeFavoriteToggling && 
                     favoritesState.partnerId == store.id) {
            isLoading = true;
            // Show optimistic update
            isFavorite = favoritesState.isAdding;
          } else if (favoritesState is HomeFavoritesCacheRefreshed) {
            // Use the updated cache data
            isFavorite = favoritesState.updatedFavorites[store.id] ?? false;
          }
          
          // Only check favorite status when user interacts with favorite button
          // No automatic checking to prevent background API calls
          
          return RestaurantCard(
            name: store.name,
            imageUrl: store.imageUrl ?? 'assets/images/placeholder.jpg',
            cuisine: store.cuisine,
            description: store.description,
            rating: store.rating ?? 0.0,
            isVeg: store.isVeg,
            restaurantLatitude: store.latitude,
            restaurantLongitude: store.longitude,
            userLatitude: state.userLatitude,
            userLongitude: state.userLongitude,
            restaurantType: store.restaurantType,
            isAcceptingOrder: store.isAcceptingOrder,
            partnerId: store.id,
            isFavorite: isFavorite,
            isLoading: isLoading,
            isFoodSupercategory: isFoodSupercategory(selectedSupercategoryId),
            onFavoriteToggle: store.id != null && store.id.isNotEmpty ? () {
              context.read<HomeFavoritesBloc>().add(
                CheckAndToggleHomeFavorite(partnerId: store.id),
              );
            } : null,
            onTap: () => _navigateToRestaurantDetails(context, store),
          ).animate(controller: _animationController)
            .fadeIn(duration: 400.ms, delay: (300 + (index * 75)).ms, curve: Curves.easeOut)
            .slideY(begin: 0.1, end: 0, duration: 400.ms, delay: (300 + (index * 50)).ms, curve: Curves.easeOutQuad);
        },
      ),
    );
  }

Widget _buildRestaurantItem(BuildContext context, dynamic restaurant, HomeLoaded state, int index, {bool isStore = false}) {
  final sanitizedName = _sanitizeRestaurantName(restaurant.name);
  
  return Hero(
    tag: 'restaurant-$sanitizedName',
    child: BlocBuilder<HomeFavoritesBloc, HomeFavoritesState>(
      builder: (context, favoritesState) {
        bool isFavorite = false;
        bool isLoading = false;
        
        // Get cached status first
        final cachedStatus = context.read<HomeFavoritesBloc>().getCachedFavoriteStatus(restaurant.id);
        if (cachedStatus != null) {
          isFavorite = cachedStatus;
        }
        
        // Check if this restaurant's favorite status has been checked
        if (favoritesState is HomeFavoriteStatusChecked && 
            favoritesState.partnerId == restaurant.id) {
          isFavorite = favoritesState.isFavorite;
        } else if (favoritesState is HomeFavoriteToggled && 
                   favoritesState.partnerId == restaurant.id) {
          isFavorite = favoritesState.isNowFavorite;
        } else if (favoritesState is HomeFavoriteToggling && 
                   favoritesState.partnerId == restaurant.id) {
          isLoading = true;
          // Show optimistic update
          isFavorite = favoritesState.isAdding;
        } else if (favoritesState is HomeFavoritesCacheRefreshed) {
          // Use the updated cache data
          isFavorite = favoritesState.updatedFavorites[restaurant.id] ?? false;
        }
        
        // Only check favorite status when user interacts with favorite button
        // No automatic checking to prevent background API calls
        
        return RestaurantCard(
          name: restaurant.name,
          imageUrl: restaurant.imageUrl ?? 'assets/images/placeholder.jpg',
          cuisine: restaurant.cuisine,
          description: restaurant.description,
          rating: restaurant.rating ?? 0.0,
          isVeg: restaurant.isVeg,
          restaurantLatitude: restaurant.latitude,
          restaurantLongitude: restaurant.longitude,
          userLatitude: state.userLatitude,
          userLongitude: state.userLongitude,
          restaurantType: restaurant.restaurantType,
          isAcceptingOrder: restaurant.isAcceptingOrder,
          partnerId: restaurant.id,
          isFavorite: isFavorite,
          isLoading: isLoading,
          isFoodSupercategory: isFoodSupercategory(selectedSupercategoryId),
          onFavoriteToggle: restaurant.id != null && restaurant.id.isNotEmpty ? () {
            context.read<HomeFavoritesBloc>().add(
              CheckAndToggleHomeFavorite(partnerId: restaurant.id),
            );
          } : null,
          onTap: () => _navigateToRestaurantDetails(context, restaurant),
        ).animate(controller: _animationController)
          .fadeIn(duration: 400.ms, delay: (300 + (index * 75)).ms, curve: Curves.easeOut)
          .slideY(begin: 0.1, end: 0, duration: 400.ms, delay: (300 + (index * 50)).ms, curve: Curves.easeOutQuad);
      },
    ),
  );
}

  Widget _buildNoResultsMessage(BuildContext context, HomeLoaded state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'No Stores Found',
            style: GoogleFonts.poppins(
              fontSize: getResponsiveFontSize(context, 24),
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Try adjusting your filters or search criteria.',
            style: GoogleFonts.poppins(
              fontSize: getResponsiveFontSize(context, 16),
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Clear all filters
              context.read<HomeBloc>().add(const ResetFilters());
            },
            icon: const Icon(Icons.clear_all, color: Colors.white),
            label: Text(
              'Clear Filters',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                fontSize: getResponsiveFontSize(context, 16),
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorManager.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              minimumSize: const Size(double.infinity, 54),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutsideServiceableArea(BuildContext context) {
    final state = context.read<HomeBloc>().state;
    final detailedMessage = state is HomeLoaded ? state.locationServiceabilityMessage : null;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Enhanced illustration
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/duckling.jpg',
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          // Main heading
          Text(
            'Outside Service Area',
            style: GoogleFonts.poppins(
              fontSize: getResponsiveFontSize(context, 28),
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
          // Detailed message from state or fallback
          Text(
            detailedMessage ?? 'We haven\'t spread our wings to this area yet.',
            style: GoogleFonts.poppins(
              fontSize: getResponsiveFontSize(context, 16),
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          Text(
            'Please try a different location within our service area to continue ordering.',
            style: GoogleFonts.poppins(
              fontSize: getResponsiveFontSize(context, 14),
              fontWeight: FontWeight.w400,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          // Action buttons
          Column(
            children: [
              // Change Location Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final state = context.read<HomeBloc>().state;
                    if (state is HomeLoaded) {
                      _showAddressPicker(context, state);
                    }
                  },
                  icon: const Icon(Icons.place, color: Colors.white, size: 20),
                  label: Text(
                    'Change Location',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: getResponsiveFontSize(context, 16),
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE17A47),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    minimumSize: const Size(double.infinity, 54),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Update Current Location Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _updateLocationFromHome(context),
                  icon: const Icon(Icons.my_location, color: Color(0xFFE17A47), size: 20),
                  label: Text(
                    'Update Current Location',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: getResponsiveFontSize(context, 14),
                      color: const Color(0xFFE17A47),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE17A47),
                    side: const BorderSide(color: Color(0xFFE17A47), width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    minimumSize: const Size(double.infinity, 54),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Additional info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'We\'re constantly expanding our service areas. Check back soon!',
                    style: GoogleFonts.poppins(
                      fontSize: getResponsiveFontSize(context, 12),
                      fontWeight: FontWeight.w400,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToRestaurantDetails(BuildContext context, dynamic restaurant) {
    debugPrint('HomePage: Navigating to restaurant details');
    
    final state = context.read<HomeBloc>().state;
    double? userLatitude;
    double? userLongitude;
    
    if (state is HomeLoaded) {
      userLatitude = state.userLatitude;
      userLongitude = state.userLongitude;
      debugPrint('HomePage: User coordinates - Lat: $userLatitude, Long: $userLongitude');
    }
    
    // Convert restaurant data to the expected Map format for RestaurantDetailsPage
    final restaurantData = <String, dynamic>{
      'id': restaurant is Map ? restaurant['id'] : restaurant.id,
      'partner_id': restaurant is Map ? restaurant['partner_id'] : restaurant.id,
      'name': restaurant is Map ? restaurant['name'] : restaurant.name,
      'restaurant_name': restaurant is Map ? restaurant['restaurant_name'] : restaurant.name,
      'imageUrl': restaurant is Map ? restaurant['imageUrl'] : restaurant.imageUrl,
      'cuisine': restaurant is Map ? restaurant['cuisine'] : restaurant.cuisine,
      'category': restaurant is Map ? restaurant['category'] : restaurant.cuisine,
      'rating': restaurant is Map ? restaurant['rating'] : restaurant.rating,
      'isVegetarian': restaurant is Map ? restaurant['isVegetarian'] : restaurant.isVeg,
      'isVeg': restaurant is Map ? restaurant['isVeg'] : restaurant.isVeg,
      'veg_nonveg': restaurant is Map ? restaurant['veg_nonveg'] : (restaurant.isVeg ? 'veg' : 'non-veg'),
      'address': restaurant is Map ? restaurant['address'] : restaurant.address,
      'latitude': restaurant is Map ? restaurant['latitude'] : restaurant.latitude,
      'longitude': restaurant is Map ? restaurant['longitude'] : restaurant.longitude,
      'restaurantType': restaurant is Map ? restaurant['restaurantType'] : restaurant.restaurantType,
      'restaurant_type': restaurant is Map ? restaurant['restaurant_type'] : restaurant.restaurantType,
      'description': restaurant is Map ? restaurant['description'] : restaurant.description,
      'openTimings': restaurant is Map ? restaurant['openTimings'] : restaurant.openTimings,
      'open_timings': restaurant is Map ? restaurant['open_timings'] : restaurant.openTimings,
      'ownerName': restaurant is Map ? restaurant['ownerName'] : restaurant.ownerName,
      'owner_name': restaurant is Map ? restaurant['owner_name'] : restaurant.ownerName,
      'availableCategories': restaurant is Map ? restaurant['availableCategories'] : restaurant.availableCategories,
      'isAcceptingOrder': restaurant is Map ? restaurant['isAcceptingOrder'] : restaurant.isAcceptingOrder,
    };
    
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => RestaurantDetailsPage(
          restaurantData: restaurantData,
          userLatitude: userLatitude,
          userLongitude: userLongitude,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutQuart;
          
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          
          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  Future<void> _showAddressPicker(BuildContext context, HomeLoaded state) async {
    try {
      debugPrint('HomePage: Opening address picker with ${state.savedAddresses.length} saved addresses');
      
      final result = await AddressPickerBottomSheet.show(
        context,
        savedAddresses: state.savedAddresses,
      );
      
      if (result != null && mounted) {
        final double latitude = result['latitude'] ?? 0.0;
        final double longitude = result['longitude'] ?? 0.0;
        
        debugPrint('HomePage: Address selected from picker:');
        debugPrint('  Address: ${result['address']}');
        debugPrint('  Sub-address: ${result['subAddress']}');
        debugPrint('  Latitude: $latitude');
        debugPrint('  Longitude: $longitude');
        
        if (latitude == 0.0 && longitude == 0.0) {
          debugPrint('HomePage: Warning - Got zero coordinates');
          _showCustomSnackBar(
            context,
            'Could not get location coordinates. Please try again.',
            Colors.orange,
            Icons.warning_amber_rounded,
          );
          return;
        }
        
        String fullAddress = result['address'];
        if (result['subAddress'].toString().isNotEmpty) {
          fullAddress += ', ${result['subAddress']}';
        }
        
        // Update the address immediately in the home bloc
        context.read<HomeBloc>().add(
          UpdateUserAddress(
            address: fullAddress,
            latitude: latitude,
            longitude: longitude,
          ),
        );
        
        // Reload saved addresses to show newly added ones immediately
        context.read<HomeBloc>().add(const LoadSavedAddresses());
        
        debugPrint('HomePage: Address update and reload triggered');
      }
    } catch (e) {
      debugPrint('HomePage: Error showing address picker: $e');
      _showCustomSnackBar(
        context,
        'Error opening address picker. Please try again.',
        Colors.red,
        Icons.error_outline,
      );
    }
  }

  void _showFuturisticFilterDialog(BuildContext context) {
    final blocContext = context;
    FilterOptions tempFilters = FilterOptions(
      //vegOnly: filterOptions.vegOnly,
      priceLowToHigh: filterOptions.priceLowToHigh,
      priceHighToLow: filterOptions.priceHighToLow,
      ratingHighToLow: filterOptions.ratingHighToLow,
      ratingLowToHigh: filterOptions.ratingLowToHigh,
      timeSort: filterOptions.timeSort,
    );
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Dialog(
            backgroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              width: MediaQuery.of(context).size.width * 0.9,
              padding: const EdgeInsets.all(0),
              child: DefaultTabController(
                length: 3,
                child: StatefulBuilder(
                  builder: (statefulContext, setStateDialog) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Heading with curved background
                        Container(
                          decoration: BoxDecoration(
                            color: ColorManager.primary,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                          ),
                          padding: const EdgeInsets.only(top: 20, bottom: 16, left: 20, right: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Sort & Filter',
                                style: GoogleFonts.poppins(
                                  fontSize: getResponsiveFontSize(context, 18),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.close),
                                  color: Colors.white,
                                  onPressed: () => Navigator.pop(dialogContext),
                                  iconSize: 20,
                                  padding: const EdgeInsets.all(4),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Tab Bar for different filter categories
                        TabBar(
                          tabs: [
                            const Tab(icon: Icon(Icons.attach_money), text: 'Price'),
                            const Tab(icon: Icon(Icons.timer), text: 'Time'),
                            // if (isFoodSupercategory(selectedSupercategoryId))
                            //   const Tab(icon: Icon(Icons.restaurant), text: 'Diet'),
                            const Tab(icon: Icon(Icons.star), text: 'Rating'),
                          ],
                          indicatorColor: ColorManager.primary,
                          labelColor: ColorManager.primary,
                          unselectedLabelColor: Colors.grey[600],
                          labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: getResponsiveFontSize(context, 12)),
                          unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: getResponsiveFontSize(context, 12)),
                        ),
                        // Tab Content - with fixed height
                        SizedBox(
                          height: 280,
                          child: TabBarView(
                            children: [
                              _buildPriceFilterTab(tempFilters, setStateDialog),
                              _buildTimeFilterTab(tempFilters, setStateDialog),
                              // if (isFoodSupercategory(selectedSupercategoryId))
                              //   _buildVegFilterTab(tempFilters, setStateDialog, blocContext),
                              _buildRatingFilterTab(tempFilters, setStateDialog),
                            ],
                          ),
                        ),
                        // Action Buttons
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    debugPrint('HomePage: Resetting all filters');
                                    setStateDialog(() {
                                      tempFilters = FilterOptions(); // local dialog state
                                    });
                                    // Update global filter options
                                    setState(() {
                                      filterOptions = FilterOptions();
                                    });
                                    blocContext.read<HomeBloc>().add(const ResetFilters());
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    side: BorderSide(color: ColorManager.primary),
                                  ),
                                  child: Text(
                                    'Reset',
                                    style: GoogleFonts.poppins(
                                      fontSize: getResponsiveFontSize(context, 14),
                                      fontWeight: FontWeight.w500,
                                      color: ColorManager.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: () {
                                    debugPrint('HomePage: Applying filters - vegOnly: ${tempFilters.vegOnly}, priceLowToHigh: ${tempFilters.priceLowToHigh}, priceHighToLow: ${tempFilters.priceHighToLow}, ratingHighToLow: ${tempFilters.ratingHighToLow}, ratingLowToHigh: ${tempFilters.ratingLowToHigh}, timeSort: ${tempFilters.timeSort}');
                                    
                                    // Update global filter options
                                    setState(() {
                                      filterOptions = FilterOptions(
                                        vegOnly: tempFilters.vegOnly,
                                        priceLowToHigh: tempFilters.priceLowToHigh,
                                        priceHighToLow: tempFilters.priceHighToLow,
                                        ratingHighToLow: tempFilters.ratingHighToLow,
                                        ratingLowToHigh: tempFilters.ratingLowToHigh,
                                        timeSort: tempFilters.timeSort,
                                      );
                                    });
                                    
                                    final allCleared = !tempFilters.vegOnly && !tempFilters.priceLowToHigh && !tempFilters.priceHighToLow && !tempFilters.ratingHighToLow && !tempFilters.ratingLowToHigh && !tempFilters.timeSort;
                                    if (allCleared) {
                                      blocContext.read<HomeBloc>().add(const ResetFilters());
                                      blocContext.read<HomeBloc>().add(const LoadHomeData());
                                    } else {
                                      // Only dispatch veg filter for now (as before)
                                      blocContext.read<HomeBloc>().add(ToggleVegOnly(tempFilters.vegOnly));
                                      // If you want to support other filters, add events here
                                    }
                                    Navigator.pop(dialogContext);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ColorManager.primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Apply Filters',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w500,
                                      fontSize: getResponsiveFontSize(context, 14),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ).animate().fadeIn(duration: 200.ms).scaleXY(begin: 0.9, end: 1.0, duration: 300.ms, curve: Curves.easeOutQuint),
        );
      },
    );
  }

  Widget _buildPriceFilterTab(FilterOptions tempFilters, StateSetter setStateDialog) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                'Sort by Price',
                style: GoogleFonts.poppins(
                  fontSize: getResponsiveFontSize(context, 16),
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ),
            _buildCheckboxOption(
              title: 'Low to High',
              subtitle: 'Sort by lowest price first',
              value: tempFilters.priceLowToHigh,
              color: Colors.green,
              onChanged: (value) {
                setStateDialog(() {
                  tempFilters.priceLowToHigh = value;
                  if (value) tempFilters.priceHighToLow = false; // Uncheck the other option
                });
              },
            ),
            const SizedBox(height: 16),
            _buildCheckboxOption(
              title: 'High to Low',
              subtitle: 'Sort by highest price first',
              value: tempFilters.priceHighToLow,
              color: Colors.orange,
              onChanged: (value) {
                setStateDialog(() {
                  tempFilters.priceHighToLow = value;
                  if (value) tempFilters.priceLowToHigh = false; // Uncheck the other option
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFilterTab(FilterOptions tempFilters, StateSetter setStateDialog) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                'Sort by Delivery Time',
                style: GoogleFonts.poppins(
                  fontSize: getResponsiveFontSize(context, 16),
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ),
            _buildCheckboxOption(
              title: 'Fastest First',
              subtitle: 'Sort by shortest delivery time',
              value: tempFilters.timeSort,
              color: Colors.blue,
              onChanged: (value) {
                setStateDialog(() {
                  tempFilters.timeSort = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingFilterTab(FilterOptions tempFilters, StateSetter setStateDialog) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                'Sort by Rating',
                style: GoogleFonts.poppins(
                  fontSize: getResponsiveFontSize(context, 16),
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ),
            _buildCheckboxOption(
              title: 'Highest Rated',
              subtitle: 'Sort by highest rating first',
              value: tempFilters.ratingHighToLow,
              color: Colors.amber,
              onChanged: (value) {
                setStateDialog(() {
                  tempFilters.ratingHighToLow = value;
                  if (value) tempFilters.ratingLowToHigh = false; // Uncheck the other option
                });
              },
            ),
            const SizedBox(height: 16),
            _buildCheckboxOption(
              title: 'Lowest Rated',
              subtitle: 'Sort by lowest rating first',
              value: tempFilters.ratingLowToHigh,
              color: Colors.grey,
              onChanged: (value) {
                setStateDialog(() {
                  tempFilters.ratingLowToHigh = value;
                  if (value) tempFilters.ratingHighToLow = false; // Uncheck the other option
                });
              },
            ),
          ],
        ),
      ),
    );
  }

    Widget _buildVegFilterTab(FilterOptions tempFilters, StateSetter setStateDialog, BuildContext blocContext) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                'Dietary Preferences',
                style: GoogleFonts.poppins(
                  fontSize: getResponsiveFontSize(context, 16),
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ),
            _buildCheckboxOption(
              title: 'Vegetarian Only',
              subtitle: 'Show only vegetarian restaurants',
              value: tempFilters.vegOnly,
              color: Colors.green,
              onChanged: (value) {
                debugPrint('Veg Only filter: wasSelected: ${tempFilters.vegOnly}, newVegOnly: $value');
                setStateDialog(() {
                  tempFilters.vegOnly = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String colorName) {
    switch (colorName) {
      case 'red': return Colors.red;
      case 'amber': return Colors.amber;
      case 'blue': return Colors.blue;
      case 'pink': return Colors.pink;
      case 'teal': return Colors.teal;
      case 'purple': return Colors.purple;
      case 'green': return Colors.green;
      case 'orange': return Colors.orange;
      case 'brown': return Colors.brown;
      case 'deepOrange': return Colors.deepOrange;
      default: return Colors.orange;
    }
  }
  
  void _showCustomSnackBar(BuildContext context, String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(12),
        elevation: 6,
        duration: const Duration(seconds: 3),
      ),
    );
  }
  
  Widget _buildLoadingIndicator() {
    debugPrint('UI: Showing loading indicator');
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildFuturisticLoadingIndicator(),
          const SizedBox(height: 24),
          Text(
            'Preparing your delicious experience...',
            style: GoogleFonts.poppins(fontSize: getResponsiveFontSize(context, 14), fontWeight: FontWeight.w500, color: Colors.grey[600]),
          ),
        ],
      ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOut),
    );
  }
  
  Widget _buildFuturisticLoadingIndicator() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: ColorManager.primary.withOpacity(0.2), blurRadius: 16, spreadRadius: 2)],
      ),
      child: Center(
        child: SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ColorManager.primary),
            strokeWidth: 3,
          ),
        ),
      ),
    ).animate(onPlay: (controller) => controller.repeat())
      .shimmer(duration: 1200.ms, color: Colors.white.withOpacity(0.3))
      .scaleXY(begin: 0.9, end: 1.0, duration: 700.ms)
      .then(delay: 100.ms)
      .scaleXY(begin: 1.0, end: 0.9, duration: 700.ms);
  }
  
  Widget _buildErrorState(BuildContext context, HomeError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, color: Colors.red, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              'Location Not Serviceable',
              style: GoogleFonts.poppins(fontSize: getResponsiveFontSize(context, 20), fontWeight: FontWeight.bold, color: Colors.grey[800]),
            ),
            const SizedBox(height: 12),
            Text(
              'We haven\'t spread our wings to this area yet.',
              style: GoogleFonts.poppins(fontSize: getResponsiveFontSize(context, 16), color: Colors.red[400]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                // Go back to previous location or default
                if (previousAddress != null && previousAddress != 'Add delivery address') {
                  // This would need to be implemented in the bloc
                  context.read<HomeBloc>().add(const LoadHomeData());
                } else {
                  context.read<HomeBloc>().add(const LoadHomeData());
                }
              },
              icon: const Icon(Icons.arrow_back),
              label: Text('Back to last location', style: GoogleFonts.poppins(fontSize: getResponsiveFontSize(context, 16), fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.primary,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: ColorManager.primary.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms, curve: Curves.easeOut),
    );
  }

  // Helper method to sanitize restaurant names for Hero tags
  String _sanitizeRestaurantName(String name) {
    // Remove special characters and replace spaces with underscores
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '') // Remove special characters
        .replaceAll(RegExp(r'\s+'), '_') // Replace spaces with underscores
        .trim();
  }

  Widget _buildCheckboxOption({
    required String title,
    required String subtitle,
    required bool value,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: value ? color.withOpacity(0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? color.withOpacity(0.3) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: (newValue) => onChanged(newValue ?? false),
            activeColor: color,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: getResponsiveFontSize(context, 16),
                    fontWeight: FontWeight.w600,
                    color: value ? color : Colors.grey[800],
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: getResponsiveFontSize(context, 13),
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  // Helper method to prevent double-tap on filters
  bool _shouldProcessFilterTap() {
    final now = DateTime.now();
    if (_lastFilterTap != null && now.difference(_lastFilterTap!) < _filterDebounceTime) {
      debugPrint('HomePage: Filter tap debounced - too soon after last tap');
      return false;
    }
    _lastFilterTap = now;
    return true;
  }

  // Smart category icon and color selector based on category name
  Map<String, String> _getSmartCategoryIconAndColor(String categoryName) {
    // Food type based mapping
    if (categoryName.contains('pizza')) {
      return {'icon': 'local_pizza', 'color': 'red'};
    } else if (categoryName.contains('burger') || categoryName.contains('sandwich')) {
      return {'icon': 'lunch_dining', 'color': 'amber'};
    } else if (categoryName.contains('sushi') || categoryName.contains('japanese') || categoryName.contains('asian')) {
      return {'icon': 'set_meal', 'color': 'blue'};
    } else if (categoryName.contains('dessert') || categoryName.contains('sweet') || categoryName.contains('ice') || categoryName.contains('cake')) {
      return {'icon': 'icecream', 'color': 'pink'};
    } else if (categoryName.contains('drink') || categoryName.contains('beverage') || categoryName.contains('juice') || categoryName.contains('coffee')) {
      return {'icon': 'local_drink', 'color': 'teal'};
    } else if (categoryName.contains('chinese') || categoryName.contains('noodle') || categoryName.contains('ramen')) {
      return {'icon': 'ramen_dining', 'color': 'orange'};
    } else if (categoryName.contains('breakfast') || categoryName.contains('bread') || categoryName.contains('bakery')) {
      return {'icon': 'bakery_dining', 'color': 'brown'};
    } else if (categoryName.contains('veg') || categoryName.contains('salad') || categoryName.contains('healthy')) {
      return {'icon': 'spa', 'color': 'green'};
    } else if (categoryName.contains('biryani') || categoryName.contains('rice') || categoryName.contains('indian')) {
      return {'icon': 'restaurant', 'color': 'deepOrange'};
    } else if (categoryName.contains('chicken') || categoryName.contains('meat') || categoryName.contains('grill')) {
      return {'icon': 'restaurant_menu', 'color': 'red'};
    } else if (categoryName.contains('seafood') || categoryName.contains('fish')) {
      return {'icon': 'set_meal', 'color': 'blue'};
    } else if (categoryName.contains('thai') || categoryName.contains('spicy')) {
      return {'icon': 'whatshot', 'color': 'red'};
    } else if (categoryName.contains('mexican') || categoryName.contains('taco')) {
      return {'icon': 'local_dining', 'color': 'green'};
    }
    // Default
    return {'icon': 'restaurant', 'color': 'orange'};
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'local_pizza': return Icons.local_pizza;
      case 'lunch_dining': return Icons.lunch_dining;
      case 'set_meal': return Icons.set_meal;
      case 'icecream': return Icons.icecream;
      case 'local_drink': return Icons.local_drink;
      case 'bakery_dining': return Icons.bakery_dining;
      case 'free_breakfast': return Icons.free_breakfast;
      case 'spa': return Icons.spa;
      case 'egg': return Icons.egg_alt;
      case 'ramen_dining': return Icons.ramen_dining;
      case 'restaurant': return Icons.restaurant;
      case 'restaurant_menu': return Icons.restaurant_menu;
      case 'whatshot': return Icons.whatshot;
      case 'local_dining': return Icons.local_dining;
      default: return Icons.restaurant;
    }
  }

  Widget _buildRecentOrdersSection(BuildContext context, HomeLoaded state) {
    final filteredOrders = _filterRecentOrdersBySupercategory(state.recentOrders);
    
    if (filteredOrders.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Orders',
                  style: GoogleFonts.poppins(
                    fontSize: getResponsiveFontSize(context, 16),
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, Routes.orderHistory);
                  },
                  child: Text(
                    'View All',
                    style: GoogleFonts.poppins(
                      fontSize: getResponsiveFontSize(context, 13),
                      fontWeight: FontWeight.w500,
                      color: ColorManager.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 130),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredOrders.length,
              itemBuilder: (context, index) {
                final order = filteredOrders[index];
                return Container(
                  margin: EdgeInsets.only(right: index == filteredOrders.length - 1 ? 16 : 12),
                  child: _buildRecentOrderCard(context, order),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

    Widget _buildRecentOrderCard(BuildContext context, RecentOrderModel order) {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 32; // Account for horizontal padding
    
    // More responsive card width calculation
    double cardWidth;
    if (screenWidth < 360) {
      cardWidth = 120.0; // Very small phones
    } else if (screenWidth < 480) {
      cardWidth = 130.0; // Small phones
    } else if (screenWidth < 768) {
      cardWidth = 140.0; // Medium phones
    } else {
      cardWidth = 150.0; // Large phones and tablets
    }
    
    // Ensure minimum width for readability
    cardWidth = cardWidth.clamp(110.0, 150.0);
    
    final scale = (screenWidth / 400).clamp(0.7, 1.0);
    
    return GestureDetector(
      onTap: () => _navigateToOrderDetails(context, order),
      child: Container(
        width: cardWidth,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12 * scale),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(8 * scale),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Restaurant name (highlighted)
              Flexible(
                child: Text(
                  order.restaurantName ?? 'Unknown Restaurant',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5 * scale,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
              SizedBox(height: 2 * scale),
              
              // Supercategory name (underneath)
              Flexible(
                child: Text(
                  order.supercategoryName ?? 'Unknown Category',
                  style: GoogleFonts.poppins(
                    fontSize: 9.5 * scale,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
              const Spacer(),
              
              // Price
              Row(
                children: [
                  Icon(
                    Icons.currency_rupee,
                    size: 9.5 * scale,
                    color: ColorManager.instamartGreen,
                  ),
                  Flexible(
                    child: Text(
                      '${order.totalPrice ?? '0'}',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5 * scale,
                        fontWeight: FontWeight.w600,
                        color: ColorManager.instamartGreen,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2 * scale),
              
              // Date
              Flexible(
                child: Text(
                  _formatOrderDate(order.createdAt),
                  style: GoogleFonts.poppins(
                    fontSize: 8.5 * scale,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: 2 * scale),
              
              // Status badge
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 2 * scale),
                  decoration: BoxDecoration(
                    color: _getOrderStatusColor(order.orderStatus ?? '').withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6 * scale),
                    border: Border.all(
                      color: _getOrderStatusColor(order.orderStatus ?? '').withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    _formatOrderStatus(order.orderStatus ?? ''),
                    style: GoogleFonts.poppins(
                      fontSize: 8 * scale,
                      fontWeight: FontWeight.w500,
                      color: _getOrderStatusColor(order.orderStatus ?? ''),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<RecentOrderModel> _filterRecentOrdersBySupercategory(List<RecentOrderModel> orders) {
    if (selectedSupercategoryId == null || selectedSupercategoryId!.isEmpty) {
      return orders;
    }
    return orders.where((order) => order.supercategoryId?.toString() == selectedSupercategoryId).toList();
  }

  Color _getOrderStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING': return const Color(0xFFFF9800);
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
      case 'PREPARING': return 'Preparing';
      case 'DELIVERED': return 'Delivered';
      case 'CANCELLED': return 'Cancelled';
      default: return status;
    }
  }

  String _formatOrderDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Unknown date';
    }
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'food': return Icons.restaurant;
      case 'grocery': return Icons.shopping_bag;
      case 'medicine': return Icons.local_pharmacy;
      case 'electronics': return Icons.devices;
      default: return Icons.category;
    }
  }

  Color _getCategoryColorFromName(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'food': return ColorManager.primary;
      case 'grocery': return const Color(0xFF4CAF50);
      case 'medicine': return const Color(0xFF2196F3);
      case 'electronics': return const Color(0xFFE91E63);
      default: return ColorManager.primary;
    }
  }

  void _navigateToOrderDetails(BuildContext context, RecentOrderModel order) {
    // Navigate to order details page
    Navigator.pushNamed(
      context,
      Routes.orderDetails,
      arguments: order.orderId,
    );
  }
}
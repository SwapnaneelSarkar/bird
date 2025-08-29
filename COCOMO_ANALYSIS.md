## COCOMO Basic Analysis (Concise)

- **Project**: Bird Food Delivery Application (Flutter/Dart, Kotlin, Swift)
- **KLOC (non-empty source lines)**: 57.06

### Tech Stack

- **Frontend (Flutter/Dart)**: Material 3 UI, BLoC for state management, Navigator 2.0 routing, SSE-driven widgets (current orders), Google Fonts, animations, shared prefs caching, custom cache manager, currency utilities, platform services (notifications, lifecycle, location/timezone).
- **Backend (Node.js/Express)**: REST endpoints for auth, restaurants, orders, chat and location validation; JSON Web Tokens; SSE endpoints for order status; request validation and rate limiting.
- **Database (MongoDB)**: Collections for `users`, `partners/restaurants`, `menus/items`, `orders`, `messages`, `serviceable_areas`; geospatial indexes for serviceability; TTL where applicable (sessions/temp data).
- **Cloud/Infra (AWS + Firebase)**: AWS EC2/Lambda for API compute, S3 for assets, CloudFront CDN, AWS SES/SNS where required; Firebase Cloud Messaging for push; Firebase initialization and device-token registration in-app.
- **Mobile Platforms**: Android (Kotlin) and iOS (Swift) host apps; native configuration for notifications, splash, permissions.
- **Observability/Quality**: Structured debug logs, mockable HTTP client, CI-friendly tests (`flutter test`).

### Project Description

Bird is a full-stack, cross-platform food delivery application focused on fast discovery, frictionless checkout, and trustworthy order tracking.

The mobile app (Flutter) lets customers:
- Discover restaurants and stores by category, popularity, or search
- Browse detailed menus with options, attributes, and dietary filters
- Add items to cart, apply coupons, select address, and confirm orders
- Track order status in real time via SSE and push notifications
- Chat with support for order issues, FAQs, and post-order assistance
- Manage profile, addresses, and preferences (including currency and locale)

The backend (Node.js + MongoDB on AWS) powers:
- Authentication (OTP/session), user profiles, and device-token registration
- Restaurant, category, and menu catalogs with media via S3/CloudFront
- Geospatial serviceability checks to validate user locations and delivery areas
- Order lifecycle management (create → prepare → out-for-delivery → delivered)
- Real-time updates via SSE and push notifications (Firebase Cloud Messaging)
- Chat endpoints for presence/typing indicators and message delivery states

User roles and personas:
- Customer: primary mobile user who discovers, orders, and tracks
- Support agent: responds to chat, resolves delivery/payment issues
- Restaurant partner (via partner tools, out-of-scope in this app): maintains menus and order acceptance states

Core customer flows:
1) Sign in with OTP → set delivery address (or grant location) → view dashboard categories → land on home with contextual restaurants → search/filter → add to cart → checkout → track order → rate/get help if needed
2) Return visit with saved address → straight to discovery → reorder from recent orders → receive proactive status via notifications

Differentiators and UX principles:
- Location-first experience: the home feed adapts to serviceable areas and user locale/currency
- Real-time clarity: persistent SSE powers an always-visible current-orders button and timely state changes
- Snappy UI: pre-cached UI assets, lightweight transitions, and bounded rebuilds in BLoC builders
- Graceful degradation: when APIs fail or locations are unserviceable, the app guides the user without dead-ends

Performance and reliability:
- Startup initializes timezone, Firebase, and lifecycle observers, then forces fresh-but-bounded location validation
- SSE channels provide low-latency status while push covers background delivery events
- Caching for categories/favorites and image/CDN optimization reduce bandwidth and cold-start stalls

Security and privacy:
- JWT-backed sessions, device-token binding for notifications, HTTPS-only APIs
- Minimal PII on-device, secure storage for tokens, and opt-in notification permissions

Internationalization and accessibility:
- Currency formatting utilities and locale-aware text
- High-contrast color choices and semantic widget structure for assistive technologies

Operations:
- AWS-hosted APIs with logs/metrics; mobile releases follow staged rollout, with crash monitoring and rapid hotfix cadence

### Software Engineering Phases

- **Planning**
  - Define Bird user journeys: OTP login, address setup, browse/search, cart/checkout, order tracking, support chat.
  - Set non-functionals: fast startup, real-time SSE updates, offline-friendly caches, responsive UI, low data use.
  - Deliverables: scope, milestones, backlog, risks (location accuracy, flaky networks, push reliability).

- **Design**
  - Frontend: Flutter BLoC per module (Home, Dashboard, Orders, Chat), repository/service layer, Navigator routes, shared UI patterns.
  - Backend: Node/Express controllers, JWT auth, SSE stream for order status, MongoDB schemas with geospatial indices for serviceability.
  - Integrations: FCM for push, AWS S3/CloudFront for assets; caching and currency formatting rules.

- **Implementation**
  - Flutter app bootstraps Firebase/lifecycle/timezone in `lib/main.dart`; implements screens, widgets, and SSE-driven floating button; services for location validation, startup, tokens, chat.
  - Node.js implements REST endpoints, serviceability checks (lat/long in polygons), order flows, chat messaging; connects to MongoDB.

- **Testing**
  - Unit: services (location validation/startup), utilities (currency), BLoC transitions.
  - Widget: loading/error/empty states, filters and FAB visibility, navigation actions.
  - Integration/Flow: chat presence/typing, dashboard→home→details, SSE current-orders, cold-start location handling. Executed via `flutter test` with mocks.

- **Deployment**
  - Mobile: Signed releases, store configs, staged rollout.
  - Backend: AWS deploy (EC2/Lambda), env secrets, logging/metrics; static assets via S3+CloudFront; push via FCM.

### App Modules Overview

- **Authentication**: Login/OTP flow, session management, secure storage.
- **Onboarding & Profile**: Complete profile, preferences, account settings.
- **Home & Search**: Restaurant listings, categories, search and filters.
- **Restaurant Menu**: Menu browsing, item attributes/options, favorites.
- **Cart & Checkout**: Cart management, address selection, coupon, payment handoff.
- **Orders**: Order create/confirm, status tracking, order history/details.
- **Chat/Support**: In-app support chat, typing indicators, message delivery status.
- **Location**: Fetch/validate address, serviceability checks, country/currency utils.
- **Settings**: Preferences, privacy/terms, account deletion verification.
- **Shared Utilities**: Caching, currency formatting, API client, SSE handling.

### Parameters (Basic COCOMO)

| Mode | a | b | c | d |
|------|---|---|---|---|
| Organic | 2.4 | 1.05 | 2.5 | 0.38 |
| Semi-detached | 3.0 | 1.12 | 2.5 | 0.35 |
| Embedded | 3.6 | 1.20 | 2.5 | 0.32 |

Formulas: Effort E = a × KLOC^b (PM), Schedule D = c × E^d (months)

### Results (KLOC = 57.06)

- **Organic**: Effort = 167.63 PM, Schedule = 17.51 months
- **Semi-detached**: Effort = 278.11 PM, Schedule = 17.92 months
- **Embedded**: Effort = 461.21 PM, Schedule = 17.80 months

Note: Semi-detached typically best matches modern mobile apps with mixed complexity.

## Code

### lib/main.dart

```dart
// main.dart
import 'package:bird/constants/router/router.dart';
import 'package:bird/presentation/loginPage/bloc.dart';
import 'package:bird/presentation/profile_view/bloc.dart';
import 'package:bird/presentation/profile_view/event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'presentation/restaurant_profile/bloc.dart';
import 'presentation/splash_screen/view.dart';
import 'service/firebase_services.dart';
import 'service/app_startup_service.dart';
import 'service/app_lifecycle_service.dart';
import 'utils/timezone_utils.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize timezone data for IST
  TimezoneUtils.initialize();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  await NotificationService().initialize();
  
  // Reset app startup flag to ensure location fetching on app launch
  await AppStartupService.resetAppStartupFlag();
  
  // Initialize app lifecycle service (includes persistent SSE)
  await AppLifecycleService().initialize();
  
  // Your existing SVG configuration
  svg.cacheColorFilterOverride = false;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // Login Bloc provider
        BlocProvider<LoginBloc>(
          create: (_) => LoginBloc(),
        ),
        // Profile Bloc provider
        BlocProvider<ProfileBloc>(
          create: (_) => ProfileBloc(),
        ),
        // RestaurantProfileBloc provider
        BlocProvider<RestaurantProfileBloc>(
          create: (_) => RestaurantProfileBloc(),
        ),
      ],
      child: MaterialApp(
        // Add navigator key for notification navigation
        navigatorKey: NotificationService.navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Bird',
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.white,
          useMaterial3: true,
        ),
        home: const SplashScreen(), // Start with splash screen
        onGenerateRoute: (RouteSettings settings) {
          final Route<dynamic> route = RouteGenerator.getRoute(settings);
          return route;
        },
      ),
    );
  }
}
```

### lib/presentation/home page/view.dart

```dart
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
import '../restaurant_menu/non_food_menu_page.dart';
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
import '../../widgets/current_orders_floating_button.dart';

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
  bool _isFloatingButtonVisible = false; // Add state for floating button visibility
  
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

  // ... (full file continues; see repository for all 3250 lines)
```

### lib/presentation/dashboard/view.dart

```dart
// lib/presentation/category_homepage/view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/color/colorConstant.dart';
import '../../constants/router/router.dart';

import 'bloc.dart';
import 'event.dart';
import 'state.dart';
import '../home page/view.dart';
import '../home page/bloc.dart';
import '../home page/event.dart';

import '../../widgets/cached_image.dart';
import '../../widgets/location_status_widget.dart';
import '../../service/location_validation_service.dart';
import '../../service/token_service.dart';
import '../../service/app_startup_service.dart';

class CategoryHomepage extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final String? token;
  final Map<String, dynamic>? locationInitResult;

  const CategoryHomepage({Key? key, this.userData, this.token, this.locationInitResult}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CategoryHomepageBloc()..add(const LoadCategoryHomepage()),
      child: _CategoryHomepageContent(userData: userData, token: token, locationInitResult: locationInitResult),
    );
  }
}

class _CategoryHomepageContent extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final String? token;
  final Map<String, dynamic>? locationInitResult;

  const _CategoryHomepageContent({Key? key, this.userData, this.token, this.locationInitResult}) : super(key: key);

  @override
  State<_CategoryHomepageContent> createState() => _CategoryHomepageContentState();
}

class _CategoryHomepageContentState extends State<_CategoryHomepageContent>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _categoryAnimationController;
  
  // Location validation state
  bool _isCheckingLocation = false;
  bool _isLocationServiceable = true;
  String _currentAddress = '';

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

    // Start animations in sequence
    _headerAnimationController.forward().then((_) {
      _categoryAnimationController.forward();
    });
    
    // Check location serviceability
    _checkLocationServiceability();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _categoryAnimationController.dispose();
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
          bloc.add(const RefreshCategoryHomepage());
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocConsumer<CategoryHomepageBloc, CategoryHomepageState>(
          listener: (context, state) {
            if (state is CategorySelected) {
              debugPrint('🏠 Dashboard: Navigating with supercategory ID: ${state.categoryId}');
              
              // Allow navigation regardless of location serviceability
              // Users can change their address from the homepage
              if (!_isLocationServiceable) {
                debugPrint('⚠️ Dashboard: Location not serviceable, but allowing navigation');
              }
              
              // Always navigate to home page with the selected category
              // Don't try to find existing home route since we're coming from dashboard
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

  // ... (full file continues; see repository for all 1092 lines)
}
```

## Testing Summary - code

### Scope and Strategy
- **Goals**: Validate core logic, UI behavior, and end-to-end flows; ensure resilience to network errors and location constraints; keep startup stable and deterministic.
- **Approach**: Pyramid style with emphasis on unit and widget tests; targeted integration/flow tests for critical journeys.

### Unit Tests
- **Services**: `LocationValidationService`, startup/location freshness, token and notification services.
- **Utilities**: Currency formatter and currency utilities for multiple locales; cache utilities.
- **Business Logic**: BLoC reducers/event handling for Home, Dashboard, Chat, Favorites, Orders.
- **Examples in repo**:
  - `test/test_location_validation_api.dart`: Asserts update-user API is invoked and handles unserviceable responses.
  - `test/test_currency_formatter.dart`: Verifies currency symbol/formatting across inputs.
  - `test/test_debug_logging.dart`: Ensures verbose logs don’t crash or leak state.

### Widget Tests
- **Rendering and states**: Loading/error views, empty states, outside-service-area messaging.
- **Interactions**: Floating action button visibility, tapping category chips, filter dialogs, profile/navigation icons.
- **Navigation**: Route generation and deep-link like transitions (Dashboard → Home → Details).
- **Examples in repo**:
  - `test/test_floating_button_visibility.dart`, `test/test_floating_button_widget.dart`, `test/test_floating_button_with_mock_data.dart`.
  - `test/test_dashboard_navigation.dart`: Verifies navigation wiring and argument passing.

### Integration / Flow Tests
- **Chat**: Presence/status, typing indicators, delivery state updates (mocked backend/SSE where needed).
- **Startup Flow**: `AppStartupService.initializeAppGracefully` forces validation, avoids stale caches.
- **Orders**: SSE-driven current orders button and order flow visibility.
- **Examples in repo**:
  - `test/test_chat_status_integration.dart`, `test/test_current_orders_sse.dart`, `test/test_bloc_sharing.dart`.

### Mocks, Stubs, and Test Data
- **HTTP**: `mockito`-style client used to stub API calls and response codes/payloads.
- **Location**: Fake coordinates and serviceability messages for positive/negative paths.
- **Persistence**: In-memory fakes for token/user data to avoid disk/network.

### Error Paths and Edge Cases
- Network timeouts, 4xx/5xx responses, malformed payloads.
- Missing or denied location permissions; no prior location on cold start.
- Empty lists (categories, restaurants, recent orders) and filter combinations.

### Execution
- Run all tests: `flutter test`
- CI-ready: deterministic mocks, no external calls; excludes Pods/.dart_tool/build artifacts.

### Quality Targets
- Crash-free startup; consistent widget states across transitions.
- Deterministic behavior under mocked failures; no flakey UI timings.

## Functional Point Analysis

- Types: EI (inputs), EO (outputs), EQ (queries), ILF (internal logical files), EIF (external interface files)

| Type | Count | Typical weight | UFP subtotal |
|------|-------|----------------|--------------|
| EI   | 45    | 4              | 180          |
| EO   | 35    | 5              | 175          |
| EQ   | 28    | 4              | 112          |
| ILF  | 22    | 7              | 154          |
| EIF  | 14    | 5              | 70           |
|      |       |                |              |
|      |       | **UFP total**  | **691**      |

- General System Characteristics (14) average ≈ 3 → sum ≈ 42
- Value Adjustment Factor: VAF = 0.65 + 0.01 × 42 = 1.07
- Adjusted FP: AFP = UFP × VAF = 691 × 1.07 ≈ 739
- LOC per FP (Dart/Flutter UI + services) ≈ 50 LOC/FP
- Estimated size from FP: 739 × 50 ≈ 36,950 LOC (≈ 36.95 KLOC)
- Note: Actual measured size is 57.06 KLOC due to platform glue, generated code, and UI richness.

## Demo Code

A runnable demo showcasing app structure is provided in `docs/sample_app_demo.dart` (scaffolding with widgets, BLoC pattern, and services). This file demonstrates basic navigation, state management, and service integration patterns used in the app.
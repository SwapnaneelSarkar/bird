// constants/router/router.dart
import 'package:bird/presentation/DeliveryAddressPage/view.dart';
import 'package:bird/presentation/chat/view.dart';
import 'package:bird/presentation/complete%20profile/view.dart';
import 'package:bird/presentation/dashboard/bloc.dart';
import 'package:bird/presentation/dashboard/view.dart';
import 'package:bird/presentation/favorites/view.dart';
import 'package:bird/presentation/home%20page/bloc.dart';
import 'package:bird/presentation/home%20page/event.dart';
import 'package:bird/presentation/order_confirmation/view.dart';
import 'package:bird/presentation/order_history/view.dart';
import 'package:bird/presentation/otpPage/view.dart';
import 'package:bird/presentation/profile_view/view.dart';
import 'package:bird/presentation/restaurant_menu/view.dart';
import 'package:bird/presentation/restaurant_profile/view.dart';
import 'package:bird/presentation/settings%20page/view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../presentation/home page/view.dart';
import '../../presentation/loginPage/view.dart';
import '../../presentation/splash_screen/view.dart';

class Routes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String profileComplete = '/profileComplete';
  static const String otp = '/otp';
  static const String address = '/address';
  static const String profileView = '/profileView';
  static const String home = '/home';
  static const String settings = '/settings';
  static const String restaurantMenu = '/restaurantMenu';
  static const String restaurantProfile = '/restaurantProfile';
  static const String orderConfirmation = '/orderConfirmation';
  static const String chat = '/chat';
  static const String orderHistory = '/orderHistory';
  static const String dashboard = '/dashboard';
  static const String favorites = '/favorites';

  static const String blank = '/blank';
}

class RouteGenerator {
  static Route<dynamic> getRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case Routes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case Routes.login:
        return MaterialPageRoute(builder: (_) => LoginPage());

            case Routes.dashboard:
        if (routeSettings.arguments != null && routeSettings.arguments is Map<String, dynamic>) {
          final args = routeSettings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => CategoryHomepage(
              userData: args['userData'] as Map<String, dynamic>?,
              token: args['token'] as String?,
            ),
          );
        }
        return MaterialPageRoute(builder: (_) => const CategoryHomepage());

      case Routes.home:
  if (routeSettings.arguments != null && routeSettings.arguments is Map<String, dynamic>) {
    final args = routeSettings.arguments as Map<String, dynamic>;
    debugPrint('Router: Home route called with arguments: $args');
    
    // Fix: Properly extract the selectedSupercategoryId
    final selectedSupercategoryId = args['selectedSupercategoryId'] as String?;
    debugPrint('Router: selectedSupercategoryId: $selectedSupercategoryId');
    
    return MaterialPageRoute(
      builder: (_) => BlocProvider(
        create: (_) {
          debugPrint('Router: Creating HomeBloc with selectedSupercategoryId: $selectedSupercategoryId');
          return HomeBloc(
            selectedSupercategoryId: selectedSupercategoryId, // Pass directly without toString()
          )..add(const LoadHomeData());
        },
        child: HomePage(
          userData: args['userData'] as Map<String, dynamic>?,
          token: args['token'] as String?,
        ),
      ),
    );
  }
  debugPrint('Router: Home route called without arguments');
  return MaterialPageRoute(
    builder: (_) => BlocProvider(
      create: (_) => HomeBloc()..add(const LoadHomeData()),
      child: const HomePage(),
    ),
  );



      case Routes.profileComplete:
        if (routeSettings.arguments != null && routeSettings.arguments is Map<String, dynamic>) {
          final args = routeSettings.arguments as Map<String, dynamic>;
          return PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                CompleteProfileView(
                  userData: args['userData'] as Map<String, dynamic>?,
                  token: args['token'] as String?,
                ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 500),
          );
        }
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const CompleteProfileView(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
        );

      case Routes.otp:
        if (routeSettings.arguments != null && routeSettings.arguments is Map<String, dynamic>) {
          final args = routeSettings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => OtpScreen(
              phoneNumber: args['phoneNumber'] as String? ?? '',
              verificationId: args['verificationId'] as String? ?? '',
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => OtpScreen(
            phoneNumber: '',
            verificationId: '',
          ),
        );

      case Routes.address:
        return MaterialPageRoute(builder: (_) => AddressScreen());

      case Routes.profileView:
        return MaterialPageRoute(builder: (_) => const ProfileView());

      case Routes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsView());

      case Routes.restaurantMenu:
        if (routeSettings.arguments != null && routeSettings.arguments is Map<String, dynamic>) {
          final restaurantData = routeSettings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => RestaurantDetailsPage(restaurantData: restaurantData),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const RestaurantDetailsPage(restaurantData: {}),
        );

      case Routes.restaurantProfile:
        if (routeSettings.arguments != null) {
          final restaurantId = routeSettings.arguments as String;
          return MaterialPageRoute(
            builder: (_) => RestaurantProfileView(restaurantId: restaurantId),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const RestaurantProfileView(restaurantId: ""),
        );

      case Routes.orderConfirmation:
        return MaterialPageRoute(builder: (_) => const OrderConfirmationView());

      case Routes.chat:
        String? orderId;
        bool isNewlyPlacedOrder = false;
        
        debugPrint('Router: 🚨 Chat route called with arguments: ${routeSettings.arguments}');
        debugPrint('Router: 🚨 Arguments type: ${routeSettings.arguments.runtimeType}');
        
        if (routeSettings.arguments is String) {
          // For navigation from order history (old format)
          orderId = routeSettings.arguments as String;
          debugPrint('Router: Chat route called with String orderId: $orderId');
        } else if (routeSettings.arguments is Map<String, dynamic>) {
          // For navigation from order confirmation (new format)
          final args = routeSettings.arguments as Map<String, dynamic>;
          orderId = args['orderId'] as String?;
          isNewlyPlacedOrder = args['isNewlyPlacedOrder'] as bool? ?? false;
          debugPrint('Router: Chat route called with Map - orderId: $orderId, isNewlyPlacedOrder: $isNewlyPlacedOrder');
        } else {
          debugPrint('Router: ⚠️ Chat route called with unexpected arguments type: ${routeSettings.arguments.runtimeType}');
        }
        
        return MaterialPageRoute(
          builder: (_) {
                    debugPrint('Router: Creating ChatView with orderId: $orderId, isNewlyPlacedOrder: $isNewlyPlacedOrder');
        if (orderId == null || orderId.isEmpty) {
          debugPrint('Router: ⚠️ WARNING - orderId is null or empty!');
        }
        return ChatView(
          orderId: orderId,
          isNewlyPlacedOrder: isNewlyPlacedOrder,
        );
          },
        );

      case Routes.orderHistory:
        return MaterialPageRoute(builder: (_) => const OrderHistoryView());

      case Routes.favorites:
        return MaterialPageRoute(builder: (_) => const FavoritesPage());

      default:
        return unDefinedRoute();
    }
  }

  static Route<dynamic> unDefinedRoute() {
    return MaterialPageRoute(
      builder: (_) => const Scaffold(
        body: Center(
          child: Text("Page Not Found"),
        ),
      ),
    );
  }
}
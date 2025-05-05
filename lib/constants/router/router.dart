import 'package:bird/presentation/DeliveryAddressPage/view.dart';
import 'package:bird/presentation/complete%20profile/view.dart';
import 'package:bird/presentation/otpPage/view.dart';
import 'package:bird/presentation/profile_view/view.dart';
import 'package:bird/presentation/settings%20page/view.dart';
import 'package:flutter/material.dart';

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

  static const String blank = '/blank';
}

class RouteGenerator {
  static Route<dynamic> getRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {
      case Routes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case Routes.login:
        return MaterialPageRoute(builder: (_) => LoginPage());

      case Routes.home:
        // Handle home route with arguments
        if (routeSettings.arguments != null && routeSettings.arguments is Map<String, dynamic>) {
          final args = routeSettings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => HomePage(
              userData: args['userData'] as Map<String, dynamic>?,
              token: args['token'] as String?,
            ),
          );
        }
        // Fallback if no arguments provided
        return MaterialPageRoute(builder: (_) => const HomePage());

      case Routes.profileComplete:
        // Add fade transition for profile complete screen with arguments
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
        // Fallback without arguments
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
        // Extract arguments for OTP screen
        if (routeSettings.arguments != null && routeSettings.arguments is Map<String, dynamic>) {
          final args = routeSettings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => OtpScreen(
              phoneNumber: args['phoneNumber'] as String? ?? '',
              verificationId: args['verificationId'] as String? ?? '',
            ),
          );
        }
        // Fallback if no arguments provided
        return MaterialPageRoute(
          builder: (_) => OtpScreen(
            phoneNumber: '',
            verificationId: '',
          ),
        );

      case Routes.address:
        // Handle address route with arguments
        if (routeSettings.arguments != null && routeSettings.arguments is Map<String, dynamic>) {
          final args = routeSettings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => AddressScreen(
            
            ),
          );
        }
        // Fallback if no arguments provided
        return MaterialPageRoute(builder: (_) => AddressScreen());

      case Routes.profileView:
        return MaterialPageRoute(builder: (_) => const ProfileView());

      case Routes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsView());

      default:
        return unDefinedRoute();
    }
  }

  static Route<dynamic> unDefinedRoute() {
    return MaterialPageRoute(
      builder: (_) => const Scaffold(
        body: SizedBox(
          child: Center(
            child: Text("Page Not Found"),
          ),
        ),
      ),
    );
  }
}
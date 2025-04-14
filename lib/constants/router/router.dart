import 'package:flutter/material.dart';
import '../../presentation/DeliveryAddressPage/view.dart';
import '../../presentation/loginPage/view.dart';
import '../../presentation/otpPage/view.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => LoginPage());
      case '/otp':
        // Safely handle the arguments
        if (settings.arguments != null) {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
              builder: (_) => OtpScreen(
                    phoneNumber:
                        args['phoneNumber'] ?? '', // Use null-safe operator
                    verificationId: args['verificationId'] ?? '',
                  ));
        } else {
          // Provide a fallback or error route when arguments are missing
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              body: Center(
                child: Text('Missing required parameters for OTP screen'),
              ),
            ),
          );
        }
      case '/address':
        return MaterialPageRoute(builder: (_) => AddressScreen());
      default:
        return MaterialPageRoute(builder: (_) => LoginPage());
    }
  }
}

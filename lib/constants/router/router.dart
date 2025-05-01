import 'package:bird/presentation/DeliveryAddressPage/view.dart';
import 'package:bird/presentation/complete%20profile/view.dart';
import 'package:bird/presentation/otpPage/view.dart';
import 'package:bird/presentation/profile_view/view.dart';
import 'package:flutter/material.dart';

import '../../presentation/loginPage/view.dart';

class Routes {
  static const String login = '/login';
  static const String profileComplete = '/profileComplete';
  static const String otp = '/otp';
    static const String address = '/address';
      static const String profileView = '/profileView';


 


  static const String blank = '/blank';
}

class RouteGenerator {
  static Route<dynamic> getRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {


      case Routes.login:
        return MaterialPageRoute(builder: (_) => LoginPage());

      case Routes.profileComplete:
        return MaterialPageRoute(builder: (_) => const CompleteProfileView());

      case Routes.otp:
        return MaterialPageRoute(builder: (_) =>  OtpScreen(phoneNumber: '', verificationId: '',));

      case Routes.address:
        return MaterialPageRoute(builder: (_) =>  AddressScreen());

      case Routes.profileView:
        return MaterialPageRoute(builder: (_) => const ProfileView());


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
            )));
  }
}

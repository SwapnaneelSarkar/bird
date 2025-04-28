import 'package:bird/presentation/complete%20profile/view.dart';
import 'package:flutter/material.dart';

import '../../presentation/loginPage/view.dart';

class Routes {
  static const String splash = '/splash';
  static const String LandingPage = '/land';
  static const String login = '/login';
  static const String profileView = '/profileView';
  static const String ConfirmLocation = '/ConfirmLocation';
 


  static const String blank = '/blank';
}

class RouteGenerator {
  static Route<dynamic> getRoute(RouteSettings routeSettings) {
    switch (routeSettings.name) {


      case Routes.login:
        return MaterialPageRoute(builder: (_) => LoginPage());

      case Routes.profileView:
        return MaterialPageRoute(builder: (_) => const CompleteProfileView());


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

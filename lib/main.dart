
import 'package:bird/constants/router/router.dart';
import 'package:bird/presentation/loginPage/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

void main() {
    svg.cacheColorFilterOverride = false;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginBloc(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Meet & more',
        theme: ThemeData(
          scaffoldBackgroundColor: Colors.black,
          useMaterial3: true,
        ),
        initialRoute: Routes.login,
        onGenerateRoute: (RouteSettings settings) {
          final Route<dynamic> route = RouteGenerator.getRoute(settings);
          // const bottomNavRoutes = {
          //   Routes.homePage,
          //   Routes.notification,
          //   // Routes.chat,
          //   // Routes.profile,
          // };

          // if (bottomNavRoutes.contains(settings.name) &&
          //     route is MaterialPageRoute) {
          //   final WidgetBuilder builder = route.builder;

          //   return PageRouteBuilder(
          //     settings: settings,
          //     pageBuilder: (ctx, animation, secondary) =>
          //         builder(ctx),
          //     transitionDuration: const Duration(milliseconds: 300),
          //     reverseTransitionDuration: const Duration(milliseconds: 300),
          //     transitionsBuilder:
          //         (ctx, Animation<double> anim, _, Widget child) {
          //       return FadeTransition(
          //         opacity: anim,
          //         child: child,
          //       );
          //     },
          //   );
          // }

          return route;
        },
      ),
    );
  }
}

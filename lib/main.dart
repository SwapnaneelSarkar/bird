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
// main.dart
import 'package:bird/constants/router/router.dart';
import 'package:bird/presentation/chat/view.dart';
import 'package:bird/presentation/loginPage/bloc.dart';
import 'package:bird/presentation/order_confirmation/view.dart';
import 'package:bird/presentation/order_history/view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'presentation/restaurant_profile/bloc.dart';
import 'presentation/splash_screen/view.dart';
import 'service/firebase_services.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Notification Service
  await NotificationService().initialize();
  
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
        home: const OrderHistoryView(), // Start with splash screen
        onGenerateRoute: (RouteSettings settings) {
          final Route<dynamic> route = RouteGenerator.getRoute(settings);
          return route;
        },
      ),
    );
  }
}
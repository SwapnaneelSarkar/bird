import 'package:bird/constants/router/router.dart';
import 'package:bird/presentation/loginPage/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'presentation/restaurant_profile/bloc.dart';
import 'presentation/splash_screen/view.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
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
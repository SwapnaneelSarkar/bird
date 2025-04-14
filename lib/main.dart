import 'package:bird/presentation/DeliveryAddressPage/bloc.dart';
import 'package:bird/presentation/otpPage/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'constants/router/router.dart';
import 'presentation/loginPage/bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LoginBloc>(create: (context) => LoginBloc()),
        BlocProvider<OtpBloc>(create: (context) => OtpBloc()),
        BlocProvider<AddressBloc>(create: (context) => AddressBloc()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'BIRD Login',
        initialRoute: '/',
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}

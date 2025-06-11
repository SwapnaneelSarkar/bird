// lib/presentation/screens/loginPage/state.dart

abstract class LoginState {}

class LoginInitialState extends LoginState {}

class LoginLoadingState extends LoginState {}

class LoginSuccessState extends LoginState {
  final String verificationId;
  
  LoginSuccessState({required this.verificationId});
}

class LoginErrorState extends LoginState {
  final String errorMessage;
  
  LoginErrorState({required this.errorMessage});
}

// Additional states if needed
class CountrySelectedState extends LoginState {
  final String countryCode;
  final String dialCode;
  
  CountrySelectedState({
    required this.countryCode,
    required this.dialCode,
  });
}
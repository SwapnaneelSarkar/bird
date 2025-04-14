import 'package:firebase_auth/firebase_auth.dart';

abstract class OtpState {}

class OtpInitialState extends OtpState {}

class OtpValidState extends OtpState {
  final String otp;
  OtpValidState({required this.otp});
}

class OtpVerificationLoadingState extends OtpState {}

class OtpVerificationSuccessState extends OtpState {
  final String otp;
  final UserCredential? userCredential;
  OtpVerificationSuccessState({required this.otp, this.userCredential});
}

class OtpVerificationFailureState extends OtpState {
  final String errorMessage;
  OtpVerificationFailureState({required this.errorMessage});
}

class OtpResentState extends OtpState {}

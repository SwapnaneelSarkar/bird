// lib/presentation/screens/otp/state.dart

abstract class OtpState {}

class OtpInitialState extends OtpState {}

class OtpValidState extends OtpState {
  final String otp;
  OtpValidState({required this.otp});
}

class OtpVerificationLoadingState extends OtpState {}

class OtpVerificationSuccessState extends OtpState {
  final String otp;
  OtpVerificationSuccessState({required this.otp});
}

class OtpVerificationFailureState extends OtpState {
  final String errorMessage;
  OtpVerificationFailureState({required this.errorMessage});
}

class OtpResentState extends OtpState {}

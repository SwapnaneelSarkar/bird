abstract class OtpState {}

class OtpInitialState extends OtpState {}

class OtpValidState extends OtpState {
  final String otp;
  OtpValidState({required this.otp});
}

class OtpVerificationLoadingState extends OtpState {}

class OtpVerificationSuccessState extends OtpState {
  final String otp;
  final bool isLogin;
  final Map<String, dynamic>? userData;
  final String? token;
  
  OtpVerificationSuccessState({
    required this.otp,
    this.isLogin = false,
    this.userData,
    this.token,
  });
}

class OtpVerificationFailureState extends OtpState {
  final String errorMessage;
  OtpVerificationFailureState({required this.errorMessage});
}

class OtpResentState extends OtpState {}
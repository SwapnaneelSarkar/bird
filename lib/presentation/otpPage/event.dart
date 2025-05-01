// lib/presentation/screens/otp/event.dart

abstract class OtpEvent {}

class OtpChangedEvent extends OtpEvent {
  final String otp;
  OtpChangedEvent({required this.otp});
}

class VerifyOtpEvent extends OtpEvent {
  final String otp;
  final String verificationId;
  VerifyOtpEvent({required this.otp, required this.verificationId});
}

class ResendOtpEvent extends OtpEvent {
  final String phoneNumber;
  ResendOtpEvent({required this.phoneNumber});
}

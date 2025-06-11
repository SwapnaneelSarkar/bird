// lib/presentation/screens/loginPage/event.dart

abstract class LoginEvent {}

class SubmitEvent extends LoginEvent {
  final String phoneNumber; // Full phone number with country code

  SubmitEvent({
    required this.phoneNumber,
  });
}

class PhoneVerificationCompletedEvent extends LoginEvent {
  final String verificationId;

  PhoneVerificationCompletedEvent({required this.verificationId});
}

class PhoneVerificationFailedEvent extends LoginEvent {
  final String error;

  PhoneVerificationFailedEvent({required this.error});
}

class PhoneCodeSentEvent extends LoginEvent {
  final String verificationId;

  PhoneCodeSentEvent({required this.verificationId});
}

// Additional events for country selection if needed
class CountrySelectedEvent extends LoginEvent {
  final String countryCode;
  final String dialCode;

  CountrySelectedEvent({
    required this.countryCode, 
    required this.dialCode,
  });
}
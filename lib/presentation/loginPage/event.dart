abstract class LoginEvent {}

class SubmitEvent extends LoginEvent {
  final String phoneNumber;

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
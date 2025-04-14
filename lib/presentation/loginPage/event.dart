abstract class LoginEvent {}

class SubmitEvent extends LoginEvent {
  final String phoneNumber;
  final String name;

  SubmitEvent({required this.phoneNumber, required this.name});
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

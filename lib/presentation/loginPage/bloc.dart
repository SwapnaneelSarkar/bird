import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'event.dart';
import 'state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _verificationId;

  LoginBloc() : super(LoginInitialState()) {
    on<SubmitEvent>(_handleSubmitEvent);
    on<PhoneVerificationCompletedEvent>(_handleVerificationCompleted);
    on<PhoneVerificationFailedEvent>(_handleVerificationFailed);
    on<PhoneCodeSentEvent>(_handleCodeSent);
  }

  Future<void> _handleSubmitEvent(
      SubmitEvent event, Emitter<LoginState> emit) async {
    emit(LoginLoadingState());

    try {
      if (event.name.isEmpty) {
        emit(LoginErrorState(errorMessage: "Please enter your name"));
        return;
      }

      if (event.phoneNumber.isEmpty) {
        emit(LoginErrorState(errorMessage: "Please enter your phone number"));
        return;
      }

      // Format phone number to include country code if needed
      String formattedPhoneNumber = event.phoneNumber;
      if (!formattedPhoneNumber.startsWith('+')) {
        // Add India's country code if not present (adjust as needed)
        formattedPhoneNumber = '+91' + formattedPhoneNumber;
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification on Android
          await _auth.signInWithCredential(credential);
          add(PhoneVerificationCompletedEvent(
              verificationId: _verificationId ?? ''));
        },
        verificationFailed: (FirebaseAuthException e) {
          add(PhoneVerificationFailedEvent(
              error: e.message ?? 'Verification failed'));
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          add(PhoneCodeSentEvent(verificationId: verificationId));
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      emit(LoginErrorState(errorMessage: e.toString()));
    }
  }

  void _handleVerificationCompleted(
      PhoneVerificationCompletedEvent event, Emitter<LoginState> emit) {
    emit(LoginSuccessState(verificationId: event.verificationId));
  }

  void _handleVerificationFailed(
      PhoneVerificationFailedEvent event, Emitter<LoginState> emit) {
    emit(LoginErrorState(errorMessage: event.error));
  }

  void _handleCodeSent(PhoneCodeSentEvent event, Emitter<LoginState> emit) {
    emit(LoginSuccessState(verificationId: event.verificationId));
  }
}

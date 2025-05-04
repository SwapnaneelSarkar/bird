import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'event.dart';
import 'state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  LoginBloc() : super(LoginInitialState()) {
    on<SubmitEvent>(_onSubmit);
    on<PhoneVerificationCompletedEvent>(_onPhoneVerificationCompleted);
    on<PhoneVerificationFailedEvent>(_onPhoneVerificationFailed);
    on<PhoneCodeSentEvent>(_onPhoneCodeSent);
  }

  Future<void> _onSubmit(SubmitEvent event, Emitter<LoginState> emit) async {
    emit(LoginLoadingState());

    try {
      // Save phone number for future use
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_phone', event.phoneNumber);

      // Force reCAPTCHA flow for Realme devices
      _auth.setSettings(
        appVerificationDisabledForTesting: false,
        forceRecaptchaFlow: true,
      );

      // Start phone verification
      await _auth.verifyPhoneNumber(
        phoneNumber: event.phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (only happens on Android)
          print('Auto-verification completed');
          add(PhoneVerificationCompletedEvent(verificationId: credential.verificationId ?? ''));
        },
        verificationFailed: (FirebaseAuthException e) {
          print('Firebase Auth Error: ${e.code} - ${e.message}');
          print('Stack trace: ${e.stackTrace}');
          add(PhoneVerificationFailedEvent(error: _getUserFriendlyError(e)));
        },
        codeSent: (String verificationId, int? resendToken) {
          print('Code sent successfully. Verification ID: $verificationId');
          add(PhoneCodeSentEvent(verificationId: verificationId));
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print('Auto retrieval timeout for verification ID: $verificationId');
        },
        timeout: const Duration(seconds: 120),
        forceResendingToken: null,
      );
    } catch (e) {
      print('Error in verifyPhoneNumber: $e');
      print('Stack trace: ${e is Error ? e.stackTrace : 'No stack trace available'}');
      emit(LoginErrorState(errorMessage: 'Error occurred. Please check your internet connection.'));
    }
  }

  void _onPhoneVerificationCompleted(
      PhoneVerificationCompletedEvent event, Emitter<LoginState> emit) {
    emit(LoginSuccessState(verificationId: event.verificationId));
  }

  void _onPhoneVerificationFailed(
      PhoneVerificationFailedEvent event, Emitter<LoginState> emit) {
    emit(LoginErrorState(errorMessage: event.error));
  }

  void _onPhoneCodeSent(
      PhoneCodeSentEvent event, Emitter<LoginState> emit) {
    emit(LoginSuccessState(verificationId: event.verificationId));
  }

  String _getUserFriendlyError(FirebaseAuthException e) {
    // Log detailed error information
    print('FirebaseAuthException Code: ${e.code}');
    print('FirebaseAuthException Message: ${e.message}');
    print('FirebaseAuthException Plugin: ${e.plugin}');
    
    // Return user-friendly error messages based on error codes
    switch (e.code) {
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'invalid-phone-number':
        return 'Invalid phone number. Please check and try again.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      case 'app-not-authorized':
        return 'App not authorized. Please contact support.';
      case 'operation-not-allowed':
        return 'Phone authentication is not enabled. Please contact support.';
      case 'invalid-verification-code':
        return 'Invalid verification code. Please try again.';
      case 'session-expired':
        return 'Verification session expired. Please request a new code.';
      default:
        // For SSL/certificate errors or other technical errors
        if (e.message?.contains('java.security.cert.CertPathValidatorException') ?? false) {
          return 'Error occurred. Please check your internet connection.';
        }
        if (e.message?.contains('Unable to resolve host') ?? false) {
          return 'Cannot connect to server. Please check your internet connection.';
        }
        if (e.message?.contains('SocketException') ?? false) {
          return 'Network error. Please check your internet connection.';
        }
        if (e.message?.contains('java.net.UnknownHostException') ?? false) {
          return 'Cannot reach server. Please check your internet connection.';
        }
        // Generic error message for other cases
        return 'An error occurred. Please try again.';
    }
  }
}
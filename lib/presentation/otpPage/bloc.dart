import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as developer;
import 'event.dart';
import 'state.dart';

class OtpBloc extends Bloc<OtpEvent, OtpState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  OtpBloc() : super(OtpInitialState()) {
    developer.log('OtpBloc initialized');
    on<OtpChangedEvent>(_onOtpChanged);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<ResendOtpEvent>(_onResendOtp);
  }

  void _onOtpChanged(OtpChangedEvent event, Emitter<OtpState> emit) {
    developer.log('OTP changed: ${event.otp}');
    try {
      if (event.otp.length == 6) {
        // Firebase OTP is 6 digits
        developer.log('OTP is valid (6 digits)');
        emit(OtpValidState(otp: event.otp));
      } else {
        developer.log('OTP is invalid length: ${event.otp.length}');
      }
    } catch (e, stackTrace) {
      developer.log('Error in _onOtpChanged: $e',
          error: e, stackTrace: stackTrace);
    }
  }

  Future<void> _onVerifyOtp(
      VerifyOtpEvent event, Emitter<OtpState> emit) async {
    developer.log('Verifying OTP: ${event.otp}');
    developer.log(
        'Verification ID: "${event.verificationId}"'); // Quote marks to see empty string

    if (event.verificationId.isEmpty) {
      developer.log('ERROR: Verification ID is empty!');
      emit(OtpVerificationFailureState(
          errorMessage:
              'Verification session invalid. Please request a new OTP.'));
      return;
    }

    try {
      developer.log('Creating PhoneAuthCredential');
      // Create a PhoneAuthCredential with the verification ID and OTP code
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: event.verificationId,
        smsCode: event.otp,
      );

      developer.log('Signing in with credential');
      // Sign in with the credential
      UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      developer.log('Sign in successful: ${userCredential.user?.uid}');
      emit(OtpVerificationSuccessState(
        otp: event.otp,
        userCredential: userCredential,
      ));
    } on FirebaseAuthException catch (e, stackTrace) {
      developer.log(
          'FirebaseAuthException in _onVerifyOtp: ${e.code} - ${e.message}',
          error: e,
          stackTrace: stackTrace);

      String errorMessage = 'Verification failed';

      if (e.code == 'invalid-verification-code') {
        errorMessage = 'The verification code is invalid. Please try again.';
      } else if (e.code == 'session-expired') {
        errorMessage =
            'The verification session has expired. Please request a new OTP.';
      }

      developer.log('Emitting failure state with message: $errorMessage');
      emit(OtpVerificationFailureState(errorMessage: errorMessage));
    } catch (e, stackTrace) {
      developer.log('General error in _onVerifyOtp: $e',
          error: e, stackTrace: stackTrace);
      emit(OtpVerificationFailureState(errorMessage: e.toString()));
    }
  }

  Future<void> _onResendOtp(
      ResendOtpEvent event, Emitter<OtpState> emit) async {
    developer.log('Resending OTP to: ${event.phoneNumber}');
    try {
      String formattedPhoneNumber = event.phoneNumber;
      if (!formattedPhoneNumber.startsWith('+')) {
        formattedPhoneNumber = '+91' + formattedPhoneNumber;
        developer.log('Formatted phone number: $formattedPhoneNumber');
      }

      developer.log('Calling verifyPhoneNumber');
      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          developer.log('Auto verification completed');
          try {
            await _auth.signInWithCredential(credential);
            developer.log('Auto sign-in successful');
          } catch (e, stackTrace) {
            developer.log('Error in auto sign-in: $e',
                error: e, stackTrace: stackTrace);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          developer.log('Verification failed: ${e.code} - ${e.message}',
              error: e);
          emit(OtpVerificationFailureState(
              errorMessage: e.message ?? 'Verification failed'));
        },
        codeSent: (String verificationId, int? resendToken) {
          developer.log(
              'Code sent successfully. VerificationId: $verificationId, ResendToken: $resendToken');
          emit(OtpResentState());
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          developer.log(
              'Code auto retrieval timeout. VerificationId: $verificationId');
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e, stackTrace) {
      developer.log('Error in _onResendOtp: $e',
          error: e, stackTrace: stackTrace);
      emit(OtpVerificationFailureState(errorMessage: e.toString()));
    }
  }

  @override
  void onTransition(Transition<OtpEvent, OtpState> transition) {
    super.onTransition(transition);
    developer.log(
        'OtpBloc Transition: ${transition.event.runtimeType} -> ${transition.currentState.runtimeType} -> ${transition.nextState.runtimeType}');
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    developer.log('OtpBloc error: $error',
        error: error, stackTrace: stackTrace);
    super.onError(error, stackTrace);
  }
}

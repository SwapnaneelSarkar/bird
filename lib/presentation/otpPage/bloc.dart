import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../service/auth_service.dart';
import '../../service/token_service.dart';
import 'event.dart';
import 'state.dart';

class OtpBloc extends Bloc<OtpEvent, OtpState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();

  OtpBloc() : super(OtpInitialState()) {
    on<OtpChangedEvent>(_onOtpChanged);
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<ResendOtpEvent>(_onResendOtp);
  }

  void _onOtpChanged(OtpChangedEvent event, Emitter<OtpState> emit) {
    if (event.otp.length == 6) {
      emit(OtpValidState(otp: event.otp));
    } else {
      emit(OtpInitialState());
    }
  }

  Future<void> _onVerifyOtp(VerifyOtpEvent event, Emitter<OtpState> emit) async {
    emit(OtpVerificationLoadingState());
    
    try {
      // Create a PhoneAuthCredential with the code
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: event.verificationId,
        smsCode: event.otp,
      );

      // Sign in with the credential
      debugPrint('Attempting Firebase sign in with OTP...');
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        debugPrint('Firebase OTP verification successful');
        debugPrint('Firebase User ID: ${userCredential.user!.uid}');
        debugPrint('Firebase Phone Number: ${userCredential.user!.phoneNumber}');
        
        // After successful Firebase OTP verification, call our API
        String phoneNumber = userCredential.user!.phoneNumber ?? '';
        if (phoneNumber.startsWith('+')) {
          // Remove country code if present (assuming Indian numbers with +91)
          phoneNumber = phoneNumber.substring(phoneNumber.length - 10);
        }
        
        debugPrint('Calling auth API with phone number: $phoneNumber');
        final authResult = await _authService.authenticateUser(phoneNumber);
        
        debugPrint('Auth API Result: $authResult');
        
        if (authResult['success'] == true) {
          bool isLogin = authResult['isLogin'] as bool;
          debugPrint('Auth Type: ${isLogin ? "Login" : "Registration"}');
          debugPrint('User Data: ${authResult['data']}');
          debugPrint('Token: ${authResult['token']}');
          
          // Save token and user data
          final token = authResult['token'] as String;
          final userData = authResult['data'] as Map<String, dynamic>;
          
          debugPrint('Saving auth data to local storage...');
          final saveResult = await TokenService.saveAuthData(token, userData);
          
          if (saveResult) {
            debugPrint('Auth data saved successfully');
          } else {
            debugPrint('Failed to save auth data');
          }
          
          emit(OtpVerificationSuccessState(
            otp: event.otp,
            isLogin: isLogin,
            userData: userData,
            token: token,
          ));
        } else {
          debugPrint('Auth API failed: ${authResult['message']}');
          emit(OtpVerificationFailureState(
            errorMessage: authResult['message'] ?? 'Authentication failed',
          ));
        }
      } else {
        debugPrint('User credential is null after sign in');
        emit(OtpVerificationFailureState(errorMessage: 'Verification failed. Please try again.'));
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during OTP verification: ${e.code} - ${e.message}');
      debugPrint('Stack trace: ${e.stackTrace}');
      
      String errorMessage = _getUserFriendlyError(e);
      emit(OtpVerificationFailureState(errorMessage: errorMessage));
    } catch (e) {
      debugPrint('Unexpected error during OTP verification: $e');
      debugPrint('Stack trace: ${e is Error ? e.stackTrace : 'No stack trace available'}');
      emit(OtpVerificationFailureState(errorMessage: 'An error occurred. Please try again.'));
    }
  }

  Future<void> _onResendOtp(ResendOtpEvent event, Emitter<OtpState> emit) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: event.phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (only happens on Android)
          debugPrint('Auto-verification completed during resend');
          UserCredential userCredential = await _auth.signInWithCredential(credential);
          if (userCredential.user != null) {
            emit(OtpVerificationSuccessState(otp: ''));
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Firebase Auth Error during resend: ${e.code} - ${e.message}');
          emit(OtpVerificationFailureState(errorMessage: _getUserFriendlyError(e)));
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('OTP resent successfully. New verification ID: $verificationId');
          emit(OtpResentState());
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('Auto retrieval timeout for verification ID: $verificationId');
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      debugPrint('Error during OTP resend: $e');
      debugPrint('Stack trace: ${e is Error ? e.stackTrace : 'No stack trace available'}');
      emit(OtpVerificationFailureState(errorMessage: 'Failed to resend OTP. Please check your connection.'));
    }
  }

  String _getUserFriendlyError(FirebaseAuthException e) {
    // Log detailed error information
    debugPrint('FirebaseAuthException Code: ${e.code}');
    debugPrint('FirebaseAuthException Message: ${e.message}');
    
    switch (e.code) {
      case 'invalid-verification-code':
        return 'Invalid OTP. Please check and try again.';
      case 'invalid-verification-id':
        return 'Session expired. Please request a new OTP.';
      case 'session-expired':
        return 'OTP has expired. Please request a new one.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
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
        return 'An error occurred. Please try again.';
    }
  }
}
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';

import '../../service/auth_service.dart';
import '../../service/token_service.dart';
import 'event.dart';
import 'state.dart';

class OtpBloc extends Bloc<OtpEvent, OtpState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AuthService _authService = AuthService();
  
  // Store the current verification ID (can be updated after resend)
  String? _currentVerificationId;
  bool _isResending = false;

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
      // Use the current verification ID if available, otherwise use the provided one
      final verificationIdToUse = _currentVerificationId ?? event.verificationId;
      
      debugPrint('OtpBloc: Verifying OTP with verification ID: $verificationIdToUse');
      
      // Create a PhoneAuthCredential with the code
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationIdToUse,
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
    // Prevent multiple concurrent resend requests
    if (_isResending) {
      debugPrint('Resend already in progress, ignoring duplicate request');
      return;
    }
    
    _isResending = true;
    debugPrint('=== STARTING FRESH OTP REQUEST (RESEND) ===');
    debugPrint('Phone number: ${event.phoneNumber}');
    
    try {
      // Set up Firebase Auth settings
      _auth.setSettings(
        appVerificationDisabledForTesting: false,
        forceRecaptchaFlow: true,
      );
      
      // Use a completer to properly handle the async callbacks
      final completer = Completer<Map<String, dynamic>>();
      bool callbackTriggered = false;
      
      debugPrint('Calling Firebase verifyPhoneNumber as fresh request...');
      
      await _auth.verifyPhoneNumber(
        phoneNumber: event.phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          debugPrint('Auto-verification completed during fresh request');
          if (!callbackTriggered && !completer.isCompleted) {
            callbackTriggered = true;
            completer.complete({
              'success': true,
              'autoVerified': true,
            });
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Firebase verification failed during fresh request: ${e.code} - ${e.message}');
          if (!callbackTriggered && !completer.isCompleted) {
            callbackTriggered = true;
            completer.complete({
              'success': false,
              'error': _getUserFriendlyError(e),
            });
          }
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('Fresh OTP code sent successfully');
          debugPrint('New verification ID: $verificationId');
          debugPrint('Resend token: $resendToken');
          
          // Update the current verification ID
          _currentVerificationId = verificationId;
          
          if (!callbackTriggered && !completer.isCompleted) {
            callbackTriggered = true;
            completer.complete({
              'success': true,
              'verificationId': verificationId,
            });
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('Auto retrieval timeout: $verificationId');
          // Don't complete here, this is just a timeout notification
        },
        timeout: const Duration(seconds: 120),
        forceResendingToken: null, // Don't use any resend token, treat as fresh
      );
      
      // Wait for one of the callbacks with a longer timeout
      final result = await completer.future.timeout(
        const Duration(seconds: 15), // Increased timeout to 15 seconds
        onTimeout: () {
          debugPrint('Fresh OTP request timed out after 15 seconds');
          return {
            'success': false,
            'error': 'Request timed out. Please try again.',
          };
        },
      );
      
      debugPrint('Fresh OTP request result: $result');
      
      if (result['success'] == true) {
        if (result['autoVerified'] == true) {
          debugPrint('Auto-verification occurred during fresh request');
          emit(OtpVerificationSuccessState(
            otp: 'auto-verified',
            isLogin: false, // Will be determined by API call
          ));
        } else {
          debugPrint('Fresh OTP sent successfully');
          emit(OtpResentState());
        }
      } else {
        final errorMessage = result['error'] ?? 'Failed to send OTP';
        debugPrint('Fresh OTP request failed: $errorMessage');
        emit(OtpVerificationFailureState(errorMessage: errorMessage));
      }
      
    } catch (e) {
      debugPrint('Error during fresh OTP request: $e');
      String errorMessage = 'Failed to send OTP. Please try again.';
      
      if (e.toString().toLowerCase().contains('network')) {
        errorMessage = 'Network error. Please check your internet connection.';
      } else if (e.toString().toLowerCase().contains('too-many-requests')) {
        errorMessage = 'Too many requests. Please wait before requesting another OTP.';
      } else if (e.toString().toLowerCase().contains('quota')) {
        errorMessage = 'SMS quota exceeded. Please try again later.';
      }
      
      emit(OtpVerificationFailureState(errorMessage: errorMessage));
    } finally {
      _isResending = false;
      debugPrint('=== FRESH OTP REQUEST (RESEND) COMPLETED ===');
    }
  }

  String _getUserFriendlyError(FirebaseAuthException e) {
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
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      case 'app-not-authorized':
        return 'Service temporarily unavailable. Please try again later.';
      case 'operation-not-allowed':
        return 'Phone authentication is not enabled. Please contact support.';
      case 'captcha-check-failed':
        return 'Security verification failed. Please try again.';
      case 'invalid-app-credential':
        return 'App verification failed. Please try again.';
      case 'web-context-cancelled':
        return 'Verification cancelled. Please try again.';
      case 'missing-verification-code':
        return 'Please enter the OTP code.';
      case 'invalid-phone-number':
        return 'Invalid phone number format.';
      default:
        if (e.message?.contains('java.security.cert.CertPathValidatorException') ?? false) {
          return 'Connection error. Please check your internet connection.';
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
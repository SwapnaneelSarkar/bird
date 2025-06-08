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
  String? _currentVerificationId;
  String? _phoneNumber;
  bool _isResending = false;

  OtpBloc() : super(OtpInitialState()) {
    on<OtpChangedEvent>(_onOtpChanged);      
    on<VerifyOtpEvent>(_onVerifyOtp);
    on<ResendOtpEvent>(_onResendOtp);
  }

  void _onOtpChanged(OtpChangedEvent event, Emitter<OtpState> emit) {
    emit(event.otp.length == 6 ? OtpValidState(otp: event.otp) : OtpInitialState());
  }

  Future<void> _onVerifyOtp(VerifyOtpEvent event, Emitter<OtpState> emit) async {
    emit(OtpVerificationLoadingState());
    
    try {
      final verificationId = _currentVerificationId ?? event.verificationId;
      debugPrint('Verifying OTP with verification ID: $verificationId');
      
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: event.otp,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        debugPrint('Firebase OTP verification successful');
        await _handleAuthFlow(userCredential.user!.phoneNumber ?? '', event.otp, emit);
      } else {
        emit(OtpVerificationFailureState(errorMessage: 'Verification failed. Please try again.'));
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');
      emit(OtpVerificationFailureState(errorMessage: _getUserFriendlyError(e)));
    } catch (e) {
      debugPrint('Unexpected error: $e');
      emit(OtpVerificationFailureState(errorMessage: 'An error occurred. Please try again.'));
    }
  }

  Future<void> _onResendOtp(ResendOtpEvent event, Emitter<OtpState> emit) async {
  if (_isResending) return;
  
  _isResending = true;
  _phoneNumber = event.phoneNumber;
  debugPrint('Sending new OTP to: ${event.phoneNumber}');
  
  try {
    // Configure Firebase Auth settings
    _auth.setSettings(appVerificationDisabledForTesting: false, forceRecaptchaFlow: true);
    
    final completer = Completer<Map<String, dynamic>>();
    bool callbackTriggered = false;
    
    // Send a completely new OTP (not using resend token)
    await _auth.verifyPhoneNumber(
      phoneNumber: event.phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        if (!callbackTriggered && !completer.isCompleted) {
          callbackTriggered = true;
          completer.complete({'success': true, 'autoVerified': true});
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!callbackTriggered && !completer.isCompleted) {
          callbackTriggered = true;
          completer.complete({'success': false, 'error': _getUserFriendlyError(e)});
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        // Update the verification ID with the new one
        _currentVerificationId = verificationId;
        debugPrint('New OTP sent with verification ID: $verificationId');
        if (!callbackTriggered && !completer.isCompleted) {
          callbackTriggered = true;
          completer.complete({'success': true, 'verificationId': verificationId});
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        debugPrint('Auto retrieval timeout for verification ID: $verificationId');
      },
      timeout: const Duration(seconds: 120),
      // Key change: Set forceResendingToken to null to send fresh OTP
      forceResendingToken: null,
    );
    
    final result = await completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () => {'success': false, 'error': 'Request timed out. Please try again.'},
    );
    
    if (result['success'] == true) {
      if (result['autoVerified'] == true) {
        // Handle auto-verification case
        debugPrint('OTP auto-verified during resend');
        await _handleAuthFlow(_phoneNumber ?? event.phoneNumber, 'auto-verified', emit);
      } else {
        // OTP sent successfully
        debugPrint('New OTP sent successfully');
        emit(OtpResentState());
      }
    } else {
      emit(OtpVerificationFailureState(errorMessage: result['error'] ?? 'Failed to send OTP'));
    }
    
  } catch (e) {
    debugPrint('Error during new OTP send: $e');
    emit(OtpVerificationFailureState(errorMessage: _getNetworkError(e.toString())));
  } finally {
    _isResending = false;
  }
}

  Future<void> _handleAuthFlow(String phoneNumber, String otp, Emitter<OtpState> emit) async {
    String cleanPhone = phoneNumber.startsWith('+') ? phoneNumber.substring(phoneNumber.length - 10) : phoneNumber;
    
    debugPrint('Calling auth API with phone: $cleanPhone');
    final authResult = await _authService.authenticateUser(cleanPhone);
    
    if (authResult['success'] == true) {
      final isLogin = authResult['isLogin'] as bool;
      final token = authResult['token'] as String;
      final userData = authResult['data'] as Map<String, dynamic>;
      
      await TokenService.saveAuthData(token, userData);
      
      emit(OtpVerificationSuccessState(
        otp: otp,
        isLogin: isLogin,
        userData: userData,
        token: token,
      ));
    } else {
      emit(OtpVerificationFailureState(errorMessage: authResult['message'] ?? 'Authentication failed'));
    }
  }

  String _getUserFriendlyError(FirebaseAuthException e) {
    final errorMap = {
      'invalid-verification-code': 'Invalid OTP. Please check and try again.',
      'invalid-verification-id': 'Session expired. Please request a new OTP.',
      'session-expired': 'OTP has expired. Please request a new one.',
      'network-request-failed': 'Network error. Please check your internet connection.',
      'too-many-requests': 'Too many attempts. Please try again later.',
      'quota-exceeded': 'SMS quota exceeded. Please try again later.',
      'app-not-authorized': 'Service temporarily unavailable. Please try again later.',
      'operation-not-allowed': 'Phone authentication is not enabled. Please contact support.',
      'captcha-check-failed': 'Security verification failed. Please try again.',
      'invalid-app-credential': 'App verification failed. Please try again.',
      'web-context-cancelled': 'Verification cancelled. Please try again.',
      'missing-verification-code': 'Please enter the OTP code.',
      'invalid-phone-number': 'Invalid phone number format.',
    };
    
    if (errorMap.containsKey(e.code)) return errorMap[e.code]!;
    if (e.message?.contains('java.security.cert.CertPathValidatorException') ?? false) {
      return 'Connection error. Please check your internet connection.';
    }
    if (e.message?.contains('Unable to resolve host') ?? false || e.message!.contains('SocketException') ?? false) {
      return 'Network error. Please check your internet connection.';
    }
    return 'An error occurred. Please try again.';
  }

  String _getNetworkError(String error) {
    if (error.toLowerCase().contains('network')) return 'Network error. Please check your internet connection.';
    if (error.toLowerCase().contains('too-many-requests')) return 'Too many requests. Please wait before requesting another OTP.';
    if (error.toLowerCase().contains('quota')) return 'SMS quota exceeded. Please try again later.';
    return 'Failed to send OTP. Please try again.';
  }
}
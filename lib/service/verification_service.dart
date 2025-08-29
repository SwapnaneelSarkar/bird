import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class VerificationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isResending = false;
  String? _emailVerificationId; // Store verification ID for email verification

  // Send OTP to phone number for verification
  Future<Map<String, dynamic>> sendPhoneVerificationOtp(String phoneNumber) async {
    if (_isResending) {
      return {'success': false, 'error': 'Please wait before requesting another OTP'};
    }

    _isResending = true;
    
    // Add +91 country code if not present
    String formattedPhoneNumber = _formatPhoneNumber(phoneNumber);
    debugPrint('Sending verification OTP to: $formattedPhoneNumber');

    try {
      // Configure Firebase Auth settings
      _auth.setSettings(appVerificationDisabledForTesting: false, forceRecaptchaFlow: true);

      final completer = Completer<Map<String, dynamic>>();
      bool callbackTriggered = false;

      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhoneNumber,
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
          debugPrint('Verification OTP sent with verification ID: $verificationId');
          if (!callbackTriggered && !completer.isCompleted) {
            callbackTriggered = true;
            completer.complete({'success': true, 'verificationId': verificationId});
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('Auto retrieval timeout for verification ID: $verificationId');
        },
        timeout: const Duration(seconds: 120),
        forceResendingToken: null,
      );

      final result = await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () => {'success': false, 'error': 'Request timed out. Please try again.'},
      );

      return result;
    } catch (e) {
      debugPrint('Error during verification OTP send: $e');
      return {'success': false, 'error': _getNetworkError(e.toString())};
    } finally {
      _isResending = false;
    }
  }

  // Verify OTP for phone number
  Future<Map<String, dynamic>> verifyPhoneOtp(String otp, String verificationId) async {
    try {
      debugPrint('Verifying OTP with verification ID: $verificationId');

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        debugPrint('Phone verification successful');
        // Sign out immediately since we only need verification, not authentication
        await _auth.signOut();
        return {'success': true, 'message': 'Phone number verified successfully'};
      } else {
        return {'success': false, 'error': 'Verification failed. Please try again.'};
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException: ${e.code} - ${e.message}');
      return {'success': false, 'error': _getUserFriendlyError(e)};
    } catch (e) {
      debugPrint('Unexpected error: $e');
      return {'success': false, 'error': 'An error occurred. Please try again.'};
    }
  }

  // Send email verification using Firebase OTP to phone
  Future<Map<String, dynamic>> sendEmailVerification(String email, {String? phoneNumber}) async {
    // For email verification, we'll use the provided phone number or get from user's profile
    debugPrint('Sending email verification OTP to phone for email: $email');
    
    // Use provided phone number or get from user's profile
    String targetPhoneNumber = phoneNumber ?? await _getUserPhoneNumber();
    
    if (targetPhoneNumber.isEmpty) {
      return {
        'success': false,
        'error': 'Phone number not found. Please update your phone number first.'
      };
    }
    
    // Use Firebase OTP to send verification code to phone
    if (_isResending) {
      return {'success': false, 'error': 'Please wait before requesting another OTP'};
    }

    _isResending = true;
    
    // Add +91 country code if not present
    String formattedPhoneNumber = _formatPhoneNumber(targetPhoneNumber);
    debugPrint('Sending email verification OTP to: $formattedPhoneNumber');

    try {
      // Configure Firebase Auth settings
      _auth.setSettings(appVerificationDisabledForTesting: false, forceRecaptchaFlow: true);

      final completer = Completer<Map<String, dynamic>>();
      bool callbackTriggered = false;

      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhoneNumber,
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
          _emailVerificationId = verificationId; // Store for email verification
          debugPrint('Email verification OTP sent with verification ID: $verificationId');
          if (!callbackTriggered && !completer.isCompleted) {
            callbackTriggered = true;
            completer.complete({'success': true, 'verificationId': verificationId});
          }
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('Auto retrieval timeout for email verification ID: $verificationId');
        },
        timeout: const Duration(seconds: 120),
        forceResendingToken: null,
      );

      final result = await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () => {'success': false, 'error': 'Request timed out. Please try again.'},
      );

      return result;
    } catch (e) {
      debugPrint('Error during email verification OTP send: $e');
      return {'success': false, 'error': _getNetworkError(e.toString())};
    } finally {
      _isResending = false;
    }
  }

  // Verify email using Firebase OTP
  Future<Map<String, dynamic>> verifyEmail(String email, String verificationCode) async {
    debugPrint('Verifying email: $email with OTP: $verificationCode');
    
    if (_emailVerificationId == null || _emailVerificationId!.isEmpty) {
      return {
        'success': false,
        'error': 'Verification session expired. Please request a new OTP.'
      };
    }
    
    return await verifyPhoneOtp(verificationCode, _emailVerificationId!);
  }

  // Helper method to get user's phone number
  Future<String> _getUserPhoneNumber() async {
    // In real implementation, get this from user profile or shared preferences
    // For now, return a placeholder
    // You should implement this to get the actual phone number from user data
    return '+1234567890'; // Placeholder - replace with actual implementation
  }

  // Helper method to format phone number with country code
  String _formatPhoneNumber(String phoneNumber) {
    // If the phone number already starts with +, it already has a country code
    if (phoneNumber.startsWith('+')) {
      return phoneNumber;
    }
    
    // Remove any special characters except digits
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // If it's a 10-digit number, we need to determine the country code
    // For now, default to +91 (India) - this should be passed from the UI
    if (cleanNumber.length == 10) {
      // This will be handled by the UI passing the full number with country code
      return '+91$cleanNumber'; // Fallback to India
    }
    
    // If it already has a country code pattern, return as is
    if (cleanNumber.length > 10) {
      return '+$cleanNumber';
    }
    
    // For any other case, assume it needs a country code
    return '+91$cleanNumber'; // Fallback to India
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
    if (e.message?.contains('Unable to resolve host') ?? false || (e.message?.contains('SocketException') ?? false)) {
      return 'Network error. Please check your internet connection.';
    }
    return 'An error occurred. Please try again.';
  }

  String _getNetworkError(String error) {
    if (error.contains('SocketException') || error.contains('NetworkException')) {
      return 'Network error. Please check your internet connection.';
    }
    if (error.contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    }
    return 'An error occurred. Please try again.';
  }
} 
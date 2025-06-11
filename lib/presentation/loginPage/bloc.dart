// lib/presentation/screens/loginPage/bloc.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../../models/country_model.dart';
import 'event.dart';
import 'state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  LoginBloc() : super(LoginInitialState()) {
    on<SubmitEvent>(_onSubmit);
    on<PhoneVerificationCompletedEvent>(_onPhoneVerificationCompleted);
    on<PhoneVerificationFailedEvent>(_onPhoneVerificationFailed);
    on<PhoneCodeSentEvent>(_onPhoneCodeSent);
    on<CountrySelectedEvent>(_onCountrySelected);
  }

  Future<void> _onSubmit(SubmitEvent event, Emitter<LoginState> emit) async {
    emit(LoginLoadingState());

    try {
      debugPrint('LoginBloc: Starting phone verification for: ${event.phoneNumber}');
      
      // Validate phone number format
      if (!_isValidPhoneNumberFormat(event.phoneNumber)) {
        debugPrint('LoginBloc: Invalid phone number format detected');
        emit(LoginErrorState(
          errorMessage: 'Invalid phone number format. Please check and try again.',
        ));
        return;
      }
      
      // Save phone number for future use
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_phone', event.phoneNumber);
      debugPrint('LoginBloc: Saved phone number to preferences');

      // Parse country code and phone number for logging
      final phoneDetails = _parsePhoneNumber(event.phoneNumber);
      debugPrint('LoginBloc: Country code: ${phoneDetails['countryCode']}, Phone: ${phoneDetails['phoneNumber']}');
      debugPrint('LoginBloc: Full number length: ${event.phoneNumber.length}');

      // Force reCAPTCHA flow for better compatibility across devices
      _auth.setSettings(
        appVerificationDisabledForTesting: false,
        forceRecaptchaFlow: true,
      );
      debugPrint('LoginBloc: Firebase auth settings configured');

      // Start phone verification
      await _auth.verifyPhoneNumber(
        phoneNumber: event.phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (only happens on Android in some cases)
          debugPrint('LoginBloc: Auto-verification completed');
          debugPrint('LoginBloc: Credential verification ID: ${credential.verificationId}');
          add(PhoneVerificationCompletedEvent(
            verificationId: credential.verificationId ?? '',
          ));
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('LoginBloc: Phone verification failed');
          debugPrint('LoginBloc: Firebase Auth Error Code: ${e.code}');
          debugPrint('LoginBloc: Firebase Auth Error Message: ${e.message}');
          debugPrint('LoginBloc: Firebase Auth Plugin: ${e.plugin}');
          debugPrint('LoginBloc: Stack trace: ${e.stackTrace}');
          
          add(PhoneVerificationFailedEvent(
            error: _getUserFriendlyError(e),
          ));
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('LoginBloc: OTP code sent successfully');
          debugPrint('LoginBloc: Verification ID: $verificationId');
          debugPrint('LoginBloc: Resend token: $resendToken');
          
          add(PhoneCodeSentEvent(verificationId: verificationId));
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('LoginBloc: Auto retrieval timeout');
          debugPrint('LoginBloc: Verification ID on timeout: $verificationId');
        },
        timeout: const Duration(seconds: 120),
        forceResendingToken: null,
      );
      
      debugPrint('LoginBloc: Phone verification process initiated');
      
    } catch (e, stackTrace) {
      debugPrint('LoginBloc: Exception in phone verification process');
      debugPrint('LoginBloc: Exception: $e');
      debugPrint('LoginBloc: Stack trace: $stackTrace');
      
      emit(LoginErrorState(
        errorMessage: 'Error occurred. Please check your internet connection and try again.',
      ));
    }
  }

  // Validate phone number format before sending to Firebase
  bool _isValidPhoneNumberFormat(String phoneNumber) {
    // Must start with +
    if (!phoneNumber.startsWith('+')) {
      debugPrint('LoginBloc: Phone number must start with +');
      return false;
    }
    
    // Must contain only digits after +
    final numberPart = phoneNumber.substring(1);
    if (!RegExp(r'^\d+$').hasMatch(numberPart)) {
      debugPrint('LoginBloc: Phone number contains non-digit characters');
      return false;
    }
    
    // Check overall length (E.164 format allows 7-15 digits after +)
    if (numberPart.length < 7 || numberPart.length > 15) {
      debugPrint('LoginBloc: Phone number length invalid: ${numberPart.length} digits');
      return false;
    }
    
    // Validate against known country patterns
    final country = _findCountryByPhoneNumber(phoneNumber);
    if (country != null) {
      final expectedPhoneLength = _getExpectedPhoneLength(country.code);
      final actualPhoneLength = phoneNumber.length - country.dialCode.length;
      
      debugPrint('LoginBloc: Country: ${country.name}, Expected: $expectedPhoneLength, Actual: $actualPhoneLength');
      
      // Strict validation for certain countries
      final strictCountries = ['AE', 'SG', 'SA', 'MY', 'TH', 'KE', 'GH', 'ET', 'LK', 'VN', 'MM'];
      
      if (strictCountries.contains(country.code)) {
        // Exact length required for these countries
        if (actualPhoneLength != expectedPhoneLength) {
          debugPrint('LoginBloc: Exact length mismatch for ${country.name}');
          return false;
        }
      } else {
        // Allow some flexibility for other countries (±1 digit)
        if (actualPhoneLength < expectedPhoneLength - 1 || actualPhoneLength > expectedPhoneLength + 1) {
          debugPrint('LoginBloc: Phone number length mismatch for ${country.name}');
          return false;
        }
      }
    }
    
    return true;
  }

  // Find country by matching dial code in phone number
  Country? _findCountryByPhoneNumber(String phoneNumber) {
    // Sort countries by dial code length (longest first) to match correctly
    final sortedCountries = List<Country>.from(CountryData.countries)
      ..sort((a, b) => b.dialCode.length.compareTo(a.dialCode.length));
    
    for (final country in sortedCountries) {
      if (phoneNumber.startsWith(country.dialCode)) {
        debugPrint('LoginBloc: Found matching country: ${country.name} (${country.dialCode})');
        return country;
      }
    }
    
    debugPrint('LoginBloc: No matching country found for: $phoneNumber');
    return null;
  }

  // Parse phone number into country code and number
  Map<String, String> _parsePhoneNumber(String phoneNumber) {
    final country = _findCountryByPhoneNumber(phoneNumber);
    
    if (country != null) {
      return {
        'countryCode': country.dialCode,
        'phoneNumber': phoneNumber.substring(country.dialCode.length),
        'countryName': country.name,
      };
    }
    
    // Fallback parsing if no country match found
    return {
      'countryCode': 'Unknown',
      'phoneNumber': phoneNumber.substring(1), // Remove +
      'countryName': 'Unknown',
    };
  }

  // Get expected phone number length for a country
  int _getExpectedPhoneLength(String countryCode) {
    switch (countryCode) {
      case 'IN': return 10; // India
      case 'US':
      case 'CA': return 10; // US, Canada
      case 'GB': return 11; // UK
      case 'AU': return 9; // Australia
      case 'DE': return 11; // Germany (corrected)
      case 'FR': return 10; // France
      case 'JP': return 11; // Japan
      case 'CN': return 11; // China
      case 'BR': return 11; // Brazil
      case 'RU': return 10; // Russia
      case 'KR': return 11; // South Korea
      case 'IT': return 10; // Italy
      case 'ES': return 9; // Spain
      case 'MX': return 10; // Mexico
      case 'ID': return 10; // Indonesia (corrected)
      case 'TR': return 10; // Turkey
      case 'SA': return 9; // Saudi Arabia
      case 'ZA': return 9; // South Africa
      case 'NG': return 10; // Nigeria (corrected)
      case 'TH': return 9; // Thailand
      case 'MY': return 9; // Malaysia (corrected)
      case 'SG': return 8; // Singapore
      case 'PH': return 10; // Philippines
      case 'VN': return 9; // Vietnam
      case 'BD': return 10; // Bangladesh (corrected)
      case 'PK': return 10; // Pakistan
      case 'LK': return 9; // Sri Lanka
      case 'NP': return 10; // Nepal
      case 'MM': return 9; // Myanmar
      case 'AE': return 9; // UAE - FIXED: exactly 9 digits
      case 'EG': return 10; // Egypt
      case 'KE': return 9; // Kenya
      case 'GH': return 9; // Ghana
      case 'ET': return 9; // Ethiopia
      default: return 10; // Default fallback
    }
  }

  void _onPhoneVerificationCompleted(
      PhoneVerificationCompletedEvent event, Emitter<LoginState> emit) {
    debugPrint('LoginBloc: Processing verification completed event');
    debugPrint('LoginBloc: Verification ID: ${event.verificationId}');
    
    emit(LoginSuccessState(verificationId: event.verificationId));
  }

  void _onPhoneVerificationFailed(
      PhoneVerificationFailedEvent event, Emitter<LoginState> emit) {
    debugPrint('LoginBloc: Processing verification failed event');
    debugPrint('LoginBloc: Error message: ${event.error}');
    
    emit(LoginErrorState(errorMessage: event.error));
  }

  void _onPhoneCodeSent(
      PhoneCodeSentEvent event, Emitter<LoginState> emit) {
    debugPrint('LoginBloc: Processing code sent event');
    debugPrint('LoginBloc: Verification ID: ${event.verificationId}');
    
    emit(LoginSuccessState(verificationId: event.verificationId));
  }

  void _onCountrySelected(
      CountrySelectedEvent event, Emitter<LoginState> emit) {
    debugPrint('LoginBloc: Country selected');
    debugPrint('LoginBloc: Country code: ${event.countryCode}');
    debugPrint('LoginBloc: Dial code: ${event.dialCode}');
  }

  String _getUserFriendlyError(FirebaseAuthException e) {
    // Log detailed error information for debugging
    debugPrint('LoginBloc: Converting Firebase error to user-friendly message');
    debugPrint('LoginBloc: Original error code: ${e.code}');
    debugPrint('LoginBloc: Original error message: ${e.message}');
    debugPrint('LoginBloc: Plugin: ${e.plugin}');
    
    // Return user-friendly error messages based on error codes
    switch (e.code) {
      case 'network-request-failed':
        debugPrint('LoginBloc: Network error detected');
        return 'Network error. Please check your internet connection and try again.';
        
      case 'too-many-requests':
        debugPrint('LoginBloc: Too many requests error');
        return 'Too many attempts. Please wait a moment and try again.';
        
      case 'invalid-phone-number':
        debugPrint('LoginBloc: Invalid phone number error');
        // Check if the error message contains specific hints
        if (e.message?.contains('TOO_LONG') ?? false) {
          return 'Phone number is too long. Please check the number and try again.';
        } else if (e.message?.contains('TOO_SHORT') ?? false) {
          return 'Phone number is too short. Please check the number and try again.';
        } else if (e.message?.contains('INVALID_COUNTRY_CODE') ?? false) {
          return 'Invalid country code. Please select the correct country.';
        }
        return 'Invalid phone number format. Please check the number and country code.';
        
      case 'quota-exceeded':
        debugPrint('LoginBloc: SMS quota exceeded');
        return 'SMS quota exceeded. Please try again later or contact support.';
        
      case 'app-not-authorized':
        debugPrint('LoginBloc: App not authorized error');
        return 'App not authorized for phone verification. Please contact support.';
        
      case 'operation-not-allowed':
        debugPrint('LoginBloc: Operation not allowed error');
        return 'Phone authentication is not enabled. Please contact support.';
        
      case 'invalid-verification-code':
        debugPrint('LoginBloc: Invalid verification code error');
        return 'Invalid verification code. Please check and try again.';
        
      case 'session-expired':
        debugPrint('LoginBloc: Session expired error');
        return 'Verification session expired. Please request a new code.';
        
      case 'missing-phone-number':
        debugPrint('LoginBloc: Missing phone number error');
        return 'Phone number is required. Please enter your phone number.';
        
      case 'captcha-check-failed':
        debugPrint('LoginBloc: CAPTCHA check failed');
        return 'Security verification failed. Please try again.';
        
      default:
        debugPrint('LoginBloc: Processing default error case');
        
        // Check for specific error message patterns
        final errorMessage = e.message?.toLowerCase() ?? '';
        
        if (errorMessage.contains('certificate') || 
            errorMessage.contains('ssl') ||
            errorMessage.contains('tls')) {
          debugPrint('LoginBloc: SSL/Certificate error detected');
          return 'Connection security error. Please check your internet connection.';
        }
        
        if (errorMessage.contains('unable to resolve host') ||
            errorMessage.contains('unknownhostexception')) {
          debugPrint('LoginBloc: DNS/Host resolution error');
          return 'Cannot connect to server. Please check your internet connection.';
        }
        
        if (errorMessage.contains('socketexception') ||
            errorMessage.contains('timeout')) {
          debugPrint('LoginBloc: Network timeout error');
          return 'Connection timeout. Please check your internet connection and try again.';
        }
        
        if (errorMessage.contains('failed to resolve')) {
          debugPrint('LoginBloc: DNS resolution error');
          return 'Network error. Please check your internet connection.';
        }
        
        if (errorMessage.contains('too_long')) {
          debugPrint('LoginBloc: Phone number too long error');
          return 'Phone number is too long. Please check and try again.';
        }
        
        // Generic error message for unknown cases
        debugPrint('LoginBloc: Using generic error message');
        return 'Something went wrong. Please try again or contact support if the issue persists.';
    }
  }
  
  @override
  Future<void> close() {
    debugPrint('LoginBloc: Closing bloc');
    return super.close();
  }
}
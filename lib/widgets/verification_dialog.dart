import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/color/colorConstant.dart';
import '../constants/font/fontManager.dart';
import '../service/verification_service.dart';
import '../service/email_verification_service.dart';
import 'package:google_fonts/google_fonts.dart';

class VerificationDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final String value; // email or phone number
  final VerificationType type;
  final Function() onVerificationSuccess;
  final String? phoneNumber; // Phone number for email verification

  const VerificationDialog({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.type,
    required this.onVerificationSuccess,
    this.phoneNumber,
  }) : super(key: key);

  @override
  State<VerificationDialog> createState() => _VerificationDialogState();
}

enum VerificationType { email, phone }

class _VerificationDialogState extends State<VerificationDialog> {
  final TextEditingController _otpController = TextEditingController();
  final VerificationService _verificationService = VerificationService();
  final EmailVerificationService _emailVerificationService = EmailVerificationService();
  
  Timer? _timer;
  int _countdown = 60;
  bool _canResend = true;
  bool _isLoading = false;
  bool _isVerifying = false;
  String? _verificationId;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _sendVerificationCode();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _sendVerificationCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Map<String, dynamic> result;
      
      if (widget.type == VerificationType.phone) {
        result = await _verificationService.sendPhoneVerificationOtp(widget.value);
        if (result['success'] == true) {
          _verificationId = result['verificationId'];
        }
      } else {
        // Use new email verification service for email verification
        result = await _emailVerificationService.sendEmailOtp(widget.value);
      }

      if (result['success'] == true) {
        _startTimer();
        _showSnackBar('Verification code sent successfully', false);
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Failed to send verification code';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startTimer() {
    _countdown = 60;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_countdown > 0) {
            _countdown--;
          } else {
            _canResend = true;
            timer.cancel();
          }
        });
      }
    });
  }

  Future<void> _verifyCode() async {
    if (_otpController.text.length != 6) {
      setState(() {
        _errorMessage = 'Please enter a 6-digit verification code';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      Map<String, dynamic> result;
      
      if (widget.type == VerificationType.phone) {
        result = await _verificationService.verifyPhoneOtp(
          _otpController.text,
          _verificationId ?? '',
        );
      } else {
        // Use new email verification service for email verification
        result = await _emailVerificationService.verifyEmailOtp(
          widget.value,
          _otpController.text,
        );
      }

      if (result['success'] == true) {
        _showSnackBar(result['message'] ?? 'Verification successful', false);
        widget.onVerificationSuccess();
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Verification failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  Future<void> _resendVerificationCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Map<String, dynamic> result;
      
      if (widget.type == VerificationType.phone) {
        result = await _verificationService.sendPhoneVerificationOtp(widget.value);
        if (result['success'] == true) {
          _verificationId = result['verificationId'];
        }
      } else {
        // Use new email verification service for email resend
        result = await _emailVerificationService.resendEmailOtp(widget.value);
      }

      if (result['success'] == true) {
        _startTimer();
        _showSnackBar('Verification code resent successfully', false);
      } else {
        setState(() {
          _errorMessage = result['error'] ?? 'Failed to resend verification code';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, bool isError) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 4 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final responsiveTextScale = screenWidth / 375;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(24 * responsiveTextScale),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  widget.type == VerificationType.phone ? Icons.phone : Icons.email,
                  color: ColorManager.primary,
                  size: 24 * responsiveTextScale,
                ),
                SizedBox(width: 12 * responsiveTextScale),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: FontSize.s18 * responsiveTextScale,
                      fontWeight: FontWeightManager.semiBold,
                      fontFamily: FontFamily.Montserrat,
                      color: ColorManager.black,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: Icon(
                    Icons.close,
                    color: Colors.grey[600],
                    size: 20 * responsiveTextScale,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16 * responsiveTextScale),
            
            // Subtitle
            Text(
              widget.subtitle,
              style: TextStyle(
                fontSize: FontSize.s14 * responsiveTextScale,
                color: Colors.grey[600],
                fontFamily: FontFamily.Montserrat,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 24 * responsiveTextScale),
            
            // OTP Input Field
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16 * responsiveTextScale),
              child: TextFormField(
                controller: _otpController,
                maxLength: 6,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: GoogleFonts.poppins(
                  fontSize: 20 * responsiveTextScale,
                  fontWeight: FontWeight.w600,
                  color: ColorManager.black,
                  letterSpacing: 8.0,
                ),
                decoration: InputDecoration(
                  hintText: "000000",
                  hintStyle: GoogleFonts.poppins(
                    fontSize: 20 * responsiveTextScale,
                    fontWeight: FontWeight.w300,
                    color: Colors.grey.shade400,
                    letterSpacing: 8.0,
                  ),
                  counterText: "",
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16 * responsiveTextScale,
                    vertical: 16 * responsiveTextScale,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12 * responsiveTextScale),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12 * responsiveTextScale),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12 * responsiveTextScale),
                    borderSide: BorderSide(color: ColorManager.primary, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12 * responsiveTextScale),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                ),
                autofocus: true,
              ),
            ),
            
            // Error Message
            if (_errorMessage != null) ...[
              SizedBox(height: 12 * responsiveTextScale),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 12 * responsiveTextScale,
                  vertical: 8 * responsiveTextScale,
                ),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8 * responsiveTextScale),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade600,
                      size: 16 * responsiveTextScale,
                    ),
                    SizedBox(width: 8 * responsiveTextScale),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Colors.red.shade600,
                          fontSize: FontSize.s12 * responsiveTextScale,
                          fontFamily: FontFamily.Montserrat,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            SizedBox(height: 24 * responsiveTextScale),
            
            // Verify Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isVerifying || _otpController.text.length != 6
                    ? null
                    : _verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    vertical: 16 * responsiveTextScale,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12 * responsiveTextScale),
                  ),
                ),
                child: _isVerifying
                    ? SizedBox(
                        width: 20 * responsiveTextScale,
                        height: 20 * responsiveTextScale,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Verify',
                        style: TextStyle(
                          fontSize: FontSize.s16 * responsiveTextScale,
                          fontWeight: FontWeightManager.semiBold,
                          fontFamily: FontFamily.Montserrat,
                        ),
                      ),
              ),
            ),
            
            SizedBox(height: 16 * responsiveTextScale),
            
            // Resend Section
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Didn't receive the code? ",
                  style: TextStyle(
                    fontSize: FontSize.s14 * responsiveTextScale,
                    color: Colors.grey[600],
                    fontFamily: FontFamily.Montserrat,
                  ),
                ),
                if (_canResend)
                  TextButton(
                    onPressed: _isLoading ? null : _resendVerificationCode,
                    child: _isLoading
                        ? SizedBox(
                            width: 16 * responsiveTextScale,
                            height: 16 * responsiveTextScale,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(ColorManager.primary),
                            ),
                          )
                        : Text(
                            'Resend',
                            style: TextStyle(
                              fontSize: FontSize.s14 * responsiveTextScale,
                              fontWeight: FontWeightManager.semiBold,
                              color: ColorManager.primary,
                              fontFamily: FontFamily.Montserrat,
                            ),
                          ),
                  )
                else
                  Text(
                    'Resend in $_countdown',
                    style: TextStyle(
                      fontSize: FontSize.s14 * responsiveTextScale,
                      color: Colors.grey[400],
                      fontFamily: FontFamily.Montserrat,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 
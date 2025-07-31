import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/font/fontManager.dart';
import '../service/verification_service.dart';

class AccountDeletionVerificationDialog extends StatefulWidget {
  final String phoneNumber;
  final Function(String otp, String verificationId) onVerificationSuccess;
  final VoidCallback onCancel;

  const AccountDeletionVerificationDialog({
    Key? key,
    required this.phoneNumber,
    required this.onVerificationSuccess,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<AccountDeletionVerificationDialog> createState() => _AccountDeletionVerificationDialogState();
}

class _AccountDeletionVerificationDialogState extends State<AccountDeletionVerificationDialog> {
  final TextEditingController _otpController = TextEditingController();
  final VerificationService _verificationService = VerificationService();
  
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
      final result = await _verificationService.sendPhoneVerificationOtp(widget.phoneNumber);

      if (result['success'] == true) {
        _verificationId = result['verificationId'];
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

    if (_verificationId == null) {
      setState(() {
        _errorMessage = 'Verification session expired. Please try again.';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final result = await _verificationService.verifyPhoneOtp(
        _otpController.text,
        _verificationId!,
      );

      if (result['success'] == true) {
        _showSnackBar('OTP verified successfully', false);
        widget.onVerificationSuccess(_otpController.text, _verificationId!);
        Navigator.of(context).pop();
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
                Container(
                  padding: EdgeInsets.all(12 * responsiveTextScale),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12 * responsiveTextScale),
                  ),
                  child: Icon(
                    Icons.delete_forever,
                    color: Colors.red.shade600,
                    size: 24 * responsiveTextScale,
                  ),
                ),
                SizedBox(width: 16 * responsiveTextScale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delete Account',
                        style: TextStyle(
                          fontSize: FontSize.s18 * responsiveTextScale,
                          fontWeight: FontWeightManager.bold,
                          fontFamily: FontFamily.Montserrat,
                          color: Colors.red.shade600,
                        ),
                      ),
                      SizedBox(height: 4 * responsiveTextScale),
                      Text(
                        'OTP Verification Required',
                        style: TextStyle(
                          fontSize: FontSize.s14 * responsiveTextScale,
                          fontFamily: FontFamily.Montserrat,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 24 * responsiveTextScale),
            
            // Warning message
            Container(
              padding: EdgeInsets.all(16 * responsiveTextScale),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12 * responsiveTextScale),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red.shade600,
                    size: 20 * responsiveTextScale,
                  ),
                  SizedBox(width: 12 * responsiveTextScale),
                  Expanded(
                    child: Text(
                      'This action cannot be undone. All your data will be permanently deleted.',
                                             style: TextStyle(
                         fontSize: FontSize.s12 * responsiveTextScale,
                         fontFamily: FontFamily.Montserrat,
                         color: Colors.red.shade700,
                         fontWeight: FontWeightManager.medium,
                       ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24 * responsiveTextScale),
            
            // OTP input
            Text(
              'Enter the 6-digit OTP sent to\n${widget.phoneNumber}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: FontSize.s14 * responsiveTextScale,
                fontFamily: FontFamily.Montserrat,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            
            SizedBox(height: 16 * responsiveTextScale),
            
            // OTP TextField
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              style: TextStyle(
                fontSize: FontSize.s18 * responsiveTextScale,
                fontWeight: FontWeightManager.bold,
                fontFamily: FontFamily.Montserrat,
                letterSpacing: 8,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '000000',
                hintStyle: TextStyle(
                  fontSize: FontSize.s18 * responsiveTextScale,
                  color: Colors.grey.shade400,
                  letterSpacing: 8,
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
                  borderSide: BorderSide(color: Colors.red.shade400, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12 * responsiveTextScale),
                  borderSide: BorderSide(color: Colors.red.shade400),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16 * responsiveTextScale,
                  vertical: 16 * responsiveTextScale,
                ),
              ),
            ),
            
            if (_errorMessage != null) ...[
              SizedBox(height: 12 * responsiveTextScale),
              Container(
                padding: EdgeInsets.all(12 * responsiveTextScale),
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
                          fontSize: FontSize.s12 * responsiveTextScale,
                          fontFamily: FontFamily.Montserrat,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            SizedBox(height: 16 * responsiveTextScale),
            
            // Resend OTP button
            if (_canResend) ...[
              TextButton(
                onPressed: _isLoading ? null : _sendVerificationCode,
                child: Text(
                  'Resend OTP',
                  style: TextStyle(
                    fontSize: FontSize.s14 * responsiveTextScale,
                    fontFamily: FontFamily.Montserrat,
                    color: Colors.red.shade600,
                    fontWeight: FontWeightManager.medium,
                  ),
                ),
              ),
            ] else ...[
              Text(
                'Resend OTP in $_countdown seconds',
                style: TextStyle(
                  fontSize: FontSize.s12 * responsiveTextScale,
                  fontFamily: FontFamily.Montserrat,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
            
            SizedBox(height: 24 * responsiveTextScale),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16 * responsiveTextScale),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12 * responsiveTextScale),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      'CANCEL',
                      style: TextStyle(
                        fontSize: FontSize.s14 * responsiveTextScale,
                        fontFamily: FontFamily.Montserrat,
                        fontWeight: FontWeightManager.medium,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12 * responsiveTextScale),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isVerifying || _otpController.text.length != 6
                        ? null
                        : _verifyCode,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16 * responsiveTextScale),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12 * responsiveTextScale),
                      ),
                      elevation: 0,
                    ),
                    child: _isVerifying
                        ? SizedBox(
                            width: 20 * responsiveTextScale,
                            height: 20 * responsiveTextScale,
                                                 child: const CircularProgressIndicator(
                       strokeWidth: 2,
                       valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                     ),
                          )
                        : Text(
                            'VERIFY & DELETE',
                            style: TextStyle(
                              fontSize: FontSize.s14 * responsiveTextScale,
                              fontFamily: FontFamily.Montserrat,
                              fontWeight: FontWeightManager.semiBold,
                            ),
                          ),
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
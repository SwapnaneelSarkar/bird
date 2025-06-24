import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../constants/color/colorConstant.dart';
import '../../constants/router/router.dart';
import '../../widgets/custom_button_large.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../utils/timezone_utils.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  const OtpScreen({Key? key, required this.phoneNumber, required this.verificationId}) : super(key: key);

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController otpController = TextEditingController();
  Timer? _timer;
  int _countdown = 0;
  bool _canResend = true;
  bool _isResendingInProgress = false;
  DateTime? _lastResendTap;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    otpController.dispose();
    _timer?.cancel();
    super.dispose();
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

  void _handleResendTap(BuildContext context) {
    final now = TimezoneUtils.getCurrentTimeIST();
    if (_lastResendTap != null && now.difference(_lastResendTap!).inSeconds < 2) return;
    _lastResendTap = now;
    
    if (_isResendingInProgress || !_canResend) return;
    
    debugPrint('Processing resend request for: ${widget.phoneNumber}');
    _isResendingInProgress = true;
    context.read<OtpBloc>().add(ResendOtpEvent(phoneNumber: widget.phoneNumber));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocProvider(
        create: (_) => OtpBloc(),
        child: BlocConsumer<OtpBloc, OtpState>(
          listener: (context, state) {
            if (_isResendingInProgress && state is! OtpVerificationLoadingState) {
              _isResendingInProgress = false;
            }
            
            if (state is OtpVerificationSuccessState) {
              _navigateBasedOnLogin(state);
            } else if (state is OtpResentState) {
              _handleOtpResent();
            } else if (state is OtpVerificationFailureState) {
              _showErrorSnackBar(state.errorMessage);
            }
          },
          builder: (context, state) {
            final isVerifying = state is OtpVerificationLoadingState;
            
            return SafeArea(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                          Image.asset('assets/logo.png', height: 60, color: ColorManager.primary),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                          const Text('Enter 6-digit OTP', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 8),
                          Text('Sent to ${widget.phoneNumber}', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                          _buildOtpField(context),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                          isVerifying 
                            ? CircularProgressIndicator(color: ColorManager.primary)
                            : CustomLargeButton(
                                text: 'Verify',
                                onPressed: otpController.text.length == 6
                                  ? () => context.read<OtpBloc>().add(VerifyOtpEvent(otp: otpController.text, verificationId: widget.verificationId))
                                  : null,
                              ),
                          const SizedBox(height: 24),
                          _buildResendSection(context, isVerifying),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOtpField(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextFormField(
        controller: otpController,
        onChanged: (val) => context.read<OtpBloc>().add(OtpChangedEvent(otp: val)),
        maxLength: 6,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: ColorManager.black, letterSpacing: 8.0),
        decoration: InputDecoration(
          hintText: "000000 *",
          hintStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w300, color: Colors.grey.shade400, letterSpacing: 8.0),
          counterText: "",
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: ColorManager.black.withOpacity(0.1))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: ColorManager.black.withOpacity(0.1))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: ColorManager.primary.withOpacity(0.8), width: 1.5)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.red)),
        ),
        autofocus: true,
      ),
    );
  }

  Widget _buildResendSection(BuildContext context, bool isVerifying) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("Didn't receive code? ", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        GestureDetector(
          onTap: (_canResend && !isVerifying && !_isResendingInProgress) ? () => _handleResendTap(context) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isResendingInProgress) ...[
                  SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5, valueColor: AlwaysStoppedAnimation<Color>(ColorManager.primary))),
                  const SizedBox(width: 6),
                  Text('Sending...', style: TextStyle(color: ColorManager.primary, fontSize: 14, fontWeight: FontWeight.w500)),
                ] else ...[
                  Text(
                    _canResend ? 'Resend' : 'Resend in ${_countdown}s',
                    style: TextStyle(
                      color: _canResend && !isVerifying ? ColorManager.primary : Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      decoration: _canResend && !isVerifying ? TextDecoration.underline : null,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _navigateBasedOnLogin(OtpVerificationSuccessState state) {
    debugPrint('OTP Verification Successful - Is Login: ${state.isLogin}');
    
    if (state.isLogin) {
  Navigator.pushNamedAndRemoveUntil(
    context,
    Routes.home,
    (route) => false, // removes all previous routes
    arguments: {
      'userData': state.userData,
      'token': state.token,
    },
  );
} else {
  Navigator.pushNamedAndRemoveUntil(
    context,
    Routes.profileComplete,
    (route) => false,
    arguments: {
      'userData': state.userData,
      'token': state.token,
    },
  );
}

  }

  void _handleOtpResent() {
    debugPrint('OTP Resent Successfully');
    _isResendingInProgress = false;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(children: [Icon(Icons.check_circle, color: Colors.white, size: 20), SizedBox(width: 12), Text("OTP Resent Successfully")]),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
    
    otpController.clear();
    _startTimer();
  }

  void _showErrorSnackBar(String message) {
    debugPrint('OTP Error: $message');
    _isResendingInProgress = false;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [Icon(Icons.error_outline, color: Colors.white, size: 20), SizedBox(width: 12), Expanded(child: Text(message))]),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
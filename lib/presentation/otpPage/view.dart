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
            final screenWidth = MediaQuery.of(context).size.width;
            final screenHeight = MediaQuery.of(context).size.height;
            
            return SafeArea(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: screenHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06), // Responsive horizontal padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: screenHeight * 0.1),
                          Image.asset(
                            'assets/logo.png', 
                            height: screenWidth * 0.15, // Responsive logo size
                            // color: ColorManager.primary
                          ),
                          SizedBox(height: screenHeight * 0.05),
                          Text(
                            'Enter 6-digit OTP', 
                            style: TextStyle(
                              fontSize: screenWidth * 0.055, // Responsive font size
                              fontWeight: FontWeight.w900
                            )
                          ),
                          SizedBox(height: screenHeight * 0.01), // Responsive spacing
                          Text(
                            'Sent to ${widget.phoneNumber}', 
                            style: TextStyle(
                              color: Colors.grey.shade600, 
                              fontSize: screenWidth * 0.035 // Responsive font size
                            )
                          ),
                          SizedBox(height: screenHeight * 0.04),
                          _buildOtpField(context, screenWidth, screenHeight),
                          SizedBox(height: screenHeight * 0.05),
                          isVerifying 
                            ? CircularProgressIndicator(color: ColorManager.primary)
                            : CustomLargeButton(
                                text: 'Verify',
                                onPressed: otpController.text.length == 6
                                  ? () => context.read<OtpBloc>().add(VerifyOtpEvent(otp: otpController.text, verificationId: widget.verificationId))
                                  : null,
                              ),
                          SizedBox(height: screenHeight * 0.03), // Responsive spacing
                          _buildResendSection(context, isVerifying, screenWidth),
                          SizedBox(height: screenHeight * 0.05), // Responsive spacing
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

  Widget _buildOtpField(BuildContext context, double screenWidth, double screenHeight) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05), // Responsive padding
      child: TextFormField(
        controller: otpController,
        onChanged: (val) => context.read<OtpBloc>().add(OtpChangedEvent(otp: val)),
        maxLength: 6,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: GoogleFonts.poppins(
          fontSize: screenWidth * 0.05, // Responsive font size
          fontWeight: FontWeight.w600, 
          color: ColorManager.black, 
          letterSpacing: screenWidth * 0.02 // Responsive letter spacing
        ),
        decoration: InputDecoration(
          hintText: "000000",
          hintStyle: GoogleFonts.poppins(
            fontSize: screenWidth * 0.05, // Responsive font size
            fontWeight: FontWeight.w300, 
            color: Colors.grey.shade400, 
            letterSpacing: screenWidth * 0.02 // Responsive letter spacing
          ),
          counterText: "",
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04, // Responsive horizontal padding
            vertical: screenHeight * 0.02 // Responsive vertical padding
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.04), // Responsive border radius
            borderSide: BorderSide(color: ColorManager.black.withOpacity(0.1))
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.04), // Responsive border radius
            borderSide: BorderSide(color: ColorManager.black.withOpacity(0.1))
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.04), // Responsive border radius
            borderSide: BorderSide(color: ColorManager.primary.withOpacity(0.8), width: 1.5)
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.04), // Responsive border radius
            borderSide: const BorderSide(color: Colors.red)
          ),
        ),
        autofocus: true,
      ),
    );
  }

  Widget _buildResendSection(BuildContext context, bool isVerifying, double screenWidth) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't receive code? ", 
          style: TextStyle(
            color: Colors.grey.shade600, 
            fontSize: screenWidth * 0.035 // Responsive font size
          )
        ),
        GestureDetector(
          onTap: (_canResend && !isVerifying && !_isResendingInProgress) ? () => _handleResendTap(context) : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isResendingInProgress) ...[
                SizedBox(
                  width: screenWidth * 0.03, 
                  height: screenWidth * 0.03, 
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5, 
                    valueColor: AlwaysStoppedAnimation<Color>(ColorManager.primary)
                  )
                ),
                SizedBox(width: screenWidth * 0.015),
                Text(
                  'Sending...', 
                  style: TextStyle(
                    color: ColorManager.primary, 
                    fontSize: screenWidth * 0.035, // Responsive font size
                    fontWeight: FontWeight.w500, 
                    decoration: TextDecoration.none
                  )
                ),
              ] else ...[
                Text(
                  _canResend ? 'Resend' : 'Resend in ${_countdown}s',
                  style: TextStyle(
                    color: _canResend && !isVerifying ? ColorManager.primary : Colors.grey,
                    fontSize: screenWidth * 0.035, // Responsive font size
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  void _navigateBasedOnLogin(OtpVerificationSuccessState state) {
    debugPrint('OTP Verification Successful - Is Login:  [33m${state.isLogin} [0m');
    
    if (state.isLogin) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        Routes.dashboard, // Changed from Routes.home
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
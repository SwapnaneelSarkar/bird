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

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  const OtpScreen({
    Key? key,
    required this.phoneNumber,
    required this.verificationId,
  }) : super(key: key);

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  // Single controller for the OTP field
  final TextEditingController otpController = TextEditingController();

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  // Get the complete OTP directly from the controller
  String get completeOtp => otpController.text;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocProvider(
        create: (_) => OtpBloc(),
        child: BlocConsumer<OtpBloc, OtpState>(
          listener: (context, state) {
            if (state is OtpVerificationSuccessState) {
              debugPrint('OTP Verification Successful');
              debugPrint('Is Login: ${state.isLogin}');
              debugPrint('User Data: ${state.userData}');
              debugPrint('Token: ${state.token}');
              
              if (state.isLogin) {
                // User is logging in, navigate to home page
                Navigator.pushReplacementNamed(
                  context,
                  Routes.home,
                  arguments: {
                    'userData': state.userData,
                    'token': state.token,
                  },
                );
              } else {
                // User is signing up, navigate to profile complete page
                Navigator.pushReplacementNamed(
                  context,
                  Routes.profileComplete,
                  arguments: {
                    'userData': state.userData,
                    'token': state.token,
                  },
                );
              }
            } else if (state is OtpResentState) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("OTP Resent")),
              );
            } else if (state is OtpVerificationFailureState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            return SafeArea(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                          Image.asset(
                            'assets/logo.png',
                            height: 60,
                            color: ColorManager.primary,
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                          const Text(
                            'Enter 6-digit OTP',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sent to ${widget.phoneNumber}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.04),
                          
                          // Replace the Wrap with a single OtpField
                          _buildOtpField(context),
                          
                          SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                          if (state is OtpVerificationLoadingState)
                            CircularProgressIndicator(color: ColorManager.primary)
                          else
                            CustomLargeButton(
                              text: 'Verify',
                              onPressed: completeOtp.length == 6
                                  ? () {
                                      context.read<OtpBloc>().add(
                                            VerifyOtpEvent(
                                              otp: completeOtp,
                                              verificationId: widget.verificationId,
                                            ),
                                          );
                                    }
                                  : () {}, // Empty function when disabled
                            ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Didn't receive code? ",
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: state is OtpVerificationLoadingState
                                    ? null
                                    : () {
                                        context.read<OtpBloc>().add(
                                            ResendOtpEvent(
                                                phoneNumber: widget.phoneNumber));
                                      },
                                child: Text(
                                  'Resend',
                                  style: TextStyle(
                                    color: state is OtpVerificationLoadingState
                                        ? Colors.grey
                                        : ColorManager.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
        onChanged: (val) {
          context.read<OtpBloc>().add(OtpChangedEvent(otp: val));
        },
        maxLength: 6,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: ColorManager.black,
          letterSpacing: 8.0, // Adding letter spacing for OTP-like appearance
        ),
        decoration: InputDecoration(
          hintText: "000000",
          hintStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w300,
            color: Colors.grey.shade400,
            letterSpacing: 8.0,
          ),
          counterText: "",
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: ColorManager.black.withOpacity(0.1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: ColorManager.black.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: ColorManager.primary.withOpacity(0.8), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red),
          ),
        ),
        autofocus: true,
      ),
    );
  }
}
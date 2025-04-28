import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../constants/color/colorConstant.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';

class OtpScreen extends StatefulWidget {
  final String phoneNumber;
  final String verificationId;

  const OtpScreen(
      {Key? key, required this.phoneNumber, required this.verificationId})
      : super(key: key);

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  // Changed from 4 to 6 digits for Firebase OTP
  final List<TextEditingController> otpControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(6, (index) => FocusNode());

  @override
  void dispose() {
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get completeOtp {
    return otpControllers.map((controller) => controller.text).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocProvider(
        create: (context) => OtpBloc(),
        child: BlocConsumer<OtpBloc, OtpState>(
          listener: (context, state) {
            if (state is OtpVerificationSuccessState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('OTP Verified Successfully!')),
              );
              Navigator.of(context).pushReplacementNamed('/nextPage');
            } else if (state is OtpVerificationFailureState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.errorMessage)),
              );
            } else if (state is OtpResentState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("OTP Resent")),
              );
            }
          },
          builder: (context, state) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 80),
                    Image.asset(
                      'assets/logo.png',
                      height: 60,
                      color: ColorManager.primary,
                    ),
                    SizedBox(height: 40),
                    Text(
                      'Enter 6-digit OTP',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 22.0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Sent to your phone number',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14.0,
                      ),
                    ),
                    SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (index) {
                        // Changed to 6 digits
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6.0), // Adjusted padding
                          child: Container(
                            width:
                                40.0, // Slightly smaller width to fit 6 digits
                            height: 55.0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: TextField(
                              controller: otpControllers[index],
                              focusNode: focusNodes[index],
                              onChanged: (value) {
                                if (value.length == 1 && index < 5) {
                                  // Changed to check for index < 5
                                  focusNodes[index + 1].requestFocus();
                                }
                                context
                                    .read<OtpBloc>()
                                    .add(OtpChangedEvent(otp: completeOtp));
                              },
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                counterText: "",
                                contentPadding: EdgeInsets.zero,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 1.0,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade300,
                                    width: 1.0,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide(
                                    color: ColorManager.primary,
                                    width: 1,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 32),
                    BlocConsumer<OtpBloc, OtpState>(
                      listener: (context, state) {
                        if (state is OtpVerificationSuccessState) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('OTP Verified Successfully!')),
                          );
                          // Navigate to the next page after successful verification
                          Navigator.of(context)
                              .pushReplacementNamed('/address');
                        } else if (state is OtpVerificationFailureState) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(state.errorMessage)),
                          );
                        }
                      },
                      builder: (context, state) {
                        if (state is OtpVerificationLoadingState) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: ColorManager.primary,
                            ),
                          );
                        }
                        return ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorManager.primary,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: Size(double.infinity, 50),
                          ),
                          onPressed: () {
                            if (completeOtp.length != 6) {
                              // Changed to check for 6 digits
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        "Please enter a valid 6-digit OTP")), // Updated message
                              );
                              return;
                            }

                            context.read<OtpBloc>().add(
                                  VerifyOtpEvent(
                                    otp: completeOtp,
                                    verificationId: widget
                                        .verificationId, // Added verification ID
                                  ),
                                );
                          },
                          child: Text(
                            'Verify',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Didn't receive code? ",
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 14),
                        ),
                        GestureDetector(
                          onTap: () {
                            // Updated to pass phone number to the ResendOtpEvent
                            context.read<OtpBloc>().add(
                                  ResendOtpEvent(
                                      phoneNumber: widget.phoneNumber),
                                );
                          },
                          child: Text(
                            'Resend',
                            style: TextStyle(
                              color: ColorManager.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

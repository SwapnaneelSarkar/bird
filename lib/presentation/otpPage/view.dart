import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../constants/color/colorConstant.dart';
import '../../widgets/custom_button_large.dart';
import '../../widgets/otp_field.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';

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
  final List<TextEditingController> otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());

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

  String get completeOtp =>
      otpControllers.map((controller) => controller.text).join();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocProvider(
        create: (_) => OtpBloc(),
        child: BlocConsumer<OtpBloc, OtpState>(
          listener: (context, state) {
            if (state is OtpVerificationSuccessState) {
              Navigator.of(context).pushReplacementNamed('/profileComplete');
            } else if (state is OtpResentState) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("OTP Resent")),
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
                          Wrap(
                            spacing: MediaQuery.of(context).size.width * 0.04,
                            alignment: WrapAlignment.center,
                            children: List.generate(4, (index) {
                              return OtpBox(
                                controller: otpControllers[index],
                                focusNode: focusNodes[index],
                                onChanged: (val) {
                                  if (val.length == 1 && index < 3) {
                                    focusNodes[index + 1].requestFocus();
                                  }
                                  context.read<OtpBloc>().add(
                                      OtpChangedEvent(otp: completeOtp));
                                },
                              );
                            }),
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.05),
                          if (state is OtpVerificationLoadingState)
                            CircularProgressIndicator(color: ColorManager.primary)
                          else
                            CustomLargeButton(
                              text: 'Verify',
                              onPressed: () {
                                context.read<OtpBloc>().add(
                                      VerifyOtpEvent(
                                        otp: completeOtp,
                                        verificationId: widget.verificationId,
                                      ),
                                    );
                              },
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
                                onTap: () {
                                  context.read<OtpBloc>().add(
                                      ResendOtpEvent(
                                          phoneNumber: widget.phoneNumber));
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
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/color/colorConstant.dart';
import '../../widgets/custom_button_large.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController phoneController = TextEditingController();
  final String countryCode = '+91'; // Default to India

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginBloc(),
      child: BlocConsumer<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state is LoginLoadingState) {
            // Show loading indicator
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              },
            );
          } else if (state is LoginSuccessState) {
            // Close loading dialog
            Navigator.pop(context);
            
            // Navigate to OTP page
            Navigator.of(context).pushNamed('/otp', arguments: {
              'phoneNumber': '$countryCode${phoneController.text}',
              'verificationId': state.verificationId,
            });
          } else if (state is LoginErrorState) {
            // Close loading dialog
            Navigator.pop(context);
            
            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 100),

                    Image.asset('assets/logo.png', width: 100),
                    SizedBox(height: 50),
                    Text(
                      'Login to BIRD',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 30),

                    _buildPhoneInput(),
                    SizedBox(height: 32),

                    CustomLargeButton(
                      text: 'Continue',
                      onPressed: () {
                        if (_validateInputs()) {
                          context.read<LoginBloc>().add(
                                SubmitEvent(
                                  phoneNumber: '$countryCode${phoneController.text}',
                                ),
                              );
                        }
                      },
                    ),

                    SizedBox(height: 28),

                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'By continuing, you agree to our',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            'Terms of Service & Privacy Policy',
                            style: TextStyle(
                                color: ColorManager.primary, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Container(
      width: MediaQuery.of(context).size.width - 48.0,
      height: 60.0,
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Text(
              '🇮🇳 +91',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black,
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: phoneController,
              style: TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Enter your phone number',
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
              keyboardType: TextInputType.phone,
            ),
          ),
        ],
      ),
    );
  }

  bool _validateInputs() {
    if (phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter your phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    if (phoneController.text.trim().length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid 10-digit phone number'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }

    return true;
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }
}
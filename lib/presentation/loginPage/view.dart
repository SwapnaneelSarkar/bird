import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:country_code_picker/country_code_picker.dart';
import '../../constants/color/colorConstant.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  String countryCode = '+1';

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginBloc(),
      child: Scaffold(
        backgroundColor: Colors.white, // Set background color to white
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 100),

                // Logo Section
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

                // Name Input
                _buildNameInput(),
                SizedBox(height: 16),

                // Phone Input Section with Country Code Picker inside
                _buildPhoneInput(),
                SizedBox(height: 32),

                // Submit Button
                BlocConsumer<LoginBloc, LoginState>(listener: (context, state) {
                  if (state is LoginSuccessState) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Login Successful!')),
                    );
                    Navigator.of(context).pushNamed('/otp', arguments: {
                      'phoneNumber': '$countryCode${phoneController.text}',
                      'verificationId': state.verificationId, // Add this line
                      'name': nameController.text,
                    });
                  } else if (state is LoginErrorState) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.errorMessage)),
                    );
                  }
                }, builder: (context, state) {
                  if (state is LoginLoadingState) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: ColorManager.primary,
                      ),
                    );
                  }

                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorManager.primary, // Button color
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize:
                          Size(double.infinity, 50), // Stretch button across
                    ),
                    onPressed: () {
                      final name = nameController.text;
                      final phone = phoneController.text;

                      // Validate inputs before submission
                      if (name.isEmpty || phone.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  "Please enter both name and phone number")),
                        );
                        return;
                      }

                      context.read<LoginBloc>().add(SubmitEvent(
                            name: name,
                            phoneNumber: '$countryCode$phone',
                          ));
                    },
                    child: Text('Continue',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  );
                }),

                SizedBox(height: 28),

                // Terms and Privacy
                Column(
                  mainAxisSize: MainAxisSize.min, // Minimize the row width
                  children: [
                    Text(
                      'By continuing, you agree to our',
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    TextButton(
                      onPressed: () {
                        // Handle navigation to terms and privacy
                      },
                      child: Text(
                        'Terms of Service & Privacy Policy',
                        style: TextStyle(
                            color: ColorManager.primary, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 40), // Adjust bottom spacing
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Name Input
  Widget _buildNameInput() {
    return Padding(
      padding: const EdgeInsets.only(
          top: 12.0, // Top padding
          bottom: 12.0 // Bottom padding
          ),
      child: SizedBox(
        width: MediaQuery.of(context).size.width -
            48.0, // Subtract padding from screen width
        height: 60.0, // Set height to match button and phone input height
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: TextField(
            controller: nameController,
            style: TextStyle(fontSize: 12), // Set text size to 12.sp
            decoration: InputDecoration(
              hintText: 'Enter your name',
              border: InputBorder.none, // Remove default border
              contentPadding: EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 14.0), // Padding inside the text field
            ),
          ),
        ),
      ),
    );
  }

  // Phone Input
  Widget _buildPhoneInput() {
    return Container(
      width:
          MediaQuery.of(context).size.width - 48.0, // Same width as name input
      height: 60.0, // Match height with the name input and button
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Country Code Picker
          CountryCodePicker(
            onChanged: (code) {
              setState(() {
                countryCode = code.dialCode!;
              });
            },
            initialSelection: 'US',
            showCountryOnly: false,
            showOnlyCountryWhenClosed: false,
            padding: EdgeInsets.zero,
            favorite: ['+1', '+91'],
            showFlag: true,
            showFlagDialog: true,
            showFlagMain: true,
            showDropDownButton: true,
            textStyle: TextStyle(
              fontSize: 14,
              color: Colors.black,
              fontWeight: FontWeight.normal,
            ),
            flagWidth: 18,
          ),
          // SizedBox(width: 8),

          // Phone Number Input
          Expanded(
            child: TextField(
              controller: phoneController,
              style: TextStyle(fontSize: 12), // Set text size to 12.sp
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
}

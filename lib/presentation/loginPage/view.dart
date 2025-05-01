import 'package:flutter/material.dart';
import 'package:country_code_picker/country_code_picker.dart';
import '../../constants/color/colorConstant.dart';
import '../../widgets/custom_button_large.dart';

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

              _buildNameInput(),
              SizedBox(height: 16),
              _buildPhoneInput(),
              SizedBox(height: 32),

              CustomLargeButton(
  text: 'Continue',
  onPressed: () {
    Navigator.of(context).pushNamed('/otp', arguments: {
      'phoneNumber': '$countryCode${phoneController.text}',
      'name': nameController.text,
      'verificationId': 'static_dummy_id',
    });
  },
),


              SizedBox(height: 28),

              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'By continuing, you agree to our',
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 12),
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
  }

  Widget _buildNameInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Container(
        width: MediaQuery.of(context).size.width - 48.0,
        height: 60.0,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: TextField(
          controller: nameController,
          style: TextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText: 'Enter your name',
            border: InputBorder.none,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          ),
        ),
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
          CountryCodePicker(
            onChanged: (code) {
              setState(() {
                countryCode = code.dialCode!;
              });
            },
            initialSelection: 'US',
            favorite: ['+1', '+91'],
            showDropDownButton: true,
            showFlag: true,
            textStyle: TextStyle(
              fontSize: 14,
              color: Colors.black,
              fontWeight: FontWeight.normal,
            ),
            flagWidth: 18,
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
}

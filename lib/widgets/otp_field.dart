import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/color/colorConstant.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/font/fontManager.dart';

class OtpField extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onChanged;

  const OtpField({
    Key? key,
    required this.controller,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final horizontal = MediaQuery.of(context).size.width * 0.05;
    
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      maxLength: 6,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      style: GoogleFonts.poppins(
        fontSize: FontSize.s18,
        fontWeight: FontWeightManager.medium,
        color: ColorManager.black,
        letterSpacing: 8.0, // Adding letter spacing for OTP-like appearance
      ),
      decoration: InputDecoration(
        hintText: "Enter 6-digit OTP",
        hintStyle: GoogleFonts.poppins(
          fontSize: FontSize.s16,
          fontWeight: FontWeightManager.regular,
          color: Colors.grey,
        ),
        counterText: "",
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: horizontal,
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
      ),
    );
  }
}
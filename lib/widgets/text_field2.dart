// lib/ui_components/universal_widgets/custom_textfield.dart

import 'package:flutter/material.dart';

import '../constants/color/colorConstant.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/font/fontManager.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool isRequired;
  final int? maxLength; // Add maxLength parameter

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.isRequired = false,
    this.maxLength, // Add maxLength to constructor
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final horizontal = MediaQuery.of(context).size.width * 0.05;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLength: maxLength, // Add maxLength to TextFormField
      decoration: InputDecoration(
        hintText: isRequired ? '$hint *' : hint,
        hintStyle: GoogleFonts.poppins(
          fontSize: FontSize.s16,
          fontWeight: FontWeightManager.regular,
          color: Colors.grey,
        ),
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
          borderSide: BorderSide(color: ColorManager.black.withOpacity(0.2)),
        ),
        counterText: '', // Hide the character counter
      ),
      style: GoogleFonts.poppins(
        fontSize: FontSize.s16,
        fontWeight: FontWeightManager.regular,
        color: ColorManager.black,
      ),
    );
  }
}

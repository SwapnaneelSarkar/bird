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

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final horizontal = MediaQuery.of(context).size.width * 0.05;
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
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
      ),
      style: GoogleFonts.poppins(
        fontSize: FontSize.s16,
        fontWeight: FontWeightManager.regular,
        color: ColorManager.black,
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../constants/color/colorConstant.dart';
import '../constants/font/fontManager.dart';


class AppText extends StatelessWidget {
  final String text;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final String? fontFamily;
  final double? height;
  final TextDecoration? decoration;

  const AppText({
    Key? key,
    required this.text,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontFamily,
    this.height,
    this.decoration,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Make text responsive based on screen size
    final screenWidth = MediaQuery.of(context).size.width;
    final responsiveFontSize = fontSize != null 
        ? (fontSize! * screenWidth) / 400 
        : (FontSize.s14 * screenWidth) / 400;
    
    return Text(
      text,
      style: TextStyle(
        fontSize: responsiveFontSize,
        fontWeight: fontWeight ?? FontWeightManager.regular,
        color: color ?? ColorManager.black,
        fontFamily: fontFamily ?? FontFamily.Montserrat,
        height: height,
        decoration: decoration,
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
import 'package:flutter/material.dart';

class ColorManager {
  static  Color primary = HexColor.fromHex('#D2691E');
   static Color textWhite = HexColor.fromHex("#E7E7E7");
  static Color black = HexColor.fromHex('#000000');
  static Color signUpRed = Color.fromARGB(191, 245, 88, 54);
  static Color otpField = HexColor.fromHex('#F3F4F6');
  static Color yellowAcc = HexColor.fromHex('#F5A936');
  static Color cardGrey = HexColor.fromHex('#D9D9D9');
  static Color faqCardGrey = HexColor.fromHex('##272727');
}
extension HexColor on Color {
  static Color fromHex(String hexColorString) {
    hexColorString = hexColorString.replaceAll('#', '');
    if (hexColorString.length == 6) {
      hexColorString =
          "FF$hexColorString"; //Appending characters for opacity of 100% at start of HexCode
    }
    return Color(int.parse(hexColorString, radix: 16));
  }
}

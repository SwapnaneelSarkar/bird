import 'package:flutter/material.dart';

class OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(String) onChanged;

  const OtpBox({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double boxSize = MediaQuery.of(context).size.width * 0.14;

    return Container(
      width: boxSize,
      height: boxSize,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5), // Almost white
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          // Soft light top-left highlight
          BoxShadow(
            color: Colors.white,
            offset: Offset(-2, -2),
            blurRadius: 6,
            spreadRadius: 1,
          ),
          // Soft dark bottom-right shadow
          BoxShadow(
            color: Color(0x33000000), // Slightly darker grey
            offset: Offset(2, 2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          maxLength: 1,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
          decoration: const InputDecoration(
            counterText: "",
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }
}

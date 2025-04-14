import 'package:flutter/material.dart';

class NameInputWidget extends StatelessWidget {
  final TextEditingController controller;

  NameInputWidget({Key? key, required this.controller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: 350.0, // Ensure the width matches the phone number field
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Enter your name',
              border: InputBorder.none, // Remove default border
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            ),
          ),
        ),
      ),
    );
  }
}

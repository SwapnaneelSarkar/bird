 import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../constants/color/colorConstant.dart';
import '../constants/font/fontManager.dart';

Widget _buildSettingsField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    required IconData icon,
    required double responsiveTextScale,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12 * responsiveTextScale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: FontSize.s14 * responsiveTextScale,
              color: Colors.grey,
              fontFamily: FontFamily.Montserrat,
            ),
          ),
          SizedBox(height: 8 * responsiveTextScale),
          Row(
            children: [
              Padding(
                padding: EdgeInsets.only(right: 12 * responsiveTextScale),
                child: Icon(
                  icon,
                  color: Colors.grey[700],
                  size: 20 * responsiveTextScale,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: TextStyle(
                    color: ColorManager.black,
                    fontSize: FontSize.s16 * responsiveTextScale,
                    fontFamily: FontFamily.Montserrat,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: FontSize.s16 * responsiveTextScale,
                      fontFamily: FontFamily.Montserrat,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }
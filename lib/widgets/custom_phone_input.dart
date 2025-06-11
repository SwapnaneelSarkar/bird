// lib/ui_components/custom_phone_input.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/country_model.dart';
import '../constants/color/colorConstant.dart';
import '../constants/font/fontManager.dart';
import 'country_picker.dart';

class CustomPhoneInput extends StatefulWidget {
  final TextEditingController phoneController;
  final Country selectedCountry;
  final Function(Country) onCountryChanged;
  final String? hintText;
  final double? height;
  final bool enabled;
  final Function(String)? onChanged;
  final TextInputType keyboardType;

  const CustomPhoneInput({
    Key? key,
    required this.phoneController,
    required this.selectedCountry,
    required this.onCountryChanged,
    this.hintText,
    this.height,
    this.enabled = true,
    this.onChanged,
    this.keyboardType = TextInputType.phone,
  }) : super(key: key);

  @override
  State<CustomPhoneInput> createState() => _CustomPhoneInputState();
}

class _CustomPhoneInputState extends State<CustomPhoneInput> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      height: widget.height ?? 60.0,
      decoration: BoxDecoration(
        border: Border.all(
          color: _isFocused 
              ? ColorManager.primary 
              : Colors.grey.shade300,
          width: _isFocused ? 2.0 : 1.0,
        ),
        borderRadius: BorderRadius.circular(12.0),
        color: widget.enabled ? Colors.white : Colors.grey.shade100,
      ),
      child: Row(
        children: [
          // Country picker
          CountryPicker(
            selectedCountry: widget.selectedCountry,
            onCountrySelected: widget.onCountryChanged,
            height: widget.height ?? 60.0,
            width: _getCountryPickerWidth(),
          ),
          
          // Divider
          Container(
            height: 30,
            width: 1,
            color: Colors.grey.shade300,
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          
          // Phone number input
          Expanded(
            child: TextField(
              controller: widget.phoneController,
              focusNode: _focusNode,
              enabled: widget.enabled,
              keyboardType: widget.keyboardType,
              onChanged: widget.onChanged,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(_getMaxLength()),
              ],
              style: TextStyle(
                fontSize: FontSize.s16,
                fontFamily: FontFamily.Montserrat,
                fontWeight: FontWeightManager.medium,
                color: widget.enabled ? ColorManager.black : Colors.grey.shade600,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText ?? 'Enter phone number',
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: FontSize.s14,
                  fontFamily: FontFamily.Montserrat,
                  fontWeight: FontWeightManager.regular,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
                counterText: '', // Hide character counter
              ),
            ),
          ),
          
          // Clear button (when focused and has text)
          if (_isFocused && widget.phoneController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () {
                  widget.phoneController.clear();
                  if (widget.onChanged != null) {
                    widget.onChanged!('');
                  }
                },
                child: Icon(
                  Icons.clear,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  double _getCountryPickerWidth() {
    // Adjust width based on dial code length
    final dialCodeLength = widget.selectedCountry.dialCode.length;
    if (dialCodeLength <= 3) return 85.0;
    if (dialCodeLength <= 4) return 95.0;
    return 105.0;
  }

  int _getMaxLength() {
    // Return max phone number length based on country
    switch (widget.selectedCountry.code) {
      case 'IN': return 10; // India
      case 'US':
      case 'CA': return 10; // US, Canada
      case 'GB': return 11; // UK
      case 'AU': return 9; // Australia
      case 'DE': return 12; // Germany
      case 'FR': return 10; // France
      case 'JP': return 11; // Japan
      case 'CN': return 11; // China
      case 'BR': return 11; // Brazil
      case 'RU': return 10; // Russia
      case 'KR': return 11; // South Korea
      case 'IT': return 10; // Italy
      case 'ES': return 9; // Spain
      case 'MX': return 10; // Mexico
      case 'ID': return 12; // Indonesia
      case 'TR': return 10; // Turkey
      case 'SA': return 9; // Saudi Arabia
      case 'ZA': return 9; // South Africa
      case 'NG': return 11; // Nigeria
      case 'TH': return 9; // Thailand
      case 'MY': return 10; // Malaysia
      case 'SG': return 8; // Singapore
      case 'PH': return 10; // Philippines
      case 'VN': return 9; // Vietnam
      case 'BD': return 11; // Bangladesh
      case 'PK': return 10; // Pakistan
      case 'LK': return 9; // Sri Lanka
      case 'NP': return 10; // Nepal
      case 'MM': return 9; // Myanmar
      case 'AE': return 9; // UAE
      case 'EG': return 10; // Egypt
      case 'KE': return 9; // Kenya
      case 'GH': return 9; // Ghana
      case 'ET': return 9; // Ethiopia
      default: return 15; // Default fallback
    }
  }
}
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/country_model.dart';
import '../constants/color/colorConstant.dart';
import '../constants/font/fontManager.dart';

class PhoneNumberField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool isRequired;
  final bool isVerified;
  final VoidCallback onVerify;
  final double responsiveTextScale;
  final int animationDelay;
  final IconData icon;
  final String? fieldName;
  final Function(String)? onCountryChanged;
  final Function(String)? onPhoneChanged;
  final bool hasError;
  final String? errorMessage;

  const PhoneNumberField({
    Key? key,
    required this.controller,
    required this.label,
    this.isRequired = false,
    this.isVerified = false,
    required this.onVerify,
    required this.responsiveTextScale,
    required this.animationDelay,
    required this.icon,
    this.fieldName,
    this.onCountryChanged,
    this.onPhoneChanged,
    this.hasError = false,
    this.errorMessage,
  }) : super(key: key);

  @override
  State<PhoneNumberField> createState() => _PhoneNumberFieldState();
}

class _PhoneNumberFieldState extends State<PhoneNumberField> {
  Country _selectedCountry = CountryData.defaultCountry;

  @override
  void initState() {
    super.initState();
    _initializeCountryCode();
  }

  void _initializeCountryCode() {
    // Try to detect country code from existing phone number
    final phoneText = widget.controller.text;
    if (phoneText.isNotEmpty) {
      // Check if phone number starts with a country code
      for (final country in CountryData.countries) {
        if (phoneText.startsWith(country.dialCode)) {
          setState(() {
            _selectedCountry = country;
          });
          // Update controller text to remove country code
          final phoneWithoutCode = phoneText.substring(country.dialCode.length);
          if (phoneWithoutCode.isNotEmpty) {
            widget.controller.text = phoneWithoutCode;
          }
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen width for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 400;
    
    return Container(
      padding: EdgeInsets.symmetric(vertical: widget.responsiveTextScale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isRequired ? '${widget.label} *' : widget.label,
            style: TextStyle(
              fontSize: (isSmallScreen ? FontSize.s10 : FontSize.s12) * widget.responsiveTextScale,
              color: widget.hasError ? Colors.red : Colors.grey,
              fontFamily: FontFamily.Montserrat,
            ),
          ),
          SizedBox(height: (isSmallScreen ? 6 : 8) * widget.responsiveTextScale),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all((isSmallScreen ? 4 : 6) * widget.responsiveTextScale),
                decoration: BoxDecoration(
                  color: widget.hasError 
                      ? Colors.red.withOpacity(0.1) 
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular((isSmallScreen ? 6 : 8) * widget.responsiveTextScale),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.hasError ? Colors.red : Colors.orange,
                  size: (isSmallScreen ? 16 : 18) * widget.responsiveTextScale,
                ),
              ),
              SizedBox(width: (isSmallScreen ? 6 : 8) * widget.responsiveTextScale),
              // Country Code Picker - Compact version
              Container(
                constraints: BoxConstraints(
                  maxWidth: (isSmallScreen ? 70 : 90) * widget.responsiveTextScale,
                  minWidth: (isSmallScreen ? 60 : 75) * widget.responsiveTextScale,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: widget.hasError ? Colors.red : Colors.grey.withOpacity(0.3),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular((isSmallScreen ? 6 : 8) * widget.responsiveTextScale),
                ),
                child: CountryCodePicker(
                  onChanged: (CountryCode countryCode) {
                    // Convert CountryCode to our Country model
                    final country = CountryData.findByCode(countryCode.code ?? 'IN') ?? CountryData.defaultCountry;
                    setState(() {
                      _selectedCountry = country;
                    });
                    widget.onCountryChanged?.call(countryCode.dialCode ?? '+91');
                  },
                  initialSelection: _selectedCountry.code,
                  favorite: ['+91', '+1', '+44', '+61'],
                  showCountryOnly: false,
                  showOnlyCountryWhenClosed: false, // Show flag and dial code when closed
                  alignLeft: false,
                  flagWidth: (isSmallScreen ? 16 : 20) * widget.responsiveTextScale, // Responsive flag size
                  textStyle: TextStyle(
                    fontSize: (isSmallScreen ? FontSize.s10 : FontSize.s12) * widget.responsiveTextScale, // Responsive text
                    fontFamily: FontFamily.Montserrat,
                    color: widget.isVerified ? ColorManager.black : Colors.grey[600],
                  ),
                  searchDecoration: InputDecoration(
                    hintText: 'Search',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      fontSize: FontSize.s12 * widget.responsiveTextScale,
                      fontFamily: FontFamily.Montserrat,
                    ),
                  ),
                  dialogTextStyle: TextStyle(
                    fontSize: FontSize.s14 * widget.responsiveTextScale,
                    fontFamily: FontFamily.Montserrat,
                  ),
                  dialogBackgroundColor: Colors.white,
                  searchStyle: TextStyle(
                    fontSize: FontSize.s14 * widget.responsiveTextScale,
                    fontFamily: FontFamily.Montserrat,
                  ),
                ),
              ),
              SizedBox(width: (isSmallScreen ? 4 : 6) * widget.responsiveTextScale), // Responsive spacing
              // Phone Number Input
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  keyboardType: TextInputType.phone,
                  enabled: widget.isVerified,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: TextStyle(
                    color: widget.isVerified ? ColorManager.black : Colors.grey[600],
                    fontSize: (isSmallScreen ? FontSize.s12 : FontSize.s14) * widget.responsiveTextScale,
                    fontFamily: FontFamily.Montserrat,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: isSmallScreen ? 'Phone' : 'Phone number',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: (isSmallScreen ? FontSize.s10 : FontSize.s12) * widget.responsiveTextScale,
                      fontFamily: FontFamily.Montserrat,
                    ),
                    disabledBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: widget.isVerified 
                        ? (widget.hasError 
                            ? UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.red, width: 1),
                              )
                            : UnderlineInputBorder(
                                borderSide: BorderSide(color: ColorManager.primary, width: 1),
                              ))
                        : InputBorder.none,
                  ),
                  onTap: () {
                    if (!widget.isVerified) {
                      HapticFeedback.selectionClick();
                      _showSnackBar(
                        message: 'Please verify this field first before editing',
                        isError: true,
                      );
                    } else {
                      widget.onPhoneChanged?.call(widget.controller.text);
                    }
                  },
                  onChanged: (value) {
                    widget.onPhoneChanged?.call(value);
                  },
                ),
              ),
            ],
          ),
          // Verification button below the input field
          SizedBox(height: (isSmallScreen ? 8 : 10) * widget.responsiveTextScale),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: widget.isVerified ? Colors.green : ColorManager.primary,
                  borderRadius: BorderRadius.circular(8 * widget.responsiveTextScale),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8 * widget.responsiveTextScale),
                    onTap: widget.isVerified ? null : () {
                      widget.onVerify();
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16 * widget.responsiveTextScale,
                        vertical: 8 * widget.responsiveTextScale,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.isVerified ? Icons.verified : Icons.verified_user,
                            color: Colors.white,
                            size: 16 * widget.responsiveTextScale,
                          ),
                          SizedBox(width: 6 * widget.responsiveTextScale),
                          Text(
                            widget.isVerified ? 'Verified' : 'Verify',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: FontSize.s12 * widget.responsiveTextScale,
                              fontWeight: FontWeightManager.medium,
                              fontFamily: FontFamily.Montserrat,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (widget.hasError && widget.errorMessage != null) ...[
            SizedBox(height: (isSmallScreen ? 3 : 4) * widget.responsiveTextScale),
            Text(
              widget.errorMessage!,
              style: TextStyle(
                color: Colors.red,
                fontSize: FontSize.s10 * widget.responsiveTextScale,
                fontFamily: FontFamily.Montserrat,
              ),
            ),
          ],
          const Divider(thickness: 0.8),
        ],
      ),
    ).animate().fadeIn(delay: widget.animationDelay.ms, duration: 500.ms).slideX(begin: 0.02, end: 0);
  }

  void _showSnackBar({required String message, required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: Colors.white,
            fontFamily: FontFamily.Montserrat,
          ),
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // Get the full phone number with country code
  String getFullPhoneNumber() {
    return '${_selectedCountry.dialCode}${widget.controller.text}';
  }

  // Get the selected country code
  String getSelectedCountryCode() {
    return _selectedCountry.dialCode;
  }
}

// lib/presentation/screens/loginPage/view.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../constants/color/colorConstant.dart';
import '../../../constants/font/fontManager.dart';
import '../../../models/country_model.dart';
import '../../widgets/custom_button_large.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController phoneController = TextEditingController();
  Country selectedCountry = CountryData.defaultCountry;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCountry();
  }

  Future<void> _loadSavedCountry() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCountryCode = prefs.getString('selected_country_code');
      
      if (savedCountryCode != null) {
        final country = CountryData.findByCode(savedCountryCode);
        if (country != null) {
          setState(() {
            selectedCountry = country;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading saved country: $e');
    }
  }

  Future<void> _saveSelectedCountry(Country country) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_country_code', country.code);
    } catch (e) {
      debugPrint('Error saving selected country: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return BlocProvider(
      create: (context) => LoginBloc(),
      child: BlocConsumer<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state is LoginLoadingState) {
            setState(() => isLoading = true);
            _showLoadingDialog();
          } else {
            setState(() => isLoading = false);
            _hideLoadingDialog();
            
            if (state is LoginSuccessState) {
              _navigateToOTP(state.verificationId);
            } else if (state is LoginErrorState) {
              _showErrorSnackBar(state.errorMessage);
            }
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: screenHeight * 0.08),
                      _buildLogo(),
                      SizedBox(height: screenHeight * 0.03),
                      _buildTitle(),
                      SizedBox(height: screenHeight * 0.04),
                      _buildPhoneInput(),
                      SizedBox(height: screenHeight * 0.04),
                      _buildContinueButton(context),
                      SizedBox(height: screenHeight * 0.035),
                      _buildTermsAndPrivacy(),
                      SizedBox(height: screenHeight * 0.05),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/logo.png',
      width: 120,
      height: 120,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.flutter_dash,
          size: 60,
          color: ColorManager.primary,
        );
      },
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'Login to BIRD',
          style: TextStyle(
            fontSize: FontSize.s27,
            fontFamily: FontFamily.Montserrat,
            fontWeight: FontWeightManager.bold,
            color: ColorManager.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your phone number to continue',
          style: TextStyle(
            fontSize: FontSize.s16,
            fontFamily: FontFamily.Montserrat,
            fontWeight: FontWeightManager.regular,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPhoneInput() {
    return Container(
      height: 60.0,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12.0),
        color: Colors.white,
      ),
      child: Row(
        children: [
          // Country picker
          GestureDetector(
            onTap: isLoading ? null : _showCountryPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    selectedCountry.flag,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    selectedCountry.dialCode,
                    style: TextStyle(
                      fontSize: FontSize.s14,
                      fontFamily: FontFamily.Montserrat,
                      fontWeight: FontWeightManager.medium,
                      color: ColorManager.black,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                    color: isLoading ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),
          
          // Divider
          Container(
            height: 30,
            width: 1,
            color: Colors.grey.shade300,
            margin: const EdgeInsets.symmetric(horizontal: 8),
          ),
          
          // Phone input
          Expanded(
            child: TextField(
              controller: phoneController,
              enabled: !isLoading,
              keyboardType: TextInputType.phone,
              maxLength: _getMaxLength(),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              style: TextStyle(
                fontSize: FontSize.s16,
                fontFamily: FontFamily.Montserrat,
                fontWeight: FontWeightManager.medium,
                color: isLoading ? Colors.grey.shade600 : ColorManager.black,
              ),
              decoration: InputDecoration(
                hintText: 'Enter your phone number',
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: FontSize.s14,
                  fontFamily: FontFamily.Montserrat,
                  fontWeight: FontWeightManager.regular,
                ),
                border: InputBorder.none,
                counterText: '',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
              onChanged: (value) {
                debugPrint('Phone number changed: $value');
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildCountryBottomSheet(),
    );
  }

  Widget _buildCountryBottomSheet() {
    final screenHeight = MediaQuery.of(context).size.height;
    final TextEditingController searchController = TextEditingController();
    List<Country> filteredCountries = CountryData.countries;

    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          height: screenHeight * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      'Select Country',
                      style: TextStyle(
                        fontSize: FontSize.s18,
                        fontFamily: FontFamily.Montserrat,
                        fontWeight: FontWeightManager.semiBold,
                        color: ColorManager.black,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              
              // Search
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: TextField(
                  controller: searchController,
                  onChanged: (query) {
                    setModalState(() {
                      filteredCountries = CountryData.searchCountries(query);
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search country',
                    prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              
              // Countries list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredCountries.length,
                  itemBuilder: (context, index) {
                    final country = filteredCountries[index];
                    final isSelected = country == selectedCountry;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isSelected ? ColorManager.primary.withOpacity(0.1) : Colors.transparent,
                        border: Border.all(
                          color: isSelected ? ColorManager.primary : Colors.transparent,
                        ),
                      ),
                      child: ListTile(
                        onTap: () {
                          _selectCountry(country);
                          Navigator.pop(context);
                        },
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(country.flag, style: const TextStyle(fontSize: 20)),
                          ),
                        ),
                        title: Text(
                          country.name,
                          style: TextStyle(
                            fontSize: FontSize.s16,
                            fontFamily: FontFamily.Montserrat,
                            fontWeight: isSelected ? FontWeightManager.semiBold : FontWeightManager.medium,
                            color: isSelected ? ColorManager.primary : ColorManager.black,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              country.dialCode,
                              style: TextStyle(
                                fontSize: FontSize.s14,
                                fontFamily: FontFamily.Montserrat,
                                fontWeight: FontWeightManager.medium,
                                color: isSelected ? ColorManager.primary : Colors.grey.shade600,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.check_circle, color: ColorManager.primary, size: 20),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _selectCountry(Country country) {
    setState(() {
      selectedCountry = country;
      phoneController.clear(); // Clear input when country changes
    });
    _saveSelectedCountry(country);
    debugPrint('Country changed to: ${country.name} (${country.dialCode})');
  }

  Widget _buildContinueButton(BuildContext context) {
    return CustomLargeButton(
      text: 'Continue',
      isLoading: isLoading,
      onPressed: isLoading ? null : () => _handleContinue(context),
    );
  }

  void _handleContinue(BuildContext context) {
    if (_validateInputs()) {
      final fullPhoneNumber = '${selectedCountry.dialCode}${phoneController.text}';
      debugPrint('Submitting phone number: $fullPhoneNumber');
      debugPrint('Country: ${selectedCountry.name} (${selectedCountry.code})');
      
      context.read<LoginBloc>().add(
        SubmitEvent(phoneNumber: fullPhoneNumber),
      );
    }
  }

  Widget _buildTermsAndPrivacy() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'By continuing, you agree to our',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: FontSize.s12,
            fontFamily: FontFamily.Montserrat,
            fontWeight: FontWeightManager.regular,
          ),
        ),
        TextButton(
          onPressed: () => debugPrint('Terms and Privacy tapped'),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            'Terms of Service & Privacy Policy',
            style: TextStyle(
              color: ColorManager.primary,
              fontSize: FontSize.s12,
              fontFamily: FontFamily.Montserrat,
              fontWeight: FontWeightManager.medium,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  bool _validateInputs() {
    final phoneNumber = phoneController.text.trim();
    
    if (phoneNumber.isEmpty) {
      _showErrorSnackBar('Please enter your phone number');
      return false;
    }

    // Add minimum length check
    if (phoneNumber.length < 5) {
      _showErrorSnackBar('Phone number must be at least 5 digits long');
      return false;
    }

    final expectedLength = _getExpectedLength();
    final strictCountries = ['AE', 'SG', 'SA', 'MY', 'TH', 'KE', 'GH', 'ET', 'LK', 'VN', 'MM'];
    
    if (strictCountries.contains(selectedCountry.code)) {
      if (phoneNumber.length != expectedLength) {
        _showErrorSnackBar(
          'Phone number for ${selectedCountry.name} must be exactly $expectedLength digits.'
        );
        return false;
      }
    } else {
      if (phoneNumber.length < expectedLength - 1 || phoneNumber.length > expectedLength + 1) {
        _showErrorSnackBar(
          'Phone number for ${selectedCountry.name} should be around $expectedLength digits.'
        );
        return false;
      }
    }

    // Check total E.164 length
    final totalLength = selectedCountry.dialCode.length + phoneNumber.length;
    if (totalLength > 16) { // +1234567890123456 (16 chars max for E.164)
      _showErrorSnackBar('Phone number is too long. Please check and try again.');
      return false;
    }

    debugPrint('Validation passed: $phoneNumber (${phoneNumber.length} digits)');
    return true;
  }

  int _getExpectedLength() {
    switch (selectedCountry.code) {
      case 'IN': return 10;
      case 'US':
      case 'CA': return 10;
      case 'GB': return 11;
      case 'AU': return 9;
      case 'DE': return 11;
      case 'FR': return 10;
      case 'JP': return 11;
      case 'CN': return 11;
      case 'BR': return 11;
      case 'RU': return 10;
      case 'KR': return 11;
      case 'IT': return 10;
      case 'ES': return 9;
      case 'MX': return 10;
      case 'ID': return 10;
      case 'TR': return 10;
      case 'SA': return 9;
      case 'ZA': return 9;
      case 'NG': return 10;
      case 'TH': return 9;
      case 'MY': return 9;
      case 'SG': return 8;
      case 'PH': return 10;
      case 'VN': return 9;
      case 'BD': return 10;
      case 'PK': return 10;
      case 'LK': return 9;
      case 'NP': return 10;
      case 'MM': return 9;
      case 'AE': return 9; // UAE exactly 9 digits
      case 'EG': return 10;
      case 'KE': return 9;
      case 'GH': return 9;
      case 'ET': return 9;
      default: return 10;
    }
  }

  int _getMaxLength() {
    final expected = _getExpectedLength();
    final strictCountries = ['AE', 'SG', 'SA', 'MY', 'TH', 'KE', 'GH', 'ET', 'LK', 'VN', 'MM'];
    
    return strictCountries.contains(selectedCountry.code) ? expected : expected + 2;
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(ColorManager.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  'Sending OTP...',
                  style: TextStyle(
                    fontSize: FontSize.s16,
                    fontFamily: FontFamily.Montserrat,
                    fontWeight: FontWeightManager.medium,
                    color: ColorManager.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _hideLoadingDialog() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _navigateToOTP(String verificationId) {
    Navigator.of(context).pushNamed('/otp', arguments: {
      'phoneNumber': '${selectedCountry.dialCode}${phoneController.text}',
      'verificationId': verificationId,
      'countryCode': selectedCountry.dialCode,
      'phoneNumberOnly': phoneController.text,
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: FontSize.s14,
                  fontFamily: FontFamily.Montserrat,
                  fontWeight: FontWeightManager.medium,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }
}
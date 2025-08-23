import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/api_constant.dart';
import '../../constants/color/colorConstant.dart';
import '../../constants/font/fontManager.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';

import '../../widgets/shimmer_helper.dart';
import '../address bottomSheet/view.dart';
import '../../service/address_service.dart';
import '../../service/app_startup_service.dart';
import '../../widgets/verification_dialog.dart';
import '../../widgets/account_deletion_verification_dialog.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  late SettingsBloc _settingsBloc;
  File? _profileImage;
  bool _isSaving = false;
  
  // Location coordinates
  double? _latitude;
  double? _longitude;
  
  // Animation controller
  late AnimationController _animationController;
  
  // --- ADDED: Saved addresses for address picker ---
  List<Map<String, dynamic>> _savedAddresses = [];
  // --- END ADDED ---
  
  // --- ADDED: Verification status tracking ---
  bool _isEmailVerified = false;
  bool _isPhoneVerified = false;
  String _originalEmail = '';
  String _originalPhone = '';
  // --- END ADDED ---
  
  // --- ADDED: Location settings tracking ---
  bool _isAutoLocationEnabled = true;
  bool _isUpdatingLocation = false;
  // --- END ADDED ---
  
  // --- ADDED: Field error tracking ---
  Map<String, String> _fieldErrors = {};
  // --- END ADDED ---
  
  @override
  void initState() {
    super.initState();
    _settingsBloc = SettingsBloc();
    _settingsBloc.add(LoadUserSettings());
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _animationController.dispose();
    _settingsBloc.close();
    super.dispose();
  }
  
  // --- MODIFIED: Now async and fetches saved addresses ---
  Future<void> _loadUserDataToControllers(Map<String, dynamic> userData) async {
    _nameController.text = userData['username'] ?? '';
    _emailController.text = userData['email'] ?? '';
    _phoneController.text = userData['mobile'] ?? '';
    _addressController.text = userData['address'] ?? '';
    
    // Validate fields after loading data
    _validateFieldsAfterLoad();
    
    // Store original values for verification comparison
    _originalEmail = userData['email'] ?? '';
    _originalPhone = userData['mobile'] ?? '';
    
    // Store coordinates
    _latitude = userData['latitude'] != null ? double.tryParse(userData['latitude'].toString()) : null;
    _longitude = userData['longitude'] != null ? double.tryParse(userData['longitude'].toString()) : null;

    // Clear any existing field errors when loading data
    setState(() {
      _fieldErrors.clear();
    });

    // --- ADDED: Fetch saved addresses for address picker ---
    try {
      final result = await AddressService.getAllAddresses();
      if (result['success'] == true && result['data'] != null) {
        setState(() {
          _savedAddresses = List<Map<String, dynamic>>.from(result['data']);
        });
      }
    } catch (e) {
      debugPrint('SettingsView: Failed to load saved addresses: $e');
    }
    // --- END ADDED ---
    
    // --- ADDED: Load location settings ---
    _loadLocationSettings();
    // --- END ADDED ---
  }
  
  // --- ADDED: Load location settings ---
  Future<void> _loadLocationSettings() async {
    try {
      final isEnabled = await AppStartupService.isAutoLocationEnabled();
      setState(() {
        _isAutoLocationEnabled = isEnabled;
      });
    } catch (e) {
      debugPrint('SettingsView: Error loading location settings: $e');
    }
  }
  // --- END ADDED ---
  
  Future<void> _pickImage() async {
    HapticFeedback.mediumImpact(); // Add haptic feedback
    
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
        
        // We'll only store the file locally and only update on save
        // This prevents the issue with fields disappearing
        debugPrint('Image selected: ${pickedFile.path}');
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      String errorMessage = 'Failed to pick image';
      
      // Provide more specific error messages
      if (e.toString().contains('permission')) {
        errorMessage = 'Please allow photo access in settings';
      } else if (e.toString().contains('file')) {
        errorMessage = 'Could not access the selected image';
      }
      
      _showSnackBar(
        message: errorMessage,
        isError: true,
      );
    }
  }
  
  // --- MODIFIED: Pass saved addresses to address picker ---
  Future<void> _showAddressPicker() async {
    HapticFeedback.selectionClick(); // Add haptic feedback
    
    final result = await AddressPickerBottomSheet.show(
      context,
      savedAddresses: _savedAddresses,
    );
    
    if (result != null) {
      setState(() {
        _addressController.text = result['address'];
        if (result['subAddress'].toString().isNotEmpty) {
          _addressController.text += ', ${result['subAddress']}';
        }
        _latitude = result['latitude'];
        _longitude = result['longitude'];
        
        // Validate address after setting it
        if (_addressController.text.trim().isEmpty) {
          _showFieldError('address', 'Address is required');
        } else {
          _clearFieldError('address');
        }
      });
      
      // Show a success toast
      _showSnackBar(
        message: 'Address updated successfully',
        isError: false,
      );
    }
  }
  
  void _saveSettings() {
    HapticFeedback.mediumImpact(); // Add haptic feedback
    
    // Validate required fields before saving
    if (!_validateRequiredFields()) {
      return;
    }
    
    // Check if verified fields have been modified and reset verification status
    _checkAndResetVerificationStatus();
    
    setState(() {
      _isSaving = true;
    });
    
    // Now we'll update all the user settings including the profile image
    _settingsBloc.add(UpdateUserSettings(
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      address: _addressController.text,
      latitude: _latitude,
      longitude: _longitude,
      imageFile: _profileImage, // Pass the image file here for saving
    ));
  }

  // Validate required fields and show errors if any are empty
  bool _validateRequiredFields() {
    bool isValid = true;
    
    // Validate name field
    if (_nameController.text.trim().isEmpty) {
      _showFieldError('name', 'Name is required');
      isValid = false;
    } else if (!_isValidName(_nameController.text.trim())) {
      _showFieldError('name', 'Name can only contain alphabets and spaces');
      isValid = false;
    }
    
    // Validate email field
    if (_emailController.text.trim().isEmpty) {
      _showFieldError('email', 'Email is required');
      isValid = false;
    } else if (!_isValidEmail(_emailController.text.trim())) {
      _showFieldError('email', 'Please enter a valid email address');
      isValid = false;
    }
    
    // Validate phone field
    if (_phoneController.text.trim().isEmpty) {
      _showFieldError('phone', 'Phone number is required');
      isValid = false;
    }
    
    // Validate address field
    if (_addressController.text.trim().isEmpty) {
      _showFieldError('address', 'Address is required');
      isValid = false;
    }
    
    if (!isValid) {
      _showSnackBar(
        message: 'Please fill in all required fields correctly',
        isError: true,
      );
    }
    
    return isValid;
  }

  // Show error for specific field
  void _showFieldError(String fieldName, String errorMessage) {
    setState(() {
      // Set error state for the specific field
      _fieldErrors[fieldName] = errorMessage;
    });
  }

  // Clear error for specific field
  void _clearFieldError(String fieldName) {
    setState(() {
      _fieldErrors.remove(fieldName);
    });
  }

  // Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Validate name format - only alphabets allowed
  bool _isValidName(String name) {
    final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
    return nameRegex.hasMatch(name.trim());
  }

  // Validate fields after loading data
  void _validateFieldsAfterLoad() {
    // Validate name field
    if (_nameController.text.trim().isEmpty) {
      _showFieldError('name', 'Name is required');
    } else if (!_isValidName(_nameController.text.trim())) {
      _showFieldError('name', 'Name can only contain alphabets and spaces');
    }
    
    // Validate email field
    if (_emailController.text.trim().isEmpty) {
      _showFieldError('email', 'Email is required');
    } else if (!_isValidEmail(_emailController.text.trim())) {
      _showFieldError('email', 'Please enter a valid email address');
    }
    
    // Validate phone field
    if (_phoneController.text.trim().isEmpty) {
      _showFieldError('phone', 'Phone number is required');
    }
    
    // Validate address field
    if (_addressController.text.trim().isEmpty) {
      _showFieldError('address', 'Address is required');
    }
  }

  // Method to check if verified fields have been modified and reset verification status
  void _checkAndResetVerificationStatus() {
    // Check if email was modified and reset verification if changed
    if (_isEmailVerified && _emailController.text != _originalEmail) {
      setState(() {
        _isEmailVerified = false;
      });
      _showSnackBar(
        message: 'Email verification reset because email was modified. Please verify again.',
        isError: true,
      );
    }
    
    // Check if phone was modified and reset verification if changed
    if (_isPhoneVerified && _phoneController.text != _originalPhone) {
      setState(() {
        _isPhoneVerified = false;
      });
      _showSnackBar(
        message: 'Phone verification reset because phone was modified. Please verify again.',
        isError: true,
      );
    }
  }
  
  // --- ADDED: Location update methods ---
  Future<void> _updateLocationNow() async {
    setState(() {
      _isUpdatingLocation = true;
    });
    
    try {
      final result = await AppStartupService.manualLocationUpdate();
      
      if (result['success'] == true) {
        if (result['locationUpdated'] == true) {
          _showSnackBar(
            message: 'Location updated successfully!',
            isError: false,
          );
          
          // Update the address controller with new location
          if (result['address'] != null) {
            setState(() {
              _addressController.text = result['address'];
              
              // Validate address after setting it
              if (_addressController.text.trim().isEmpty) {
                _showFieldError('address', 'Address is required');
              } else {
                _clearFieldError('address');
              }
            });
          }
        } else {
          _showSnackBar(
            message: result['message'] ?? 'Location is up to date',
            isError: false,
          );
        }
      } else {
        _showSnackBar(
          message: result['message'] ?? 'Failed to update location',
          isError: true,
        );
      }
    } catch (e) {
      _showSnackBar(
        message: 'Error updating location. Please try again.',
        isError: true,
      );
    } finally {
      setState(() {
        _isUpdatingLocation = false;
      });
    }
  }
  
  Future<void> _toggleAutoLocation(bool value) async {
    try {
      await AppStartupService.setAutoLocationEnabled(value);
      setState(() {
        _isAutoLocationEnabled = value;
      });
      
      _showSnackBar(
        message: 'Auto location updates ${value ? 'enabled' : 'disabled'}',
        isError: false,
      );
    } catch (e) {
      _showSnackBar(
        message: 'Failed to update location settings',
        isError: true,
      );
    }
  }
  // --- END ADDED ---

  // Helper method to show snackbar
  void _showSnackBar({required String message, required bool isError}) {
    // Clear any existing snackbars
    ScaffoldMessenger.of(context).clearSnackBars();
    
    // Create the snackbar with custom animation
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.error : Icons.check_circle,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: isError ? Colors.red.shade700 : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.all(16),
      duration: Duration(seconds: isError ? 4 : 2),
      // No custom animation specified here - using Flutter's default
    );
    
    // Show the snackbar
    ScaffoldMessenger.of(context)
      .showSnackBar(snackBar)
      // Apply animate extension to the snackbar controller
      .closed
      .then((_) {
        // Optional: handle when snackbar is closed
      });
  }

  // Show OTP verification dialog for account deletion
  Future<void> _showDeleteConfirmation(double responsiveTextScale) async {
    HapticFeedback.heavyImpact(); // Strong haptic feedback for destructive action
    
    // Get the current phone number from the state
    String phoneNumber = '';
    if (_settingsBloc.state is SettingsLoaded) {
      final state = _settingsBloc.state as SettingsLoaded;
      phoneNumber = state.userData['mobile']?.toString() ?? '';
    }
    
    if (phoneNumber.isEmpty) {
      _showSnackBar(message: 'Unable to get phone number. Please try again.', isError: true);
      return;
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AccountDeletionVerificationDialog(
        phoneNumber: phoneNumber,
        onVerificationSuccess: (otp, verificationId) {
          // Proceed with account deletion after OTP verification
          _settingsBloc.add(DeleteAccountWithOtp(otp: otp, verificationId: verificationId));
        },
        onCancel: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double responsiveTextScale = screenSize.width / 375; // Base scale factor
    
    return BlocProvider.value(
      value: _settingsBloc,
      child: BlocListener<SettingsBloc, SettingsState>(
        listener: (context, state) {
          if (state is SettingsUpdateSuccess) {
            // Clear field errors on successful update
            setState(() {
              _fieldErrors.clear();
              _isSaving = false;
            });
          } else if (state is SettingsError) {
            // Clear saving state on error
            setState(() {
              _isSaving = false;
            });
          }
        },
        child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark, // Better status bar contrast
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: ColorManager.black, size: 22 * responsiveTextScale),
            onPressed: () {
              HapticFeedback.selectionClick(); // Haptic feedback
              Navigator.of(context).pop();
            },
            // Add animation to back button
          ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.1, end: 0),
          title: Text(
            'Settings',
            style: TextStyle(
              color: ColorManager.black,
              fontSize: FontSize.s18 * responsiveTextScale,
              fontWeight: FontWeightManager.semiBold,
              letterSpacing: 0.2,
              fontFamily: FontFamily.Montserrat,
            ),
          ).animate().fadeIn(duration: 400.ms),
          actions: [
            BlocBuilder<SettingsBloc, SettingsState>(
              builder: (context, state) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: TextButton(
                    onPressed: state is SettingsLoaded && !_isSaving 
                        ? _saveSettings 
                        : null,
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12 * responsiveTextScale),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 16 * responsiveTextScale,
                        vertical: 8 * responsiveTextScale,
                      ),
                    ),
                    child: _isSaving 
                      ? SizedBox(
                          width: 20 * responsiveTextScale,
                          height: 20 * responsiveTextScale,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                          ),
                        ).animate().fadeIn(duration: 200.ms)
                      : Text(
                        'Save',
                        style: TextStyle(
                          color: state is SettingsLoaded && !_isSaving 
                              ? ColorManager.primary 
                              : Colors.grey,
                          fontSize: FontSize.s16 * responsiveTextScale,
                          fontWeight: FontWeightManager.semiBold,
                          fontFamily: FontFamily.Montserrat,
                        ),
                      ),
                  ),
                ).animate().fadeIn(duration: 500.ms).slideX(begin: 0.1, end: 0);
              },
            ),
          ],
        ),
        body: BlocConsumer<SettingsBloc, SettingsState>(
          listener: (context, state) {
            if (state is SettingsUpdateSuccess) {
              setState(() {
                _isSaving = false;
              });
              _showSnackBar(
                message: state.message,
                isError: false,
              );
            }
            
            if (state is SettingsError) {
              setState(() {
                _isSaving = false;
              });
              _showSnackBar(
                message: state.message,
                isError: true,
              );
            }
            
            // Redirect to login page when account is deleted
            if (state is SettingsAccountDeleted) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            }
            
            if (state is SettingsLoaded) {
              _loadUserDataToControllers(state.userData);
            }
          },
          builder: (context, state) {
            if (state is SettingsLoading || state is SettingsInitial) {
              // Show shimmer loading effect
              return _buildShimmerView(responsiveTextScale);
            }
            
            if (state is SettingsLoaded) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(), // Add bounce effect for scrolling
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Photo Section
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 28 * responsiveTextScale),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 6,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: 12 * responsiveTextScale),
                          Text(
                            'Profile',
                            style: TextStyle(
                              fontSize: FontSize.s12 * responsiveTextScale,
                              color: Colors.grey,
                              letterSpacing: 0.2,
                              fontFamily: FontFamily.Montserrat,
                            ),
                          ),
                        ],
                      ),
                    ).animate().slideY(begin: 0.05, end: 0, duration: 600.ms, curve: Curves.easeOutQuint),
                    
                    SizedBox(height: 20 * responsiveTextScale),
                    
                    // Settings Form Fields with staggered animation
                    Container(
                      margin: EdgeInsets.symmetric(horizontal: 18 * responsiveTextScale),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12 * responsiveTextScale),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 18 * responsiveTextScale, 
                          vertical: 2 * responsiveTextScale
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name Field
                            _buildSettingsField(
                              label: 'Name',
                              controller: _nameController,
                              icon: Icons.person_outline,
                              responsiveTextScale: responsiveTextScale,
                              animationDelay: 100,
                              isRequired: true,
                              fieldName: 'name',
                            ),
                            
                            // Email Field with Verification
                            _buildVerifiableField(
                              label: 'Email',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              icon: Icons.email_outlined,
                              responsiveTextScale: responsiveTextScale,
                              animationDelay: 200,
                              isRequired: true,
                              isVerified: _isEmailVerified,
                              onVerify: () => _showEmailVerificationDialog(),
                              fieldType: 'email',
                              fieldName: 'email',
                            ),
                            
                            // Phone Number Field with Verification
                            _buildVerifiableField(
                              label: 'Phone Number',
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              icon: Icons.phone_outlined,
                              responsiveTextScale: responsiveTextScale,
                              animationDelay: 300,
                              isRequired: true,
                              isVerified: _isPhoneVerified,
                              onVerify: () => _showPhoneVerificationDialog(),
                              fieldType: 'phone',
                              fieldName: 'phone',
                            ),
                            
                            // Address Field with location picker
                            _buildAddressField(responsiveTextScale, 400),
                            
                            // Location Settings Section
                            _buildLocationSettingsSection(responsiveTextScale, 450),
                          ],
                        ),
                      ),
                    ).animate().slideY(begin: 0.1, end: 0, duration: 800.ms, curve: Curves.easeOutQuint)
                     .fadeIn(duration: 800.ms),
                    
                    // SizedBox(height: 20 * responsiveTextScale),
                    
                    // Delete Account Button with animation
                    _buildDeleteAccountButton(responsiveTextScale)
                      .animate()
                      .slideY(begin: 0.1, end: 0, duration: 1000.ms, curve: Curves.easeOutQuint)
                      .fadeIn(duration: 1000.ms),
                    
                    SizedBox(height: 30 * responsiveTextScale),
                  ],
                ),
              );
            }

            if (state is SettingsError) {
              // Show a user-friendly error view with retry
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(state.message, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        context.read<SettingsBloc>().add(LoadUserSettings());
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (state is SettingsUpdateSuccess) {
              // Optionally, show a success message
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
                    const SizedBox(height: 16),
                    Text(state.message, style: const TextStyle(color: Colors.green)),
                  ],
                ),
              );
            }

            if (state is SettingsUpdating) {
              // Show a loading indicator while updating
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text('Updating profile...'),
                  ],
                ),
              );
            }

            // Fallback - should not happen
            return const Center(child: Text('Something went wrong!'));
          },
        ),
        ),
      ),
    );
  }

  // Helper method to build address field
  Widget _buildAddressField(double responsiveTextScale, int animationDelay) {
    final hasError = _fieldErrors.containsKey('address');
    final errorMessage = hasError ? _fieldErrors['address'] : null;
    
    return Container(
      padding: EdgeInsets.symmetric(vertical: responsiveTextScale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Address *',
            style: TextStyle(
              fontSize: FontSize.s12 * responsiveTextScale,
              color: hasError ? Colors.red : Colors.grey,
              fontFamily: FontFamily.Montserrat,
            ),
          ),
          SizedBox(height: 8 * responsiveTextScale),
          InkWell(
            onTap: () {
              _showAddressPicker();
              // Clear error when user selects address
              _clearFieldError('address');
            },
            borderRadius: BorderRadius.circular(8 * responsiveTextScale),
            splashColor: Colors.orange.withOpacity(0.1),
            highlightColor: Colors.orange.withOpacity(0.05),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 4 * responsiveTextScale),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6 * responsiveTextScale),
                    decoration: BoxDecoration(
                      color: hasError ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8 * responsiveTextScale),
                    ),
                    child: Icon(
                      Icons.location_on_outlined,
                      color: hasError ? Colors.red : Colors.orange,
                      size: 18 * responsiveTextScale,
                    ),
                  ),
                  SizedBox(width: 8 * responsiveTextScale),
                  Expanded(
                    child: IgnorePointer(
                      child: TextField(
                        controller: _addressController,
                        style: TextStyle(
                          color: ColorManager.black,
                          fontSize: FontSize.s14 * responsiveTextScale,
                          fontFamily: FontFamily.Montserrat,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Select your address',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: FontSize.s16 * responsiveTextScale,
                            fontFamily: FontFamily.Montserrat,
                          ),
                          border: InputBorder.none,
                          suffixIcon: Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey[500],
                            size: 24 * responsiveTextScale,
                          ),
                        ),
                        onChanged: (value) {
                          // Show or clear error in real-time for address
                          if (value.trim().isEmpty) {
                            _showFieldError('address', 'Address is required');
                          } else {
                            _clearFieldError('address');
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_latitude != null && _longitude != null)
            Padding(
              padding: EdgeInsets.only(
                top: 4 * responsiveTextScale, 
                left: 42 * responsiveTextScale
              ),
              
            ),
          if (hasError && errorMessage != null) ...[
            SizedBox(height: 4 * responsiveTextScale),
            Text(
              errorMessage,
              style: TextStyle(
                color: Colors.red,
                fontSize: FontSize.s10 * responsiveTextScale,
                fontFamily: FontFamily.Montserrat,
              ),
            ),
          ],
          // const Divider(thickness: 0.8),
        ],
      ),
    ).animate().fadeIn(delay: animationDelay.ms, duration: 500.ms).slideX(begin: 0.02, end: 0);
  }

  // --- ADDED: Location settings section ---
  Widget _buildLocationSettingsSection(double responsiveTextScale, int animationDelay) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: responsiveTextScale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location Settings',
            style: TextStyle(
              fontSize: FontSize.s12 * responsiveTextScale,
              color: Colors.grey,
              fontFamily: FontFamily.Montserrat,
            ),
          ),
          SizedBox(height: 8 * responsiveTextScale),
          
          // Auto location updates toggle
          Container(
            padding: EdgeInsets.symmetric(vertical: 8 * responsiveTextScale),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(6 * responsiveTextScale),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8 * responsiveTextScale),
                  ),
                  child: Icon(
                    Icons.location_on,
                    color: Colors.blue,
                    size: 18 * responsiveTextScale,
                  ),
                ),
                SizedBox(width: 8 * responsiveTextScale),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto Location Updates',
                        style: TextStyle(
                          color: ColorManager.black,
                          fontSize: FontSize.s14 * responsiveTextScale,
                          fontFamily: FontFamily.Montserrat,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Automatically update location when app starts',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: FontSize.s12 * responsiveTextScale,
                          fontFamily: FontFamily.Montserrat,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isAutoLocationEnabled,
                  onChanged: _toggleAutoLocation,
                  activeColor: Colors.blue,
                  activeTrackColor: Colors.blue.withOpacity(0.3),
                ),
              ],
            ),
          ),
          
          // Manual location update button
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(top: 8 * responsiveTextScale),
            child: ElevatedButton.icon(
              onPressed: _isUpdatingLocation ? null : _updateLocationNow,
              icon: _isUpdatingLocation 
                ? SizedBox(
                    width: 16 * responsiveTextScale,
                    height: 16 * responsiveTextScale,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(Icons.refresh, size: 18 * responsiveTextScale),
              label: Text(
                _isUpdatingLocation ? 'Updating...' : 'Update Location Now',
                style: TextStyle(
                  fontSize: FontSize.s14 * responsiveTextScale,
                  fontFamily: FontFamily.Montserrat,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 16 * responsiveTextScale,
                  vertical: 12 * responsiveTextScale,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8 * responsiveTextScale),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: animationDelay.ms, duration: 500.ms).slideX(begin: 0.02, end: 0);
  }
  // --- END ADDED ---

  // Helper method to build settings field
  Widget _buildSettingsField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    required IconData icon,
    required double responsiveTextScale,
    required int animationDelay,
    bool isRequired = false,
    String? fieldName, // Add field name for error tracking
  }) {
    final hasError = fieldName != null && _fieldErrors.containsKey(fieldName);
    final errorMessage = hasError ? _fieldErrors[fieldName] : null;
    
    return Container(
      padding: EdgeInsets.symmetric(vertical: responsiveTextScale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isRequired ? '$label *' : label,
            style: TextStyle(
              fontSize: FontSize.s12 * responsiveTextScale,
              color: hasError ? Colors.red : Colors.grey,
              fontFamily: FontFamily.Montserrat,
            ),
          ),
          SizedBox(height: 8 * responsiveTextScale),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6 * responsiveTextScale),
                decoration: BoxDecoration(
                  color: hasError ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8 * responsiveTextScale),
                ),
                child: Icon(
                  icon,
                  color: hasError ? Colors.red : Colors.orange,
                  size: 18 * responsiveTextScale,
                ),
              ),
              SizedBox(width: 8 * responsiveTextScale),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  inputFormatters: fieldName == 'name' ? [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                  ] : null,
                  style: TextStyle(
                    color: ColorManager.black,
                    fontSize: FontSize.s14 * responsiveTextScale,
                    fontFamily: FontFamily.Montserrat,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: fieldName == 'name' ? 'Enter your full name (alphabets only)' : null,
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: FontSize.s12 * responsiveTextScale,
                      fontFamily: FontFamily.Montserrat,
                    ),
                    focusedBorder: hasError ? UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 1),
                    ) : UnderlineInputBorder(
                      borderSide: BorderSide(color: ColorManager.primary, width: 1),
                    ),
                  ),
                  onTap: () {
                    HapticFeedback.selectionClick(); // Add haptic feedback
                    // Clear error when user starts typing
                    if (fieldName != null) {
                      _clearFieldError(fieldName);
                    }
                  },
                  onChanged: (value) {
                    // Show or clear error in real-time
                    if (fieldName != null) {
                      if (value.trim().isEmpty) {
                        _showFieldError(fieldName, '${label} is required');
                      } else if (fieldName == 'email' && !_isValidEmail(value.trim())) {
                        _showFieldError(fieldName, 'Please enter a valid email address');
                      } else if (fieldName == 'name' && !_isValidName(value.trim())) {
                        _showFieldError(fieldName, 'Name can only contain alphabets and spaces');
                      } else {
                        _clearFieldError(fieldName);
                      }
                    }
                  },
                ),
              ),
            ],
          ),
          if (hasError && errorMessage != null) ...[
            SizedBox(height: 4 * responsiveTextScale),
            Text(
              errorMessage,
              style: TextStyle(
                color: Colors.red,
                fontSize: FontSize.s10 * responsiveTextScale,
                fontFamily: FontFamily.Montserrat,
              ),
            ),
          ],
          const Divider(thickness: 0.8),
        ],
      ),
    ).animate().fadeIn(delay: animationDelay.ms, duration: 500.ms).slideX(begin: 0.02, end: 0);
  }

  // Helper method to build verifiable field (editable after verification)
  Widget _buildVerifiableField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    required IconData icon,
    required double responsiveTextScale,
    required int animationDelay,
    bool isRequired = false,
    bool isVerified = false,
    required VoidCallback onVerify,
    String? fieldType, // 'email' or 'phone'
    String? fieldName, // Add field name for error tracking
  }) {
    final hasError = fieldName != null && _fieldErrors.containsKey(fieldName);
    final errorMessage = hasError ? _fieldErrors[fieldName] : null;
    return Container(
      padding: EdgeInsets.symmetric(vertical: responsiveTextScale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isRequired ? '$label *' : label,
            style: TextStyle(
              fontSize: FontSize.s12 * responsiveTextScale,
              color: hasError ? Colors.red : Colors.grey,
              fontFamily: FontFamily.Montserrat,
            ),
          ),
          SizedBox(height: 8 * responsiveTextScale),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6 * responsiveTextScale),
                decoration: BoxDecoration(
                  color: hasError ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8 * responsiveTextScale),
                ),
                child: Icon(
                  icon,
                  color: hasError ? Colors.red : Colors.orange,
                  size: 18 * responsiveTextScale,
                ),
              ),
              SizedBox(width: 8 * responsiveTextScale),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  enabled: isVerified, // Make field editable only after verification
                  style: TextStyle(
                    color: isVerified ? ColorManager.black : Colors.grey[600],
                    fontSize: FontSize.s14 * responsiveTextScale,
                    fontFamily: FontFamily.Montserrat,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: FontSize.s12 * responsiveTextScale,
                      fontFamily: FontFamily.Montserrat,
                    ),
                    disabledBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: isVerified ? (hasError ? UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.red, width: 1),
                    ) : UnderlineInputBorder(
                      borderSide: BorderSide(color: ColorManager.primary, width: 1),
                    )) : InputBorder.none,
                  ),
                  onTap: () {
                    if (!isVerified) {
                      HapticFeedback.selectionClick();
                      _showSnackBar(
                        message: 'Please verify this field first before editing',
                        isError: true,
                      );
                    } else {
                      // Clear error when user starts typing
                      if (fieldName != null) {
                        _clearFieldError(fieldName);
                      }
                    }
                  },
                  onChanged: (value) {
                    // Show or clear error in real-time (only if verified)
                    if (isVerified && fieldName != null) {
                      if (value.trim().isEmpty) {
                        _showFieldError(fieldName, '${label} is required');
                      } else if (fieldName == 'email' && !_isValidEmail(value.trim())) {
                        _showFieldError(fieldName, 'Please enter a valid email address');
                      } else {
                        _clearFieldError(fieldName);
                      }
                    }
                  },
                ),
              ),
              SizedBox(width: 8 * responsiveTextScale),
              // Verification button
              Container(
                decoration: BoxDecoration(
                  color: isVerified ? Colors.green : ColorManager.primary,
                  borderRadius: BorderRadius.circular(8 * responsiveTextScale),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8 * responsiveTextScale),
                    onTap: isVerified ? null : onVerify, // Disable button if already verified
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12 * responsiveTextScale,
                        vertical: 8 * responsiveTextScale,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isVerified ? Icons.verified : Icons.verified_user,
                            color: Colors.white,
                            size: 16 * responsiveTextScale,
                          ),
                          SizedBox(width: 4 * responsiveTextScale),
                          Text(
                            isVerified ? 'Verified' : 'Verify',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: FontSize.s12 * responsiveTextScale,
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
          if (hasError && errorMessage != null) ...[
            SizedBox(height: 4 * responsiveTextScale),
            Text(
              errorMessage,
              style: TextStyle(
                color: Colors.red,
                fontSize: FontSize.s10 * responsiveTextScale,
                fontFamily: FontFamily.Montserrat,
              ),
            ),
          ],
          const Divider(thickness: 0.8),
        ],
      ),
    ).animate().fadeIn(delay: animationDelay.ms, duration: 500.ms).slideX(begin: 0.02, end: 0);
  }

  // Show email verification dialog
  void _showEmailVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VerificationDialog(
        title: 'Verify Email',
        subtitle: 'Enter the 6-digit OTP sent to your email\n${_originalEmail}',
        value: _originalEmail, // Use original email from profile
        type: VerificationType.email,
        onVerificationSuccess: () {
          setState(() {
            _isEmailVerified = true;
          });
          _showSnackBar(
            message: 'Email verified successfully! You can now edit this field.',
            isError: false,
          );
        },
      ),
    );
  }

  // Show phone verification dialog
  void _showPhoneVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => VerificationDialog(
        title: 'Verify Phone',
        subtitle: 'Enter the 6-digit OTP sent to\n${_phoneController.text}',
        value: _phoneController.text,
        type: VerificationType.phone,
        onVerificationSuccess: () {
          setState(() {
            _isPhoneVerified = true;
          });
          _showSnackBar(
            message: 'Phone number verified successfully! You can now edit this field.',
            isError: false,
          );
        },
      ),
    );
  }



  Widget _buildDeleteAccountButton(double responsiveTextScale) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 18 * responsiveTextScale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12 * responsiveTextScale),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showDeleteConfirmation(responsiveTextScale),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 16 * responsiveTextScale),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Colors.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.delete_outline,
                  color: Colors.red[500],
                  size: 20 * responsiveTextScale,
                ),
                SizedBox(width: 8 * responsiveTextScale),
                Text(
                  'Delete Account',
                  style: TextStyle(
                    color: Colors.red[500],
                    fontSize: 14 * responsiveTextScale,
                    fontWeight: FontWeight.w500,
                    fontFamily: FontFamily.Montserrat,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Shimmer loading effect UI with more appealing animations
  Widget _buildShimmerView(double responsiveTextScale) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: ShimmerLoading(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile photo shimmer
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 28 * responsiveTextScale),
              color: Colors.white,
              child: Column(
                children: [
                  Container(
                    width: 110 * responsiveTextScale,
                    height: 110 * responsiveTextScale,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[300],
                    ),
                  ),
                  SizedBox(height: 12 * responsiveTextScale),
                  Container(
                    width: 160 * responsiveTextScale,
                    height: 14 * responsiveTextScale,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4 * responsiveTextScale),
                      color: Colors.grey[300],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20 * responsiveTextScale),
            
            // Form fields shimmer
            Container(
              margin: EdgeInsets.symmetric(horizontal: 18 * responsiveTextScale),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12 * responsiveTextScale),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 18 * responsiveTextScale, 
                vertical: 20 * responsiveTextScale
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildShimmerField(responsiveTextScale),
                  SizedBox(height: 20 * responsiveTextScale),
                  
                  _buildShimmerField(responsiveTextScale),
                  SizedBox(height: 20 * responsiveTextScale),
                  
                  _buildShimmerField(responsiveTextScale),
                  SizedBox(height: 20 * responsiveTextScale),
                  
                  _buildShimmerField(responsiveTextScale),
                ],
              ),
            ),
            
            SizedBox(height: 20 * responsiveTextScale),
            
            // Delete button shimmer
            Container(
              margin: EdgeInsets.symmetric(horizontal: 18 * responsiveTextScale),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12 * responsiveTextScale),
              ),
              padding: EdgeInsets.symmetric(
                vertical: 16 * responsiveTextScale, 
                horizontal: 18 * responsiveTextScale
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 38 * responsiveTextScale,
                    height: 38 * responsiveTextScale,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8 * responsiveTextScale),
                      color: Colors.grey[300],
                    ),
                  ),
                  SizedBox(width: 12 * responsiveTextScale),
                  Container(
                    width: 120 * responsiveTextScale,
                    height: 16 * responsiveTextScale,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4 * responsiveTextScale),
                      color: Colors.grey[300],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 30 * responsiveTextScale),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 800.ms);
  }
  
  // Helper method to build shimmer field with gradual loading effect
  Widget _buildShimmerField(double responsiveTextScale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label shimmer
        Container(
          width: 80 * responsiveTextScale,
          height: 14 * responsiveTextScale,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4 * responsiveTextScale),
            color: Colors.grey[300],
          ),
        ),
        SizedBox(height: 8 * responsiveTextScale),
        
        // Value shimmer
        Container(
          width: double.infinity,
          height: 16 * responsiveTextScale,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4 * responsiveTextScale),
            color: Colors.grey[300],
          ),
        ),
        SizedBox(height: 4 * responsiveTextScale),
        
        // Divider shimmer
        Container(
          width: double.infinity,
          height: 1,
          decoration: BoxDecoration(
            color: Colors.grey[300],
          ),
        ),
      ],
    );
  }

  String _getFullImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return '';
    }
    
    // Check if the image path already has the base URL
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    return '${ApiConstants.baseUrl}/api/${imagePath.startsWith('/') ? imagePath.substring(1) : imagePath}';
  }
}
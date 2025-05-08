import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../constants/api_constant.dart';
import '../../constants/color/colorConstant.dart';
import '../../constants/font/fontManager.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Add this package

import '../../widgets/shimmer_helper.dart';
import '../address bottomSheet/view.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';

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
  
  void _loadUserDataToControllers(Map<String, dynamic> userData) {
    _nameController.text = userData['username'] ?? '';
    _emailController.text = userData['email'] ?? '';
    _phoneController.text = userData['mobile'] ?? '';
    _addressController.text = userData['address'] ?? '';
    
    // Store coordinates
    _latitude = userData['latitude'] != null ? double.tryParse(userData['latitude'].toString()) : null;
    _longitude = userData['longitude'] != null ? double.tryParse(userData['longitude'].toString()) : null;
  }
  
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
  
  // Method to show address picker
  Future<void> _showAddressPicker() async {
    HapticFeedback.selectionClick(); // Add haptic feedback
    
    final result = await AddressPickerBottomSheet.show(context);
    
    if (result != null) {
      setState(() {
        _addressController.text = result['address'];
        if (result['subAddress'].toString().isNotEmpty) {
          _addressController.text += ', ${result['subAddress']}';
        }
        _latitude = result['latitude'];
        _longitude = result['longitude'];
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

  // Show confirmation dialog with improved animations
  Future<void> _showDeleteConfirmation(double responsiveTextScale) async {
    HapticFeedback.heavyImpact(); // Strong haptic feedback for destructive action
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Delete Account Dialog',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation1, animation2) => Container(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );
        
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(curvedAnimation),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curvedAnimation),
            child: AlertDialog(
              title: Text(
                'Delete Account',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeightManager.bold,
                  fontSize: FontSize.s16 * responsiveTextScale,
                  fontFamily: FontFamily.Montserrat,
                ),
              ),
              content: Text(
                'Are you sure you want to delete your account? This action cannot be undone.',
                style: TextStyle(
                  fontSize: FontSize.s14 * responsiveTextScale,
                  fontFamily: FontFamily.Montserrat,
                  height: 1.4,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16 * responsiveTextScale),
              ),
              elevation: 4,
              backgroundColor: Colors.white,
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16 * responsiveTextScale,
                      vertical: 8 * responsiveTextScale,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8 * responsiveTextScale),
                    ),
                  ),
                  child: Text(
                    'CANCEL',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: FontSize.s14 * responsiveTextScale,
                      fontFamily: FontFamily.Montserrat,
                      fontWeight: FontWeightManager.medium,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _settingsBloc.add(DeleteAccount());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: ColorManager.textWhite,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      horizontal: 16 * responsiveTextScale,
                      vertical: 8 * responsiveTextScale,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20 * responsiveTextScale),
                    ),
                  ),
                  child: Text(
                    'DELETE',
                    style: TextStyle(
                      fontSize: FontSize.s14 * responsiveTextScale,
                      fontFamily: FontFamily.Montserrat,
                      fontWeight: FontWeightManager.semiBold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double responsiveTextScale = screenSize.width / 375; // Base scale factor
    
    return BlocProvider.value(
      value: _settingsBloc,
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
                              ? Colors.deepOrange 
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
                          // Profile image with animations
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.elasticOut,
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: child,
                              );
                            },
                            child: Stack(
                              children: [
                                GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    width: 110 * responsiveTextScale,
                                    height: 110 * responsiveTextScale,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey[200],
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 4,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.08),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Hero(  // Add Hero animation for profile photo
                                      tag: 'profile_image',
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(55 * responsiveTextScale),
                                        child: _profileImage != null
                                            ? Image.file(
                                                _profileImage!,
                                                fit: BoxFit.cover,
                                              )
                                            : state.userData['image'] != null && state.userData['image'].toString().isNotEmpty
                                                ? Image.network(
                                                    _getFullImageUrl(state.userData['image']),
                                                    fit: BoxFit.cover,
                                                    loadingBuilder: (context, child, loadingProgress) {
                                                      if (loadingProgress == null) return child;
                                                      return Center(
                                                        child: CircularProgressIndicator(
                                                          value: loadingProgress.expectedTotalBytes != null
                                                              ? loadingProgress.cumulativeBytesLoaded / 
                                                                  loadingProgress.expectedTotalBytes!
                                                              : null,
                                                          valueColor: const AlwaysStoppedAnimation<Color>(
                                                            Colors.deepOrange,
                                                          ),
                                                          strokeWidth: 2,
                                                        ),
                                                      );
                                                    },
                                                    errorBuilder: (context, error, stackTrace) {
                                                      debugPrint('Error loading image: $error');
                                                      return Icon(
                                                        Icons.person,
                                                        size: 55 * responsiveTextScale,
                                                        color: Colors.grey,
                                                      );
                                                    },
                                                  )
                                                : Icon(
                                                    Icons.person,
                                                    size: 55 * responsiveTextScale,
                                                    color: Colors.grey,
                                                  ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0.0, end: 1.0),
                                    duration: const Duration(milliseconds: 600),
                                    curve: Curves.elasticOut,
                                    builder: (context, value, child) {
                                      return Transform.scale(
                                        scale: value,
                                        child: child,
                                      );
                                    },
                                    child: GestureDetector(
                                      onTap: _pickImage,
                                      child: Container(
                                        padding: EdgeInsets.all(8 * responsiveTextScale),
                                        decoration: BoxDecoration(
                                          color: Colors.deepOrange,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.1),
                                              blurRadius: 4,
                                              spreadRadius: 0,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.camera_alt,
                                          size: 18 * responsiveTextScale,
                                          color: ColorManager.textWhite,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 12 * responsiveTextScale),
                          Text(
                            'Tap to change profile photo',
                            style: TextStyle(
                              fontSize: FontSize.s12 * responsiveTextScale,
                              color: Colors.grey,
                              letterSpacing: 0.2,
                              fontFamily: FontFamily.Montserrat,
                            ),
                          ).animate().fadeIn(duration: 600.ms),
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
                            ),
                            
                            // Email Field
                            _buildSettingsField(
                              label: 'Email',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              icon: Icons.email_outlined,
                              responsiveTextScale: responsiveTextScale,
                              animationDelay: 200,
                            ),
                            
                            // Phone Number Field
                            _buildSettingsField(
                              label: 'Phone Number',
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              icon: Icons.phone_outlined,
                              responsiveTextScale: responsiveTextScale,
                              animationDelay: 300,
                            ),
                            
                            // Address Field with location picker
                            _buildAddressField(responsiveTextScale, 400),
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
            
            // Fallback - should not happen
            return const Center(child: Text('Something went wrong!'));
          },
        ),
      ),
    );
  }

  // Helper method to build address field
  Widget _buildAddressField(double responsiveTextScale, int animationDelay) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: responsiveTextScale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Address',
            style: TextStyle(
              fontSize: FontSize.s12 * responsiveTextScale,
              color: Colors.grey,
              fontFamily: FontFamily.Montserrat,
            ),
          ),
          SizedBox(height: 8 * responsiveTextScale),
          InkWell(
            onTap: _showAddressPicker,
            borderRadius: BorderRadius.circular(8 * responsiveTextScale),
            splashColor: Colors.deepOrange.withOpacity(0.1),
            highlightColor: Colors.deepOrange.withOpacity(0.05),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 4 * responsiveTextScale),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6 * responsiveTextScale),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8 * responsiveTextScale),
                    ),
                    child: Icon(
                      Icons.location_on_outlined,
                      color: Colors.deepOrange,
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
          // const Divider(thickness: 0.8),
        ],
      ),
    ).animate().fadeIn(delay: animationDelay.ms, duration: 500.ms).slideX(begin: 0.02, end: 0);
  }

  // Helper method to build settings field
  Widget _buildSettingsField({
    required String label,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    required IconData icon,
    required double responsiveTextScale,
    required int animationDelay,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: responsiveTextScale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: FontSize.s12 * responsiveTextScale,
              color: Colors.grey,
              fontFamily: FontFamily.Montserrat,
            ),
          ),
          SizedBox(height: 8 * responsiveTextScale),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6 * responsiveTextScale),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8 * responsiveTextScale),
                ),
                child: Icon(
                  icon,
                  color: Colors.deepOrange,
                  size: 18 * responsiveTextScale,
                ),
              ),
              SizedBox(width: 8 * responsiveTextScale),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: TextStyle(
                    color: ColorManager.black,
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
                  ),
                  onTap: () {
                    HapticFeedback.selectionClick(); // Add haptic feedback
                  },
                ),
              ),
            ],
          ),
          const Divider(thickness: 0.8),
        ],
      ),
    ).animate().fadeIn(delay: animationDelay.ms, duration: 500.ms).slideX(begin: 0.02, end: 0);
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
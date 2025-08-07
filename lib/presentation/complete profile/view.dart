import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../constants/color/colorConstant.dart';
import '../../constants/font/fontManager.dart';
import '../../service/profile_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_button_large.dart';
import '../../widgets/text_field2.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';

class CompleteProfileView extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final String? token;
  
  const CompleteProfileView({
    Key? key,
    this.userData,
    this.token,
  }) : super(key: key);

  @override
  _CompleteProfileViewState createState() => _CompleteProfileViewState();
}

class _CompleteProfileViewState extends State<CompleteProfileView> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  File? _avatarFile;
  final _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  Future<void> _loadExistingData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load existing profile data if available
      final profileData = await ProfileService.getProfileData();
      
      if (profileData['name'] != null) {
        _nameCtrl.text = profileData['name'];
      }
      
      if (profileData['email'] != null) {
        _emailCtrl.text = profileData['email'];
      }
      
      if (profileData['photo'] != null) {
        setState(() {
          _avatarFile = profileData['photo'];
        });
      }
    } catch (e) {
      debugPrint('Error loading existing data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    // padding & sizes
    final hPad      = w * .05;
    final avatarDim = w * .35;
    final cornerRad = avatarDim * .4; // rounded-corner box

    return BlocProvider(
      create: (_) => CompleteProfileBloc(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: 48,
          leading: BackButton(color: ColorManager.black),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: ColorManager.black.withOpacity(0.05),
            ),
          ),
        ),
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: hPad,
            vertical: hPad * .8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: h * .015),

              // Title
              Text(
                'Complete Your Profile',
                style: GoogleFonts.poppins(
                  fontSize: FontSize.s22,
                  fontWeight: FontWeightManager.bold,
                  color: ColorManager.black,
                ),
              ),

              SizedBox(height: h * .005),

              // Subtitle
              Text(
                'Add your name and optionally a photo to get started',
                style: GoogleFonts.poppins(
                  fontSize: FontSize.s14,
                  fontWeight: FontWeightManager.regular,
                  color: ColorManager.black.withOpacity(0.6),
                ),
              ),

              SizedBox(height: h * .03),

              // ─── rounded-corner box avatar ───
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // box with rounded corners
                  ClipRRect(
                    borderRadius: BorderRadius.circular(cornerRad),
                    child: Container(
                      width: avatarDim,
                      height: avatarDim,
                      color: ColorManager.black.withOpacity(0.05),
                      child: _avatarFile != null
                          ? Image.file(
                              _avatarFile!,
                              fit: BoxFit.cover,
                              width: avatarDim,
                              height: avatarDim,
                            )
                          // two-tone placeholder
                          : Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    color: ColorManager.black.withOpacity(0.1),
                                    child: Center(
                                      child: Text(
                                        'Optional',
                                        style: GoogleFonts.poppins(
                                          fontSize: FontSize.s14,
                                          fontWeight:
                                              FontWeightManager.regular,
                                          color:
                                              ColorManager.black.withOpacity(0.3),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    color: Colors.white,
                                    child: Center(
                                      child: Icon(
                                        Icons.person,
                                        size: avatarDim * .4,
                                        color: ColorManager.black
                                            .withOpacity(0.3),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  // camera button
                  Positioned(
                    bottom: -(avatarDim * .07),
                    right: 0,
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: EdgeInsets.all(avatarDim * .07),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ColorManager.primary,
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          size: avatarDim * .14,
                          color: ColorManager.textWhite,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: h * .04),

              // Your Name
              _buildLabel('Your Name'),
              SizedBox(height: h * .008),
              SizedBox(
                height: 50,
                child: CustomTextField(
                  controller: _nameCtrl,
                  hint: 'Enter your name',
                  isRequired: true,
                ),
              ),

              SizedBox(height: h * .02),

              // Email
              _buildLabel('Email'),
              SizedBox(height: h * .008),
              SizedBox(
                height: 50,
                child: CustomTextField(
                  controller: _emailCtrl,
                  hint: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                ),
              ),

              SizedBox(height: h * .03),

              // Continue button
              BlocConsumer<CompleteProfileBloc, CompleteProfileState>(
                listener: (context, state) {
                  if (state is ProfileSuccess) {
                    Navigator.of(context).pushReplacementNamed('/address', arguments: {
                      'name': _nameCtrl.text.trim(),
                      'email': _emailCtrl.text.trim().isEmpty ? '' : _emailCtrl.text.trim(),
                      'photoPath': _avatarFile?.path,
                      'userData': widget.userData,
                      'token': widget.token,
                    });
                  } else if (state is ProfileFailure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.error),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  final isLoading = state is ProfileSubmitting;
                  
                  return SizedBox(
                    width: double.infinity,
                    child: CustomLargeButton(
                      text: isLoading ? 'Saving...' : 'Continue',
                      onPressed: isLoading ? () {} : () {
                        FocusScope.of(context).unfocus(); // Hide keyboard
                        context.read<CompleteProfileBloc>().add(
                              SubmitProfile(
                                name: _nameCtrl.text.trim(),
                                email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
                                avatar: _avatarFile,
                              ),
                            );
                      },
                    ),
                  );
                },
              ),

              SizedBox(height: h * .015),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: FontSize.s14,
            fontWeight: FontWeightManager.semiBold,
            color: ColorManager.black,
          ),
        ),
      );

  Future<void> _pickImage() async {
    try {
      // Show dialog to choose between camera and gallery
      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Wrap(
                children: <Widget>[
                  ListTile(
                    leading: const Icon(Icons.photo_camera),
                    title: const Text('Take Photo'),
                    onTap: () {
                      Navigator.pop(context);
                      _getImage(ImageSource.camera);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_library),
                    title: const Text('Choose from Gallery'),
                    onTap: () {
                      Navigator.pop(context);
                      _getImage(ImageSource.gallery);
                    },
                  ),
                  if (_avatarFile != null)
                    ListTile(
                      leading: const Icon(Icons.delete),
                      title: const Text('Remove Photo'),
                      onTap: () {
                        Navigator.pop(context);
                        setState(() => _avatarFile = null);
                      },
                    ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('Error showing image picker options: $e');
    }
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 800,
        maxHeight: 800,
      );
      
      if (picked != null) {
        setState(() => _avatarFile = File(picked.path));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to pick image. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }
}
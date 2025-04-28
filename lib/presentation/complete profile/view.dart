// lib/presentation/screens/profile/complete_profile/complete_profile_view.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../constants/color/colorConstant.dart';
import '../../constants/font/fontManager.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/text_field2.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';

class CompleteProfileView extends StatefulWidget {
  const CompleteProfileView({Key? key}) : super(key: key);

  @override
  _CompleteProfileViewState createState() => _CompleteProfileViewState();
}

class _CompleteProfileViewState extends State<CompleteProfileView> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  File? _avatarFile;
  final _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    // padding & sizes
    final hPad      = w * .05;
    final avatarDim = w * .35;
    final cornerRad = avatarDim * .4; // rounded-corner box

    return BlocProvider(
      create: (_) => CompleteProfileBloc(), // stubbed
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
        body: SingleChildScrollView(
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
                'Add a photo and your name to get started',
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
                          // when you plug in your backend, you'll supply the file here
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
                                        'Image',
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
                          color: ColorManager.orangeAcc,
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
                    Navigator.of(context).pushReplacementNamed('/home');
                  } else if (state is ProfileFailure) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.error)),
                    );
                  }
                },
                builder: (context, state) {
                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: CustomButton(
                      label: 'Continue',
                      isLoading: state is ProfileSubmitting,
                      onPressed: () {
                        context.read<CompleteProfileBloc>().add(
                              SubmitProfile(
                                name: _nameCtrl.text.trim(),
                                email: _emailCtrl.text.trim(),
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
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) setState(() => _avatarFile = File(picked.path));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }
}

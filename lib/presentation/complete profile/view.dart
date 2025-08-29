import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/color/colorConstant.dart';
import '../../constants/font/fontManager.dart';
import '../../service/profile_service.dart';
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
    final hPad = w * .05;

    return BlocProvider(
      create: (_) => CompleteProfileBloc(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          toolbarHeight: h < 700 ? 52 : 48, // Slightly taller on small screens
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
                'Add your name and email to get started',
                style: GoogleFonts.poppins(
                  fontSize: FontSize.s14,
                  fontWeight: FontWeightManager.regular,
                  color: ColorManager.black.withOpacity(0.6),
                ),
              ),

              SizedBox(height: h * .03),

              // Your Name
              _buildLabel('Your Name'),
              SizedBox(height: h * .008),
              SizedBox(
                height: h < 700 ? 55 : 50, // Slightly taller on small screens
                child: CustomTextField(
                  controller: _nameCtrl,
                  hint: 'Enter your name (max 30 characters)',
                  isRequired: true,
                  maxLength: 30, // Add 30 character limit
                ),
              ),

              SizedBox(height: h * .02),

              // Email
              _buildLabel('Email'),
              SizedBox(height: h * .008),
              SizedBox(
                height: h < 700 ? 55 : 50, // Slightly taller on small screens
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

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }
}
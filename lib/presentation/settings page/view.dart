import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../widgets/settings_fields.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  File? _profileImage;
  bool _isSaving = false;
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
  
  void _loadUserDataToControllers(Map<String, dynamic> userData) {
    _nameController.text = userData['username'] ?? '';
    _emailController.text = userData['email'] ?? '';
    _phoneController.text = userData['mobile'] ?? '';
    _addressController.text = userData['address'] ?? '';
  }
  
  Future<void> _pickImage() async {
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
        
        // Update profile image immediately
        context.read<SettingsBloc>().add(UpdateProfileImage(
          imageFile: _profileImage!,
        ));
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick image')),
      );
    }
  }
  
  void _saveSettings() {
    setState(() {
      _isSaving = true;
    });
    
    context.read<SettingsBloc>().add(UpdateUserSettings(
      name: _nameController.text,
      email: _emailController.text,
      phone: _phoneController.text,
      address: _addressController.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsBloc()..add(LoadUserSettings()),
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Settings',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            BlocBuilder<SettingsBloc, SettingsState>(
              builder: (context, state) {
                return TextButton(
                  onPressed: state is SettingsLoaded && !_isSaving 
                      ? _saveSettings 
                      : null,
                  child: Text(
                    'Save',
                    style: TextStyle(
                      color: state is SettingsLoaded && !_isSaving 
                          ? Colors.blue 
                          : Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
            
            if (state is SettingsError) {
              setState(() {
                _isSaving = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                ),
              );
            }
            
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
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Photo
                    BlocBuilder<SettingsBloc, SettingsState>(
                      builder: (context, state) {
                        String imageUrl = '';
                        
                        if (state is SettingsLoaded) {
                          imageUrl = state.userData['image'] ?? '';
                        }
                        
                        return Center(
                          child: Stack(
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey[200],
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(60),
                                  child: _profileImage != null
                                      ? Image.file(
                                          _profileImage!,
                                          fit: BoxFit.cover,
                                        )
                                      : imageUrl.isNotEmpty
                                          ? Image.network(
                                              imageUrl,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return const Icon(
                                                  Icons.person,
                                                  size: 60,
                                                  color: Colors.grey,
                                                );
                                              },
                                            )
                                          : const Icon(
                                              Icons.person,
                                              size: 60,
                                              color: Colors.grey,
                                            ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tap to change profile photo',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // Settings Form
                    if (state is SettingsLoading || state is SettingsInitial)
                      const Center(child: CircularProgressIndicator())
                    else if (state is SettingsLoaded)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name Field
                          SettingsField(
                            label: 'Name',
                            value: state.userData['username'] ?? '',
                            controller: _nameController,
                          ),
                          
                          // Email Field
                          SettingsField(
                            label: 'Email',
                            value: state.userData['email'] ?? '',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          
                          // Phone Number Field
                          SettingsField(
                            label: 'Phone Number',
                            value: state.userData['mobile'] ?? '',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                          ),
                          
                          // Address Field
                          SettingsField(
                            label: 'Address',
                            value: state.userData['address'] ?? '',
                            controller: _addressController,
                          ),
                          
                          const SizedBox(height: 30),
                          
                          // Delete Account Button
                          Center(
                            child: TextButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text('Delete Account'),
                                    content: const Text(
                                      'Are you sure you want to delete your account? This action cannot be undone.'
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(dialogContext),
                                        child: const Text('CANCEL'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(dialogContext);
                                          context.read<SettingsBloc>().add(DeleteAccount());
                                        },
                                        child: const Text(
                                          'DELETE',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              label: const Text(
                                'Delete Account',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else if (state is SettingsError)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            Text(state.message),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                context.read<SettingsBloc>().add(LoadUserSettings());
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
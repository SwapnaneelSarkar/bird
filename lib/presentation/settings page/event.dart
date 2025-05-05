import 'dart:io';

abstract class SettingsEvent {}

class LoadUserSettings extends SettingsEvent {}

class UpdateUserSettings extends SettingsEvent {
  final String? name;
  final String? email;
  final String? phone;
  final String? address;
  final String? password;
  final File? imageFile;
  
  UpdateUserSettings({
    this.name,
    this.email,
    this.phone,
    this.address,
    this.password,
    this.imageFile,
  });
}

class UpdateProfileImage extends SettingsEvent {
  final File imageFile;
  
  UpdateProfileImage({required this.imageFile});
}

class DeleteAccount extends SettingsEvent {}
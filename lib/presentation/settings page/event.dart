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
  final double? latitude;
  final double? longitude;
  
  UpdateUserSettings({
    this.name,
    this.email,
    this.phone,
    this.address,
    this.password,
    this.imageFile,
    this.latitude,
    this.longitude,
  });
}

class UpdateProfileImage extends SettingsEvent {
  final File imageFile;
  
  UpdateProfileImage({required this.imageFile});
}

class DeleteAccount extends SettingsEvent {}
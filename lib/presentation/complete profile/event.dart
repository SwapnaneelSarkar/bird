// lib/presentation/screens/profile/complete_profile/bloc/complete_profile_event.dart

import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class CompleteProfileEvent extends Equatable {
  const CompleteProfileEvent();

  @override
  List<Object?> get props => [];
}

class SubmitProfile extends CompleteProfileEvent {
  final String name;
  final String email;
  final File? avatar;

  const SubmitProfile({
    required this.name,
    required this.email,
    this.avatar,
  });

  @override
  List<Object?> get props => [name, email, avatar];
}

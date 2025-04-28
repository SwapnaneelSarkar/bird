// lib/presentation/screens/profile/complete_profile/bloc/complete_profile_state.dart

import 'package:equatable/equatable.dart';

abstract class CompleteProfileState extends Equatable {
  const CompleteProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends CompleteProfileState {}

class ProfileSubmitting extends CompleteProfileState {}

class ProfileSuccess extends CompleteProfileState {}

class ProfileFailure extends CompleteProfileState {
  final String error;
  const ProfileFailure(this.error);

  @override
  List<Object?> get props => [error];
}

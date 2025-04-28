// lib/presentation/screens/profile/complete_profile/bloc/complete_profile_bloc.dart

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'event.dart';
import 'state.dart';

class CompleteProfileBloc
    extends Bloc<CompleteProfileEvent, CompleteProfileState> {
  CompleteProfileBloc() : super(ProfileInitial()) {
    on<SubmitProfile>(_onSubmitProfile);
  }

  Future<void> _onSubmitProfile(
    SubmitProfile event,
    Emitter<CompleteProfileState> emit,
  ) async {
    emit(ProfileSubmitting());
    // simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    // just log the payload for now
    debugPrint('📝 [STATIC] name=${event.name}, email=${event.email}, avatar=${event.avatar}');
    // immediately succeed
    emit(ProfileSuccess());
  }
}

import 'dart:async';
import 'dart:io';

import 'package:bird/service/profile_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'event.dart';
import 'state.dart';

class CompleteProfileBloc extends Bloc<CompleteProfileEvent, CompleteProfileState> {
  CompleteProfileBloc() : super(ProfileInitial()) {
    on<SubmitProfile>(_onSubmitProfile);
  }
  

  Future<void> _onSubmitProfile(
    SubmitProfile event,
    Emitter<CompleteProfileState> emit,
  ) async {
    emit(ProfileSubmitting());
    
    try {
      // Validate input
      if (event.name.isEmpty) {
        emit(const ProfileFailure('Please enter your name'));
        return;
      }
      
      if (event.email.isEmpty) {
        emit(const ProfileFailure('Please enter your email'));
        return;
      }
      
      // Basic email validation
      if (!_isValidEmail(event.email)) {
        emit(const ProfileFailure('Please enter a valid email address'));
        return;
      }
      
      // Save profile data
      debugPrint('Saving profile data...');
      debugPrint('Name: ${event.name}');
      debugPrint('Email: ${event.email}');
      debugPrint('Has photo: ${event.avatar != null}');
      
      final success = await ProfileService.saveProfileData(
        name: event.name,
        email: event.email,
        photo: event.avatar,
      );
      
      if (success) {
        debugPrint('Profile data saved successfully');
        emit(ProfileSuccess());
      } else {
        debugPrint('Failed to save profile data');
        emit(const ProfileFailure('Failed to save profile data. Please try again.'));
      }
    } catch (e) {
      debugPrint('Error in _onSubmitProfile: $e');
      emit(ProfileFailure('An error occurred: ${e.toString()}'));
    }
  }
  
  
  bool _isValidEmail(String email) {
    // Basic email validation
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
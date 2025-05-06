import 'dart:async';
import 'dart:io';

import 'package:bird/service/profile_service.dart';
import 'package:bird/service/location_services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'event.dart';
import 'state.dart';

class CompleteProfileBloc extends Bloc<CompleteProfileEvent, CompleteProfileState> {
  final LocationService _locationService = LocationService();
  
  CompleteProfileBloc() : super(ProfileInitial()) {
    on<SubmitProfile>(_onSubmitProfile);
    on<SelectPlace>(_onSelectPlace);
  }
  
  Future<void> _onSelectPlace(
    SelectPlace event,
    Emitter<CompleteProfileState> emit,
  ) async {
    try {
      debugPrint('CompleteProfileBloc: Getting coordinates for place ID: ${event.placeId}');
      emit(ProfileSubmitting());
      
      // Get coordinates from selected place
      final placeData = await _locationService.getCoordinatesFromPlace(event.placeId);
      
      if (placeData != null) {
        debugPrint('Place selected successfully');
        debugPrint('Latitude: ${placeData['latitude']}');
        debugPrint('Longitude: ${placeData['longitude']}');
        debugPrint('Address: ${placeData['address']}');
        
        emit(PlaceSelected(
          address: placeData['address'],
          latitude: placeData['latitude'],
          longitude: placeData['longitude'],
        ));
      } else {
        debugPrint('Failed to get place coordinates');
        emit(const ProfileFailure('Could not get coordinates for selected place'));
      }
    } catch (e) {
      debugPrint('Error selecting place: $e');
      emit(ProfileFailure('Error getting place details: ${e.toString()}'));
    }
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
      
      // If address and coordinates are provided, save them too
      if (event.address != null && event.latitude != null && event.longitude != null) {
        debugPrint('Address: ${event.address}');
        debugPrint('Latitude: ${event.latitude}');
        debugPrint('Longitude: ${event.longitude}');
        
        final success = await ProfileService.saveProfileData(
          name: event.name,
          email: event.email,
          photo: event.avatar,
          address: event.address,
          latitude: event.latitude,
          longitude: event.longitude,
        );
        
        if (success) {
          debugPrint('Profile data saved successfully with location');
          emit(ProfileSuccess());
        } else {
          debugPrint('Failed to save profile data');
          emit(const ProfileFailure('Failed to save profile data. Please try again.'));
        }
      } else {
        // Just save name, email and photo if no address/coordinates
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
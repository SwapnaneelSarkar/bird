import 'dart:io';
import 'package:bird/service/location_services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../service/update_user_service.dart';
import '../../service/token_service.dart';
import '../../service/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'event.dart';
import 'state.dart';

class AddressBloc extends Bloc<AddressEvent, AddressState> {
  final LocationService _locationService = LocationService();
  final UpdateUserService _updateUserService = UpdateUserService();

  AddressBloc() : super(AddressInitialState()) {
    on<SubmitAddressEvent>(_onSubmitAddress);
    on<DetectLocationEvent>(_onDetectLocation);
  }

  Future<void> _onSubmitAddress(
      SubmitAddressEvent event, Emitter<AddressState> emit) async {
    try {
      debugPrint('AddressBloc: Starting address submission...');
      emit(AddressLoadingState());

      // Get saved data
      final token = await TokenService.getToken();
      final profileData = await ProfileService.getProfileData();
      final prefs = await SharedPreferences.getInstance();
      final mobile = prefs.getString('user_phone');

      debugPrint('Retrieved token: ${token != null ? "Found" : "Not found"}');
      debugPrint('Retrieved mobile: $mobile');
      debugPrint('Retrieved profile data: $profileData');

      if (token == null || mobile == null) {
        debugPrint('Missing required data: token or mobile');
        emit(AddressErrorState(error: 'Please login again'));
        return;
      }

      // Clean up mobile number (remove country code if present)
      String cleanMobile = mobile;
      if (cleanMobile.startsWith('+91')) {
        cleanMobile = cleanMobile.substring(3);
      } else if (cleanMobile.startsWith('+')) {
        // Remove any country code
        cleanMobile = cleanMobile.substring(cleanMobile.length - 10);
      }

      // Get name and email from profile data
      final name = profileData['name'] ?? '';
      final email = profileData['email'] ?? '';
      final photoFile = profileData['photo'] as File?;

      debugPrint('Submitting profile update with:');
      debugPrint('Name: $name');
      debugPrint('Email: $email');
      debugPrint('Mobile: $cleanMobile');
      debugPrint('Address: ${event.address}');
      debugPrint('Latitude: ${event.latitude}');
      debugPrint('Longitude: ${event.longitude}');
      debugPrint('Has photo: ${photoFile != null}');

      // Call update user API
      final result = await _updateUserService.updateUserProfile(
        token: token,
        mobile: cleanMobile,
        username: name,
        email: email,
        address: event.address,
        latitude: event.latitude,
        longitude: event.longitude,
        imageFile: photoFile,
      );

      if (result['success'] == true) {
        debugPrint('Address submission successful');
        emit(AddressSubmittedState(address: event.address));
      } else {
        debugPrint('Address submission failed: ${result['message']}');
        emit(AddressErrorState(error: 'Something went wrong. Please try again.'));
      }
    } catch (e) {
      debugPrint('Error submitting address: $e');
      emit(AddressErrorState(error: 'Something went wrong. Please try again.'));
    }
  }

  Future<void> _onDetectLocation(
      DetectLocationEvent event, Emitter<AddressState> emit) async {
    try {
      debugPrint('AddressBloc: Detecting current location...');
      emit(AddressLoadingState());

      final locationData = await _locationService.getCurrentLocationAndAddress();

      if (locationData != null) {
        debugPrint('Location detected successfully');
        debugPrint('Latitude: ${locationData['latitude']}');
        debugPrint('Longitude: ${locationData['longitude']}');
        debugPrint('Address: ${locationData['address']}');

        emit(LocationDetectedState(
          location: locationData['address'],
          latitude: locationData['latitude'],
          longitude: locationData['longitude'],
        ));
      } else {
        debugPrint('Failed to detect location');
        emit(AddressErrorState(error: 'Could not detect location. Please enable location services.'));
      }
    } catch (e) {
      debugPrint('Error detecting location: $e');
      emit(AddressErrorState(error: 'Error detecting location. Please try again.'));
    }
  }
}
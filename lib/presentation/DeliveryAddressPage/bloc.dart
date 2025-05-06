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
    on<SelectPlaceEvent>(_onSelectPlace);
  }

  Future<void> _onSubmitAddress(
      SubmitAddressEvent event, Emitter<AddressState> emit) async {
    try {
      debugPrint('AddressBloc: Starting address submission...');
      debugPrint('AddressBloc: Address: ${event.address}');
      debugPrint('AddressBloc: Latitude: ${event.latitude}');
      debugPrint('AddressBloc: Longitude: ${event.longitude}');
      
      emit(AddressLoadingState());

      // Get saved data
      final token = await TokenService.getToken();
      final profileData = await ProfileService.getProfileData();
      final prefs = await SharedPreferences.getInstance();
      final mobile = prefs.getString('user_phone');

      debugPrint('AddressBloc: Retrieved token: ${token != null ? "Found" : "Not found"}');
      debugPrint('AddressBloc: Retrieved mobile: $mobile');
      debugPrint('AddressBloc: Retrieved profile data: $profileData');

      if (token == null || mobile == null) {
        debugPrint('AddressBloc: Missing required data: token or mobile');
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

      debugPrint('AddressBloc: Submitting profile update with:');
      debugPrint('AddressBloc: Name: $name');
      debugPrint('AddressBloc: Email: $email');
      debugPrint('AddressBloc: Mobile: $cleanMobile');
      debugPrint('AddressBloc: Address: ${event.address}');
      debugPrint('AddressBloc: Latitude: ${event.latitude}');
      debugPrint('AddressBloc: Longitude: ${event.longitude}');
      debugPrint('AddressBloc: Has photo: ${photoFile != null}');

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
        debugPrint('AddressBloc: Address submission successful');
        
        // Also save the address to local storage for future use
        await ProfileService.saveProfileData(
          name: name,
          email: email,
          photo: photoFile,
          address: event.address,
          latitude: event.latitude,
          longitude: event.longitude,
        );
        
        emit(AddressSubmittedState(address: event.address));
      } else {
        debugPrint('AddressBloc: Address submission failed: ${result['message']}');
        emit(AddressErrorState(error: 'Something went wrong. Please try again.'));
      }
    } catch (e) {
      debugPrint('AddressBloc: Error submitting address: $e');
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
        debugPrint('AddressBloc: Location detected successfully');
        debugPrint('AddressBloc: Latitude: ${locationData['latitude']}');
        debugPrint('AddressBloc: Longitude: ${locationData['longitude']}');
        debugPrint('AddressBloc: Address: ${locationData['address']}');

        emit(LocationDetectedState(
          location: locationData['address'],
          latitude: locationData['latitude'],
          longitude: locationData['longitude'],
        ));
      } else {
        debugPrint('AddressBloc: Failed to detect location');
        emit(AddressErrorState(error: 'Could not detect location. Please enable location services.'));
      }
    } catch (e) {
      debugPrint('AddressBloc: Error detecting location: $e');
      emit(AddressErrorState(error: 'Error detecting location. Please try again.'));
    }
  }
  
  Future<void> _onSelectPlace(
      SelectPlaceEvent event, Emitter<AddressState> emit) async {
    try {
      debugPrint('AddressBloc: Getting coordinates for place ID: ${event.placeId}');
      emit(AddressLoadingState());
      
      // Get coordinates from the Google Places API
      final placeData = await _locationService.getCoordinatesFromPlace(event.placeId);
      
      if (placeData != null) {
        debugPrint('AddressBloc: Place coordinates retrieved successfully');
        debugPrint('AddressBloc: Latitude: ${placeData['latitude']}');
        debugPrint('AddressBloc: Longitude: ${placeData['longitude']}');
        debugPrint('AddressBloc: Address: ${placeData['address']}');
        
        emit(LocationDetectedState(
          location: placeData['address'],
          latitude: placeData['latitude'],
          longitude: placeData['longitude'],
        ));
      } else {
        debugPrint('AddressBloc: Failed to get place coordinates');
        emit(AddressErrorState(error: 'Could not get coordinates for the selected place.'));
      }
    } catch (e) {
      debugPrint('AddressBloc: Error getting place coordinates: $e');
      emit(AddressErrorState(error: 'Error getting coordinates. Please try again.'));
    }
  }
}
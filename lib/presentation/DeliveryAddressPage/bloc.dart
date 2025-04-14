import 'package:flutter_bloc/flutter_bloc.dart';
import 'event.dart';
import 'state.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:developer' as developer;

class AddressBloc extends Bloc<AddressEvent, AddressState> {
  AddressBloc() : super(AddressInitialState()) {
    on<SubmitAddressEvent>(_onSubmitAddress);
    on<DetectLocationEvent>(_onDetectLocation);
  }

  void _onSubmitAddress(
      SubmitAddressEvent event, Emitter<AddressState> emit) async {
    try {
      developer.log('Submitting address: ${event.address}');
      emit(AddressLoadingState());

      // Here you would typically make an API call to validate or process the address
      // For this example, we'll just simulate a delay
      await Future.delayed(Duration(seconds: 1));

      // Success state
      developer.log('Address submitted successfully: ${event.address}');
      emit(AddressSubmittedState(address: event.address));
    } catch (e) {
      developer.log('Error submitting address: ${e.toString()}', error: e);
      emit(AddressErrorState(error: e.toString()));
    }
  }

  void _onDetectLocation(
      DetectLocationEvent event, Emitter<AddressState> emit) async {
    try {
      developer.log('Detecting current location');
      emit(AddressLoadingState());

      // Request location permission
      developer.log('Checking location permission');
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        developer.log('Location permission denied, requesting permission');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          developer.log('Location permission denied after request');
          emit(AddressErrorState(error: 'Location permissions are denied'));
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        developer.log('Location permission permanently denied');
        emit(AddressErrorState(
            error:
                'Location permissions are permanently denied, we cannot request permissions.'));
        return;
      }

      // Get current position
      developer.log('Getting current position');
      Position position = await Geolocator.getCurrentPosition();
      String locationString = "${position.latitude}, ${position.longitude}";
      developer.log('Current location detected: $locationString');

      // Here you would typically use a geocoding service to convert coordinates to address
      // For this example, we'll just use the coordinates

      emit(LocationDetectedState(location: locationString));
    } catch (e) {
      developer.log('Error detecting location: ${e.toString()}', error: e);
      emit(AddressErrorState(error: e.toString()));
    }
  }
}

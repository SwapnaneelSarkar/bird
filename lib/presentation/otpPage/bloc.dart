// lib/presentation/screens/otp/bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'event.dart';
import 'state.dart';

class OtpBloc extends Bloc<OtpEvent, OtpState> {
  OtpBloc() : super(OtpInitialState()) {
    on<OtpChangedEvent>((event, emit) {
      if (event.otp.length == 6) {
        emit(OtpValidState(otp: event.otp));
      }
    });

    on<VerifyOtpEvent>((event, emit) async {
      emit(OtpVerificationLoadingState());
      await Future.delayed(Duration(seconds: 1)); // mock delay
      emit(OtpVerificationSuccessState(otp: event.otp));
    });

    on<ResendOtpEvent>((event, emit) {
      emit(OtpResentState());
    });
  }
}

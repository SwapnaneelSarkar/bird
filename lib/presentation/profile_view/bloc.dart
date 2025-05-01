import 'package:flutter_bloc/flutter_bloc.dart';
import 'event.dart';
import 'state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc() : super(ProfileInitial());

  @override
  Stream<ProfileState> mapEventToState(ProfileEvent event) async* {
    if (event is LogoutRequested) {
      yield ProfileLoggingOut();
      await Future.delayed(const Duration(seconds: 1));
      yield ProfileLoggedOut();
    }
  }
}

abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final Map<String, dynamic> userData;
  final List<Map<String, dynamic>> orderHistory;
  
  ProfileLoaded({
    required this.userData,
    this.orderHistory = const [],
  });
}

class ProfileLoggingOut extends ProfileState {}

class ProfileLoggedOut extends ProfileState {}

class ProfileError extends ProfileState {
  final String message;
  
  ProfileError({required this.message});
}
abstract class SettingsState {}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final Map<String, dynamic> userData;
  
  SettingsLoaded({required this.userData});
}

class SettingsUpdating extends SettingsState {}

class SettingsUpdateSuccess extends SettingsState {
  final String message;
  
  SettingsUpdateSuccess({required this.message});
}

class SettingsDeleting extends SettingsState {}

class SettingsAccountDeleted extends SettingsState {}

class SettingsError extends SettingsState {
  final String message;
  
  SettingsError({required this.message});
}
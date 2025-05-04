class ApiConstants {
  static const String baseUrl = 'https://api.bird.delivery';
  static const String authEndpoint = '/api/user/auth';
  static const String updateUserEndpoint = '/api/user/update-user/';
  
  static String get authUrl => '$baseUrl$authEndpoint';
  static String get updateUserUrl => '$baseUrl$updateUserEndpoint';
}
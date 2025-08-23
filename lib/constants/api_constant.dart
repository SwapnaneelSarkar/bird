class ApiConstants {
  static const String baseUrl = 'https://api.bird.delivery';
  static const String authEndpoint = '/api/user/auth';
  static const String updateUserEndpoint = '/api/user/update-user/';
  static const String placeOrderEndpoint = '/api/user/place-order';
  static const String chatRoomEndpoint = '/api/chat/rooms';
  static const String chatHistoryEndpoint = '/api/chat/history';
  static const String chatMessageEndpoint = '/api/chat/message';
  static const String currentOrdersSSEEndpoint = '/api/user/orders/current/stream';
  
  static String get authUrl => '$baseUrl$authEndpoint';
  static String get updateUserUrl => '$baseUrl$updateUserEndpoint';
  static String get placeOrderUrl => '$baseUrl$placeOrderEndpoint';
  static String getChatRoomUrl(String orderId) => '$baseUrl$chatRoomEndpoint/$orderId';
  static String getChatHistoryUrl(String roomId) => '$baseUrl$chatHistoryEndpoint/$roomId';
  static String get chatMessageUrl => '$baseUrl$chatMessageEndpoint';
  static String get currentOrdersSSEUrl => '$baseUrl$currentOrdersSSEEndpoint';
}
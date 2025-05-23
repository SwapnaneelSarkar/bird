// lib/services/notification_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

// At the top of your notification_service.dart file
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔥 BACKGROUND MESSAGE RECEIVED!');
  print('Message ID: ${message.messageId}');
  print('Notification: ${message.notification?.title} - ${message.notification?.body}');
  print('Data: ${message.data}');
  print('From: ${message.from}');
  print('Message Type: ${message.messageType}');
}
// Top-level function for background message handling

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Navigation context for handling notification clicks
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  Future<void> initialize() async {
    // Request permissions
    await _requestPermissions();
    
    // Initialize local notifications
    await _initializeLocalNotifications();
    
    // Configure Firebase Messaging
    await _configureFirebaseMessaging();
    
    // Get and print the FCM token
    await _printFCMToken();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      // Request iOS permissions
      await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
    }
    
    // Request notification permission for Android 13+
    if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      if (status != PermissionStatus.granted) {
        print('Notification permission denied');
      }
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_notification');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notifications',
      description: 'This channel is used for important notifications.',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // lib/services/notification_service.dart - Add these debug methods

Future<void> _configureFirebaseMessaging() async {
    print('🔧 Configuring Firebase Messaging...');
    
    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    print('✅ Background message handler set');

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🔥 FOREGROUND MESSAGE RECEIVED!');
      print('Message ID: ${message.messageId}');
      print('Notification: ${message.notification?.title} - ${message.notification?.body}');
      print('Data: ${message.data}');
      _handleForegroundMessage(message);
    });

    // Handle notification tap when app is in background but not terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔥 MESSAGE OPENED APP FROM BACKGROUND!');
      print('Message ID: ${message.messageId}');
      print('Data: ${message.data}');
      _handleNotificationClick(message);
    });

    // Handle notification tap when app is terminated
    _handleInitialMessage();
    
    print('✅ Firebase Messaging configuration complete');
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('🎯 Processing foreground message: ${message.messageId}');
    
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    print('Notification object: $notification');
    print('Android notification: $android');

    // Show local notification when app is in foreground
    if (notification != null) {
      print('📱 Showing local notification...');
      await _showLocalNotification(
        title: notification.title ?? 'New Notification',
        body: notification.body ?? '',
        payload: jsonEncode(message.data),
      );
      print('✅ Local notification shown');
    } else {
      print('❌ No notification object found');
    }
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    print('🔔 Creating local notification: $title - $body');
    
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      styleInformation: BigTextStyleInformation(''),
      icon: '@drawable/ic_notification',
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    try {
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );
      print('✅ Local notification display success');
    } catch (e) {
      print('❌ Local notification display error: $e');
    }
  }

  // Add this test method
  Future<void> testLocalNotificationManually() async {
    print('🧪 Testing local notification manually...');
    await _showLocalNotification(
      title: 'Manual Test Notification',
      body: 'This is a direct test of local notifications',
    );
  }
  

  

  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped with payload: ${response.payload}');
    
    if (response.payload != null) {
      final data = jsonDecode(response.payload!);
      _navigateBasedOnData(data);
    }
  }

  Future<void> _handleNotificationClick(RemoteMessage message) async {
    print('Notification clicked: ${message.data}');
    _navigateBasedOnData(message.data);
  }

  Future<void> _handleInitialMessage() async {
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    
    if (initialMessage != null) {
      print('App opened from terminated state via notification: ${initialMessage.data}');
      // Wait a bit for the app to fully initialize
      Future.delayed(const Duration(seconds: 2), () {
        _navigateBasedOnData(initialMessage.data);
      });
    }
  }

  void _navigateBasedOnData(Map<String, dynamic> data) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    // Handle navigation based on notification data
    if (data.containsKey('screen')) {
      final screen = data['screen'];
      switch (screen) {
        case 'profile':
          Navigator.pushNamed(context, '/profile');
          break;
        case 'restaurant':
          final restaurantId = data['restaurantId'];
          Navigator.pushNamed(context, '/restaurant', arguments: restaurantId);
          break;
        case 'orders':
          Navigator.pushNamed(context, '/orders');
          break;
        default:
          Navigator.pushNamed(context, '/home');
      }
    }
  }

  Future<void> _printFCMToken() async {
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');
    
    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print('FCM Token refreshed: $newToken');
      // Send the new token to your server
      _sendTokenToServer(newToken);
    });
    
    if (token != null) {
      _sendTokenToServer(token);
    }
  }

  Future<void> _sendTokenToServer(String token) async {
    // TODO: Implement your server API call to save the token
    // This is where you would send the token to your backend
    print('TODO: Send token to server: $token');
  }

  // Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('Subscribed to topic: $topic');
  }

  // Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('Unsubscribed from topic: $topic');
  }

  // Get current FCM token
  Future<String?> getCurrentToken() async {
    return await _firebaseMessaging.getToken();
  }

  // Delete FCM token (useful for logout)
  Future<void> deleteToken() async {
    await _firebaseMessaging.deleteToken();
    print('FCM token deleted');
  }
}
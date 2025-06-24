// lib/services/notification_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constant.dart';
import '../utils/timezone_utils.dart';

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

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Navigation context for handling notification clicks
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  // SharedPreferences keys for tracking permission state
  static const String _permissionRequestedKey = 'notification_permission_requested';
  static const String _permissionGrantedKey = 'notification_permission_granted';
  
  Future<void> initialize() async {
    print('🔧 Initializing NotificationService...');
    
    // Check and request permissions only if needed
    await _checkAndRequestPermissions();
    
    // Initialize local notifications
    await _initializeLocalNotifications();
    
    // Configure Firebase Messaging
    await _configureFirebaseMessaging();
    
    // Get and print the FCM token
    await _printFCMToken();
    
    print('✅ NotificationService initialization complete');
  }

  Future<void> _checkAndRequestPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if we've already handled permissions
      final hasRequestedBefore = prefs.getBool(_permissionRequestedKey) ?? false;
      final wasGrantedBefore = prefs.getBool(_permissionGrantedKey) ?? false;
      
      print('📱 Permission status - Requested before: $hasRequestedBefore, Granted before: $wasGrantedBefore');
      
      if (Platform.isIOS) {
        // Check current iOS permission status
        final settings = await _firebaseMessaging.getNotificationSettings();
        print('📱 iOS current authorization status: ${settings.authorizationStatus}');
        
        if (settings.authorizationStatus == AuthorizationStatus.notDetermined || 
            (!hasRequestedBefore && settings.authorizationStatus == AuthorizationStatus.denied)) {
          
          print('📱 Requesting iOS notification permissions...');
          final newSettings = await _firebaseMessaging.requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );
          
          // Save permission state
          await prefs.setBool(_permissionRequestedKey, true);
          final isGranted = newSettings.authorizationStatus == AuthorizationStatus.authorized ||
                           newSettings.authorizationStatus == AuthorizationStatus.provisional;
          await prefs.setBool(_permissionGrantedKey, isGranted);
          
          print('📱 iOS permission result: ${newSettings.authorizationStatus}');
        } else {
          print('📱 iOS permissions already handled - Status: ${settings.authorizationStatus}');
        }
      }
      
      if (Platform.isAndroid) {
        // Check current Android permission status
        final currentStatus = await Permission.notification.status;
        print('📱 Android current permission status: $currentStatus');
        
        // Only request if permission is not determined and we haven't requested before
        if (currentStatus.isDenied && !hasRequestedBefore) {
          print('📱 Requesting Android notification permissions...');
          final newStatus = await Permission.notification.request();
          
          // Save permission state
          await prefs.setBool(_permissionRequestedKey, true);
          await prefs.setBool(_permissionGrantedKey, newStatus.isGranted);
          
          print('📱 Android permission result: $newStatus');
          
          if (newStatus.isDenied) {
            print('⚠️ Android notification permission denied');
          }
        } else if (currentStatus.isPermanentlyDenied) {
          print('⚠️ Android notification permission permanently denied');
          // Optionally show dialog to open app settings
          _showPermissionDeniedDialog();
        } else {
          print('📱 Android permissions already handled - Status: $currentStatus');
        }
      }
    } catch (e) {
      print('❌ Error checking/requesting permissions: $e');
    }
  }
  
  void _showPermissionDeniedDialog() {
    final context = navigatorKey.currentContext;
    if (context != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Notification Permission'),
            content: const Text(
              'Notifications are disabled. To receive updates about your orders, please enable notifications in your device settings.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Later'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
                child: const Text('Settings'),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> _initializeLocalNotifications() async {
    print('🔧 Initializing local notifications...');
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_notification');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false, // Don't request again here
      requestBadgePermission: false, // Don't request again here
      requestSoundPermission: false, // Don't request again here
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
    
    print('✅ Local notifications initialized');
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
    
    print('✅ Android notification channels created');
  }

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
        TimezoneUtils.getCurrentTimeIST().millisecondsSinceEpoch ~/ 1000,
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

  // Test method for manual notification testing
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

  Future<void> _sendTokenToServer(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      final authToken = prefs.getString('auth_token');
      
      // Only send if we have both userId and authToken
      if (userId != null && authToken != null) {
        final response = await http.post(
          Uri.parse('${ApiConstants.baseUrl}/api/user/register-device-token'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $authToken',
          },
          body: jsonEncode({
            'userId': userId,
            'token': token,
          }),
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          if (responseData['status'] == true) {
            print('✅ Device token registered successfully');
            // Save that we've registered this token
            await prefs.setString('registered_fcm_token', token);
          } else {
            print('❌ Failed to register device token: ${responseData['message']}');
          }
        } else {
          print('❌ Failed to register device token: HTTP ${response.statusCode}');
        }
      } else {
        print('⚠️ Cannot register device token: Missing userId or authToken');
      }
    } catch (e) {
      print('❌ Error registering device token: $e');
    }
  }

  // Method to check if token needs to be registered
  Future<bool> _shouldRegisterToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final registeredToken = prefs.getString('registered_fcm_token');
    return registeredToken != token;
  }

  Future<void> _printFCMToken() async {
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');
    
    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      print('FCM Token refreshed: $newToken');
      // Only send if token has changed
      if (await _shouldRegisterToken(newToken)) {
        await _sendTokenToServer(newToken);
      }
    });
    
    if (token != null) {
      // Only send if token has changed
      if (await _shouldRegisterToken(token)) {
        await _sendTokenToServer(token);
      }
    }
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
  
  // Method to check current permission status (useful for debugging)
  Future<Map<String, dynamic>> getPermissionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final hasRequested = prefs.getBool(_permissionRequestedKey) ?? false;
    final wasGranted = prefs.getBool(_permissionGrantedKey) ?? false;
    
    if (Platform.isIOS) {
      final settings = await _firebaseMessaging.getNotificationSettings();
      return {
        'platform': 'iOS',
        'hasRequestedBefore': hasRequested,
        'wasGrantedBefore': wasGranted,
        'currentStatus': settings.authorizationStatus.toString(),
        'isAuthorized': settings.authorizationStatus == AuthorizationStatus.authorized ||
                       settings.authorizationStatus == AuthorizationStatus.provisional,
      };
    } else {
      final status = await Permission.notification.status;
      return {
        'platform': 'Android',
        'hasRequestedBefore': hasRequested,
        'wasGrantedBefore': wasGranted,
        'currentStatus': status.toString(),
        'isGranted': status.isGranted,
      };
    }
  }
  
  // Method to reset permission tracking (useful for testing)
  Future<void> resetPermissionTracking() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_permissionRequestedKey);
    await prefs.remove(_permissionGrantedKey);
    print('🔄 Permission tracking reset');
  }
}
import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/router/router.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  /// Check if device has internet connectivity
  Future<bool> hasInternetConnection() async {
    try {
      // Check if we can reach the internet
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Show no internet page
  static void showNoInternetPage(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      Routes.noInternet,
      (route) => false,
    );
  }

  /// Check connectivity and show no internet page if needed
  static Future<bool> checkAndHandleConnectivity(BuildContext context) async {
    final hasConnection = await ConnectivityService().hasInternetConnection();
    
    if (!hasConnection) {
      showNoInternetPage(context);
      return false;
    }
    
    return true;
  }

  /// Simple method to check connectivity without showing the page
  static Future<bool> hasConnection() async {
    return await ConnectivityService().hasInternetConnection();
  }
} 
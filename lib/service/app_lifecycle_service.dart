import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'persistent_sse_service.dart';

class AppLifecycleService {
  static final AppLifecycleService _instance = AppLifecycleService._internal();
  factory AppLifecycleService() => _instance;
  AppLifecycleService._internal();

  final PersistentSSEService _persistentSSEService = PersistentSSEService();
  bool _isInitialized = false;

  /// Initialize the app lifecycle service
  /// This should be called once when the app starts
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('🔄 AppLifecycleService: Already initialized');
      return;
    }

    debugPrint('🔄 AppLifecycleService: Initializing app lifecycle service');
    
    // Set up app lifecycle listeners
    _setupAppLifecycleListeners();
    
    _isInitialized = true;
    debugPrint('🔄 AppLifecycleService: Initialization complete');
  }

  void _setupAppLifecycleListeners() {
    // Listen for app lifecycle changes
    SystemChannels.lifecycle.setMessageHandler((msg) async {
      debugPrint('🔄 AppLifecycleService: App lifecycle event: $msg');
      
      switch (msg) {
        case 'AppLifecycleState.paused':
          _handleAppPaused();
          break;
        case 'AppLifecycleState.resumed':
          _handleAppResumed();
          break;
        case 'AppLifecycleState.detached':
          _handleAppDetached();
          break;
        case 'AppLifecycleState.inactive':
          _handleAppInactive();
          break;
      }
      
      return null;
    });
  }

  void _handleAppPaused() {
    debugPrint('🔄 AppLifecycleService: App paused - maintaining SSE connection');
    // Keep the SSE connection alive when app is paused
    // This allows real-time updates even when app is in background
  }

  void _handleAppResumed() {
    debugPrint('🔄 AppLifecycleService: App resumed - checking SSE connection');
    // Check if SSE connection is still active and reconnect if needed
    _checkAndReconnectSSE();
  }

  void _handleAppDetached() {
    debugPrint('🔄 AppLifecycleService: App detached - disconnecting SSE');
    // App is being terminated, disconnect SSE
    _persistentSSEService.disconnect();
  }

  void _handleAppInactive() {
    debugPrint('🔄 AppLifecycleService: App inactive - maintaining SSE connection');
    // Keep the SSE connection alive when app is inactive
  }

  Future<void> _checkAndReconnectSSE() async {
    if (_persistentSSEService.hasValidToken && !_persistentSSEService.isConnected) {
      debugPrint('🔄 AppLifecycleService: SSE not connected, attempting reconnection');
      await _persistentSSEService.connect(_persistentSSEService.currentToken!);
    } else {
      debugPrint('🔄 AppLifecycleService: SSE connection status - Connected: ${_persistentSSEService.isConnected}, HasToken: ${_persistentSSEService.hasValidToken}');
    }
  }

  /// Connect to SSE with the provided token
  Future<void> connectToSSE(String token) async {
    debugPrint('🔄 AppLifecycleService: Connecting to SSE with token');
    await _persistentSSEService.connect(token);
  }

  /// Update the token
  Future<void> updateToken(String newToken) async {
    debugPrint('🔄 AppLifecycleService: Updating token');
    await _persistentSSEService.updateToken(newToken);
  }

  /// Disconnect from SSE
  Future<void> disconnectFromSSE() async {
    debugPrint('🔄 AppLifecycleService: Disconnecting from SSE');
    await _persistentSSEService.disconnect();
  }

  /// Get the persistent SSE service
  PersistentSSEService get persistentSSEService => _persistentSSEService;

  /// Dispose the service
  void dispose() {
    debugPrint('🔄 AppLifecycleService: Disposing app lifecycle service');
    _persistentSSEService.dispose();
    _isInitialized = false;
    debugPrint('🔄 AppLifecycleService: Disposed successfully');
  }
} 
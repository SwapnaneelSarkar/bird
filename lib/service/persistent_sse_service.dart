import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../constants/api_constant.dart';
import 'current_orders_sse_service.dart';

class PersistentSSEService {
  static final PersistentSSEService _instance = PersistentSSEService._internal();
  factory PersistentSSEService() => _instance;
  PersistentSSEService._internal();

  final CurrentOrdersSSEService _currentOrdersService = CurrentOrdersSSEService();
  String? _currentToken;
  bool _isInitialized = false;
  Timer? _reconnectionTimer;
  int _reconnectionAttempts = 0;
  static const int _maxReconnectionAttempts = 5;
  static const Duration _reconnectionDelay = Duration(seconds: 5);

  // Getters
  Stream<CurrentOrdersUpdate> get currentOrdersStream => _currentOrdersService.ordersStream;
  bool get isConnected => _currentOrdersService.isConnected;
  bool get isInitialized => _isInitialized;

  /// Initialize the persistent SSE service
  /// This should be called once when the app starts
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('🔄 PersistentSSEService: Already initialized');
      return;
    }

    debugPrint('🔄 PersistentSSEService: Initializing persistent SSE service');
    _isInitialized = true;
    
    // Set up automatic reconnection
    _setupReconnectionListener();
    
    debugPrint('🔄 PersistentSSEService: Initialization complete');
  }

  /// Connect to SSE with the provided token
  /// This will maintain the connection until disconnect() is called
  Future<void> connect(String token) async {
    if (!_isInitialized) {
      debugPrint('🔄 PersistentSSEService: Service not initialized, initializing first');
      await initialize();
    }

    if (_currentToken == token && _currentOrdersService.isConnected) {
      debugPrint('🔄 PersistentSSEService: Already connected with same token');
      return;
    }

    debugPrint('🔄 PersistentSSEService: Connecting with new token');
    _currentToken = token;
    _reconnectionAttempts = 0;
    
    await _connectToSSE();
  }

  /// Disconnect from SSE
  /// This will stop all connections and reconnection attempts
  Future<void> disconnect() async {
    debugPrint('🔄 PersistentSSEService: Disconnecting persistent SSE service');
    
    _currentToken = null;
    _reconnectionAttempts = 0;
    _reconnectionTimer?.cancel();
    _reconnectionTimer = null;
    
    await _currentOrdersService.disconnect();
    
    debugPrint('🔄 PersistentSSEService: Disconnected successfully');
  }

  /// Update the token and reconnect if necessary
  Future<void> updateToken(String newToken) async {
    if (_currentToken != newToken) {
      debugPrint('🔄 PersistentSSEService: Token updated, reconnecting');
      await connect(newToken);
    }
  }

  /// Check if we have a valid token
  bool get hasValidToken => _currentToken != null && _currentToken!.isNotEmpty;

  /// Get the current token
  String? get currentToken => _currentToken;

  Future<void> _connectToSSE() async {
    if (_currentToken == null || _currentToken!.isEmpty) {
      debugPrint('🔄 PersistentSSEService: No valid token available for connection');
      return;
    }

    try {
      debugPrint('🔄 PersistentSSEService: Attempting to connect to SSE (attempt ${_reconnectionAttempts + 1})');
      await _currentOrdersService.connect(_currentToken!);
      
      if (_currentOrdersService.isConnected) {
        debugPrint('🔄 PersistentSSEService: Successfully connected to SSE');
        _reconnectionAttempts = 0; // Reset reconnection attempts on successful connection
      } else {
        debugPrint('🔄 PersistentSSEService: Failed to connect to SSE');
        _scheduleReconnection();
      }
    } catch (e) {
      debugPrint('❌ PersistentSSEService: Error connecting to SSE: $e');
      _scheduleReconnection();
    }
  }

  void _setupReconnectionListener() {
    // Listen for disconnections and automatically reconnect
    _currentOrdersService.ordersStream.listen(
      (update) {
        // Connection is working, reset reconnection attempts
        _reconnectionAttempts = 0;
      },
      onError: (error) {
        debugPrint('❌ PersistentSSEService: SSE stream error, scheduling reconnection: $error');
        _scheduleReconnection();
      },
    );
  }

  void _scheduleReconnection() {
    if (_currentToken == null || _currentToken!.isEmpty) {
      debugPrint('🔄 PersistentSSEService: No token available, skipping reconnection');
      return;
    }

    if (_reconnectionAttempts >= _maxReconnectionAttempts) {
      debugPrint('🔄 PersistentSSEService: Max reconnection attempts reached, stopping reconnection');
      return;
    }

    _reconnectionTimer?.cancel();
    _reconnectionTimer = Timer(_reconnectionDelay, () async {
      _reconnectionAttempts++;
      debugPrint('🔄 PersistentSSEService: Attempting reconnection ${_reconnectionAttempts}/${_maxReconnectionAttempts}');
      await _connectToSSE();
    });
  }

  /// Dispose the service
  /// This should be called when the app is closing
  void dispose() {
    debugPrint('🔄 PersistentSSEService: Disposing persistent SSE service');
    _reconnectionTimer?.cancel();
    _currentOrdersService.dispose();
    _isInitialized = false;
    debugPrint('🔄 PersistentSSEService: Disposed successfully');
  }
} 
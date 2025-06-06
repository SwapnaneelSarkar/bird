import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constant.dart';
import '../service/token_service.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentRoomId;
  bool _isPollingEnabled = true; // Polling is primary method
  
  // Stream controllers for different events
  final StreamController<Map<String, dynamic>> _messageStreamController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionStreamController = 
      StreamController<bool>.broadcast();
  final StreamController<String> _errorStreamController = 
      StreamController<String>.broadcast();

  // Getters for streams
  Stream<Map<String, dynamic>> get messageStream => _messageStreamController.stream;
  Stream<bool> get connectionStream => _connectionStreamController.stream;
  Stream<String> get errorStream => _errorStreamController.stream;
  
  bool get isConnected => _isConnected;
  String? get currentRoomId => _currentRoomId;
  bool get isPollingEnabled => _isPollingEnabled;

  Future<bool> connect() async {
    debugPrint('SocketService: Attempting to connect (polling priority mode)...');
    
    try {
      final token = await TokenService.getToken();
      if (token == null) {
        debugPrint('SocketService: No auth token available');
        _errorStreamController.add('Authentication required');
        return false;
      }

      // Try socket connection but don't fail if it doesn't work
      try {
        _socket = IO.io(
          ApiConstants.baseUrl,
          IO.OptionBuilder()
              .setTransports(['websocket'])
              .disableAutoConnect()
              .setExtraHeaders({'Authorization': 'Bearer $token'})
              .enableReconnection()
              .setReconnectionAttempts(3) // Reduced attempts
              .setReconnectionDelay(3000)
              .setTimeout(5000) // Shorter timeout
              .build(),
        );

        _setupEventListeners();
        _socket!.connect();
        
        // Wait briefly for connection, but don't block
        Timer(const Duration(seconds: 3), () {
          if (_socket?.connected == true) {
            debugPrint('SocketService: Socket connected as backup');
            _isConnected = true;
            _connectionStreamController.add(true);
            
            if (_currentRoomId != null) {
              joinRoom(_currentRoomId!);
            }
          } else {
            debugPrint('SocketService: Socket connection failed/timeout, using polling only');
            _isConnected = false;
            _connectionStreamController.add(false);
          }
        });
        
        // Return true immediately since we're using polling as primary
        return true;
        
      } catch (e) {
        debugPrint('SocketService: Socket connection failed: $e, using polling only');
        _isConnected = false;
        _connectionStreamController.add(false);
        return true; // Still return true because polling works
      }
      
    } catch (e) {
      debugPrint('SocketService: General connection error: $e');
      _errorStreamController.add('Connection failed: $e');
      return false;
    }
  }

  void _setupEventListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      debugPrint('SocketService: Socket connected successfully (backup method)');
      _isConnected = true;
      _connectionStreamController.add(true);
      
      // Rejoin room if we were in one
      if (_currentRoomId != null) {
        joinRoom(_currentRoomId!);
      }
    });

    _socket!.onDisconnect((_) {
      debugPrint('SocketService: Socket disconnected (falling back to polling only)');
      _isConnected = false;
      _connectionStreamController.add(false);
    });

    _socket!.onConnectError((error) {
      debugPrint('SocketService: Socket connection error: $error (polling continues)');
      _isConnected = false;
    });

    _socket!.onError((error) {
      debugPrint('SocketService: Socket error: $error (polling continues)');
    });

    // Listen for socket messages (backup method)
    final messageEvents = [
      'new-message',
      'message-sent',
      'message-delivered',
      'message',
      'chat-message',
      'receive-message'
    ];

    for (final eventName in messageEvents) {
      _socket!.on(eventName, (data) {
        debugPrint('SocketService: Received $eventName via socket (backup): $data');
        try {
          Map<String, dynamic> messageData;
          
          if (data is Map<String, dynamic>) {
            messageData = data;
          } else if (data is List && data.isNotEmpty && data[0] is Map<String, dynamic>) {
            messageData = data[0] as Map<String, dynamic>;
          } else {
            debugPrint('SocketService: Unexpected socket data format for $eventName: $data');
            return;
          }
          
          // Only broadcast socket messages if polling is having issues
          if (messageData.containsKey('_id') || 
              messageData.containsKey('id') || 
              messageData.containsKey('content')) {
            debugPrint('SocketService: Broadcasting socket message as backup');
            _messageStreamController.add(messageData);
          }
        } catch (e) {
          debugPrint('SocketService: Error parsing socket $eventName data: $e');
        }
      });
    }

    // Listen for room events
    _socket!.on('room-joined', (data) {
      debugPrint('SocketService: Joined room via socket: $data');
    });

    _socket!.on('room-left', (data) {
      debugPrint('SocketService: Left room via socket: $data');
    });
  }

  void joinRoom(String roomId) {
    _currentRoomId = roomId;
    debugPrint('SocketService: Setting current room to: $roomId');
    
    if (_socket != null && _isConnected) {
      _socket!.emit('join-room', roomId);
      _socket!.emit('joinRoom', roomId);
      _socket!.emit('join_room', roomId);
      debugPrint('SocketService: Joining room via socket: $roomId');
    } else {
      debugPrint('SocketService: Socket not connected, relying on polling for room: $roomId');
    }
  }

  void leaveRoom() {
    if (_socket != null && _isConnected && _currentRoomId != null) {
      _socket!.emit('leave-room', _currentRoomId);
      _socket!.emit('leaveRoom', _currentRoomId);
      _socket!.emit('leave_room', _currentRoomId);
      debugPrint('SocketService: Leaving room via socket: $_currentRoomId');
    }
    _currentRoomId = null;
  }

  bool sendMessage({
    required String roomId,
    required String content,
    String messageType = 'text',
  }) {
    final messageData = {
      'roomId': roomId,
      'content': content,
      'messageType': messageType,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    // Try socket first if connected
    if (_socket != null && _isConnected) {
      _socket!.emit('send-message', messageData);
      _socket!.emit('sendMessage', messageData);
      _socket!.emit('send_message', messageData);
      _socket!.emit('message', messageData);
      debugPrint('SocketService: Sending message via socket: $content');
      return true;
    } else {
      debugPrint('SocketService: Socket not available, message will be sent via HTTP API');
      return false;
    }
  }

  void enablePolling() {
    _isPollingEnabled = true;
    debugPrint('SocketService: Polling enabled');
  }

  void disablePolling() {
    _isPollingEnabled = false;
    debugPrint('SocketService: Polling disabled');
  }

  void disconnect() {
    debugPrint('SocketService: Disconnecting...');
    
    if (_currentRoomId != null) {
      leaveRoom();
    }
    
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
    
    _isConnected = false;
    _currentRoomId = null;
    _connectionStreamController.add(false);
  }

  void dispose() {
    disconnect();
    _messageStreamController.close();
    _connectionStreamController.close();
    _errorStreamController.close();
  }
}
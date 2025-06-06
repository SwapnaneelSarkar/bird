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

  Future<bool> connect() async {
    if (_socket != null && _socket!.connected) {
      debugPrint('SocketService: Already connected');
      return true;
    }

    try {
      debugPrint('SocketService: Attempting to connect...');
      
      final token = await TokenService.getToken();
      if (token == null) {
        debugPrint('SocketService: No auth token available');
        _errorStreamController.add('Authentication required');
        return false;
      }

      _socket = IO.io(
        ApiConstants.baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .disableAutoConnect()
            .setExtraHeaders({'Authorization': 'Bearer $token'})
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(2000)
            .build(),
      );

      _setupEventListeners();
      _socket!.connect();
      
      // Wait for connection with timeout
      final completer = Completer<bool>();
      Timer? timeoutTimer;
      
      final connectionSub = connectionStream.listen((connected) {
        if (connected && !completer.isCompleted) {
          timeoutTimer?.cancel();
          completer.complete(true);
        }
      });
      
      final errorSub = errorStream.listen((error) {
        if (!completer.isCompleted) {
          timeoutTimer?.cancel();
          completer.complete(false);
        }
      });
      
      timeoutTimer = Timer(const Duration(seconds: 10), () {
        if (!completer.isCompleted) {
          debugPrint('SocketService: Connection timeout');
          completer.complete(false);
        }
      });
      
      final result = await completer.future;
      
      connectionSub.cancel();
      errorSub.cancel();
      timeoutTimer?.cancel();
      
      return result;
      
    } catch (e) {
      debugPrint('SocketService: Connection error: $e');
      _errorStreamController.add('Connection failed: $e');
      return false;
    }
  }

  void _setupEventListeners() {
    if (_socket == null) return;

    _socket!.onConnect((_) {
      debugPrint('SocketService: Connected successfully');
      _isConnected = true;
      _connectionStreamController.add(true);
      
      // Rejoin room if we were in one
      if (_currentRoomId != null) {
        joinRoom(_currentRoomId!);
      }
    });

    _socket!.onDisconnect((_) {
      debugPrint('SocketService: Disconnected');
      _isConnected = false;
      _connectionStreamController.add(false);
    });

    _socket!.onConnectError((error) {
      debugPrint('SocketService: Connection error: $error');
      _isConnected = false;
      _errorStreamController.add('Connection error: $error');
    });

    _socket!.onError((error) {
      debugPrint('SocketService: Socket error: $error');
      _errorStreamController.add('Socket error: $error');
    });

    // ENHANCED: Listen for all possible message events
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
        debugPrint('SocketService: Received $eventName event: $data');
        try {
          Map<String, dynamic> messageData;
          
          if (data is Map<String, dynamic>) {
            messageData = data;
          } else if (data is List && data.isNotEmpty && data[0] is Map<String, dynamic>) {
            messageData = data[0] as Map<String, dynamic>;
          } else {
            debugPrint('SocketService: Unexpected data format for $eventName: $data');
            return;
          }
          
          // Ensure we have the required fields for a message
          if (messageData.containsKey('_id') || 
              messageData.containsKey('id') || 
              messageData.containsKey('content')) {
            debugPrint('SocketService: Broadcasting message from $eventName');
            _messageStreamController.add(messageData);
          } else {
            debugPrint('SocketService: Invalid message format from $eventName: $messageData');
          }
        } catch (e) {
          debugPrint('SocketService: Error parsing $eventName data: $e');
        }
      });
    }

    // Listen for room events
    _socket!.on('room-joined', (data) {
      debugPrint('SocketService: Joined room: $data');
    });

    _socket!.on('room-left', (data) {
      debugPrint('SocketService: Left room: $data');
    });
    
    // Listen for typing indicators (optional)
    _socket!.on('user-typing', (data) {
      debugPrint('SocketService: User typing: $data');
    });
    
    // Listen for connection events
    _socket!.on('connect', (_) {
      debugPrint('SocketService: Socket connected event received');
    });
    
    _socket!.on('disconnect', (reason) {
      debugPrint('SocketService: Socket disconnected event received: $reason');
    });
  }

  void joinRoom(String roomId) {
    if (_socket != null && _isConnected) {
      _currentRoomId = roomId;
      _socket!.emit('join-room', roomId);
      debugPrint('SocketService: Joining room: $roomId');
      
      // Also try alternative room join event names
      _socket!.emit('joinRoom', roomId);
      _socket!.emit('join_room', roomId);
    } else {
      debugPrint('SocketService: Cannot join room - not connected');
    }
  }

  void leaveRoom() {
    if (_socket != null && _isConnected && _currentRoomId != null) {
      _socket!.emit('leave-room', _currentRoomId);
      _socket!.emit('leaveRoom', _currentRoomId);
      _socket!.emit('leave_room', _currentRoomId);
      debugPrint('SocketService: Leaving room: $_currentRoomId');
      _currentRoomId = null;
    }
  }

  bool sendMessage({
    required String roomId,
    required String content,
    String messageType = 'text',
  }) {
    if (_socket != null && _isConnected) {
      final messageData = {
        'roomId': roomId,
        'content': content,
        'messageType': messageType,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Try multiple event names for sending messages
      _socket!.emit('send-message', messageData);
      _socket!.emit('sendMessage', messageData);
      _socket!.emit('send_message', messageData);
      _socket!.emit('message', messageData);
      
      debugPrint('SocketService: Sending message via socket: $content');
      return true;
    } else {
      debugPrint('SocketService: Cannot send message - not connected');
      return false;
    }
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
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

  // Listen for new messages
    _socket!.on('new-message', (data) {
      debugPrint('SocketService: Received new message: $data');
      try {
        final messageData = data as Map<String, dynamic>;
        _messageStreamController.add(messageData);
      } catch (e) {
        debugPrint('SocketService: Error parsing message data: $e');
      }
    });

    // Listen for message confirmations
    _socket!.on('message-sent', (data) {
      debugPrint('SocketService: Message sent confirmation: $data');
      try {
        final messageData = data as Map<String, dynamic>;
        _messageStreamController.add(messageData);
      } catch (e) {
        debugPrint('SocketService: Error parsing message confirmation: $e');
      }
    });
    
    // Listen for message delivery confirmations
    _socket!.on('message-delivered', (data) {
      debugPrint('SocketService: Message delivered: $data');
      try {
        final messageData = data as Map<String, dynamic>;
        _messageStreamController.add(messageData);
      } catch (e) {
        debugPrint('SocketService: Error parsing message delivery: $e');
      }
    });

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
    
    // Listen for generic message events
    _socket!.on('message', (data) {
      debugPrint('SocketService: Generic message event: $data');
      try {
        final messageData = data as Map<String, dynamic>;
        _messageStreamController.add(messageData);
      } catch (e) {
        debugPrint('SocketService: Error parsing generic message: $e');
      }
    });
  }

  void joinRoom(String roomId) {
    if (_socket != null && _isConnected) {
      _currentRoomId = roomId;
      _socket!.emit('join-room', roomId);
      debugPrint('SocketService: Joining room: $roomId');
    } else {
      debugPrint('SocketService: Cannot join room - not connected');
    }
  }

  void leaveRoom() {
    if (_socket != null && _isConnected && _currentRoomId != null) {
      _socket!.emit('leave-room', _currentRoomId);
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
      };
      
      _socket!.emit('send-message', messageData);
      debugPrint('SocketService: Sending message: $content');
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
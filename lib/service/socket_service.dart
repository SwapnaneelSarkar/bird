import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/api_constant.dart';
import '../service/token_service.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  // Socket.IO Configuration from document
  static const String wsUrl = 'https://api.bird.delivery/';
  
  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentRoomId;
  String? _currentUserId;
  String? _token;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  Timer? _reconnectTimer;
  
  // Stream controllers for different events
  final StreamController<Map<String, dynamic>> _messageStreamController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<bool> _connectionStreamController = 
      StreamController<bool>.broadcast();
  final StreamController<String> _errorStreamController = 
      StreamController<String>.broadcast();
  final StreamController<Map<String, dynamic>> _readReceiptStreamController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _typingStreamController = 
      StreamController<Map<String, dynamic>>.broadcast();

  // Getters for streams
  Stream<Map<String, dynamic>> get messageStream => _messageStreamController.stream;
  Stream<bool> get connectionStream => _connectionStreamController.stream;
  Stream<String> get errorStream => _errorStreamController.stream;
  Stream<Map<String, dynamic>> get readReceiptStream => _readReceiptStreamController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingStreamController.stream;
  
  bool get isConnected => _isConnected;
  String? get currentRoomId => _currentRoomId;

  Future<bool> connect() async {
    debugPrint('SocketService: Attempting to connect...');
    
    try {
      _token = await TokenService.getToken();
      _currentUserId = await TokenService.getUserId();
      
      if (_token == null || _currentUserId == null) {
        debugPrint('SocketService: No auth token or user ID available');
        _errorStreamController.add('Authentication required');
        return false;
      }

      // Socket.IO initialization for USER app (as per document)
      _socket = IO.io(wsUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
        'query': {
          'userId': _currentUserId,
          'userType': 'user', // USER app sends as 'user'
        },
        'extraHeaders': {
          'Authorization': 'Bearer $_token',
        },
        'timeout': 20000,
        'reconnection': true,
        'reconnectionAttempts': _maxReconnectAttempts,
        'reconnectionDelay': 3000,
      });

      _setupSocketEventHandlers();
      _socket!.connect();
      
      return true;
        
    } catch (e) {
      debugPrint('SocketService: Connection error: $e');
      _errorStreamController.add('Connection failed: $e');
      return false;
    }
  }

  void _setupSocketEventHandlers() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      debugPrint('Socket connected successfully');
      _isConnected = true;
      _reconnectAttempts = 0;
      _connectionStreamController.add(true);
      
      // Auto-rejoin current room
      if (_currentRoomId != null) {
        _socket!.emit('join_room', _currentRoomId);
        debugPrint('Auto-rejoined room: $_currentRoomId');
      }
    });

    _socket!.onDisconnect((_) {
      debugPrint('Socket disconnected');
      _isConnected = false;
      _connectionStreamController.add(false);
      _handleReconnection();
    });

    _socket!.onConnectError((error) {
      debugPrint('Socket connection error: $error');
      _isConnected = false;
      _connectionStreamController.add(false);
      _handleReconnection();
    });

    _socket!.onError((error) {
      debugPrint('Socket error: $error');
      _errorStreamController.add('Socket error: $error');
    });

    // INCOMING EVENTS (Server → Client) as per document

    // 1. receive_message - Handle with better error checking
    _socket!.on('receive_message', (data) {
      _handleReceivedMessage(data);
    });

    // 2. message_read (single message read status)
    _socket!.on('message_read', (data) {
      _handleMessageReadUpdate(data);
    });

    // 3. messages_marked_read (bulk read status)
    _socket!.on('messages_marked_read', (data) {
      _handleMessagesMarkedRead(data);
    });

    // 4. user_joined / user_left
    _socket!.on('user_joined', (data) {
      debugPrint('User joined: $data');
    });

    _socket!.on('user_left', (data) {
      debugPrint('User left: $data');
    });

    // 5. user_typing / user_stop_typing
    _socket!.on('user_typing', (data) {
      _handleTypingStatus(data, true);
    });

    _socket!.on('user_stop_typing', (data) {
      _handleTypingStatus(data, false);
    });
  }

  void _handleReceivedMessage(dynamic data) {
    try {
      debugPrint('SocketService: Raw received message data: $data');
      
      Map<String, dynamic> messageData;
      
      if (data is String) {
        try {
          messageData = jsonDecode(data);
        } catch (e) {
          debugPrint('SocketService: Error parsing JSON string: $e');
          return;
        }
      } else if (data is Map<String, dynamic>) {
        messageData = data;
      } else if (data is List && data.isNotEmpty) {
        // Sometimes socket.io sends arrays
        if (data[0] is Map<String, dynamic>) {
          messageData = data[0] as Map<String, dynamic>;
        } else {
          debugPrint('SocketService: Invalid list data format: $data');
          return;
        }
      } else {
        debugPrint('SocketService: Invalid message data format: $data');
        return;
      }
      
      // Validate required fields with null safety
      if (messageData['content'] == null) {
        debugPrint('SocketService: Message missing content field');
        return;
      }
      
      if (messageData['senderId'] == null) {
        debugPrint('SocketService: Message missing senderId field');
        return;
      }
      
      // Create safe message data with defaults
      final safeMessageData = <String, dynamic>{
        '_id': messageData['_id'] ?? messageData['id'] ?? 'socket_${DateTime.now().millisecondsSinceEpoch}',
        'roomId': messageData['roomId'] ?? '',
        'senderId': messageData['senderId'].toString(),
        'senderType': messageData['senderType'] ?? 'user',
        'content': messageData['content'].toString(),
        'messageType': messageData['messageType'] ?? 'text',
        'readBy': messageData['readBy'] ?? [],
        // Use current time for socket messages to ensure they appear at bottom
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      debugPrint('SocketService: Processed message data: $safeMessageData');
      
      // Skip own messages to avoid duplicates
      if (safeMessageData['senderId'] == _currentUserId) {
        debugPrint('SocketService: Skipping own message to avoid duplicates');
        return;
      }
      
      // Emit to stream for UI updates
      if (!_messageStreamController.isClosed) {
        _messageStreamController.add(safeMessageData);
      }
      
      // Auto mark as read for incoming messages
      if (_currentRoomId != null) {
        markAsReadViaSocket(_currentRoomId!);
      }
      
    } catch (e, stackTrace) {
      debugPrint('SocketService: Error handling received message: $e');
      debugPrint('SocketService: Stack trace: $stackTrace');
      debugPrint('SocketService: Raw data that caused error: $data');
    }
  }

  void _handleMessageReadUpdate(dynamic data) {
    try {
      final readData = data is Map<String, dynamic> ? data : jsonDecode(data.toString());
      debugPrint('SocketService: Message read update: $readData');
      
      if (!_readReceiptStreamController.isClosed) {
        _readReceiptStreamController.add({
          'type': 'single_message_read',
          'data': readData,
        });
      }
    } catch (e) {
      debugPrint('SocketService: Error handling message read update: $e');
    }
  }

  void _handleMessagesMarkedRead(dynamic data) {
    try {
      final readData = data is Map<String, dynamic> ? data : jsonDecode(data.toString());
      debugPrint('SocketService: Messages marked read: $readData');
      
      if (!_readReceiptStreamController.isClosed) {
        _readReceiptStreamController.add({
          'type': 'bulk_messages_read',
          'data': readData,
        });
      }
    } catch (e) {
      debugPrint('SocketService: Error handling messages marked read: $e');
    }
  }

  void _handleTypingStatus(dynamic data, bool isTyping) {
    try {
      final typingData = data is Map<String, dynamic> ? data : jsonDecode(data.toString());
      debugPrint('SocketService: Typing status: $isTyping, data: $typingData');
      
      if (!_typingStreamController.isClosed) {
        _typingStreamController.add({
          'isTyping': isTyping,
          'userId': typingData['userId'] ?? '',
          'userType': typingData['userType'] ?? '',
          'roomId': typingData['roomId'] ?? '',
        });
      }
    } catch (e) {
      debugPrint('SocketService: Error handling typing status: $e');
    }
  }

  void _handleReconnection() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('SocketService: Max reconnection attempts reached');
      return;
    }
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: 3 * (_reconnectAttempts + 1)), () {
      if (!_isConnected) {
        _reconnectAttempts++;
        debugPrint('SocketService: Reconnection attempt $_reconnectAttempts');
        _socket?.connect();
      }
    });
  }

  // OUTGOING EVENTS (Client → Server) as per document

  // 1. join_room
  void joinRoom(String roomId) {
    _currentRoomId = roomId;
    debugPrint('SocketService: Setting current room to: $roomId');
    
    if (_socket != null && _isConnected) {
      _socket!.emit('join_room', roomId);
      debugPrint('SocketService: Joined room via socket: $roomId');
      
      // Auto mark as read when joining room
      markAsReadViaSocket(roomId);
    } else {
      debugPrint('SocketService: Socket not connected, will join room when connected');
    }
  }

  // 2. send_message
  bool sendMessage({
    required String roomId,
    required String content,
    String messageType = 'text',
  }) {
    if (_socket != null && _isConnected) {
      try {
        final messageData = {
          'roomId': roomId,
          'senderId': _currentUserId,
          'senderType': 'user', // USER sends as 'user'
          'content': content,
          'messageType': messageType,
        };
        
        _socket!.emit('send_message', messageData);
        debugPrint('SocketService: Sending message via socket: $content');
        return true;
      } catch (e) {
        debugPrint('SocketService: Error sending message: $e');
        return false;
      }
    } else {
      debugPrint('SocketService: Socket not available for sending message');
      return false;
    }
  }

  // 3. mark_as_read
  void markAsReadViaSocket(String roomId) {
    if (_socket != null && _isConnected && _currentUserId != null) {
      final readData = {
        'roomId': roomId,
        'userId': _currentUserId,
        'userType': 'user', // USER sends as 'user'
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _socket!.emit('mark_as_read', readData);
      debugPrint('SocketService: Marked messages as read via socket for room: $roomId');
    }
  }

  // 4. typing / stop_typing
  void sendTyping(String roomId) {
    if (_socket != null && _isConnected && _currentUserId != null) {
      final typingData = {
        'roomId': roomId,
        'userId': _currentUserId,
        'userType': 'user',
      };
      
      _socket!.emit('typing', typingData);
      debugPrint('SocketService: Sent typing indicator for room: $roomId');
    }
  }

  void sendStopTyping(String roomId) {
    if (_socket != null && _isConnected && _currentUserId != null) {
      final typingData = {
        'roomId': roomId,
        'userId': _currentUserId,
        'userType': 'user',
      };
      
      _socket!.emit('stop_typing', typingData);
      debugPrint('SocketService: Sent stop typing indicator for room: $roomId');
    }
  }

  // 5. leave_room
  void leaveRoom() {
    if (_socket != null && _isConnected && _currentRoomId != null) {
      _socket!.emit('leave_room', _currentRoomId);
      debugPrint('SocketService: Left room via socket: $_currentRoomId');
    }
    _currentRoomId = null;
  }

  void disconnect() {
    debugPrint('SocketService: Disconnecting...');
    
    _reconnectTimer?.cancel();
    
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
    _reconnectAttempts = 0;
    _connectionStreamController.add(false);
  }

  void dispose() {
    disconnect();
    _messageStreamController.close();
    _connectionStreamController.close();
    _errorStreamController.close();
    _readReceiptStreamController.close();
    _typingStreamController.close();
  }
}
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
  static const String baseUrl = 'https://api.bird.delivery/api/';
  static const String wsUrl = 'https://api.bird.delivery/';
  
  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentRoomId;
  String? _currentUserId;
  String? _token;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  Timer? _reconnectTimer;
  
  // Add duplicate detection
  final Set<String> _recentMessageHashes = <String>{};
  static const int _maxRecentHashes = 100;
  
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
    try {
      debugPrint('SocketService: Attempting to connect...');
      
      // Get authentication token
      final token = await TokenService.getToken();
      final userId = await TokenService.getUserId();
      
      if (token == null || userId == null) {
        debugPrint('SocketService: Missing auth credentials');
        _errorStreamController.add('Authentication token or user ID not found');
        return false;
      }
      
      _token = token;
      _currentUserId = userId;
      
      debugPrint('SocketService: Token retrieved: ${token.isNotEmpty ? 'Found' : 'Empty'}');
      debugPrint('SocketService: User ID retrieved: $userId');
      
      // Create socket connection with auth
      _socket = IO.io(
        wsUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(_maxReconnectAttempts)
            .setReconnectionDelay(1000)
            .setReconnectionDelayMax(5000)
            .setTimeout(20000)
            .setQuery({
              'token': token,
              'userId': userId,
              'userType': 'user',
            })
            .build(),
      );
      
      debugPrint('SocketService: Socket created with URL: $wsUrl');
      debugPrint('SocketService: Query parameters: token=${token.isNotEmpty ? 'present' : 'missing'}, userId=$userId, userType=user');
      
      // Setup event handlers
      _setupSocketEventHandlers();
      
      // Connect
      _socket!.connect();
      
      debugPrint('SocketService: Socket connect() called');
      
      // Wait for connection with timeout
      bool connected = false;
      Timer? timeoutTimer;
      
      timeoutTimer = Timer(const Duration(seconds: 10), () {
        if (!connected) {
          debugPrint('SocketService: Connection timeout after 10 seconds');
          _errorStreamController.add('Connection timeout');
        }
      });
      
      // Listen for connection
      _socket!.onConnect((_) {
        connected = true;
        timeoutTimer?.cancel();
        debugPrint('SocketService: Connection established successfully');
      });
      
      // Wait a bit for connection
      await Future.delayed(const Duration(seconds: 2));
      
      return _isConnected;
        
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
      debugPrint('SocketService: Received "receive_message" event with data: $data');
      _handleReceivedMessage(data);
    });

    // 2. message - Alternative event name that might be used
    _socket!.on('message', (data) {
      debugPrint('SocketService: Received "message" event with data: $data');
      _handleReceivedMessage(data);
    });

    // 3. new_message - Another possible event name
    _socket!.on('new_message', (data) {
      debugPrint('SocketService: Received "new_message" event with data: $data');
      _handleReceivedMessage(data);
    });

    // 4. chat_message - Another possible event name
    _socket!.on('chat_message', (data) {
      debugPrint('SocketService: Received "chat_message" event with data: $data');
      _handleReceivedMessage(data);
    });

    // 5. message_read (single message read status)
    _socket!.on('message_read', (data) {
      debugPrint('SocketService: Received "message_read" event with data: $data');
      _handleMessageReadUpdate(data);
    });

    // 6. message_seen (new event for individual message read receipts)
    _socket!.on('message_seen', (data) {
      debugPrint('SocketService: Received "message_seen" event with data: $data');
      _handleMessageSeenUpdate(data);
    });

    // 6.1. message_seen_response (server confirmation of message seen)
    _socket!.on('message_seen_response', (data) {
      debugPrint('SocketService: Received "message_seen_response" event with data: $data');
      _handleMessageSeenUpdate(data);
    });

    // 7. messages_marked_read (bulk read status)
    _socket!.on('messages_marked_read', (data) {
      debugPrint('SocketService: Received "messages_marked_read" event with data: $data');
      _handleMessagesMarkedRead(data);
    });

    // 7.1. mark_as_read (server broadcast when messages are marked as read)
    _socket!.on('mark_as_read', (data) {
      debugPrint('SocketService: Received "mark_as_read" event with data: $data');
      _handleMarkAsReadUpdate(data);
    });

    // 8. user_joined / user_left
    _socket!.on('user_joined', (data) {
      debugPrint('SocketService: Received "user_joined" event with data: $data');
    });

    _socket!.on('user_left', (data) {
      debugPrint('SocketService: Received "user_left" event with data: $data');
    });

    // 9. user_typing / user_stop_typing
    _socket!.on('user_typing', (data) {
      debugPrint('SocketService: 📨 RECEIVED "user_typing" event with data: $data');
      debugPrint('SocketService: Typing event from user: ${data['userId']}, type: ${data['userType']}, room: ${data['roomId']}');
      _handleTypingStatus(data, true);
    });

    _socket!.on('user_stop_typing', (data) {
      debugPrint('SocketService: 📨 RECEIVED "user_stop_typing" event with data: $data');
      debugPrint('SocketService: Stop typing event from user: ${data['userId']}, type: ${data['userType']}, room: ${data['roomId']}');
      _handleTypingStatus(data, false);
    });
  }

  void _handleReceivedMessage(dynamic data) {
    try {
      debugPrint('SocketService: Raw received message data: $data');
      debugPrint('SocketService: Data type: ${data.runtimeType}');
      
      Map<String, dynamic> messageData;
      
      if (data is String) {
        try {
          messageData = jsonDecode(data);
          debugPrint('SocketService: Parsed JSON string successfully');
        } catch (e) {
          debugPrint('SocketService: Error parsing JSON string: $e');
          return;
        }
      } else if (data is Map<String, dynamic>) {
        messageData = data;
        debugPrint('SocketService: Data is already Map<String, dynamic>');
      } else if (data is List && data.isNotEmpty) {
        // Sometimes socket.io sends arrays
        if (data[0] is Map<String, dynamic>) {
          messageData = data[0] as Map<String, dynamic>;
          debugPrint('SocketService: Extracted first element from array');
        } else {
          debugPrint('SocketService: Invalid list data format: $data');
          return;
        }
      } else {
        debugPrint('SocketService: Invalid message data format: $data');
        debugPrint('SocketService: Data type: ${data.runtimeType}');
        return;
      }
      
      debugPrint('SocketService: Parsed messageData: $messageData');
      
      // Validate required fields with null safety
      // Handle both 'content' and 'message' fields for compatibility
      final messageContent = messageData['content'] ?? messageData['message'];
      if (messageContent == null) {
        debugPrint('SocketService: Message missing content/message field');
        debugPrint('SocketService: Available fields: ${messageData.keys.toList()}');
        return;
      }
      
      if (messageData['senderId'] == null) {
        debugPrint('SocketService: Message missing senderId field');
        debugPrint('SocketService: Available fields: ${messageData.keys.toList()}');
        return;
      }
      
      // Create safe message data with defaults
      final safeMessageData = <String, dynamic>{
        '_id': messageData['_id'] ?? messageData['id'] ?? 'socket_${DateTime.now().millisecondsSinceEpoch}',
        'roomId': messageData['roomId'] ?? _currentRoomId ?? '',
        'senderId': messageData['senderId'].toString(),
        'senderType': messageData['senderType'] ?? 'user',
        'content': messageContent.toString(), // Use either content or message field
        'messageType': messageData['messageType'] ?? 'text',
        'readBy': messageData['readBy'] ?? [],
        // Handle timestamp properly - convert string timestamp to DateTime
        'createdAt': _parseTimestamp(messageData['timestamp'] ?? messageData['createdAt']),
      };
      
      debugPrint('SocketService: Processed message data: $safeMessageData');
      debugPrint('SocketService: Current user ID: $_currentUserId');
      debugPrint('SocketService: Message sender ID: ${safeMessageData['senderId']}');
      
      // Skip own messages to avoid duplicates
      if (safeMessageData['senderId'] == _currentUserId) {
        debugPrint('SocketService: Skipping own message to avoid duplicates');
        return;
      }
      
      debugPrint('SocketService: Message is from other user, processing...');
      
      // Create a hash for duplicate detection - use content, sender, and time window
      final messageTime = safeMessageData['createdAt'] as DateTime;
      final timeWindow = messageTime.millisecondsSinceEpoch ~/ 1000; // Round to nearest second
      final messageHash = '${safeMessageData['content']}_${safeMessageData['senderId']}_${safeMessageData['senderType']}_$timeWindow';
      
      // Check if we've recently processed this exact message
      if (_recentMessageHashes.contains(messageHash)) {
        debugPrint('SocketService: Duplicate message detected, skipping: $messageHash');
        return;
      }
      
      // Add to recent hashes and maintain size limit
      _recentMessageHashes.add(messageHash);
      debugPrint('SocketService: Added message hash: $messageHash');
      if (_recentMessageHashes.length > _maxRecentHashes) {
        final removed = _recentMessageHashes.first;
        _recentMessageHashes.remove(removed);
        debugPrint('SocketService: Removed old message hash: $removed');
      }
      
      debugPrint('SocketService: Emitting message to ChatBloc: ${safeMessageData['content']}');
      _messageStreamController.add(safeMessageData);
      
      // CRITICAL: Emit message_seen immediately when message is received (Same as partner app)
      if (_currentRoomId != null && _currentUserId != null) {
        debugPrint('SocketService: Emitting message_seen immediately for received message');
        emitMessageSeen(
          roomId: _currentRoomId!,
          messageId: safeMessageData['_id'] as String,
          content: safeMessageData['content'],
          senderId: safeMessageData['senderId'],
        );
      }
      
      // Auto mark as read for incoming messages
      if (_currentRoomId != null) {
        debugPrint('SocketService: Auto marking as read for incoming message');
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

  void _handleMessageSeenUpdate(dynamic data) {
    try {
      debugPrint('SocketService: Raw message_seen data: $data');
      debugPrint('SocketService: Message_seen data type: ${data.runtimeType}');
      
      Map<String, dynamic> seenData;
      
      if (data is String) {
        try {
          seenData = jsonDecode(data);
          debugPrint('SocketService: Parsed message_seen JSON string successfully');
        } catch (e) {
          debugPrint('SocketService: Error parsing message_seen JSON string: $e');
          return;
        }
      } else if (data is Map<String, dynamic>) {
        seenData = data;
        debugPrint('SocketService: Message_seen data is already Map<String, dynamic>');
      } else {
        debugPrint('SocketService: Invalid message_seen data format: $data');
        return;
      }
      
      debugPrint('SocketService: Processed message_seen data: $seenData');
      
      // Validate required fields
      if (seenData['messageId'] == null) {
        debugPrint('SocketService: Message_seen missing messageId field');
        return;
      }
      
      if (seenData['seenBy'] == null) {
        debugPrint('SocketService: Message_seen missing seenBy field');
        return;
      }
      
      // IMPORTANT: Always emit to read receipt stream, even for own messages
      // This ensures the sender gets notified when their messages are read
      if (!_readReceiptStreamController.isClosed) {
        _readReceiptStreamController.add({
          'type': 'single_message_seen',
          'data': seenData,
        });
        debugPrint('SocketService: Emitted message_seen to read receipt stream');
        debugPrint('SocketService: Message seen by: ${seenData['seenBy']}, Message ID: ${seenData['messageId']}');
      }
    } catch (e) {
      debugPrint('SocketService: Error handling message seen update: $e');
      debugPrint('SocketService: Raw data that caused error: $data');
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

  void _handleMarkAsReadUpdate(dynamic data) {
    try {
      debugPrint('SocketService: Raw mark_as_read data: $data');
      debugPrint('SocketService: Mark_as_read data type: ${data.runtimeType}');
      
      Map<String, dynamic> readData;
      
      if (data is String) {
        try {
          readData = jsonDecode(data);
          debugPrint('SocketService: Parsed mark_as_read JSON string successfully');
        } catch (e) {
          debugPrint('SocketService: Error parsing mark_as_read JSON string: $e');
          return;
        }
      } else if (data is Map<String, dynamic>) {
        readData = data;
        debugPrint('SocketService: Mark_as_read data is already Map<String, dynamic>');
      } else {
        debugPrint('SocketService: Invalid mark_as_read data format: $data');
        return;
      }
      
      debugPrint('SocketService: Processed mark_as_read data: $readData');
      
      if (!_readReceiptStreamController.isClosed) {
        _readReceiptStreamController.add({
          'type': 'bulk_messages_read',
          'data': readData,
        });
        debugPrint('SocketService: Emitted mark_as_read to read receipt stream');
      }
    } catch (e) {
      debugPrint('SocketService: Error handling mark as read update: $e');
      debugPrint('SocketService: Raw data that caused error: $data');
    }
  }

  void _handleTypingStatus(dynamic data, bool isTyping) {
    try {
      final typingData = data is Map<String, dynamic> ? data : jsonDecode(data.toString());
      debugPrint('SocketService: 🔄 PROCESSING typing status: $isTyping, data: $typingData');
      debugPrint('SocketService: Current user ID: $_currentUserId, Typing user ID: ${typingData['userId']}');
      
      // Emit to typing stream for UI updates
      if (!_typingStreamController.isClosed) {
        final typingInfo = {
          'isTyping': isTyping,
          'userId': typingData['userId'] ?? '',
          'userType': typingData['userType'] ?? '',
          'roomId': typingData['roomId'] ?? '',
        };
        _typingStreamController.add(typingInfo);
        debugPrint('SocketService: 📤 Emitted to typing stream: $typingInfo');
      }
      
      // When partner starts typing, mark messages as read
      if (isTyping && typingData['userId'] != _currentUserId) {
        debugPrint('SocketService: 👥 Partner started typing, marking messages as read');
        debugPrint('SocketService: Partner user ID: ${typingData['userId']}, Current user ID: $_currentUserId');
        
        // Emit to read receipt stream to trigger mark as read
        if (!_readReceiptStreamController.isClosed) {
          final readReceiptData = {
            'type': 'partner_typing',
            'data': {
              'userId': typingData['userId'],
              'roomId': typingData['roomId'] ?? _currentRoomId,
              'timestamp': DateTime.now().toIso8601String(),
            },
          };
          _readReceiptStreamController.add(readReceiptData);
          debugPrint('SocketService: 📤 Emitted partner_typing event for user: ${typingData['userId']}');
          debugPrint('SocketService: Read receipt data: $readReceiptData');
        }
      } else if (isTyping && typingData['userId'] == _currentUserId) {
        debugPrint('SocketService: 👤 Own typing event received (from self)');
      } else if (!isTyping) {
        debugPrint('SocketService: 🛑 Stop typing event processed');
      }
    } catch (e) {
      debugPrint('SocketService: ❌ Error handling typing status: $e');
      debugPrint('SocketService: Raw data that caused error: $data');
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
    
    // Clear recent message hashes when joining a new room
    _recentMessageHashes.clear();
    debugPrint('SocketService: Cleared recent message hashes for new room');
    
    if (_socket != null && _isConnected) {
      debugPrint('SocketService: Socket is connected, joining room: $roomId');
      _socket!.emit('join_room', roomId);
      debugPrint('SocketService: Joined room via socket: $roomId');
      
      // Auto mark as read when joining room
      markAsReadViaSocket(roomId);
    } else {
      debugPrint('SocketService: Socket not connected, will join room when connected');
      debugPrint('SocketService: Socket null: ${_socket == null}');
      debugPrint('SocketService: Is connected: $_isConnected');
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

  // 3.1. message_seen (for individual message read receipts)
  void emitMessageSeen({
    required String roomId,
    required String messageId,
    String? content,
    String? senderId,
  }) {
    if (_socket != null && _isConnected && _currentUserId != null) {
      final seenData = {
        'roomId': roomId,
        'messageId': messageId,
        'seenBy': _currentUserId,
        'seenAt': DateTime.now().toIso8601String(),
        'content': content, // Include content for content-based matching
        'senderId': senderId, // Include sender ID for content-based matching
      };
      
      _socket!.emit('message_seen', seenData);
      debugPrint('SocketService: Emitted message_seen for message: $messageId in room: $roomId');
      debugPrint('SocketService: Message_seen data: $seenData');
    } else {
      debugPrint('SocketService: Cannot emit message_seen - socket not connected or missing data');
      debugPrint('SocketService: Socket null: ${_socket == null}, Connected: $_isConnected, User ID: $_currentUserId');
    }
  }

  // 4. typing / stop_typing
  void sendTyping(String roomId) {
    debugPrint('SocketService: 📤 SEND TYPING called for room: $roomId');
    debugPrint('SocketService: Socket null: ${_socket == null}, Connected: $_isConnected, User ID: $_currentUserId');
    
    if (_socket != null && _isConnected && _currentUserId != null) {
      final typingData = {
        'roomId': roomId,
        'userId': _currentUserId,
        'userType': 'user',
      };
      
      _socket!.emit('typing', typingData);
      debugPrint('SocketService: 🚀 SENT TYPING EVENT for room: $roomId, user: $_currentUserId');
      debugPrint('SocketService: Typing data: $typingData');
    } else {
      debugPrint('SocketService: ⚠️ Cannot send typing - Socket null: ${_socket == null}, Connected: $_isConnected, User ID: $_currentUserId');
    }
  }

  void sendStopTyping(String roomId) {
    debugPrint('SocketService: 📤 SEND STOP TYPING called for room: $roomId');
    debugPrint('SocketService: Socket null: ${_socket == null}, Connected: $_isConnected, User ID: $_currentUserId');
    
    if (_socket != null && _isConnected && _currentUserId != null) {
      final typingData = {
        'roomId': roomId,
        'userId': _currentUserId,
        'userType': 'user',
      };
      
      _socket!.emit('stop_typing', typingData);
      debugPrint('SocketService: 🚪 SENT STOP TYPING EVENT for room: $roomId, user: $_currentUserId');
      debugPrint('SocketService: Stop typing data: $typingData');
    } else {
      debugPrint('SocketService: ⚠️ Cannot send stop typing - Socket null: ${_socket == null}, Connected: $_isConnected, User ID: $_currentUserId');
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
    _recentMessageHashes.clear(); // Clear recent message hashes
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

  DateTime _parseTimestamp(dynamic timestamp) {
    try {
      if (timestamp is DateTime) {
        return timestamp;
      } else if (timestamp is String) {
        return DateTime.parse(timestamp);
      } else if (timestamp is num) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
      } else {
        debugPrint('SocketService: Invalid timestamp format, using current time: $timestamp');
        return DateTime.now();
      }
    } catch (e) {
      debugPrint('SocketService: Error parsing timestamp: $e, using current time');
      return DateTime.now();
    }
  }
}
// TODO Implement this library.import 'dart:async';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import '../constants/api_constant.dart';
import '../service/token_service.dart';
import '../models/chat_models.dart';
import '../utils/timezone_utils.dart';

class SocketChatService extends ChangeNotifier {
  // Socket.IO Configuration from document
  static const String baseUrl = 'https://api.bird.delivery/api/';
  static const String wsUrl = 'https://api.bird.delivery/';
  
  IO.Socket? _socket;
  List<ApiChatMessage> _messages = [];
  bool _isConnected = false;
  String? _currentRoomId;
  String? _currentUserId;
  String? _token;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  Timer? _reconnectTimer;
  
  // Stream for real-time message updates
  final StreamController<ApiChatMessage> _messageStreamController = 
      StreamController<ApiChatMessage>.broadcast();
  
  final StreamController<Map<String, dynamic>> _readReceiptStreamController = 
      StreamController<Map<String, dynamic>>.broadcast();
      
  final StreamController<Map<String, dynamic>> _typingStreamController = 
      StreamController<Map<String, dynamic>>.broadcast();
      
  final StreamController<bool> _connectionStreamController = 
      StreamController<bool>.broadcast();
  
  // Getters
  Stream<ApiChatMessage> get messageStream => _messageStreamController.stream;
  Stream<Map<String, dynamic>> get readReceiptStream => _readReceiptStreamController.stream;
  Stream<Map<String, dynamic>> get typingStream => _typingStreamController.stream;
  Stream<bool> get connectionStream => _connectionStreamController.stream;
  
  List<ApiChatMessage> get messages => List.unmodifiable(_messages);
  bool get isConnected => _isConnected;
  String? get currentRoomId => _currentRoomId;
  
  Future<void> connect() async {
    debugPrint('SocketChatService: Attempting to connect...');
    
    try {
      _token = await TokenService.getToken();
      _currentUserId = await TokenService.getUserId();
      
      if (_token == null || _currentUserId == null) {
        debugPrint('SocketChatService: No auth token or user ID available');
        throw Exception('Authentication required');
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
      
    } catch (e) {
      debugPrint('SocketChatService: Connection error: $e');
      rethrow;
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
      notifyListeners();
      
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
      notifyListeners();
      _handleReconnection();
    });

    _socket!.onConnectError((error) {
      debugPrint('Socket connection error: $error');
      _isConnected = false;
      _connectionStreamController.add(false);
      notifyListeners();
      _handleReconnection();
    });

    _socket!.onError((error) {
      debugPrint('Socket error: $error');
    });

    // INCOMING EVENTS (Server → Client) as per document

    // 1. receive_message
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
      Map<String, dynamic> messageData;
      if (data is String) {
        messageData = jsonDecode(data);
      } else if (data is Map<String, dynamic>) {
        messageData = data;
      } else {
        debugPrint('Invalid message data format: $data');
        return;
      }
      
      debugPrint('SocketService: Raw received message data: $messageData');
      
      final message = ApiChatMessage.fromJson(messageData);
      
      debugPrint('SocketService: Processed message data: ${message.toJson()}');
      debugPrint('Received message via socket: ${message.content}');
      debugPrint('Message from: ${message.senderType} (ID: ${message.senderId})');
      
      // Skip own messages to avoid duplicates
      if (message.isFromCurrentUser(_currentUserId)) {
        debugPrint('Skipping own message to avoid duplicates');
        return;
      }
      
      // Check for duplicates
      final messageExists = _messages.any((m) => 
        m.id == message.id ||
        (m.content == message.content && 
         m.senderId == message.senderId &&
         m.createdAt.difference(message.createdAt).abs().inSeconds < 5));
      
      if (!messageExists) {
        _messages.add(message);
        _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        
        // Emit to stream for UI updates
        if (!_messageStreamController.isClosed) {
          _messageStreamController.add(message);
        }
        
        // Auto mark as read for incoming messages
        if (_currentRoomId != null) {
          markAsReadViaSocket(_currentRoomId!);
        }
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error handling received message: $e');
    }
  }

  void _handleMessageReadUpdate(dynamic data) {
    try {
      final readData = data is Map<String, dynamic> ? data : jsonDecode(data.toString());
      final messageId = readData['messageId'];
      final userId = readData['userId'];
      final readAt = TimezoneUtils.parseToIST(readData['readAt']);
      
      debugPrint('Message read update - Message: $messageId, User: $userId');
      
      // Find and update the specific message
      final messageIndex = _messages.indexWhere((msg) => msg.id == messageId);
      if (messageIndex != -1) {
        final message = _messages[messageIndex];
        final updatedReadBy = List<ReadByEntry>.from(message.readBy);
        
        // Add new read entry if not already present
        if (!updatedReadBy.any((entry) => entry.userId == userId)) {
          updatedReadBy.add(ReadByEntry(
            userId: userId,
            readAt: readAt,
            id: DateTime.now().millisecondsSinceEpoch.toString(),
          ));
          
          // Create updated message with new read status
          _messages[messageIndex] = ApiChatMessage(
            id: message.id,
            roomId: message.roomId,
            senderId: message.senderId,
            senderType: message.senderType,
            content: message.content,
            messageType: message.messageType,
            readBy: updatedReadBy,
            createdAt: message.createdAt,
          );
          
          // Emit read receipt update
          if (!_readReceiptStreamController.isClosed) {
            _readReceiptStreamController.add({
              'type': 'single_message_read',
              'messageId': messageId,
              'userId': userId,
              'readAt': readAt.toIso8601String(),
            });
          }
          
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error handling message read update: $e');
    }
  }

  void _handleMessagesMarkedRead(dynamic data) {
    try {
      final readData = data is Map<String, dynamic> ? data : jsonDecode(data.toString());
      final roomId = readData['roomId'];
      final userId = readData['userId'];
      final readAt = TimezoneUtils.parseToIST(readData['readAt']);
      
      debugPrint('Messages marked read - Room: $roomId, User: $userId');
      
      // Update all messages in the room
      bool hasUpdates = false;
      for (int i = 0; i < _messages.length; i++) {
        final message = _messages[i];
        if (message.roomId == roomId && !message.readBy.any((entry) => entry.userId == userId)) {
          final updatedReadBy = List<ReadByEntry>.from(message.readBy);
          updatedReadBy.add(ReadByEntry(
            userId: userId,
            readAt: readAt,
            id: DateTime.now().millisecondsSinceEpoch.toString(),
          ));
          
          _messages[i] = ApiChatMessage(
            id: message.id,
            roomId: message.roomId,
            senderId: message.senderId,
            senderType: message.senderType,
            content: message.content,
            messageType: message.messageType,
            readBy: updatedReadBy,
            createdAt: message.createdAt,
          );
          hasUpdates = true;
        }
      }
      
      if (hasUpdates) {
        // Emit bulk read receipt update
        if (!_readReceiptStreamController.isClosed) {
          _readReceiptStreamController.add({
            'type': 'bulk_messages_read',
            'roomId': roomId,
            'userId': userId,
            'readAt': readAt.toIso8601String(),
          });
        }
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error handling messages marked read: $e');
    }
  }

  void _handleTypingStatus(dynamic data, bool isTyping) {
    try {
      final typingData = data is Map<String, dynamic> ? data : jsonDecode(data.toString());
      debugPrint('Typing status: $isTyping, data: $typingData');
      
      if (!_typingStreamController.isClosed) {
        _typingStreamController.add({
          'isTyping': isTyping,
          'userId': typingData['userId'],
          'userType': typingData['userType'],
          'roomId': typingData['roomId'],
        });
      }
    } catch (e) {
      debugPrint('Error handling typing status: $e');
    }
  }

  void _handleReconnection() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('Max reconnection attempts reached');
      return;
    }
    
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: 3 * (_reconnectAttempts + 1)), () {
      if (!_isConnected) {
        _reconnectAttempts++;
        debugPrint('Reconnection attempt $_reconnectAttempts');
        _socket?.connect();
      }
    });
  }

  // OUTGOING EVENTS (Client → Server) as per document

  // 1. join_room
  Future<void> joinRoom(String roomId) async {
    _currentRoomId = roomId;
    debugPrint('Setting current room to: $roomId');
    
    if (_socket != null && _isConnected) {
      _socket!.emit('join_room', roomId);
      debugPrint('Joined room via socket: $roomId');
      
      // Auto mark as read when joining room
      markAsReadViaSocket(roomId);
    } else {
      debugPrint('Socket not connected, will join room when connected');
    }
  }

  // 2. send_message
  Future<bool> sendMessage(String roomId, String content) async {
    if (_socket != null && _isConnected) {
      try {
        final messageData = {
          'roomId': roomId,
          'senderId': _currentUserId,
          'senderType': 'user', // USER sends as 'user'
          'content': content,
          'messageType': 'text',
        };
        
        _socket!.emit('send_message', messageData);
        debugPrint('Sending message via socket: $content');
        
        // Also persist via HTTP API
        await _sendMessageViaAPI(roomId, content);
        
        // Auto mark as read after sending
        markAsReadViaSocket(roomId);
        
        return true;
      } catch (e) {
        debugPrint('Error sending message: $e');
        return false;
      }
    } else {
      debugPrint('Socket not available for sending message');
      // Fallback to API only
      return await _sendMessageViaAPI(roomId, content);
    }
  }

  // HTTP API fallback for message persistence
  Future<bool> _sendMessageViaAPI(String roomId, String content) async {
    try {
      final url = Uri.parse('${baseUrl}chat/message');
      
      final body = {
        'roomId': roomId,
        'senderId': _currentUserId,
        'senderType': 'user',
        'content': content,
        'messageType': 'text',
      };
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['_id'] != null) {
          // Add message to local list if not already present
          final message = ApiChatMessage.fromJson(responseData);
          final messageExists = _messages.any((m) => m.id == message.id);
          
          if (!messageExists) {
            _messages.add(message);
            _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
            
            if (!_messageStreamController.isClosed) {
              _messageStreamController.add(message);
            }
            
            notifyListeners();
          }
          
          debugPrint('Message sent successfully via API');
          return true;
        }
      }
      
      debugPrint('Failed to send message via API: ${response.statusCode}');
      return false;
    } catch (e) {
      debugPrint('Error sending message via API: $e');
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
        'timestamp': TimezoneUtils.getCurrentTime().toIso8601String(),
      };
      
      _socket!.emit('mark_as_read', readData);
      debugPrint('Marked messages as read via socket for room: $roomId');
    }
  }

  // Hybrid approach for reliability
  Future<bool> markAsRead(String roomId) async {
    try {
      // PRIMARY: Socket for real-time updates
      if (_isConnected) {
        markAsReadViaSocket(roomId);
        // Also call API as backup
        await _markAsReadViaAPI(roomId);
        return true;
      } else {
        // FALLBACK: API if socket not connected
        return await _markAsReadViaAPI(roomId);
      }
    } catch (e) {
      debugPrint('Error marking as read: $e');
      return false;
    }
  }

  Future<bool> _markAsReadViaAPI(String roomId) async {
    try {
      final url = Uri.parse('${baseUrl}chat/read');
      
      final body = {
        'roomId': roomId,
        'userId': _currentUserId,
      };
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        debugPrint('Messages marked as read via API: ${responseData['success']}');
        return responseData['success'] == true;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error marking as read via API: $e');
      return false;
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
      debugPrint('Sent typing indicator for room: $roomId');
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
      debugPrint('Sent stop typing indicator for room: $roomId');
    }
  }

  // 5. leave_room
  void leaveRoom(String roomId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('leave_room', roomId);
      debugPrint('Left room via socket: $roomId');
    }
    _currentRoomId = null;
  }

  // Load initial chat history via API
  Future<void> loadChatHistory(String roomId) async {
    try {
      debugPrint('Loading chat history for room: $roomId');
      
      final url = Uri.parse('${baseUrl}chat/history/$roomId');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData is List) {
          _messages = responseData
              .map((messageData) => ApiChatMessage.fromJson(messageData))
              .toList();
          
          _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          
          debugPrint('Loaded ${_messages.length} messages from history');
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
    }
  }

  void disconnect() {
    debugPrint('SocketChatService: Disconnecting...');
    
    _reconnectTimer?.cancel();
    
    if (_currentRoomId != null) {
      leaveRoom(_currentRoomId!);
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
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    _messageStreamController.close();
    _readReceiptStreamController.close();
    _typingStreamController.close();
    _connectionStreamController.close();
    super.dispose();
  }
}
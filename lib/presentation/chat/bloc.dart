import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../models/chat_models.dart';
import '../../service/chat_service.dart';
import '../../service/socket_service.dart';
import '../../service/token_service.dart';
import '../../utils/timezone_utils.dart';
import 'event.dart';
import 'state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatService _chatService;
  final SocketService _socketService;
  String? _currentRoomId;
  String? _currentUserId;
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  StreamSubscription? _readReceiptSubscription;
  StreamSubscription? _typingSubscription;
  bool _isSocketConnected = false;
  Timer? _typingTimer;
  
  // Add global message tracking to prevent duplicates
  final Set<String> _processedMessageHashes = <String>{};
  static const int _maxProcessedHashes = 200;
  
  ChatBloc({required ChatService chatService, required SocketService socketService})
      : _chatService = chatService,
        _socketService = socketService,
        super(ChatInitial()) {
    _setupSocketListeners();
    _setupConnectionListener();
    on<LoadChatData>(_onLoadChatData);
    on<SendMessage>(_onSendMessage);
    on<ConnectSocket>(_onConnectSocket);
    on<DisconnectSocket>(_onDisconnectSocket);
    on<ReceiveMessage>(_onReceiveMessage);
    on<MarkAsRead>(_onMarkAsRead);
    on<StartTyping>(_onStartTyping);
    on<StopTyping>(_onStopTyping);
    on<UpdateMessageReadStatus>(_onUpdateMessageReadStatus);
  }
  
  @override
  Future<void> close() {
    _typingTimer?.cancel();
    _messageSubscription?.cancel();
    _connectionSubscription?.cancel();
    _readReceiptSubscription?.cancel();
    _typingSubscription?.cancel();
    _socketService.disconnect();
    return super.close();
  }
  
  void _setupSocketListeners() {
    // Listen for socket connection status
    _connectionSubscription = _socketService.connectionStream.listen((connected) {
      _isSocketConnected = connected;
      debugPrint('ChatBloc: Socket connection status: $connected');
      
      if (connected && _currentRoomId != null) {
        _socketService.joinRoom(_currentRoomId!);
        debugPrint('ChatBloc: Socket joined room on reconnection');
      }
    });
    
    // Listen for incoming socket messages
    _messageSubscription = _socketService.messageStream.listen((messageData) {
      try {
        debugPrint('ChatBloc: Received socket message: $messageData');
        debugPrint('ChatBloc: Message data type: ${messageData.runtimeType}');
        
        // Handle different message data formats
        String messageId = '';
        String roomId = '';
        String senderId = '';
        String senderType = '';
        String content = '';
        String messageType = 'text';
        DateTime createdAt = TimezoneUtils.getCurrentTime();
        List<ReadByEntry> readBy = [];
        
        // Parse message data safely
        if (messageData['_id'] != null) {
          messageId = messageData['_id'].toString();
        } else if (messageData['id'] != null) {
          messageId = messageData['id'].toString();
        } else {
          messageId = 'socket_${DateTime.now().millisecondsSinceEpoch}';
        }
        
        if (messageData['roomId'] != null) {
          roomId = messageData['roomId'].toString();
        }
        
        if (messageData['senderId'] != null) {
          senderId = messageData['senderId'].toString();
        }
        
        if (messageData['senderType'] != null) {
          senderType = messageData['senderType'].toString();
        }
        
        if (messageData['content'] != null) {
          content = messageData['content'].toString();
        }
        
        if (messageData['messageType'] != null) {
          messageType = messageData['messageType'].toString();
        }
        
        // Parse createdAt safely
        if (messageData['createdAt'] != null) {
          try {
            createdAt = TimezoneUtils.parseToIST(messageData['createdAt'].toString());
          } catch (e) {
            debugPrint('Error parsing createdAt: $e');
            createdAt = TimezoneUtils.getCurrentTime();
          }
        } else {
          // If no createdAt in socket message, use current IST time
          // This should only happen for real-time messages that don't have server timestamp
          createdAt = TimezoneUtils.getCurrentTime();
          debugPrint('No createdAt in socket message, using current IST time: $createdAt');
        }
        
        // Parse readBy safely
        if (messageData['readBy'] != null && messageData['readBy'] is List) {
          try {
            readBy = (messageData['readBy'] as List)
                .map((entry) => ReadByEntry.fromJson(entry as Map<String, dynamic>))
                .toList();
          } catch (e) {
            debugPrint('Error parsing readBy: $e');
            readBy = [];
          }
        }
        
        final chatMessage = ChatMessage(
          id: messageId,
          roomId: roomId,
          senderId: senderId,
          senderType: senderType,
          content: content,
          messageType: messageType,
          readBy: readBy,
          createdAt: createdAt,
        );
        
        debugPrint('ChatBloc: Parsed socket message: ${chatMessage.content}');
        debugPrint('ChatBloc: Message from: ${chatMessage.senderType} (ID: ${chatMessage.senderId})');
        debugPrint('ChatBloc: Current user ID: $_currentUserId');
        
        // Only add messages from OTHER users (avoid duplicates)
        if (senderId != _currentUserId) {
          debugPrint('ChatBloc: Adding message from other user to UI');
          add(ReceiveMessage(chatMessage));
        } else {
          debugPrint('ChatBloc: Ignoring own message from socket');
        }
      } catch (e) {
        debugPrint('ChatBloc: Error parsing socket message: $e');
        debugPrint('ChatBloc: Raw message data: $messageData');
      }
    });
    
    // Listen for read receipt updates
    _readReceiptSubscription = _socketService.readReceiptStream.listen((readData) {
      debugPrint('ChatBloc: Received read receipt: $readData');
      add(UpdateMessageReadStatus(readData));
    });
    
    // Listen for typing indicators
    _typingSubscription = _socketService.typingStream.listen((typingData) {
      debugPrint('ChatBloc: Typing status: $typingData');
      // Handle typing indicators in UI if needed
    });
  }
  
  void _setupConnectionListener() {
    // Listen for socket connection status
    _connectionSubscription = _socketService.connectionStream.listen((connected) {
      _isSocketConnected = connected;
      debugPrint('ChatBloc: Socket connection status: $connected');
      
      if (connected && _currentRoomId != null) {
        _socketService.joinRoom(_currentRoomId!);
        debugPrint('ChatBloc: Socket joined room on reconnection');
      }
    });
  }
  
  Future<void> _onLoadChatData(LoadChatData event, Emitter<ChatState> emit) async {
    try {
      emit(ChatLoading());
      
      // Get current user ID first
      _currentUserId = await TokenService.getUserId();
      if (_currentUserId == null) {
        debugPrint('ChatBloc: No user ID found');
        emit(const ChatError('Please login to access chat.'));
        return;
      }
      
      debugPrint('ChatBloc: Loading chat data for order: ${event.orderId}');
      debugPrint('ChatBloc: Current user ID: $_currentUserId');
      
      // Create or get chat room
      final roomResult = await ChatService.createOrGetChatRoom(event.orderId);
      
      if (roomResult['success'] != true) {
        debugPrint('ChatBloc: Failed to create/get chat room: ${roomResult['message']}');
        emit(ChatError(roomResult['message'] ?? 'Failed to load chat room'));
        return;
      }
      
      final chatRoom = ChatRoom.fromJson(roomResult['data']);
      _currentRoomId = chatRoom.roomId;
      
      // Clear processed messages when joining a new room
      _clearProcessedMessages();
      
      debugPrint('ChatBloc: Chat room loaded: ${chatRoom.roomId}');
      
      // Connect to socket and join room
      final connected = await _socketService.connect();
      if (connected && _currentRoomId != null) {
        _socketService.joinRoom(_currentRoomId!);
        debugPrint('ChatBloc: Socket connected and joined room');
      } else {
        debugPrint('ChatBloc: Failed to connect to socket or roomId is null');
      }
      
      // Get initial chat history
      final historyResult = await ChatService.getChatHistory(chatRoom.roomId);
      
      List<ChatMessage> messages = [];
      if (historyResult['success'] == true) {
        final historyData = historyResult['data'] as List<dynamic>;
        messages = historyData
            .map((messageData) => ChatMessage.fromJson(messageData))
            .toList();
        
        // Sort messages by creation time
        messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        
        debugPrint('ChatBloc: Loaded ${messages.length} messages');
      } else {
        debugPrint('ChatBloc: Failed to load chat history: ${historyResult['message']}');
      }
      
      emit(ChatLoaded(
        chatRoom: chatRoom,
        messages: messages,
        currentUserId: _currentUserId!,
      ));
      
      // Setup socket listeners AFTER emitting loaded state
      _setupSocketListeners();
      add(const ConnectSocket());
      
      // Auto mark as read when opening chat
      debugPrint('ChatBloc: Auto marking as read when opening chat');
      if (_currentRoomId != null) {
        // Delay to ensure socket connection is established
        await Future.delayed(const Duration(milliseconds: 500));
        add(MarkAsRead(_currentRoomId!));
      }
      
      debugPrint('ChatBloc: Chat data loaded with socket integration');
    } catch (e, stackTrace) {
      debugPrint('ChatBloc: Error loading chat data: $e');
      debugPrint('ChatBloc: Stack trace: $stackTrace');
      emit(const ChatError('Failed to load chat. Please try again.'));
    }
  }
  
  Future<void> _onSendMessage(SendMessage event, Emitter<ChatState> emit) async {
    if (state is ChatLoaded && _currentRoomId != null && _currentUserId != null) {
      final currentState = state as ChatLoaded;
      
      debugPrint('ChatBloc: Sending message: "${event.content}"');
      
      // OPTIMISTIC UPDATE: Add message immediately to UI
      final optimisticMessage = ChatMessage(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        roomId: _currentRoomId!,
        senderId: _currentUserId!,
        senderType: 'user',
        content: event.content,
        messageType: 'text',
        readBy: [],
        createdAt: TimezoneUtils.getCurrentTime(),
      );
      
      // Add the optimistic message to the UI immediately
      final updatedMessages = [...currentState.messages, optimisticMessage];
      updatedMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      emit(currentState.copyWith(
        messages: updatedMessages,
        isSendingMessage: true,
      ));
      
      try {
        // PRIMARY: Send via HTTP API for persistence
        debugPrint('ChatBloc: Sending message via HTTP API (primary)');
        final result = await ChatService.sendMessage(
          roomId: _currentRoomId!,
          content: event.content,
        );
        
        debugPrint('ChatBloc: HTTP send result: ${result['success']}');
        
        if (result['success'] == true) {
          debugPrint('ChatBloc: Message sent successfully via HTTP');
          
          // BACKUP: Also send via socket for real-time delivery
          if (_isSocketConnected) {
            debugPrint('ChatBloc: Also sending via socket (real-time)');
            _socketService.sendMessage(
              roomId: _currentRoomId!,
              content: event.content,
            );
          }
          
          // IMPORTANT: Auto mark as read after sending message
          debugPrint('ChatBloc: Auto marking as read after sending message');
          await Future.delayed(const Duration(milliseconds: 300)); // Small delay to ensure message is processed
          add(MarkAsRead(_currentRoomId!));
          
          // Remove optimistic message after delay (real message should come via API response)
          await Future.delayed(const Duration(milliseconds: 1000));
          
          if (!emit.isDone && state is ChatLoaded) {
            final newState = state as ChatLoaded;
            // Add the real message from API response if not already added
            if (result['data'] != null) {
              try {
                final realMessage = ChatMessage.fromJson(result['data']);
                
                // Remove optimistic message and add real message
                final messagesWithoutOptimistic = newState.messages
                    .where((msg) => msg.id != optimisticMessage.id)
                    .toList();
                
                // Check if real message already exists
                final messageExists = messagesWithoutOptimistic.any((msg) => msg.id == realMessage.id);
                
                if (!messageExists) {
                  // Ensure the real message appears at the bottom by adjusting timestamp if needed
                  var finalRealMessage = realMessage;
                  if (messagesWithoutOptimistic.isNotEmpty) {
                    final lastMessage = messagesWithoutOptimistic.last;
                    if (realMessage.createdAt.isBefore(lastMessage.createdAt) || 
                        realMessage.createdAt.isAtSameMomentAs(lastMessage.createdAt)) {
                      final adjustedTime = lastMessage.createdAt.add(const Duration(milliseconds: 500));
                      finalRealMessage = ChatMessage(
                        id: realMessage.id,
                        roomId: realMessage.roomId,
                        senderId: realMessage.senderId,
                        senderType: realMessage.senderType,
                        content: realMessage.content,
                        messageType: realMessage.messageType,
                        readBy: realMessage.readBy,
                        createdAt: adjustedTime,
                      );
                      debugPrint('ChatBloc: Adjusted real message timestamp to ensure bottom position');
                    }
                  }
                  
                  messagesWithoutOptimistic.add(finalRealMessage);
                  messagesWithoutOptimistic.sort((a, b) => a.createdAt.compareTo(b.createdAt));
                }
                
                emit(newState.copyWith(
                  messages: messagesWithoutOptimistic,
                  isSendingMessage: false,
                ));
              } catch (e) {
                debugPrint('ChatBloc: Error parsing real message: $e');
                // Just remove optimistic message
                final messagesWithoutOptimistic = newState.messages
                    .where((msg) => !msg.id.startsWith('temp_'))
                    .toList();
                
                emit(newState.copyWith(
                  messages: messagesWithoutOptimistic,
                  isSendingMessage: false,
                ));
              }
            } else {
              // Just remove optimistic message
              final messagesWithoutOptimistic = newState.messages
                  .where((msg) => !msg.id.startsWith('temp_'))
                  .toList();
              
              emit(newState.copyWith(
                messages: messagesWithoutOptimistic,
                isSendingMessage: false,
              ));
            }
          }
          
        } else {
          debugPrint('ChatBloc: Failed to send message via HTTP: ${result['message']}');
          
          // Remove the optimistic message since sending failed
          final messagesWithoutOptimistic = currentState.messages
              .where((msg) => msg.id != optimisticMessage.id)
              .toList();
          
          emit(currentState.copyWith(
            messages: messagesWithoutOptimistic,
            isSendingMessage: false,
          ));
          
          debugPrint('ChatBloc: Message send failed, removed optimistic update');
        }
        
      } catch (e) {
        debugPrint('ChatBloc: Error sending message: $e');
        
        // Remove the optimistic message since sending failed
        final messagesWithoutOptimistic = currentState.messages
            .where((msg) => msg.id != optimisticMessage.id)
            .toList();
        
        emit(currentState.copyWith(
          messages: messagesWithoutOptimistic,
          isSendingMessage: false,
        ));
      }
    } else {
      debugPrint('ChatBloc: Cannot send message - invalid state or missing room/user ID');
    }
  }
  
  Future<void> _onConnectSocket(ConnectSocket event, Emitter<ChatState> emit) async {
    debugPrint('ChatBloc: Attempting to connect socket...');
    
    try {
      final connected = await _socketService.connect();
      if (connected) {
        debugPrint('ChatBloc: Socket connection initiated');
        
        // Join room after connection
        if (_currentRoomId != null) {
          _socketService.joinRoom(_currentRoomId!);
        }
      } else {
        debugPrint('ChatBloc: Socket connection failed');
      }
    } catch (e) {
      debugPrint('ChatBloc: Error connecting socket: $e');
    }
  }
  
  Future<void> _onDisconnectSocket(DisconnectSocket event, Emitter<ChatState> emit) async {
    debugPrint('ChatBloc: Disconnecting from socket...');
    _socketService.disconnect();
  }
  
  Future<void> _onReceiveMessage(ReceiveMessage event, Emitter<ChatState> emit) async {
    debugPrint('ChatBloc: _onReceiveMessage called with message: ${event.message.content}');
    
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      
      debugPrint('ChatBloc: Processing received message: ${event.message.content}');
      debugPrint('ChatBloc: Message from: ${event.message.senderType} (ID: ${event.message.senderId})');
      debugPrint('ChatBloc: Message timestamp: ${event.message.createdAt}');
      debugPrint('ChatBloc: Current messages count: ${currentState.messages.length}');
      
      // Check if message has been processed recently using global tracking
      if (_isMessageProcessed(event.message)) {
        debugPrint('ChatBloc: Message already processed recently, ignoring duplicate');
        debugPrint('ChatBloc: Duplicate message content: "${event.message.content}"');
        return;
      }
      
      // Mark message as processed immediately to prevent future duplicates
      _markMessageAsProcessed(event.message);
      
      // Additional check for existing messages in the current list
      final existingMessageIndex = currentState.messages
          .indexWhere((msg) => 
              // Exact ID match
              msg.id == event.message.id ||
              // Same content, sender, and very recent timestamp (within 2 seconds)
              (msg.content == event.message.content && 
               msg.senderId == event.message.senderId &&
               msg.senderType == event.message.senderType &&
               msg.createdAt.difference(event.message.createdAt).abs().inSeconds < 2));
      
      debugPrint('ChatBloc: Existing message index: $existingMessageIndex');
      debugPrint('ChatBloc: Checking for duplicates - Content: "${event.message.content}", Sender: ${event.message.senderId}');
      
      if (existingMessageIndex == -1) {
        debugPrint('ChatBloc: Message is new, adding to UI');
        
        // Remove any temporary optimistic messages that might match this content
        final messagesWithoutOptimistic = currentState.messages
            .where((msg) => !(msg.id.startsWith('temp_') && 
                            msg.content == event.message.content &&
                            msg.senderId == event.message.senderId))
            .toList();
        
        debugPrint('ChatBloc: Messages without optimistic: ${messagesWithoutOptimistic.length}');
        
        // Create a new message with adjusted timestamp if needed
        var newMessage = event.message;
        
        // If the incoming message timestamp is older than the last message,
        // adjust it to ensure it appears at the bottom
        if (messagesWithoutOptimistic.isNotEmpty) {
          final lastMessage = messagesWithoutOptimistic.last;
          if (newMessage.createdAt.isBefore(lastMessage.createdAt) || 
              newMessage.createdAt.isAtSameMomentAs(lastMessage.createdAt)) {
            // Adjust timestamp to be 1 second after the last message
            final adjustedTime = lastMessage.createdAt.add(const Duration(seconds: 1));
            newMessage = ChatMessage(
              id: newMessage.id,
              roomId: newMessage.roomId,
              senderId: newMessage.senderId,
              senderType: newMessage.senderType,
              content: newMessage.content,
              messageType: newMessage.messageType,
              readBy: newMessage.readBy,
              createdAt: adjustedTime,
            );
            debugPrint('ChatBloc: Adjusted message timestamp from ${event.message.createdAt} to $adjustedTime');
          }
        }
        
        // Add new message to the list
        final updatedMessages = [...messagesWithoutOptimistic, newMessage];
        
        // Sort by creation time to ensure proper order
        updatedMessages.sort((a, b) {
          final comparison = a.createdAt.compareTo(b.createdAt);
          // If timestamps are equal, prioritize real messages over temp ones
          if (comparison == 0) {
            if (a.id.startsWith('temp_') && !b.id.startsWith('temp_')) {
              return -1; // temp message comes first
            } else if (!a.id.startsWith('temp_') && b.id.startsWith('temp_')) {
              return 1; // real message comes after
            }
          }
          return comparison;
        });
        
        debugPrint('ChatBloc: Added new message from ${newMessage.senderType}: ${newMessage.content}');
        debugPrint('ChatBloc: Total messages now: ${updatedMessages.length}');
        
        // Log the last few messages for debugging
        if (updatedMessages.length > 1) {
          final lastTwo = updatedMessages.length >= 2 
              ? updatedMessages.sublist(updatedMessages.length - 2)
              : updatedMessages;
          debugPrint('ChatBloc: Last two messages:');
          for (int i = 0; i < lastTwo.length; i++) {
            debugPrint('  ${i + 1}. ${lastTwo[i].content} (${lastTwo[i].createdAt}) from ${lastTwo[i].senderId}');
          }
        }
        
        // Emit the updated state first
        debugPrint('ChatBloc: Emitting updated state with ${updatedMessages.length} messages');
        emit(currentState.copyWith(
          messages: updatedMessages,
          isSendingMessage: false,
        ));
        
        // Auto mark as read for incoming messages (not from current user)
        if (_currentRoomId != null && newMessage.senderId != _currentUserId) {
          debugPrint('ChatBloc: Auto marking as read for incoming message from ${newMessage.senderType}');
          // Small delay to ensure message is fully processed
          await Future.delayed(const Duration(milliseconds: 200));
          add(MarkAsRead(_currentRoomId!));
        }
        
      } else {
        debugPrint('ChatBloc: Message already exists in current list, ignoring duplicate');
        debugPrint('ChatBloc: Duplicate message content: "${event.message.content}"');
      }
    } else {
      debugPrint('ChatBloc: Cannot process message - state is not ChatLoaded');
    }
  }
  
  Future<void> _onMarkAsRead(MarkAsRead event, Emitter<ChatState> emit) async {
    try {
      debugPrint('ChatBloc: Marking messages as read for room: ${event.roomId}');
      
      // Use hybrid approach for maximum reliability
      bool socketSuccess = false;
      bool apiSuccess = false;
      
      // PRIMARY: Socket for real-time updates
      if (_isSocketConnected) {
        try {
          _socketService.markAsReadViaSocket(event.roomId);
          socketSuccess = true;
          debugPrint('ChatBloc: Marked as read via socket - SUCCESS');
        } catch (e) {
          debugPrint('ChatBloc: Socket mark as read failed: $e');
        }
      } else {
        debugPrint('ChatBloc: Socket not connected, skipping socket mark as read');
      }
      
      // SECONDARY: API for reliability and persistence
      try {
        debugPrint('ChatBloc: Calling mark as read API...');
        final result = await ChatService.markMessagesAsRead(roomId: event.roomId);
        if (result['success'] == true) {
          apiSuccess = true;
          debugPrint('ChatBloc: Marked as read via API - SUCCESS');
        } else {
          debugPrint('ChatBloc: API mark as read failed: ${result['message']}');
        }
      } catch (e) {
        debugPrint('ChatBloc: API mark as read exception: $e');
      }
      
      // Log the overall result
      if (socketSuccess || apiSuccess) {
        debugPrint('ChatBloc: Mark as read completed - Socket: $socketSuccess, API: $apiSuccess');
      } else {
        debugPrint('ChatBloc: Mark as read FAILED - both socket and API failed');
      }
      
    } catch (e) {
      debugPrint('ChatBloc: Error in mark as read process: $e');
    }
  }
  
  Future<void> _onStartTyping(StartTyping event, Emitter<ChatState> emit) async {
    if (_isSocketConnected && _currentRoomId != null) {
      _socketService.sendTyping(_currentRoomId!);
      debugPrint('ChatBloc: Started typing indicator');
    }
  }
  
  Future<void> _onStopTyping(StopTyping event, Emitter<ChatState> emit) async {
    if (_isSocketConnected && _currentRoomId != null) {
      _socketService.sendStopTyping(_currentRoomId!);
      debugPrint('ChatBloc: Stopped typing indicator');
    }
  }
  
  Future<void> _onUpdateMessageReadStatus(UpdateMessageReadStatus event, Emitter<ChatState> emit) async {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final readData = event.readData;
      
      try {
        bool hasUpdates = false;
        final updatedMessages = currentState.messages.map((message) {
          // Update read status for matching messages
          if (readData['type'] == 'single_message_read') {
            final messageId = readData['messageId'];
            if (message.id == messageId) {
              final updatedReadBy = List<ReadByEntry>.from(message.readBy);
              final userId = readData['userId'];
              
              if (!updatedReadBy.any((entry) => entry.userId == userId)) {
                updatedReadBy.add(ReadByEntry(
                  userId: userId,
                  readAt: TimezoneUtils.parseToIST(readData['readAt']),
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                ));
                hasUpdates = true;
                
                return ChatMessage(
                  id: message.id,
                  roomId: message.roomId,
                  senderId: message.senderId,
                  senderType: message.senderType,
                  content: message.content,
                  messageType: message.messageType,
                  readBy: updatedReadBy,
                  createdAt: message.createdAt,
                );
              }
            }
          } else if (readData['type'] == 'bulk_messages_read') {
            final roomId = readData['roomId'];
            final userId = readData['userId'];
            
            if (message.roomId == roomId && !message.readBy.any((entry) => entry.userId == userId)) {
              final updatedReadBy = List<ReadByEntry>.from(message.readBy);
              updatedReadBy.add(ReadByEntry(
                userId: userId,
                readAt: TimezoneUtils.parseToIST(readData['readAt']),
                id: DateTime.now().millisecondsSinceEpoch.toString(),
              ));
              hasUpdates = true;
              
              return ChatMessage(
                id: message.id,
                roomId: message.roomId,
                senderId: message.senderId,
                senderType: message.senderType,
                content: message.content,
                messageType: message.messageType,
                readBy: updatedReadBy,
                createdAt: message.createdAt,
              );
            }
          }
          
          return message;
        }).toList();
        
        if (hasUpdates) {
          emit(currentState.copyWith(messages: updatedMessages));
          debugPrint('ChatBloc: Updated message read status via socket');
        }
      } catch (e) {
        debugPrint('ChatBloc: Error updating message read status: $e');
      }
    }
  }
  
  // Helper method to create a unique hash for a message
  String _createMessageHash(ChatMessage message) {
    // Create a more unique hash using content, sender, and a time window
    final timeWindow = (message.createdAt.millisecondsSinceEpoch / 1000).round(); // Round to nearest second
    return '${message.content}_${message.senderId}_${message.senderType}_$timeWindow';
  }
  
  // Helper method to check if message has been processed recently
  bool _isMessageProcessed(ChatMessage message) {
    final hash = _createMessageHash(message);
    final isProcessed = _processedMessageHashes.contains(hash);
    debugPrint('ChatBloc: Checking message hash: $hash - Processed: $isProcessed');
    return isProcessed;
  }
  
  // Helper method to mark message as processed
  void _markMessageAsProcessed(ChatMessage message) {
    final hash = _createMessageHash(message);
    _processedMessageHashes.add(hash);
    debugPrint('ChatBloc: Marked message as processed: $hash');
    
    // Maintain size limit
    if (_processedMessageHashes.length > _maxProcessedHashes) {
      final removed = _processedMessageHashes.first;
      _processedMessageHashes.remove(removed);
      debugPrint('ChatBloc: Removed old message hash: $removed');
    }
  }
  
  // Helper method to clear processed messages when joining new room
  void _clearProcessedMessages() {
    _processedMessageHashes.clear();
    debugPrint('ChatBloc: Cleared processed message hashes for new room');
  }
}
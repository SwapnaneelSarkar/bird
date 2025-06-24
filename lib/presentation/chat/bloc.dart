import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/chat_models.dart';
import '../../service/chat_service.dart';
import '../../service/socket_service.dart';
import '../../service/token_service.dart';
import 'event.dart';
import 'state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  String? _currentRoomId;
  String? _currentUserId;
  late SocketService _socketService;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _readReceiptSubscription;
  StreamSubscription? _typingSubscription;
  bool _isSocketConnected = false;
  Timer? _typingTimer;
  
  ChatBloc() : super(ChatInitial()) {
    _socketService = SocketService();
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
        
        // Handle different message data formats
        String messageId = '';
        String roomId = '';
        String senderId = '';
        String senderType = '';
        String content = '';
        String messageType = 'text';
        DateTime createdAt = DateTime.now();
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
            createdAt = DateTime.parse(messageData['createdAt'].toString());
          } catch (e) {
            debugPrint('Error parsing createdAt: $e');
            createdAt = DateTime.now();
          }
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
        
        // Only add messages from OTHER users (avoid duplicates)
        if (senderId != _currentUserId) {
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
  
  Future<void> _onLoadChatData(LoadChatData event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    
    try {
      debugPrint('ChatBloc: Loading chat data for order: ${event.orderId}');
      
      // Get current user ID
      final currentUserId = await TokenService.getUserId();
      if (currentUserId == null) {
        debugPrint('ChatBloc: No user ID found');
        emit(const ChatError('Please login to access chat.'));
        return;
      }
      
      _currentUserId = currentUserId;
      debugPrint('ChatBloc: Current user ID: $currentUserId');
      
      // Create or get chat room
      final roomResult = await ChatService.createOrGetChatRoom(event.orderId);
      
      if (roomResult['success'] != true) {
        debugPrint('ChatBloc: Failed to get chat room: ${roomResult['message']}');
        emit(ChatError(roomResult['message'] ?? 'Failed to load chat room.'));
        return;
      }
      
      final chatRoom = ChatRoom.fromJson(roomResult['data']);
      _currentRoomId = chatRoom.roomId;
      
      debugPrint('ChatBloc: Chat room loaded: ${chatRoom.roomId}');
      debugPrint('ChatBloc: Participants: ${chatRoom.participants.length}');
      
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
        currentUserId: currentUserId,
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
        createdAt: DateTime.now(),
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
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      
      debugPrint('ChatBloc: Processing received message: ${event.message.content}');
      debugPrint('ChatBloc: Message from: ${event.message.senderType} (ID: ${event.message.senderId})');
      debugPrint('ChatBloc: Message timestamp: ${event.message.createdAt}');
      
      // Check if message is already in the list to avoid duplicates
      final existingMessageIndex = currentState.messages
          .indexWhere((msg) => msg.id == event.message.id || 
                                (msg.content == event.message.content && 
                                 msg.senderId == event.message.senderId &&
                                 msg.createdAt.difference(event.message.createdAt).abs().inSeconds < 5));
      
      if (existingMessageIndex == -1) {
        // Remove any temporary optimistic messages that might match this content
        final messagesWithoutOptimistic = currentState.messages
            .where((msg) => !(msg.id.startsWith('temp_') && 
                            msg.content == event.message.content &&
                            msg.senderId == event.message.senderId))
            .toList();
        
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
        emit(currentState.copyWith(
          messages: updatedMessages,
          isSendingMessage: false,
        ));
        
        // IMPORTANT: Fetch updated chat history to check read status of previous messages
        debugPrint('ChatBloc: Fetching chat history to update read status after receiving message');
        await _refreshChatHistoryForReadStatus(emit);
        
        // Auto mark as read for incoming messages (not from current user)
        if (_currentRoomId != null && newMessage.senderId != _currentUserId) {
          debugPrint('ChatBloc: Auto marking as read for incoming message from ${newMessage.senderType}');
          // Small delay to ensure message is fully processed
          await Future.delayed(const Duration(milliseconds: 200));
          add(MarkAsRead(_currentRoomId!));
        }
        
      } else {
        debugPrint('ChatBloc: Message already exists, ignoring duplicate');
      }
    }
  }
  
  // New method to refresh chat history and update read status
  Future<void> _refreshChatHistoryForReadStatus(Emitter<ChatState> emit) async {
    if (state is ChatLoaded && _currentRoomId != null) {
      final currentState = state as ChatLoaded;
      
      try {
        debugPrint('ChatBloc: Refreshing chat history to check read status...');
        
        // Get updated chat history
        final historyResult = await ChatService.getChatHistory(_currentRoomId!);
        
        if (historyResult['success'] == true) {
          final historyData = historyResult['data'] as List<dynamic>;
          final apiMessages = historyData
              .map((messageData) => ChatMessage.fromJson(messageData))
              .toList();
          
          // Sort by creation time
          apiMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          
          debugPrint('ChatBloc: Got ${apiMessages.length} messages from history API');
          
          // Update current messages with fresh read status from API
          final updatedMessages = <ChatMessage>[];
          
          for (final currentMsg in currentState.messages) {
            // Skip temporary messages
            if (currentMsg.id.startsWith('temp_')) {
              updatedMessages.add(currentMsg);
              continue;
            }
            
            // Find corresponding message in API response
            final apiMsg = apiMessages.firstWhere(
              (msg) => msg.id == currentMsg.id,
              orElse: () => currentMsg, // Use current if not found in API
            );
            
            // Check if read status changed
            final currentReadCount = currentMsg.readBy.length;
            final apiReadCount = apiMsg.readBy.length;
            
            if (apiReadCount != currentReadCount) {
              debugPrint('ChatBloc: Read status updated for message "${currentMsg.content}" - ReadBy count: $currentReadCount → $apiReadCount');
              updatedMessages.add(apiMsg); // Use API version with updated read status
            } else {
              updatedMessages.add(currentMsg); // Keep current version
            }
          }
          
          // Add any new messages from API that aren't in current list
          for (final apiMsg in apiMessages) {
            final existsInCurrent = updatedMessages.any((msg) => msg.id == apiMsg.id);
            if (!existsInCurrent) {
              debugPrint('ChatBloc: Found new message in API that was missing locally: ${apiMsg.content}');
              updatedMessages.add(apiMsg);
            }
          }
          
          // Sort final list
          updatedMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          
          // Only emit if there are actual changes
          if (_hasReadStatusChanges(currentState.messages, updatedMessages)) {
            debugPrint('ChatBloc: Read status changes detected, updating UI');
            emit(currentState.copyWith(messages: updatedMessages));
          } else {
            debugPrint('ChatBloc: No read status changes detected');
          }
          
        } else {
          debugPrint('ChatBloc: Failed to refresh chat history: ${historyResult['message']}');
        }
        
      } catch (e) {
        debugPrint('ChatBloc: Error refreshing chat history for read status: $e');
      }
    }
  }
  
  // Helper method to check if there are read status changes
  bool _hasReadStatusChanges(List<ChatMessage> oldMessages, List<ChatMessage> newMessages) {
    if (oldMessages.length != newMessages.length) return true;
    
    for (int i = 0; i < oldMessages.length; i++) {
      final oldMsg = oldMessages[i];
      final newMsg = newMessages[i];
      
      // Skip temporary messages
      if (oldMsg.id.startsWith('temp_') || newMsg.id.startsWith('temp_')) continue;
      
      // Check if read status changed
      if (oldMsg.id == newMsg.id && oldMsg.readBy.length != newMsg.readBy.length) {
        return true;
      }
    }
    
    return false;
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
                  readAt: DateTime.parse(readData['readAt']),
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
                readAt: DateTime.parse(readData['readAt']),
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
}
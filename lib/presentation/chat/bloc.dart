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
  Timer? _pollingTimer;
  late SocketService _socketService;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _connectionSubscription;
  bool _isSocketConnected = false;
  int _lastMessageCount = 0;
  DateTime? _lastPollTime;
  int _pollFailureCount = 0;
  static const int _maxPollFailures = 3;
  
  ChatBloc() : super(ChatInitial()) {
    _socketService = SocketService();
    on<LoadChatData>(_onLoadChatData);
    on<SendMessage>(_onSendMessage);
    on<RefreshMessages>(_onRefreshMessages);
    on<ConnectSocket>(_onConnectSocket);
    on<DisconnectSocket>(_onDisconnectSocket);
    on<ReceiveMessage>(_onReceiveMessage);
  }
  
  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    _messageSubscription?.cancel();
    _connectionSubscription?.cancel();
    _socketService.disconnect();
    return super.close();
  }
  
  void _startPolling() {
    _pollingTimer?.cancel();
    
    // Use adaptive polling interval based on recent activity
    Duration pollInterval = const Duration(seconds: 2);
    
    // If we've had recent activity, poll more frequently
    if (_lastPollTime != null && 
        DateTime.now().difference(_lastPollTime!) < const Duration(minutes: 2)) {
      pollInterval = const Duration(milliseconds: 1500);
    }
    
    _pollingTimer = Timer.periodic(pollInterval, (timer) {
      if (state is ChatLoaded && _currentRoomId != null) {
        debugPrint('ChatBloc: Polling for messages (primary method) - interval: ${pollInterval.inMilliseconds}ms');
        add(const RefreshMessages());
      }
    });
    
    debugPrint('ChatBloc: Started polling every ${pollInterval.inMilliseconds}ms (primary method)');
  }
  
  void _stopPolling() {
    _pollingTimer?.cancel();
    debugPrint('ChatBloc: Stopped polling for messages');
  }
  
  void _adjustPollingInterval() {
    if (_pollFailureCount >= _maxPollFailures) {
      // Slow down polling if we're having issues
      _pollingTimer?.cancel();
      _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        if (state is ChatLoaded && _currentRoomId != null) {
          debugPrint('ChatBloc: Slow polling due to failures');
          add(const RefreshMessages());
        }
      });
      debugPrint('ChatBloc: Switched to slow polling due to failures');
    } else {
      _startPolling(); // Normal polling
    }
  }
  
  void _setupSocketListeners() {
    // Listen for socket connection status (backup only)
    _connectionSubscription = _socketService.connectionStream.listen((connected) {
      _isSocketConnected = connected;
      debugPrint('ChatBloc: Socket connection status: $connected (backup method)');
      
      if (connected && _currentRoomId != null) {
        _socketService.joinRoom(_currentRoomId!);
        debugPrint('ChatBloc: Socket joined room as backup');
      }
    });
    
    // Listen for incoming socket messages (backup method)
    _messageSubscription = _socketService.messageStream.listen((messageData) {
      try {
        debugPrint('ChatBloc: Received socket message (backup): $messageData');
        final message = ChatMessage.fromJson(messageData);
        debugPrint('ChatBloc: Parsed socket message (backup): ${message.content}');
        
        // Only use socket messages as backup if polling is failing
        if (_pollFailureCount >= 2) {
          debugPrint('ChatBloc: Using socket message due to polling issues');
          add(ReceiveMessage(message));
        } else {
          debugPrint('ChatBloc: Ignoring socket message, polling is working fine');
        }
      } catch (e) {
        debugPrint('ChatBloc: Error parsing socket message: $e');
        // Don't add refresh here to avoid conflicts with polling
      }
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
        
        _lastMessageCount = messages.length;
        _pollFailureCount = 0; // Reset failure count on success
        debugPrint('ChatBloc: Loaded ${messages.length} messages');
      } else {
        debugPrint('ChatBloc: Failed to load chat history: ${historyResult['message']}');
        _pollFailureCount++;
      }
      
      emit(ChatLoaded(
        chatRoom: chatRoom,
        messages: messages,
        currentUserId: currentUserId,
      ));
      
      // Setup socket as backup method
      _setupSocketListeners();
      add(const ConnectSocket());
      
      // Start polling as PRIMARY method for real-time updates
      _startPolling();
      
      debugPrint('ChatBloc: Chat data loaded, polling started as primary method');
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
        // Send via HTTP API (primary method)
        debugPrint('ChatBloc: Sending message via HTTP API (primary)');
        final result = await ChatService.sendMessage(
          roomId: _currentRoomId!,
          content: event.content,
        );
        
        debugPrint('ChatBloc: HTTP send result: ${result['success']}');
        
        if (result['success'] == true) {
          debugPrint('ChatBloc: Message sent successfully via HTTP');
          
          // Also try socket as backup for real-time delivery
          if (_isSocketConnected) {
            debugPrint('ChatBloc: Also sending via socket (backup)');
            _socketService.sendMessage(
              roomId: _currentRoomId!,
              content: event.content,
            );
          }
          
          // Trigger immediate poll to get the real message
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (!emit.isDone && state is ChatLoaded) {
            debugPrint('ChatBloc: Triggering immediate poll after message send');
            add(const RefreshMessages());
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
  
  Future<void> _onRefreshMessages(RefreshMessages event, Emitter<ChatState> emit) async {
    if (state is ChatLoaded && _currentRoomId != null) {
      final currentState = state as ChatLoaded;
      
      try {
        debugPrint('ChatBloc: Polling for new messages...');
        _lastPollTime = DateTime.now();
        
        // Get updated chat history via polling
        final historyResult = await ChatService.getChatHistory(_currentRoomId!);
        
        if (historyResult['success'] == true) {
          final historyData = historyResult['data'] as List<dynamic>;
          final messages = historyData
              .map((messageData) => ChatMessage.fromJson(messageData))
              .toList();
          
          // Sort messages by creation time
          messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          
          // Check if we have new messages
          final previousCount = _lastMessageCount;
          final hasNewMessages = messages.length != previousCount;
          
          if (hasNewMessages) {
            debugPrint('ChatBloc: Polling found ${messages.length - previousCount} new messages');
            _lastMessageCount = messages.length;
            _pollFailureCount = 0; // Reset failure count on successful poll with new messages
            
            // Adjust polling interval for recent activity
            if (messages.length > previousCount) {
              _startPolling(); // Restart with potentially faster interval
            }
          } else {
            debugPrint('ChatBloc: Polling - no new messages (${messages.length} total)');
          }
          
          // Filter out any temporary optimistic messages and show real messages
          final realMessages = messages
              .where((msg) => !msg.id.startsWith('temp_'))
              .toList();
          
          emit(currentState.copyWith(
            messages: realMessages,
            isSendingMessage: false,
          ));
          
          _pollFailureCount = 0; // Reset on successful poll
          
        } else {
          debugPrint('ChatBloc: Polling failed: ${historyResult['message']}');
          _pollFailureCount++;
          
          // Adjust polling strategy based on failures
          if (_pollFailureCount >= _maxPollFailures) {
            debugPrint('ChatBloc: Too many poll failures, adjusting strategy');
            _adjustPollingInterval();
          }
          
          emit(currentState.copyWith(isSendingMessage: false));
        }
        
      } catch (e) {
        debugPrint('ChatBloc: Error during polling: $e');
        _pollFailureCount++;
        
        if (_pollFailureCount >= _maxPollFailures) {
          _adjustPollingInterval();
        }
        
        emit(currentState.copyWith(isSendingMessage: false));
      }
    }
  }
  
  Future<void> _onConnectSocket(ConnectSocket event, Emitter<ChatState> emit) async {
    debugPrint('ChatBloc: Attempting to connect socket (backup method)...');
    
    try {
      final connected = await _socketService.connect();
      if (connected) {
        debugPrint('ChatBloc: Socket connection attempt completed (backup ready)');
        // Socket will join room automatically if connection succeeds
      } else {
        debugPrint('ChatBloc: Socket connection failed, polling continues as primary');
      }
    } catch (e) {
      debugPrint('ChatBloc: Error connecting socket: $e, polling continues');
    }
  }
  
  Future<void> _onDisconnectSocket(DisconnectSocket event, Emitter<ChatState> emit) async {
    debugPrint('ChatBloc: Disconnecting from socket...');
    _socketService.disconnect();
    _stopPolling();
  }
  
  Future<void> _onReceiveMessage(ReceiveMessage event, Emitter<ChatState> emit) async {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      
      debugPrint('ChatBloc: Processing received message: ${event.message.content}');
      debugPrint('ChatBloc: Message from: ${event.message.senderType} (ID: ${event.message.senderId})');
      
      // Check if message is already in the list to avoid duplicates
      final existingMessageIndex = currentState.messages
          .indexWhere((msg) => msg.id == event.message.id);
      
      if (existingMessageIndex == -1) {
        // Remove any temporary optimistic messages that might match this content
        final messagesWithoutOptimistic = currentState.messages
            .where((msg) => !(msg.id.startsWith('temp_') && 
                            msg.content == event.message.content &&
                            msg.senderId == event.message.senderId))
            .toList();
        
        // Add new message to the list
        final updatedMessages = [...messagesWithoutOptimistic, event.message];
        
        // Sort by creation time
        updatedMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        
        _lastMessageCount = updatedMessages.length;
        
        debugPrint('ChatBloc: Added new message from ${event.message.senderType}: ${event.message.content}');
        
        emit(currentState.copyWith(
          messages: updatedMessages,
          isSendingMessage: false,
        ));
        
        // Trigger faster polling for recent activity
        _startPolling();
        
      } else {
        debugPrint('ChatBloc: Message already exists, ignoring duplicate');
      }
    }
  }
}
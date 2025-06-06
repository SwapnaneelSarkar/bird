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
    // Use more frequent polling for better real-time experience
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (state is ChatLoaded && _currentRoomId != null) {
        debugPrint('ChatBloc: Polling for new messages...');
        add(const RefreshMessages());
      }
    });
    debugPrint('ChatBloc: Started polling every 2 seconds');
  }
  
  void _stopPolling() {
    _pollingTimer?.cancel();
    debugPrint('ChatBloc: Stopped polling for messages');
  }
  
  void _setupSocketListeners() {
    // Listen for socket connection status
    _connectionSubscription = _socketService.connectionStream.listen((connected) {
      _isSocketConnected = connected;
      debugPrint('ChatBloc: Socket connection status changed: $connected');
      
      if (connected) {
        debugPrint('ChatBloc: Socket connected, but keeping polling as backup');
        // Keep polling but reduce frequency when socket is connected
        _pollingTimer?.cancel();
        _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
          if (state is ChatLoaded && _currentRoomId != null) {
            add(const RefreshMessages());
          }
        });
        
        // Join the room if we have one
        if (_currentRoomId != null) {
          _socketService.joinRoom(_currentRoomId!);
        }
      } else {
        debugPrint('ChatBloc: Socket disconnected, increasing polling frequency');
        _startPolling(); // More frequent polling when socket is down
      }
    });
    
    // Listen for incoming messages
    _messageSubscription = _socketService.messageStream.listen((messageData) {
      try {
        debugPrint('ChatBloc: Received socket message data: $messageData');
        final message = ChatMessage.fromJson(messageData);
        debugPrint('ChatBloc: Parsed socket message: ${message.content} from ${message.senderType}');
        add(ReceiveMessage(message));
      } catch (e) {
        debugPrint('ChatBloc: Error parsing socket message: $e');
        debugPrint('ChatBloc: Raw message data: $messageData');
        // Fallback to refreshing all messages
        add(const RefreshMessages());
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
      
      // Get chat history
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
        debugPrint('ChatBloc: Loaded ${messages.length} messages');
      } else {
        debugPrint('ChatBloc: Failed to load chat history: ${historyResult['message']}');
        // Continue with empty messages list
      }
      
      emit(ChatLoaded(
        chatRoom: chatRoom,
        messages: messages,
        currentUserId: currentUserId,
      ));
      
      // Setup socket listeners and try to connect
      _setupSocketListeners();
      add(const ConnectSocket());
      
      // Start polling immediately as primary method for real-time updates
      _startPolling();
      
      debugPrint('ChatBloc: Chat data loaded successfully');
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
        // Send via HTTP API
        debugPrint('ChatBloc: Sending message via HTTP API');
        final result = await ChatService.sendMessage(
          roomId: _currentRoomId!,
          content: event.content,
        );
        
        debugPrint('ChatBloc: HTTP send result: ${result['success']}');
        
        if (result['success'] == true) {
          debugPrint('ChatBloc: Message sent successfully via HTTP');
          
          // Also try to send via socket for real-time updates to other users
          if (_isSocketConnected) {
            debugPrint('ChatBloc: Also sending via socket for real-time update');
            _socketService.sendMessage(
              roomId: _currentRoomId!,
              content: event.content,
            );
          }
          
          // Wait a moment then refresh to get the real message from server
          await Future.delayed(const Duration(milliseconds: 800));
          
          if (!emit.isDone && state is ChatLoaded) {
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
        // Get updated chat history
        final historyResult = await ChatService.getChatHistory(_currentRoomId!);
        
        if (historyResult['success'] == true) {
          final historyData = historyResult['data'] as List<dynamic>;
          final messages = historyData
              .map((messageData) => ChatMessage.fromJson(messageData))
              .toList();
          
          // Sort messages by creation time
          messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          
          // Check if we have new messages
          final hasNewMessages = messages.length != _lastMessageCount;
          
          if (hasNewMessages) {
            debugPrint('ChatBloc: Found ${messages.length - _lastMessageCount} new messages');
            _lastMessageCount = messages.length;
          } else {
            debugPrint('ChatBloc: No new messages found (${messages.length} total)');
          }
          
          // Filter out any temporary optimistic messages and show real messages
          final realMessages = messages
              .where((msg) => !msg.id.startsWith('temp_'))
              .toList();
          
          emit(currentState.copyWith(
            messages: realMessages,
            isSendingMessage: false,
          ));
          
        } else {
          debugPrint('ChatBloc: Failed to refresh messages: ${historyResult['message']}');
          emit(currentState.copyWith(isSendingMessage: false));
        }
        
      } catch (e) {
        debugPrint('ChatBloc: Error refreshing messages: $e');
        emit(currentState.copyWith(isSendingMessage: false));
      }
    }
  }
  
  Future<void> _onConnectSocket(ConnectSocket event, Emitter<ChatState> emit) async {
    debugPrint('ChatBloc: Attempting to connect socket...');
    
    try {
      final connected = await _socketService.connect();
      if (connected) {
        debugPrint('ChatBloc: Socket connected successfully');
        // If we have a room, join it
        if (_currentRoomId != null) {
          _socketService.joinRoom(_currentRoomId!);
        }
      } else {
        debugPrint('ChatBloc: Socket connection failed, relying on polling');
      }
    } catch (e) {
      debugPrint('ChatBloc: Error connecting socket: $e');
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
      } else {
        debugPrint('ChatBloc: Message already exists, ignoring duplicate');
      }
    }
  }
}
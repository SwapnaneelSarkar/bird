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
    // Only use polling as fallback if socket is not connected
    if (!_isSocketConnected) {
      _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        if (state is ChatLoaded && _currentRoomId != null) {
          add(const RefreshMessages());
        }
      });
      debugPrint('ChatBloc: Started polling for new messages (fallback)');
    }
  }
  
  void _stopPolling() {
    _pollingTimer?.cancel();
    debugPrint('ChatBloc: Stopped polling for messages');
  }
  
  void _setupSocketListeners() {
    // Listen for socket connection status
    _connectionSubscription = _socketService.connectionStream.listen((connected) {
      _isSocketConnected = connected;
      if (connected) {
        debugPrint('ChatBloc: Socket connected, stopping polling');
        _stopPolling();
        // Join the room if we have one
        if (_currentRoomId != null) {
          _socketService.joinRoom(_currentRoomId!);
        }
      } else {
        debugPrint('ChatBloc: Socket disconnected, starting polling fallback');
        _startPolling();
      }
    });
    
    // Listen for incoming messages
    _messageSubscription = _socketService.messageStream.listen((messageData) {
      try {
        final message = ChatMessage.fromJson(messageData);
        add(ReceiveMessage(message));
      } catch (e) {
        debugPrint('ChatBloc: Error parsing socket message: $e');
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
      
      // Show sending state
      emit(currentState.copyWith(isSendingMessage: true));
      
      try {
        debugPrint('ChatBloc: Sending message: ${event.content}');
        
        // Always try HTTP API first for reliability
        debugPrint('ChatBloc: Sending message via HTTP API');
        final result = await ChatService.sendMessage(
          roomId: _currentRoomId!,
          content: event.content,
        );
        
        if (result['success'] == true) {
          debugPrint('ChatBloc: Message sent successfully via HTTP');
          
          // Also try to send via socket for real-time updates
          if (_isSocketConnected) {
            debugPrint('ChatBloc: Also sending via socket for real-time update');
            _socketService.sendMessage(
              roomId: _currentRoomId!,
              content: event.content,
            );
          }
          
          // Refresh messages to show the sent message
          add(const RefreshMessages());
          
          // Reset sending state
          emit(currentState.copyWith(isSendingMessage: false));
        } else {
          debugPrint('ChatBloc: Failed to send message via HTTP: ${result['message']}');
          emit(currentState.copyWith(isSendingMessage: false));
          
          // Show error message to user
          // You could emit a different state here to show error
        }
        
      } catch (e) {
        debugPrint('ChatBloc: Error sending message: $e');
        emit(currentState.copyWith(isSendingMessage: false));
      }
    }
  }
  
  Future<void> _sendViaHttp(String content, ChatLoaded currentState, Emitter<ChatState> emit) async {
    final result = await ChatService.sendMessage(
      roomId: _currentRoomId!,
      content: content,
    );
    
    if (result['success'] == true) {
      debugPrint('ChatBloc: Message sent successfully via HTTP');
      
      // Wait a moment for the server to process
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Refresh messages to show the sent message
      add(const RefreshMessages());
    } else {
      debugPrint('ChatBloc: Failed to send message via HTTP: ${result['message']}');
      emit(currentState.copyWith(isSendingMessage: false));
    }
  }
  
  Future<void> _onRefreshMessages(RefreshMessages event, Emitter<ChatState> emit) async {
    if (state is ChatLoaded && _currentRoomId != null) {
      final currentState = state as ChatLoaded;
      
      try {
        debugPrint('ChatBloc: Refreshing messages for room: $_currentRoomId');
        
        // Get updated chat history
        final historyResult = await ChatService.getChatHistory(_currentRoomId!);
        
        if (historyResult['success'] == true) {
          final historyData = historyResult['data'] as List<dynamic>;
          final messages = historyData
              .map((messageData) => ChatMessage.fromJson(messageData))
              .toList();
          
          // Sort messages by creation time
          messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          
          debugPrint('ChatBloc: Refreshed with ${messages.length} messages');
          
          // Check if we have new messages
          final hadNewMessages = messages.length != currentState.messages.length;
          
          emit(currentState.copyWith(
            messages: messages,
            isSendingMessage: false,
          ));
          
          // If no new messages and we're not sending, try again after a delay
          if (!hadNewMessages && currentState.isSendingMessage) {
            debugPrint('ChatBloc: No new messages found, retrying in 1 second...');
            await Future.delayed(const Duration(seconds: 1));
            if (state is ChatLoaded && _currentRoomId != null) {
              add(const RefreshMessages());
            }
          }
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
        debugPrint('ChatBloc: Socket connection failed, using polling fallback');
        _startPolling();
      }
    } catch (e) {
      debugPrint('ChatBloc: Error connecting socket: $e');
      _startPolling();
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
      
      // Check if message is already in the list to avoid duplicates
      final existingMessageIndex = currentState.messages
          .indexWhere((msg) => msg.id == event.message.id);
      
      if (existingMessageIndex == -1) {
        // Add new message to the list
        final updatedMessages = [...currentState.messages, event.message];
        
        // Sort by creation time
        updatedMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        
        debugPrint('ChatBloc: Added new message from socket: ${event.message.content}');
        
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
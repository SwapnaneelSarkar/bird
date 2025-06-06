import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/chat_models.dart';
import '../../service/chat_service.dart';
import '../../service/token_service.dart';
import 'event.dart';
import 'state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  String? _currentRoomId;
  Timer? _pollingTimer;
  
  ChatBloc() : super(ChatInitial()) {
    on<LoadChatData>(_onLoadChatData);
    on<SendMessage>(_onSendMessage);
    on<RefreshMessages>(_onRefreshMessages);
  }
  
  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    return super.close();
  }
  
  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (state is ChatLoaded && _currentRoomId != null) {
        add(const RefreshMessages());
      }
    });
    debugPrint('ChatBloc: Started polling for new messages');
  }
  
  void _stopPolling() {
    _pollingTimer?.cancel();
    debugPrint('ChatBloc: Stopped polling for messages');
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
      
      // Start polling for new messages
      _startPolling();
      
      debugPrint('ChatBloc: Chat data loaded successfully');
    } catch (e, stackTrace) {
      debugPrint('ChatBloc: Error loading chat data: $e');
      debugPrint('ChatBloc: Stack trace: $stackTrace');
      emit(const ChatError('Failed to load chat. Please try again.'));
    }
  }
  
  Future<void> _onSendMessage(SendMessage event, Emitter<ChatState> emit) async {
    if (state is ChatLoaded && _currentRoomId != null) {
      final currentState = state as ChatLoaded;
      
      // Show sending state
      emit(currentState.copyWith(isSendingMessage: true));
      
      try {
        debugPrint('ChatBloc: Sending message: ${event.content}');
        
        // Send message via API
        final result = await ChatService.sendMessage(
          roomId: _currentRoomId!,
          content: event.content,
        );
        
        if (result['success'] == true) {
          debugPrint('ChatBloc: Message sent successfully');
          
          // Refresh messages immediately to show the sent message
          add(const RefreshMessages());
        } else {
          debugPrint('ChatBloc: Failed to send message: ${result['message']}');
          emit(currentState.copyWith(isSendingMessage: false));
          
          // You could emit a snackbar message here if needed
        }
        
      } catch (e) {
        debugPrint('ChatBloc: Error sending message: $e');
        emit(currentState.copyWith(isSendingMessage: false));
      }
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
          
          emit(currentState.copyWith(
            messages: messages,
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
}
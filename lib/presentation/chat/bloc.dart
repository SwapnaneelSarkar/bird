import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'event.dart';
import 'state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc() : super(ChatInitial()) {
    on<LoadChatData>(_onLoadChatData);
    on<SendMessage>(_onSendMessage);
    on<ReceiveMessage>(_onReceiveMessage);
  }
  
  Future<void> _onLoadChatData(LoadChatData event, Emitter<ChatState> emit) async {
    emit(ChatLoading());
    
    try {
      debugPrint('ChatBloc: Loading chat data for order: ${event.orderId}');
      
      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Mock order info
      const orderInfo = ChatOrderInfo(
        orderId: '#2504',
        restaurantName: 'Italian Restaurant',
        estimatedDelivery: '30 mins',
        status: 'Preparing',
      );
      
      // Mock messages with exact content from the design
      final messages = [
        const ChatMessage(
          id: '1',
          message: 'Hi! Your order has been confirmed.\nWe\'ll start preparing it right away!',
          isUserMessage: false,
          time: '10:30 AM',
        ),
        const ChatMessage(
          id: '2',
          message: 'Great! Could you please make sure the pasta is extra spicy?',
          isUserMessage: true,
          time: '10:31 AM',
        ),
        const ChatMessage(
          id: '3',
          message: 'Of course! I\'ve added a note for extra spicy pasta to your order.',
          isUserMessage: false,
          time: '10:32 AM',
        ),
        const ChatMessage(
          id: '4',
          message: 'Thank you! How long will it take?',
          isUserMessage: true,
          time: '10:33 AM',
        ),
        const ChatMessage(
          id: '5',
          message: 'Your order will be ready in about 20 minutes. We\'ll notify you when it\'s ready for pickup!',
          isUserMessage: false,
          time: '10:34 AM',
        ),
      ];
      
      emit(ChatLoaded(
        orderInfo: orderInfo,
        messages: messages,
      ));
      
      debugPrint('ChatBloc: Chat data loaded successfully');
    } catch (e) {
      debugPrint('ChatBloc: Error loading chat data: $e');
      emit(const ChatError('Failed to load chat. Please try again.'));
    }
  }
  
  Future<void> _onSendMessage(SendMessage event, Emitter<ChatState> emit) async {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      
      // Show sending state
      emit(currentState.copyWith(isSendingMessage: true));
      
      try {
        debugPrint('ChatBloc: Sending message: ${event.message}');
        
        // Create new user message
        final newMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          message: event.message,
          isUserMessage: true,
          time: _getCurrentTime(),
        );
        
        // Add message to list
        final updatedMessages = [...currentState.messages, newMessage];
        
        emit(currentState.copyWith(
          messages: updatedMessages,
          isSendingMessage: false,
        ));
        
        // Simulate API call
        await Future.delayed(const Duration(milliseconds: 500));
        
        debugPrint('ChatBloc: Message sent successfully');
        
        // Simulate auto-response after a delay
        await Future.delayed(const Duration(seconds: 2));
        add(const ReceiveMessage('Thank you for your message! We\'ll get back to you shortly.'));
        
      } catch (e) {
        debugPrint('ChatBloc: Error sending message: $e');
        emit(currentState.copyWith(isSendingMessage: false));
        // You could emit an error state here if needed
      }
    }
  }
  
  Future<void> _onReceiveMessage(ReceiveMessage event, Emitter<ChatState> emit) async {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      
      try {
        debugPrint('ChatBloc: Receiving message: ${event.message}');
        
        // Create new restaurant message
        final newMessage = ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          message: event.message,
          isUserMessage: false,
          time: _getCurrentTime(),
        );
        
        // Add message to list
        final updatedMessages = [...currentState.messages, newMessage];
        
        emit(currentState.copyWith(messages: updatedMessages));
        
        debugPrint('ChatBloc: Message received successfully');
      } catch (e) {
        debugPrint('ChatBloc: Error receiving message: $e');
      }
    }
  }
  
  String _getCurrentTime() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : now.hour;
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
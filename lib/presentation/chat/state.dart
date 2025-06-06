import 'package:equatable/equatable.dart';
import '../../models/chat_models.dart';

abstract class ChatState extends Equatable {
  const ChatState();
  
  @override
  List<Object?> get props => [];
}

class ChatOrderInfo {
  final String orderId;
  final String restaurantName;
  final String estimatedDelivery;
  final String status;
  
  const ChatOrderInfo({
    required this.orderId,
    required this.restaurantName,
    required this.estimatedDelivery,
    required this.status,
  });
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final ChatRoom chatRoom;
  final List<ChatMessage> messages;
  final String currentUserId;
  final bool isSendingMessage;
  
  const ChatLoaded({
    required this.chatRoom,
    required this.messages,
    required this.currentUserId,
    this.isSendingMessage = false,
  });
  
  @override
  List<Object?> get props => [chatRoom, messages, currentUserId, isSendingMessage];
  
  ChatLoaded copyWith({
    ChatRoom? chatRoom,
    List<ChatMessage>? messages,
    String? currentUserId,
    bool? isSendingMessage,
  }) {
    return ChatLoaded(
      chatRoom: chatRoom ?? this.chatRoom,
      messages: messages ?? this.messages,
      currentUserId: currentUserId ?? this.currentUserId,
      isSendingMessage: isSendingMessage ?? this.isSendingMessage,
    );
  }
}

class ChatError extends ChatState {
  final String message;
  
  const ChatError(this.message);
  
  @override
  List<Object?> get props => [message];
}
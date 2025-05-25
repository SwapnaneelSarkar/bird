import 'package:equatable/equatable.dart';

abstract class ChatState extends Equatable {
  const ChatState();
  
  @override
  List<Object?> get props => [];
}

class ChatMessage {
  final String message;
  final bool isUserMessage;
  final String time;
  final String id;
  
  const ChatMessage({
    required this.message,
    required this.isUserMessage,
    required this.time,
    required this.id,
  });
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
  final ChatOrderInfo orderInfo;
  final List<ChatMessage> messages;
  final bool isSendingMessage;
  
  const ChatLoaded({
    required this.orderInfo,
    required this.messages,
    this.isSendingMessage = false,
  });
  
  @override
  List<Object?> get props => [orderInfo, messages, isSendingMessage];
  
  ChatLoaded copyWith({
    ChatOrderInfo? orderInfo,
    List<ChatMessage>? messages,
    bool? isSendingMessage,
  }) {
    return ChatLoaded(
      orderInfo: orderInfo ?? this.orderInfo,
      messages: messages ?? this.messages,
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
import 'package:equatable/equatable.dart';
import '../../models/chat_models.dart';
import '../../models/order_details_model.dart';

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
  final OrderDetails? orderDetails; // Add order details
  final Map<String, Map<String, dynamic>> menuItemDetails; // Add menu item details
  
  const ChatLoaded({
    required this.chatRoom,
    required this.messages,
    required this.currentUserId,
    this.isSendingMessage = false,
    this.orderDetails, // Add order details parameter
    this.menuItemDetails = const {}, // Add menu item details parameter
  });
  
  @override
  List<Object?> get props => [chatRoom, messages, currentUserId, isSendingMessage, orderDetails, menuItemDetails];
  
  ChatLoaded copyWith({
    ChatRoom? chatRoom,
    List<ChatMessage>? messages,
    String? currentUserId,
    bool? isSendingMessage,
    OrderDetails? orderDetails, // Add order details to copyWith
    Map<String, Map<String, dynamic>>? menuItemDetails, // Add menu item details to copyWith
  }) {
    return ChatLoaded(
      chatRoom: chatRoom ?? this.chatRoom,
      messages: messages ?? this.messages,
      currentUserId: currentUserId ?? this.currentUserId,
      isSendingMessage: isSendingMessage ?? this.isSendingMessage,
      orderDetails: orderDetails ?? this.orderDetails, // Add order details
      menuItemDetails: menuItemDetails ?? this.menuItemDetails, // Add menu item details
    );
  }
}

class ChatError extends ChatState {
  final String message;
  
  const ChatError(this.message);
  
  @override
  List<Object?> get props => [message];
}
import 'package:equatable/equatable.dart';
import '../../models/chat_models.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadChatData extends ChatEvent {
  final String orderId;
  
  const LoadChatData(this.orderId);
  
  @override
  List<Object?> get props => [orderId];
}

class SendMessage extends ChatEvent {
  final String content;
  
  const SendMessage(this.content);
  
  @override
  List<Object?> get props => [content];
}

class RefreshMessages extends ChatEvent {
  const RefreshMessages();
}

class ConnectSocket extends ChatEvent {
  const ConnectSocket();
}

class DisconnectSocket extends ChatEvent {
  const DisconnectSocket();
}

class ReceiveMessage extends ChatEvent {
  final ChatMessage message;
  
  const ReceiveMessage(this.message);
  
  @override
  List<Object?> get props => [message];
}
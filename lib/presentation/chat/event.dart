import 'package:equatable/equatable.dart';

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
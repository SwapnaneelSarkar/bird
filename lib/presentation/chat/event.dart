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
  final String message;
  
  const SendMessage(this.message);
  
  @override
  List<Object?> get props => [message];
}

class ReceiveMessage extends ChatEvent {
  final String message;
  
  const ReceiveMessage(this.message);
  
  @override
  List<Object?> get props => [message];
}
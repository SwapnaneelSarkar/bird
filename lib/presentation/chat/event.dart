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

class MarkAsRead extends ChatEvent {
  final String roomId;
  
  const MarkAsRead(this.roomId);
  
  @override
  List<Object?> get props => [roomId];
}

class StartTyping extends ChatEvent {
  const StartTyping();
}

class StopTyping extends ChatEvent {
  const StopTyping();
}

class UpdateMessageReadStatus extends ChatEvent {
  final Map<String, dynamic> readData;
  
  const UpdateMessageReadStatus(this.readData);
  
  @override
  List<Object?> get props => [readData];
}

class ChatPageOpened extends ChatEvent {
  const ChatPageOpened();
}

class ChatPageClosed extends ChatEvent {
  const ChatPageClosed();
}

class MessageReceivedOnActivePage extends ChatEvent {
  final ChatMessage message;
  
  const MessageReceivedOnActivePage(this.message);
  
  @override
  List<Object?> get props => [message];
}

class UpdateBlueTicksForPreviousMessages extends ChatEvent {
  const UpdateBlueTicksForPreviousMessages();
}

class AppResumed extends ChatEvent {
  const AppResumed();
}

class AppPaused extends ChatEvent {
  const AppPaused();
}

class BackgroundMessageReceived extends ChatEvent {
  final Map<String, dynamic> messageData;
  
  const BackgroundMessageReceived(this.messageData);
  
  @override
  List<Object?> get props => [messageData];
}

class TestStatusUpdate extends ChatEvent {
  const TestStatusUpdate();
}
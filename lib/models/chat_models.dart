// models/chat_models.dart

class ChatRoom {
  final String id;
  final String roomId;
  final String orderId;
  final List<ChatParticipant> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final DateTime createdAt;

  ChatRoom({
    required this.id,
    required this.roomId,
    required this.orderId,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.createdAt,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['_id'] ?? '',
      roomId: json['roomId'] ?? '',
      orderId: json['orderId'] ?? '',
      participants: (json['participants'] as List<dynamic>?)
          ?.map((p) => ChatParticipant.fromJson(p))
          .toList() ?? [],
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime: DateTime.tryParse(json['lastMessageTime'] ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class ChatParticipant {
  final String userId;
  final String userType;
  final String id;

  ChatParticipant({
    required this.userId,
    required this.userType,
    required this.id,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      userId: json['userId'] ?? '',
      userType: json['userType'] ?? '',
      id: json['_id'] ?? '',
    );
  }
}

class ChatMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String senderType;
  final String content;
  final String messageType;
  final List<String> readBy;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderType,
    required this.content,
    required this.messageType,
    required this.readBy,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['_id'] ?? '',
      roomId: json['roomId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderType: json['senderType'] ?? '',
      content: json['content'] ?? '',
      messageType: json['messageType'] ?? 'text',
      readBy: (json['readBy'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  // Helper method to determine if message is from current user
  bool isFromCurrentUser(String currentUserId) {
    return senderId == currentUserId;
  }

  // Helper method to get formatted time
  String get formattedTime {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(createdAt.year, createdAt.month, createdAt.day);
    
    if (messageDate == today) {
      // Today - show time only
      return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    } else {
      // Other days - show date and time
      return '${createdAt.day}/${createdAt.month} ${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
    }
  }
}
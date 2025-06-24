import 'package:intl/intl.dart';
import '../utils/timezone_utils.dart';

// ReadByEntry Model as per document
class ReadByEntry {
  final String userId;
  final DateTime readAt;
  final String id;

  ReadByEntry({
    required this.userId,
    required this.readAt,
    required this.id,
  });

  factory ReadByEntry.fromJson(Map<String, dynamic> json) {
    return ReadByEntry(
      userId: json['userId'] ?? '',
      readAt: TimezoneUtils.parseToIST(json['readAt']),
      id: json['_id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'readAt': readAt.toIso8601String(),
      '_id': id,
    };
  }
}

// ApiChatMessage Model as per document
class ApiChatMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String senderType;
  final String content;
  final String messageType;
  final List<ReadByEntry> readBy;
  final DateTime createdAt;

  ApiChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.senderType,
    required this.content,
    required this.messageType,
    required this.readBy,
    required this.createdAt,
  });

  factory ApiChatMessage.fromJson(Map<String, dynamic> json) {
    return ApiChatMessage(
      id: json['_id'] ?? json['id'] ?? '',
      roomId: json['roomId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderType: json['senderType'] ?? '',
      content: json['content'] ?? '',
      messageType: json['messageType'] ?? 'text',
      readBy: (json['readBy'] as List<dynamic>?)
          ?.map((e) => ReadByEntry.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: TimezoneUtils.parseToIST(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'roomId': roomId,
      'senderId': senderId,
      'senderType': senderType,
      'content': content,
      'messageType': messageType,
      'readBy': readBy.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Check if this message is from current user
  bool isFromCurrentUser(String? currentUserId) {
    if (currentUserId == null || currentUserId.isEmpty) return false;
    return senderId == currentUserId;
  }

  // Check if message is read by anyone other than sender  
  bool isReadByOthers(String senderId) {
    return readBy.any((entry) => entry.userId != senderId);
  }

  // Get read status for UI (blue tick if read, grey if not)
  bool get isRead => readBy.isNotEmpty && readBy.any((entry) => entry.userId != senderId);

  // Enhanced method to check if read by others for UI
  // bool isReadByOthers(String currentUserId) {
  //   // For messages sent by current user, check if read by others (partner/support)
  //   if (senderId == currentUserId) {
  //     return readBy.any((entry) => entry.userId != currentUserId);
  //   }
  //   // For messages from others, always return false (we don't show read status on incoming messages)
  //   return false;
  // }
}

// ChatMessage Model (for UI) - Enhanced with read receipt support
class ChatMessage {
  final String id;
  final String roomId;
  final String senderId;
  final String senderType;
  final String content;
  final String messageType;
  final List<ReadByEntry> readBy;
  final DateTime createdAt;

  const ChatMessage({
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
      id: json['_id'] ?? json['id'] ?? '',
      roomId: json['roomId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderType: json['senderType'] ?? '',
      content: json['content'] ?? '',
      messageType: json['messageType'] ?? 'text',
      readBy: (json['readBy'] as List<dynamic>?)
          ?.map((e) => ReadByEntry.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: TimezoneUtils.parseToIST(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'roomId': roomId,
      'senderId': senderId,
      'senderType': senderType,
      'content': content,
      'messageType': messageType,
      'readBy': readBy.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Check if this message is from current user
  bool isFromCurrentUser(String? currentUserId) {
    if (currentUserId == null || currentUserId.isEmpty) return false;
    return senderId == currentUserId;
  }

  // Check if message is read by anyone other than sender
  bool isReadByOthers(String senderId) {
    return readBy.any((entry) => entry.userId != senderId);
  }

  // Get read status for UI (blue tick if read, grey if not)
  bool get isRead => readBy.isNotEmpty && readBy.any((entry) => entry.userId != senderId);

  // Get formatted time string
  String get formattedTime {
    return TimezoneUtils.formatChatTime(createdAt);
  }
}

// ChatRoom Model with participants
class ChatRoom {
  final String id;
  final String roomId;
  final String orderId;
  final List<Participant> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final DateTime createdAt;

  ChatRoom({
    required this.id,
    required this.roomId,
    required this.orderId,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    required this.createdAt,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['_id'] ?? '',
      roomId: json['roomId'] ?? '',
      orderId: json['orderId'] ?? '',
      participants: (json['participants'] as List<dynamic>?)
          ?.map((e) => Participant.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      lastMessage: json['lastMessage'],
      lastMessageTime: json['lastMessageTime'] != null 
          ? TimezoneUtils.parseToIST(json['lastMessageTime'])
          : null,
      createdAt: TimezoneUtils.parseToIST(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'roomId': roomId,
      'orderId': orderId,
      'participants': participants.map((e) => e.toJson()).toList(),
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

// Participant Model
class Participant {
  final String userId;
  final String userType;

  Participant({
    required this.userId,
    required this.userType,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      userId: json['userId'] ?? '',
      userType: json['userType'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userType': userType,
    };
  }
}
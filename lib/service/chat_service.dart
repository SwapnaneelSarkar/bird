import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constant.dart';
import '../service/token_service.dart';

class ChatService {
  // API Base URLs from document
  static const String baseUrl = 'https://api.bird.delivery/api/';
  
  // 1. Get Chat Rooms - As per document
  static Future<Map<String, dynamic>> getChatRooms() async {
    try {
      debugPrint('ChatService: Getting chat rooms');
      
      final token = await TokenService.getToken();
      final userId = await TokenService.getUserId();
      
      if (token == null || userId == null) {
        return {
          'success': false,
          'message': 'Authentication token or user ID not found. Please login again.',
        };
      }
      
      // Query params: userId={userId}&userType=user
      final url = Uri.parse('${baseUrl}chat/rooms/').replace(queryParameters: {
        'userId': userId,
        'userType': 'user',
      });
      
      debugPrint('ChatService: Chat rooms URL: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      debugPrint('ChatService: Chat rooms response status: ${response.statusCode}');
      debugPrint('ChatService: Chat rooms response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Response is array of ChatRoom objects
        if (responseData is List) {
          debugPrint('ChatService: Chat rooms retrieved successfully');
          debugPrint('ChatService: Room count: ${responseData.length}');
          
          return {
            'success': true,
            'message': 'Chat rooms retrieved successfully',
            'data': responseData,
          };
        } else {
          debugPrint('ChatService: Unexpected response format');
          return {
            'success': false,
            'message': 'Unexpected response format',
          };
        }
      } else {
        debugPrint('ChatService: Chat rooms server error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server error occurred. Please try again.',
        };
      }
    } catch (e) {
      debugPrint('ChatService: Chat rooms exception: $e');
      return {
        'success': false,
        'message': 'Network error occurred. Please check your connection.',
      };
    }
  }

  // 2. Create or get chat room for an order (Modified to match document)
  static Future<Map<String, dynamic>> createOrGetChatRoom(String orderId) async {
    try {
      debugPrint('ChatService: Creating/Getting chat room for order: $orderId');
      
      final token = await TokenService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found. Please login again.',
        };
      }
      
      // This might be a custom endpoint for your app
      final url = Uri.parse('${baseUrl}chat/rooms/$orderId');
      
      debugPrint('ChatService: Chat room URL: $url');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      debugPrint('ChatService: Chat room response status: ${response.statusCode}');
      debugPrint('ChatService: Chat room response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['status'] == 'SUCCESS') {
          debugPrint('ChatService: Chat room retrieved/created successfully');
          debugPrint('ChatService: Room ID: ${responseData['data']['roomId']}');
          
          return {
            'success': true,
            'message': responseData['message'] ?? 'Chat room retrieved successfully',
            'data': responseData['data'],
          };
        } else {
          debugPrint('ChatService: Chat room operation failed: ${responseData['message']}');
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to get chat room',
          };
        }
      } else {
        debugPrint('ChatService: Chat room server error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server error occurred. Please try again.',
        };
      }
    } catch (e) {
      debugPrint('ChatService: Chat room exception: $e');
      return {
        'success': false,
        'message': 'Network error occurred. Please check your connection.',
      };
    }
  }
  
  // 3. Get Message History - As per document
  static Future<Map<String, dynamic>> getChatHistory(String roomId, {int limit = 100}) async {
    try {
      debugPrint('ChatService: Getting chat history for room: $roomId');
      
      final token = await TokenService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found. Please login again.',
        };
      }
      
      // Endpoint: GET /chat/history/{roomId}
      final url = Uri.parse('${baseUrl}chat/history/$roomId').replace(queryParameters: {
        'limit': limit.toString(),
      });
      
      debugPrint('ChatService: Chat history URL: $url');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      debugPrint('ChatService: Chat history response status: ${response.statusCode}');
      debugPrint('ChatService: Chat history response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // The response is directly an array of ChatMessage objects
        if (responseData is List) {
          debugPrint('ChatService: Chat history retrieved successfully');
          debugPrint('ChatService: Message count: ${responseData.length}');
          
          return {
            'success': true,
            'message': 'Chat history retrieved successfully',
            'data': responseData,
          };
        } else {
          debugPrint('ChatService: Unexpected response format');
          return {
            'success': false,
            'message': 'Unexpected response format',
          };
        }
      } else {
        debugPrint('ChatService: Chat history server error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server error occurred. Please try again.',
        };
      }
    } catch (e) {
      debugPrint('ChatService: Chat history exception: $e');
      return {
        'success': false,
        'message': 'Network error occurred. Please check your connection.',
      };
    }
  }
  
  // 4. Send Message (Persistence) - Updated to match document format
  static Future<Map<String, dynamic>> sendMessage({
    required String roomId,
    required String content,
    String messageType = 'text',
  }) async {
    try {
      debugPrint('ChatService: Sending message to room: $roomId');
      debugPrint('ChatService: Message content: $content');
      
      final token = await TokenService.getToken();
      final userId = await TokenService.getUserId();
      
      if (token == null || userId == null) {
        return {
          'success': false,
          'message': 'Authentication token or user ID not found. Please login again.',
        };
      }
      
      // Endpoint: POST /chat/message
      final url = Uri.parse('${baseUrl}chat/message');
      
      // Body format as per document
      final body = {
        'roomId': roomId,
        'senderId': userId,
        'senderType': 'user',  // Always 'user' for customer app
        'content': content,
        'messageType': messageType,
      };
      
      debugPrint('ChatService: Send message URL: $url');
      debugPrint('ChatService: Send message body: ${jsonEncode(body)}');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      
      debugPrint('ChatService: Send message response status: ${response.statusCode}');
      debugPrint('ChatService: Send message response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        
        // Response format as per document: ChatMessage object with _id
        if (responseData['_id'] != null) {
          debugPrint('ChatService: Message sent successfully');
          debugPrint('ChatService: Message ID: ${responseData['_id']}');
          
          return {
            'success': true,
            'message': 'Message sent successfully',
            'data': responseData,
          };
        } else if (responseData['status'] == 'SUCCESS' || responseData['status'] == true) {
          debugPrint('ChatService: Message sent successfully (with status)');
          
          return {
            'success': true,
            'message': responseData['message'] ?? 'Message sent successfully',
            'data': responseData['data'] ?? responseData,
          };
        } else {
          debugPrint('ChatService: Message send failed: ${responseData['message']}');
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to send message',
          };
        }
      } else {
        debugPrint('ChatService: Send message server error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server error occurred. Please try again.',
        };
      }
    } catch (e) {
      debugPrint('ChatService: Send message exception: $e');
      return {
        'success': false,
        'message': 'Network error occurred. Please check your connection.',
      };
    }
  }

  // 5. Mark Messages as Read - Enhanced with better error handling
  static Future<Map<String, dynamic>> markMessagesAsRead({
    required String roomId,
  }) async {
    try {
      debugPrint('ChatService: Marking messages as read for room: $roomId');
      
      final token = await TokenService.getToken();
      final userId = await TokenService.getUserId();
      
      if (token == null || userId == null) {
        debugPrint('ChatService: Missing auth credentials for mark as read');
        return {
          'success': false,
          'message': 'Authentication token or user ID not found. Please login again.',
        };
      }
      
      // Endpoint: POST /chat/read
      final url = Uri.parse('${baseUrl}chat/read');
      
      // Body format as per document
      final body = {
        'roomId': roomId,
        'userId': userId,
      };
      
      debugPrint('ChatService: Mark as read URL: $url');
      debugPrint('ChatService: Mark as read body: ${jsonEncode(body)}');
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );
      
      debugPrint('ChatService: Mark as read response status: ${response.statusCode}');
      debugPrint('ChatService: Mark as read response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Response format as per document: {"success": boolean}
        if (responseData['success'] == true) {
          debugPrint('ChatService: Messages marked as read successfully via API');
          
          return {
            'success': true,
            'message': 'Messages marked as read successfully',
            'data': responseData,
          };
        } else {
          debugPrint('ChatService: API returned success=false for mark as read');
          return {
            'success': false,
            'message': responseData['message'] ?? 'Failed to mark messages as read',
          };
        }
      } else if (response.statusCode == 404) {
        debugPrint('ChatService: Mark as read endpoint not found (404)');
        return {
          'success': false,
          'message': 'Mark as read feature not available on server',
        };
      } else {
        debugPrint('ChatService: Mark as read server error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server error occurred while marking messages as read. Please try again.',
        };
      }
    } catch (e) {
      debugPrint('ChatService: Mark as read exception: $e');
      return {
        'success': false,
        'message': 'Network error occurred while marking messages as read. Please check your connection.',
      };
    }
  }
}
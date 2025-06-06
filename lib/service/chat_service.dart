import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constant.dart';
import '../service/token_service.dart';

class ChatService {
  // Create or get chat room for an order
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
      
      final url = Uri.parse('${ApiConstants.baseUrl}/api/chat/rooms/$orderId');
      
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
  
  // Get chat history for a room
  static Future<Map<String, dynamic>> getChatHistory(String roomId) async {
    try {
      debugPrint('ChatService: Getting chat history for room: $roomId');
      
      final token = await TokenService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found. Please login again.',
        };
      }
      
      final url = Uri.parse('${ApiConstants.baseUrl}/api/chat/history/$roomId');
      
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
        
        // The response is directly an array of messages
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
  
  // Send a message with the correct API format - FIXED VERSION
  static Future<Map<String, dynamic>> sendMessage({
    required String roomId,
    required String content,
    String messageType = 'text',
  }) async {
    try {
      debugPrint('ChatService: Sending message to room: $roomId');
      debugPrint('ChatService: Message content: $content');
      
      final token = await TokenService.getToken();
      if (token == null) {
        return {
          'success': false,
          'message': 'Authentication token not found. Please login again.',
        };
      }
      
      // Get current user ID
      final userId = await TokenService.getUserId();
      if (userId == null) {
        return {
          'success': false,
          'message': 'User ID not found. Please login again.',
        };
      }
      
      final url = Uri.parse('${ApiConstants.baseUrl}/api/chat/message');
      
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
        
        // FIXED: Check for the actual response format from the API
        // The API returns the message object directly without a status field
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
}
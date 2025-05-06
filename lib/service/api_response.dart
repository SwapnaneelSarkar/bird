import 'package:flutter/foundation.dart';
import 'api_exception.dart';

class ApiResponse<T> {
  ApiStatus status;
  T? data;
  String? message;
  int? statusCode;

  ApiResponse.initial() : status = ApiStatus.initial;
  ApiResponse.loading() : status = ApiStatus.loading;
  ApiResponse.completed(this.data) : status = ApiStatus.completed;
  ApiResponse.error(this.message, {this.statusCode}) : status = ApiStatus.error;

  @override
  String toString() {
    return "Status: $status \nMessage: $message \nData: $data";
  }
}

enum ApiStatus { initial, loading, completed, error }

class ApiResponseHandler {
  // Debug print API request details
  static void debugPrintRequest({
    required String url,
    required String method,
    Map<String, dynamic>? headers,
    dynamic body,
  }) {
    if (kDebugMode) {
      print('╔══════════════ API REQUEST ══════════════╗');
      print('║ URL: $url');
      print('║ Method: $method');
      if (headers != null) {
        print('║ Headers:');
        headers.forEach((key, value) {
          if (key.toLowerCase() != 'authorization') {
            print('║   $key: $value');
          } else {
            print('║   $key: [REDACTED]');
          }
        });
      }
      if (body != null) {
        print('║ Body:');
        if (body is Map) {
          body.forEach((key, value) {
            if (key.toString().toLowerCase().contains('password')) {
              print('║   $key: [REDACTED]');
            } else {
              print('║   $key: $value');
            }
          });
        } else {
          print('║   $body');
        }
      }
      print('╚════════════════════════════════════════╝');
    }
  }

  // Debug print API response details
  static void debugPrintResponse({
    required String url,
    required int statusCode,
    dynamic body,
    dynamic error,
  }) {
    if (kDebugMode) {
      print('╔══════════════ API RESPONSE ══════════════╗');
      print('║ URL: $url');
      print('║ Status Code: $statusCode');
      if (error != null) {
        print('║ Error: $error');
      }
      if (body != null) {
        print('║ Body:');
        if (body is Map) {
          body.forEach((key, value) {
            print('║   $key: $value');
          });
        } else {
          print('║   $body');
        }
      }
      print('╚═════════════════════════════════════════╝');
    }
  }

  // Handle API exceptions and return a user-friendly error message
  static String handleApiException(dynamic error) {
    if (error is ApiException) {
      return error.message;
    } else if (error.toString().contains('SocketException')) {
      return 'Network error. Please check your internet connection.';
    } else if (error.toString().contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }
}
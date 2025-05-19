// utils/image_cache_manager.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:typed_data';

class ImageCacheManager {
  static final ImageCacheManager _instance = ImageCacheManager._internal();
  static ImageCacheManager get instance => _instance;
  
  // In-memory cache
  final Map<String, Uint8List> _memoryCache = {};
  
  // Private constructor
  ImageCacheManager._internal();
  
  // Get image from cache or network
  Future<Uint8List?> getImage(String url) async {
    final cacheKey = _generateCacheKey(url);
    
    // 1. Try memory cache first
    if (_memoryCache.containsKey(cacheKey)) {
      debugPrint('Found image in memory cache: $url');
      return _memoryCache[cacheKey];
    }
    
    // 2. Try disk cache
    try {
      final file = await _getCachedImageFile(cacheKey);
      if (await file.exists()) {
        debugPrint('Found image in disk cache: $url');
        final bytes = await file.readAsBytes();
        // Store in memory cache
        _memoryCache[cacheKey] = bytes;
        return bytes;
      }
    } catch (e) {
      debugPrint('Error reading from disk cache: $e');
    }
    
    // 3. Download and cache
    try {
      debugPrint('Downloading image: $url');
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        
        // Save to memory cache
        _memoryCache[cacheKey] = bytes;
        
        // Save to disk cache
        try {
          final file = await _getCachedImageFile(cacheKey);
          await file.writeAsBytes(bytes);
          debugPrint('Image cached successfully: $url');
        } catch (e) {
          debugPrint('Error writing to disk cache: $e');
        }
        
        return bytes;
      } else {
        debugPrint('Failed to download image. Status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error downloading image: $e');
      return null;
    }
  }
  
  Future<File> _getCachedImageFile(String cacheKey) async {
    final cacheDir = await _getCacheDirectory();
    return File('${cacheDir.path}/$cacheKey');
  }
  
  Future<Directory> _getCacheDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final cachePath = '${directory.path}/image_cache';
    final cacheDir = Directory(cachePath);
    
    // Create cache directory if it doesn't exist
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    
    return cacheDir;
  }
  
  String _generateCacheKey(String url) {
    final bytes = utf8.encode(url);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  // Clear cache
  Future<void> clearCache() async {
    // Clear memory cache
    _memoryCache.clear();
    
    // Clear disk cache
    try {
      final cacheDir = await _getCacheDirectory();
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('Error clearing disk cache: $e');
    }
  }
}
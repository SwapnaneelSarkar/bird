// utils/custom_cache_manager.dart
import 'package:flutter_cache_manager/flutter_cache_manager.dart';


class CustomCacheManager {
  static const key = 'birdAppCustomCache';
  
  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
      fileService: HttpFileService(),
    ),
  );
}
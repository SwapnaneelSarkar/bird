// lib/utils/performance_monitor.dart
import 'package:flutter/foundation.dart';

class PerformanceMonitor {
  static final Map<String, DateTime> _startTimes = {};
  static final Map<String, List<Duration>> _measurements = {};
  
  /// Start timing a performance measurement
  static void startTimer(String operationName) {
    _startTimes[operationName] = DateTime.now();
    debugPrint('⏱️ PerformanceMonitor: Started timing $operationName');
  }
  
  /// End timing and log the duration
  static Duration endTimer(String operationName) {
    final startTime = _startTimes[operationName];
    if (startTime == null) {
      debugPrint('⏱️ PerformanceMonitor: No start time found for $operationName');
      return Duration.zero;
    }
    
    final duration = DateTime.now().difference(startTime);
    _startTimes.remove(operationName);
    
    // Store measurement for averaging
    _measurements.putIfAbsent(operationName, () => []);
    _measurements[operationName]!.add(duration);
    
    // Keep only last 10 measurements
    if (_measurements[operationName]!.length > 10) {
      _measurements[operationName]!.removeAt(0);
    }
    
    debugPrint('⏱️ PerformanceMonitor: $operationName completed in ${duration.inMilliseconds}ms');
    
    // Log warning if operation takes too long
    if (duration.inMilliseconds > 3000) {
      debugPrint('⚠️ PerformanceMonitor: $operationName took ${duration.inMilliseconds}ms (slow!)');
    }
    
    return duration;
  }
  
  /// Get average duration for an operation
  static Duration getAverageDuration(String operationName) {
    final measurements = _measurements[operationName];
    if (measurements == null || measurements.isEmpty) {
      return Duration.zero;
    }
    
    final totalMilliseconds = measurements.fold<int>(0, (sum, duration) => sum + duration.inMilliseconds);
    final averageMilliseconds = totalMilliseconds ~/ measurements.length;
    
    return Duration(milliseconds: averageMilliseconds);
  }
  
  /// Get all performance statistics
  static Map<String, Duration> getAllAverages() {
    final averages = <String, Duration>{};
    for (final operationName in _measurements.keys) {
      averages[operationName] = getAverageDuration(operationName);
    }
    return averages;
  }
  
  /// Clear all measurements
  static void clearMeasurements() {
    _startTimes.clear();
    _measurements.clear();
    debugPrint('⏱️ PerformanceMonitor: Cleared all measurements');
  }
  
  /// Log all performance statistics
  static void logAllStatistics() {
    debugPrint('📊 PerformanceMonitor: Performance Statistics');
    debugPrint('==========================================');
    
    final averages = getAllAverages();
    if (averages.isEmpty) {
      debugPrint('No measurements available');
      return;
    }
    
    // Sort by average duration (slowest first)
    final sortedEntries = averages.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (final entry in sortedEntries) {
      final avgMs = entry.value.inMilliseconds;
      final icon = avgMs > 3000 ? '🐌' : avgMs > 1000 ? '⚠️' : '✅';
      debugPrint('$icon ${entry.key}: ${avgMs}ms average');
    }
    
    debugPrint('==========================================');
  }
} 
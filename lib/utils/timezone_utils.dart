import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class TimezoneUtils {
  static const String _istTimezone = 'Asia/Kolkata';
  
  // Initialize timezone data
  static void initialize() {
    tz.initializeTimeZones();
  }
  
  // Get current time in IST
  static DateTime getCurrentTimeIST() {
    return tz.TZDateTime.now(tz.getLocation(_istTimezone));
  }
  
  // Get current time (handles the case where local time is already IST)
  static DateTime getCurrentTime() {
    // Check if local time is already IST
    final localNow = DateTime.now();
    final istNow = getCurrentTimeIST();
    
    // If local time and IST time are very close (within 5 minutes), 
    // assume we're already in IST timezone
    final timeDiff = localNow.difference(istNow).abs();
    if (timeDiff.inMinutes <= 5) {
      // We're already in IST timezone, return local time
      return localNow;
    } else {
      // We're in a different timezone, return IST time
      return istNow;
    }
  }
  
  // Convert UTC DateTime to IST
  static DateTime convertToIST(DateTime utcDateTime) {
    return tz.TZDateTime.from(utcDateTime, tz.getLocation(_istTimezone));
  }
  
  // Convert any DateTime to IST (assuming it's in UTC if no timezone info)
  static DateTime toIST(DateTime dateTime) {
    // If the DateTime is already in UTC, convert it to IST
    if (dateTime.isUtc) {
      return convertToIST(dateTime);
    } else {
      // If it's not UTC, check if we're already in IST timezone
      // For simplicity, if the DateTime is not UTC, assume it's already in local time
      // and if local time is IST, return it as is
      
      // Get current local time and current IST time
      final localNow = DateTime.now();
      final istNow = getCurrentTimeIST();
      
      // If local time and IST time are very close (within 5 minutes), 
      // assume we're already in IST timezone
      final timeDiff = localNow.difference(istNow).abs();
      if (timeDiff.inMinutes <= 5) {
        // We're already in IST timezone, return the DateTime as is
        return dateTime;
      } else {
        // We're in a different timezone, need to convert
        // Treat the DateTime as UTC and convert to IST
        final utcDateTime = DateTime.utc(
          dateTime.year,
          dateTime.month,
          dateTime.day,
          dateTime.hour,
          dateTime.minute,
          dateTime.second,
          dateTime.millisecond,
          dateTime.microsecond,
        );
        return convertToIST(utcDateTime);
      }
    }
  }
  
  // Format DateTime to IST string with custom format
  static String formatToIST(DateTime dateTime, String format) {
    final istDateTime = toIST(dateTime);
    return DateFormat(format).format(istDateTime);
  }
  
  // Format for chat messages (MMM dd, hh:mm a or hh:mm a)
  static String formatChatTime(DateTime dateTime) {
    final istDateTime = toIST(dateTime);
    final now = getCurrentTimeIST();
    final difference = now.difference(istDateTime);
    
    if (difference.inDays > 0) {
      return DateFormat('MMM dd, hh:mm a').format(istDateTime);
    } else {
      return DateFormat('hh:mm a').format(istDateTime);
    }
  }
  
  // Format for order dates (MMM dd, yyyy)
  static String formatOrderDate(DateTime dateTime) {
    return formatToIST(dateTime, 'MMM dd, yyyy');
  }
  
  // Format for order date with time (MMM dd, yyyy HH:mm)
  static String formatOrderDateTime(DateTime dateTime) {
    return formatToIST(dateTime, 'MMM dd, yyyy HH:mm');
  }
  
  // Format for time only (hh:mm a)
  static String formatTimeOnly(DateTime dateTime) {
    return formatToIST(dateTime, 'hh:mm a');
  }
  
  // Format for date only (dd/MM/yyyy)
  static String formatDateOnly(DateTime dateTime) {
    return formatToIST(dateTime, 'dd/MM/yyyy');
  }
  
  // Parse string to DateTime and convert to IST
  static DateTime parseToIST(String dateTimeString) {
    try {
      final parsedDateTime = DateTime.parse(dateTimeString);
      return toIST(parsedDateTime);
    } catch (e) {
      // Return current IST time if parsing fails
      return getCurrentTimeIST();
    }
  }
  
  // Get IST timezone offset string
  static String getISTOffset() {
    final istLocation = tz.getLocation(_istTimezone);
    final now = tz.TZDateTime.now(istLocation);
    final offset = now.timeZoneOffset;
    final hours = offset.inHours.abs();
    final minutes = (offset.inMinutes.abs() % 60);
    final sign = offset.isNegative ? '-' : '+';
    return 'IST (GMT${sign}${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')})';
  }
  
  // Check if a DateTime is today in IST
  static bool isToday(DateTime dateTime) {
    final istDateTime = toIST(dateTime);
    final now = getCurrentTimeIST();
    return istDateTime.year == now.year &&
           istDateTime.month == now.month &&
           istDateTime.day == now.day;
  }
  
  // Check if a DateTime is yesterday in IST
  static bool isYesterday(DateTime dateTime) {
    final istDateTime = toIST(dateTime);
    final yesterday = getCurrentTimeIST().subtract(const Duration(days: 1));
    return istDateTime.year == yesterday.year &&
           istDateTime.month == yesterday.month &&
           istDateTime.day == yesterday.day;
  }
} 
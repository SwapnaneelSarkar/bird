# Indian Standard Time (IST) Implementation

## Overview
This document outlines the implementation of Indian Standard Time (IST) throughout the Bird food delivery app. All times in the app are now displayed and processed in IST (UTC+5:30).

## Changes Made

### 1. Dependencies Added
- Added `timezone: ^0.10.1` package to `pubspec.yaml` for timezone support

### 2. Timezone Utility Created
**File: `lib/utils/timezone_utils.dart`**
- Created a comprehensive utility class for handling IST time conversions
- Provides methods for:
  - Getting current time in IST
  - Converting UTC to IST
  - Formatting dates and times in IST
  - Parsing date strings to IST
  - Checking if dates are today/yesterday in IST

### 3. Main App Initialization
**File: `lib/main.dart`**
- Added timezone initialization in the main function
- Ensures IST timezone data is loaded when the app starts

### 4. Model Updates

#### Chat Models (`lib/models/chat_models.dart`)
- Updated `ReadByEntry`, `ApiChatMessage`, and `ChatRoom` models
- All timestamps now parsed and converted to IST
- Chat message formatting uses IST time

#### Order Models
- **OrderItem Model** (`lib/models/OrderItem_model.dart`): Updated date parsing and formatting
- **Order Details Model** (`lib/models/order_details_model.dart`): Updated `createdAt` field to use IST
- **Order History State** (`lib/presentation/order_history/state.dart`): Updated OrderItem class

#### Address Model (`lib/presentation/address bottomSheet/state.dart`)
- Updated `createdAt` and `updatedAt` fields to use IST

### 5. Service Updates

#### Chat Service (`lib/presentation/chat/bloc.dart`)
- Updated optimistic message creation to use IST time
- Message timestamps now use IST

#### Socket Service (`lib/service/socket_service.dart`)
- Updated timestamp generation for read receipts to use IST

#### Cart Service (`lib/service/cart_service.dart`)
- Updated debouncing logic to use IST time

#### Profile Service (`lib/service/profile_service.dart`)
- Updated file name generation to use IST timestamps

#### Firebase Services (`lib/service/firebase_services.dart`)
- Updated notification ID generation to use IST time

### 6. View Updates

#### Order Details View (`lib/presentation/order_details/view.dart`)
- Updated order date display to use IST formatting

#### Profile View (`lib/presentation/profile_view/view.dart`)
- Updated date formatting to use IST

#### Restaurant Profile View (`lib/presentation/restaurant_profile/view.dart`)
- Updated "today" checking logic to use IST time

#### OTP Page (`lib/presentation/otpPage/view.dart`)
- Updated resend debouncing to use IST time

### 7. Restaurant Model (`lib/models/restaurant_model.dart`)
- Updated open status determination to use IST time

## Key Features

### Timezone Conversion
- All incoming UTC timestamps are automatically converted to IST
- All outgoing timestamps are in IST format
- Current time operations use IST instead of local device time

### Date Formatting
- **Chat Messages**: `HH:mm` for same day, `MMM dd, HH:mm` for other days
- **Order Dates**: `MMM dd, yyyy` format
- **Order Date with Time**: `MMM dd, yyyy HH:mm` format
- **Time Only**: `HH:mm` format
- **Date Only**: `dd/MM/yyyy` format

### Utility Methods
- `TimezoneUtils.getCurrentTimeIST()`: Get current time in IST
- `TimezoneUtils.convertToIST(DateTime)`: Convert any DateTime to IST
- `TimezoneUtils.formatChatTime(DateTime)`: Format for chat messages
- `TimezoneUtils.formatOrderDate(DateTime)`: Format for order dates
- `TimezoneUtils.parseToIST(String)`: Parse string to IST DateTime
- `TimezoneUtils.isToday(DateTime)`: Check if date is today in IST
- `TimezoneUtils.isYesterday(DateTime)`: Check if date is yesterday in IST

## Benefits

1. **Consistency**: All times across the app are now in IST
2. **User Experience**: Users see times in their local timezone (India)
3. **Data Integrity**: All timestamps are stored and processed consistently
4. **Maintainability**: Centralized timezone handling through utility class

## Testing

The implementation has been tested to ensure:
- UTC to IST conversion works correctly (UTC+5:30)
- Date formatting displays correctly
- All time-based operations use IST
- No breaking changes to existing functionality

## Usage Examples

```dart
// Get current time in IST
final now = TimezoneUtils.getCurrentTimeIST();

// Convert UTC to IST
final utcTime = DateTime.utc(2024, 1, 1, 12, 0, 0);
final istTime = TimezoneUtils.convertToIST(utcTime);

// Format for display
final formatted = TimezoneUtils.formatOrderDate(istTime);

// Parse from API response
final parsed = TimezoneUtils.parseToIST('2024-01-15T10:30:00Z');
```

## Notes

- The app now consistently shows all times in Indian Standard Time
- All API responses with timestamps are automatically converted to IST
- Local notifications and file operations use IST timestamps
- The implementation is backward compatible and doesn't break existing functionality 
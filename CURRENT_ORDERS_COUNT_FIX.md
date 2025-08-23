# Current Orders Count Fix

## Issue Description

The current order socket was always showing 5 orders on the screen regardless of the actual `orders_count` field from the SSE response. The floating button was displaying the length of filtered orders instead of respecting the `orders_count` field from the server.

## Root Cause

1. **Mock Data Issue**: The mock data in `CurrentOrdersSSEService` was hardcoded to show 5 orders with `ordersCount: 5`
2. **Display Logic Issue**: The floating button was using `filteredOrders.length` instead of `_currentOrdersUpdate?.ordersCount`
3. **Condition Logic Issue**: The visibility condition was checking `filteredOrders.isNotEmpty` instead of the `orders_count` field

## Changes Made

### 1. Fixed Mock Data (`lib/service/current_orders_sse_service.dart`)

**Before:**
```dart
final mockUpdate = CurrentOrdersUpdate(
  type: 'current_orders_update',
  userId: '8669493124e945a4ad775a66',
  hasCurrentOrders: true,
  ordersCount: 5, // Hardcoded to 5
  orders: [/* 5 hardcoded orders */],
  timestamp: '2025-08-20T22:00:36.489Z',
);
```

**After:**
```dart
// Create orders list
final orders = [/* 3 orders */];

final mockUpdate = CurrentOrdersUpdate(
  type: 'current_orders_update',
  userId: '8669493124e945a4ad775a66',
  hasCurrentOrders: true,
  ordersCount: orders.length, // Use actual orders count
  orders: orders,
  timestamp: '2025-08-20T22:00:36.489Z',
);
```

### 2. Fixed Display Logic (`lib/widgets/current_orders_floating_button.dart`)

**Before:**
```dart
final hasOrders = _currentOrdersUpdate?.hasCurrentOrders == true && filteredOrders.isNotEmpty;

Text(
  'Current Orders (${filteredOrders.length})', // Using filtered orders length
  // ...
),
```

**After:**
```dart
final hasOrders = _currentOrdersUpdate?.hasCurrentOrders == true && 
                  _currentOrdersUpdate?.ordersCount != null && 
                  _currentOrdersUpdate!.ordersCount > 0;

Text(
  'Current Orders (${_currentOrdersUpdate?.ordersCount ?? 0})', // Using orders_count field
  // ...
),
```

### 3. Updated Modal Header

**Before:**
```dart
Text(
  'Current Orders (${filteredOrders.length})',
  // ...
),
```

**After:**
```dart
Text(
  'Current Orders (${_currentOrdersUpdate?.ordersCount ?? 0})',
  // ...
),
```

### 4. Enhanced Debug Logging

Added more detailed logging to track:
- `ordersCount` field value
- `hasCurrentOrders` flag
- Filtered orders count
- Visibility decision logic

## Expected Behavior

Now the current orders socket will:

1. **Show correct count**: Display the count from `orders_count` field (e.g., "Current Orders (3)")
2. **Respect server data**: Use `has_current_orders: true` and `orders_count: 3` to determine visibility
3. **Handle filtering**: When a supercategory is selected, filter orders but still show the total count
4. **Graceful fallback**: Show 0 if `orders_count` is null or invalid

## Test Cases Added

1. **Basic count test**: Verifies that `orders_count: 3` displays correctly
2. **Mismatch test**: Verifies that `orders_count: 2` is respected even if the orders array has 3 items
3. **No orders test**: Verifies that `has_current_orders: false` and `orders_count: 0` work correctly

## Files Modified

- `lib/service/current_orders_sse_service.dart` - Fixed mock data to use actual orders count
- `lib/widgets/current_orders_floating_button.dart` - Fixed display logic to use orders_count field
- `test/test_current_orders_sse.dart` - Added comprehensive tests for the fix

## Testing

Run the tests to verify the fix:
```bash
flutter test test/test_current_orders_sse.dart
```

All tests should pass, confirming that the orders count is now properly displayed based on the `orders_count` field from the SSE response. 
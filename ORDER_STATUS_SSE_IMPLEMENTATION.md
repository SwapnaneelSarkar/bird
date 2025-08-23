# Order Status SSE Implementation in Chat Page

## Overview

This implementation adds real-time order status updates to the chat page using Server-Sent Events (SSE). When a user opens a chat page for an order, the system automatically connects to the order status stream and displays real-time status updates as chat bubbles.

## Features

- **Real-time Order Status Updates**: Connects to SSE endpoint for live order status changes
- **Automatic Connection Management**: Connects when chat page opens, disconnects when closed
- **Background Support**: Maintains connection even when app is in background
- **Visual Status Bubbles**: Displays status updates as chat bubbles with icons and colors
- **Status History**: Shows the latest status update with timestamp
- **Non-intrusive**: Doesn't interfere with existing chat functionality

## Architecture

### 1. Order Status SSE Service (`lib/service/order_status_sse_service.dart`)

**Classes:**
- `OrderStatusUpdate`: Model for order status update data
- `OrderStatusItem`: Model for order item details
- `OrderStatusSSEService`: Service for SSE connection management

**Key Features:**
- Connects to `/user/orders/{orderId}/status-stream` endpoint
- Handles JSON stream parsing with proper error handling
- Manages connection lifecycle with automatic reconnection
- Provides broadcast stream for status updates
- Singleton pattern per order ID to prevent duplicate connections

**SSE Endpoint Details:**
```
GET /user/orders/{orderId}/status-stream
Headers:
- Authorization: Bearer {token}
- Accept: text/event-stream
- Cache-Control: no-cache
- Connection: keep-alive
```

**Expected JSON Structure:**
```json
{
  "type": "status_update",
  "order_id": "2508000006",
  "status": "CANCELLED",
  "message": "Order status: CANCELLED",
  "timestamp": "2025-08-20T08:16:15.326Z",
  "delivery_partner_id": null,
  "created_at": "2025-08-02T15:41:57.000Z",
  "last_updated": "2025-08-02T20:30:00.000Z",
  "total_price": "20.00",
  "address": "Hyderabad, test1",
  "coordinates": {
    "latitude": "17.4064980",
    "longitude": "78.4772439"
  },
  "payment_mode": "cash",
  "supercategory": "7acc47a2fa5a4eeb906a753b3",
  "items": [
    {
      "quantity": 1,
      "price": "20.00",
      "item_name": "biryani ",
      "item_description": ""
    }
  ]
}
```

### 2. Chat Bloc Integration (`lib/presentation/chat/bloc.dart`)

**Key Changes:**
- Added `OrderStatusSSEService` integration
- Added `latestStatusUpdate` to `ChatLoaded` state
- Added `_setupOrderStatusSSE()` method for connection management
- Updated `_onChatPageClosed()` to disconnect SSE when page closes
- Added automatic reconnection logic

**Connection Lifecycle:**
1. **Chat Page Opens**: Automatically connects to order status SSE
2. **Status Update Received**: Updates both order details and latest status
3. **Chat Page Closes**: Disconnects SSE connection
4. **Background Mode**: Maintains connection for real-time updates

### 3. Chat State Updates (`lib/presentation/chat/state.dart`)

**Added Fields:**
- `latestStatusUpdate`: Stores the most recent status update
- Updated `copyWith()` method to handle status updates

### 4. Chat Order Status Bubble (`lib/widgets/chat_order_status_bubble.dart`)

**Features:**
- Displays order status with appropriate icons and colors
- Shows status message and timestamp
- Includes order details (ID, amount, payment mode, address)
- Responsive design with proper spacing
- Color-coded status indicators

**Status Colors:**
- **Pending**: Orange
- **Confirmed**: Blue
- **Preparing**: Indigo
- **Ready**: Green
- **On the Way**: Purple
- **Delivered**: Green
- **Cancelled**: Red

### 5. Chat View Integration (`lib/presentation/chat/view.dart`)

**Key Changes:**
- Added `ChatOrderStatusBubble` import
- Updated `_buildMessagesList()` to show status bubbles
- Added status bubble display logic in ListView
- Maintains existing chat functionality

**Display Logic:**
1. **Order Details Bubble**: Always shown first (if available)
2. **Status Bubble**: Shown second (if status update available)
3. **Chat Messages**: Shown after bubbles

## Implementation Details

### Connection Management

```dart
// Setup order status SSE connection
void _setupOrderStatusSSE(String orderId) {
  // Dispose existing connection if any
  _orderStatusSubscription?.cancel();
  _orderStatusSSEService?.disconnect();
  
  // Create new SSE service for this order
  _orderStatusSSEService = OrderStatusSSEService(orderId);
  
  // Connect and listen for updates
  _orderStatusSSEService!.connect().then((_) {
    _orderStatusSubscription = _orderStatusSSEService!.statusStream.listen(
      (statusUpdate) {
        // Update state with new status
        emit(currentState.copyWith(
          orderDetails: updatedOrderDetails,
          latestStatusUpdate: statusUpdate,
        ));
      },
    );
  });
}
```

### State Updates

```dart
// Update order details and status in state
final updatedOrderDetails = OrderDetails(
  orderId: currentState.orderDetails!.orderId,
  userId: currentState.orderDetails!.userId,
  itemIds: currentState.orderDetails!.itemIds,
  items: currentState.orderDetails!.items,
  totalAmount: double.tryParse(statusUpdate.totalPrice) ?? currentState.orderDetails!.totalAmount,
  deliveryFees: currentState.orderDetails!.deliveryFees,
  orderStatus: statusUpdate.status, // Updated status
  createdAt: currentState.orderDetails!.createdAt,
  restaurantName: currentState.orderDetails!.restaurantName,
  deliveryAddress: statusUpdate.address,
  partnerId: currentState.orderDetails!.partnerId,
  paymentMode: statusUpdate.paymentMode,
  restaurantAddress: currentState.orderDetails!.restaurantAddress,
  rating: currentState.orderDetails!.rating,
  reviewText: currentState.orderDetails!.reviewText,
  isCancellable: currentState.orderDetails!.isCancellable,
);

// Emit updated state
emit(currentState.copyWith(
  orderDetails: updatedOrderDetails,
  latestStatusUpdate: statusUpdate,
));
```

### UI Display

```dart
// Show status bubble in chat
if (latestStatusUpdate != null && index == currentIndex) {
  return ChatOrderStatusBubble(
    orderDetails: orderDetails!,
    isFromCurrentUser: false, // Status updates from restaurant
    currentUserId: currentUserId,
    latestStatusUpdate: latestStatusUpdate,
  );
}
```

## Testing

### Unit Tests (`test/test_order_status_sse.dart`)

**Test Coverage:**
- JSON parsing for `OrderStatusUpdate` and `OrderStatusItem`
- Singleton pattern verification
- Connection lifecycle management
- SSE message parsing
- Multiple instance handling

**Running Tests:**
```bash
flutter test test/test_order_status_sse.dart
```

## Usage

### For Users

1. **Open Chat Page**: Navigate to chat for any order
2. **Automatic Connection**: SSE connection is established automatically
3. **Real-time Updates**: Status changes appear as chat bubbles
4. **Background Updates**: Continue receiving updates when app is in background
5. **Close Chat**: Connection is automatically closed when leaving chat

### For Developers

1. **No Configuration Required**: Works automatically with existing chat implementation
2. **Non-intrusive**: Doesn't affect existing chat functionality
3. **Extensible**: Easy to add more status types or modify display
4. **Testable**: Comprehensive test coverage included

## Error Handling

### Connection Errors
- Automatic reconnection with exponential backoff
- Maximum 5 reconnection attempts
- Graceful degradation if connection fails

### Parsing Errors
- Safe JSON parsing with fallback values
- Error logging for debugging
- Continues operation even if individual updates fail

### State Management
- Proper cleanup on page close
- Memory leak prevention
- Singleton pattern prevents duplicate connections

## Performance Considerations

### Memory Management
- Automatic disposal of unused connections
- Singleton pattern reduces memory usage
- Proper stream subscription cleanup

### Network Efficiency
- Single SSE connection per order
- Automatic reconnection with delays
- Connection sharing across app lifecycle

### UI Performance
- Efficient state updates
- Minimal rebuilds
- Responsive design with proper caching

## Future Enhancements

### Potential Improvements
1. **Status History**: Show multiple status updates in chronological order
2. **Push Notifications**: Integrate with push notifications for status changes
3. **Custom Status Types**: Support for custom status messages
4. **Status Actions**: Add action buttons for status-specific operations
5. **Offline Support**: Cache status updates for offline viewing

### Integration Opportunities
1. **Order Tracking**: Integrate with order tracking features
2. **Analytics**: Track status change patterns
3. **Customer Support**: Link status updates to support tickets
4. **Feedback System**: Collect feedback on status accuracy

## Conclusion

This implementation provides a robust, real-time order status update system that enhances the user experience in the chat page. It maintains the existing chat functionality while adding valuable status information in a non-intrusive way. The system is designed to be reliable, performant, and easily maintainable. 
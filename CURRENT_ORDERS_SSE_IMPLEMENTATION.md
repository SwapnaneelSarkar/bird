# Current Orders SSE Implementation

## Overview

This implementation provides real-time order tracking using Server-Sent Events (SSE) with a floating action button that displays current orders on the home page.

## Features

- **Real-time Order Tracking**: Connects to SSE endpoint for live order updates
- **Floating Action Button**: Shows current orders with dropdown functionality
- **Order Filtering**: Filters orders by selected supercategory
- **Order Navigation**: Click on orders to navigate to order details page
- **Visual Indicators**: Shows order count badge and status colors
- **Responsive Design**: Adapts to different screen sizes

## Architecture

### 1. SSE Service (`lib/service/current_orders_sse_service.dart`)

**Classes:**
- `CurrentOrder`: Model for individual order data
- `CurrentOrdersUpdate`: Model for SSE update payload
- `CurrentOrdersSSEService`: Service for SSE connection management

**Key Features:**
- Connects to `/user/orders/current/stream` endpoint
- Handles JSON stream parsing
- Manages connection lifecycle
- Provides broadcast stream for order updates

**SSE Endpoint Details:**
```
GET /user/orders/current/stream
Headers:
- Authorization: Bearer {token}
- Accept: text/event-stream
- Cache-Control: no-cache
- Connection: keep-alive
```

**Expected JSON Structure:**
```json
{
  "type": "current_orders_update",
  "user_id": "dd273fc400e24d77af6ffd56",
  "has_current_orders": true,
  "orders_count": 1,
  "orders": [{
    "order_id": "2508000136",
    "order_status": "PENDING",
    "total_price": "200.00",
    "address": "123 Main St, City",
    "latitude": null,
    "longitude": null,
    "created_at": "2025-08-20T07:02:34.000Z",
    "updated_at": "2025-08-20T07:02:34.000Z",
    "payment_mode": "cash",
    "supercategory": "7acc47a2fa5a4eeb906a753b3",
    "delivery_partner_id": null,
    "restaurant_name": "Soofi restaurant and cafe",
    "restaurant_mobile": "1111111111"
  }],
  "timestamp": "2025-08-20T07:02:35.867Z"
}
```

### 2. Floating Button Widget (`lib/widgets/current_orders_floating_button.dart`)

**Features:**
- **Centered Design**: Positioned in the center of the screen
- **60% Width**: Takes 60% of screen width for better visibility
- **Extended Button**: Shows text label with icon for better UX
- **Stacked Display**: Shows multiple orders in a dropdown
- **Animation**: Smooth expand/collapse animations
- **Order Filtering**: Filters by selected supercategory
- **Status Indicators**: Color-coded order status
- **Navigation**: Direct navigation to order details
- **Badge Counter**: Shows number of current orders

**UI Components:**
- Centered Floating Action Button with extended layout
- Delivery icon with "Current Orders" text
- Order count badge for multiple orders
- Expandable dropdown with order cards (90% screen width)
- Status indicators and price formatting
- Restaurant name and order ID display

### 3. Home Page Integration

**Location:** `lib/presentation/home page/view.dart`

**Integration Points:**
- Added as `floatingActionButton` to the main Scaffold
- Receives token and selectedSupercategoryId as parameters
- Automatically shows/hides based on order availability

## Usage

### 1. Automatic Integration

The floating button is automatically integrated into the home page and will:
- Connect to SSE when a valid token is provided
- Show/hide based on `has_current_orders` flag
- Filter orders by the currently selected supercategory
- Handle navigation to order details page

### 2. Manual Usage

```dart
CurrentOrdersFloatingButton(
  token: userToken,
  selectedSupercategoryId: currentSupercategoryId,
)
```

## Order Status Colors

- **PENDING**: Orange (`#FF9800`)
- **CONFIRMED**: Green (`#4CAF50`)
- **PREPARING**: Blue (`#2196F3`)
- **OUT_FOR_DELIVERY**: Purple (`#9C27B0`)
- **DELIVERED**: Green (`#4CAF50`)
- **CANCELLED**: Red (`#F44336`)

## Error Handling

### SSE Connection Errors
- Automatic reconnection attempts
- Error logging for debugging
- Graceful degradation when connection fails

### Data Parsing Errors
- Safe JSON parsing with null checks
- Fallback to default values
- Error logging for malformed data

## Debug Logging

### Comprehensive Debug Information
The implementation includes extensive debug logging to help with troubleshooting and development:

#### SSE Service Debug Logs
- **Connection Lifecycle**: Connection attempts, success/failure, disconnection
- **Request Details**: URL, headers (with token masking), response status
- **Stream Processing**: Received data, parsing results, error details
- **State Changes**: Connection status, subscription management

#### Floating Button Debug Logs
- **Widget Lifecycle**: Initialization, state changes, disposal
- **SSE Integration**: Connection status, data updates, filtering results
- **UI Interactions**: Expand/collapse actions, navigation events
- **Order Processing**: Filtering logic, order counts, display decisions

#### Debug Log Format
```
🔗 CurrentOrdersSSEService: [SSE service messages]
🎯 CurrentOrdersFloatingButton: [Widget messages]
📨 CurrentOrdersSSEService: [Data reception messages]
❌ CurrentOrdersSSEService: [Error messages]
🔍 CurrentOrdersSSEService: [Processing messages]
```

#### Token Security
- Debug logs mask sensitive token information
- Only first 10 and last 5 characters are shown
- Full token is never logged for security

## Testing

### Unit Tests
Location: `test/test_current_orders_sse.dart`

**Test Coverage:**
- JSON parsing for CurrentOrder model
- JSON parsing for CurrentOrdersUpdate model
- Handling of empty orders array
- SSE service initialization

### Running Tests
```bash
flutter test test/test_current_orders_sse.dart
```

## Configuration

### API Base URL
The SSE service uses the base URL from `ApiConstants.baseUrl`:
```dart
static const String _baseUrl = ApiConstants.baseUrl;
```

### Currency Formatting
Uses `CurrencyUtils.formatPriceWithUserCurrency()` for proper currency display based on user location.

## Performance Considerations

### Memory Management
- Proper disposal of SSE connections
- Stream subscription cleanup
- Animation controller disposal

### Network Efficiency
- Single SSE connection for real-time updates
- Automatic reconnection on connection loss
- Minimal data transfer with efficient JSON structure

## Security

### Authentication
- Bearer token authentication for SSE connection
- Token validation before connection establishment

### Data Privacy
- Secure transmission over HTTPS
- No sensitive data in client-side storage
- Automatic token refresh handling

## Future Enhancements

### Potential Improvements
1. **Order Notifications**: Push notifications for order status changes
2. **Order History**: Integration with order history page
3. **Live Tracking**: Real-time delivery partner location
4. **Order Actions**: Cancel/modify orders from floating button
5. **Offline Support**: Cache orders for offline viewing

### Scalability
- Connection pooling for multiple users
- Rate limiting for SSE connections
- Load balancing for high-traffic scenarios

## Troubleshooting

### Common Issues

1. **Floating Button Not Showing**
   - Check if user has valid token
   - Verify `has_current_orders` is true
   - Ensure orders array is not empty

2. **SSE Connection Fails**
   - Verify API endpoint is accessible
   - Check token validity
   - Review network connectivity

3. **Orders Not Filtering**
   - Verify selectedSupercategoryId is correct
   - Check order supercategory values
   - Ensure filtering logic is working

### Debug Information
Enable debug logging by checking console output for:

#### Connection Debugging
- `🔗 CurrentOrdersSSEService: Attempting to connect to SSE stream`
- `🔗 CurrentOrdersSSEService: Successfully connected to SSE stream`
- `🔗 CurrentOrdersSSEService: Response status: 200`

#### Data Processing Debugging
- `📨 CurrentOrdersSSEService: Received SSE line: X chars`
- `🔍 CurrentOrdersSSEService: Successfully parsed JSON`
- `🔍 CurrentOrdersSSEService: hasCurrentOrders: true`

#### Widget Debugging
- `🎯 CurrentOrdersFloatingButton: Initializing widget`
- `🎯 CurrentOrdersFloatingButton: Received order update`
- `🎯 CurrentOrdersFloatingButton: Filtered orders count: X`

#### Error Debugging
- `❌ CurrentOrdersSSEService: Connection error: [error details]`
- `❌ CurrentOrdersSSEService: Error parsing SSE message: [error details]`
- `❌ CurrentOrdersFloatingButton: SSE stream error: [error details]`

## Dependencies

### Required Packages
- `http`: For SSE connection
- `flutter_bloc`: For state management
- `google_fonts`: For typography
- `shared_preferences`: For token storage

### Internal Dependencies
- `CurrencyUtils`: For price formatting
- `ApiConstants`: For API configuration
- `ColorManager`: For consistent theming
- `Routes`: For navigation

## Conclusion

This implementation provides a robust, real-time order tracking system that enhances user experience by providing immediate access to current order information. The floating button design ensures easy access without cluttering the main interface, while the SSE connection ensures data is always up-to-date. 
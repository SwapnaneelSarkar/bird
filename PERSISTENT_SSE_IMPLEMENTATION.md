# Persistent SSE Implementation

## Overview

This implementation provides a persistent Server-Sent Events (SSE) connection that stays connected throughout the app lifecycle and automatically reconnects when the app starts or resumes from background.

## Architecture

### 1. App Lifecycle Service (`lib/service/app_lifecycle_service.dart`)

**Purpose**: Manages the app lifecycle and coordinates the persistent SSE connection.

**Key Features**:
- **App Lifecycle Management**: Listens for app state changes (paused, resumed, detached, inactive)
- **Automatic Reconnection**: Checks and reconnects SSE when app resumes
- **Background Support**: Maintains SSE connection when app is in background
- **Clean Disconnection**: Properly disconnects when app is terminated

**Lifecycle Events**:
- **App Paused**: Maintains SSE connection for background updates
- **App Resumed**: Checks SSE connection and reconnects if needed
- **App Detached**: Disconnects SSE before app termination
- **App Inactive**: Maintains SSE connection during transitions

### 2. Persistent SSE Service (`lib/service/persistent_sse_service.dart`)

**Purpose**: Manages the persistent SSE connection with automatic reconnection logic.

**Key Features**:
- **Singleton Pattern**: Single instance across the entire app
- **Automatic Reconnection**: Attempts to reconnect up to 5 times with 5-second delays
- **Token Management**: Handles token updates and validation
- **Connection State Tracking**: Monitors connection status and reconnection attempts
- **Error Handling**: Graceful handling of connection errors and network issues

**Reconnection Logic**:
```dart
static const int _maxReconnectionAttempts = 5;
static const Duration _reconnectionDelay = Duration(seconds: 5);
```

### 3. Current Orders SSE Service (`lib/service/current_orders_sse_service.dart`)

**Purpose**: Handles the actual SSE connection and data parsing.

**Key Features**:
- **SSE Connection**: Establishes and maintains the SSE stream
- **Data Parsing**: Parses incoming SSE messages into `CurrentOrdersUpdate` objects
- **Mock Data**: Provides mock data for testing when SSE is unavailable
- **Error Handling**: Handles connection errors and data parsing errors

## Usage

### 1. App Initialization (`lib/main.dart`)

The persistent SSE service is initialized when the app starts:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ... other initializations ...
  
  // Initialize app lifecycle service (includes persistent SSE)
  await AppLifecycleService().initialize();
  
  runApp(const MyApp());
}
```

### 2. Widget Integration (`lib/widgets/current_orders_floating_button.dart`)

Widgets use the app lifecycle service to connect to SSE:

```dart
class _CurrentOrdersFloatingButtonState extends State<CurrentOrdersFloatingButton> {
  final AppLifecycleService _appLifecycleService = AppLifecycleService();
  
  Future<void> _connectToSSE() async {
    await _appLifecycleService.connectToSSE(widget.token!);
    
    _appLifecycleService.persistentSSEService.currentOrdersStream.listen(
      (update) {
        setState(() {
          _currentOrdersUpdate = update;
        });
      },
      onError: (error) {
        debugPrint('SSE stream error: $error');
      },
    );
  }
}
```

### 3. Token Management

Update the token when user logs in/out:

```dart
// When user logs in
await AppLifecycleService().connectToSSE(userToken);

// When user logs out
await AppLifecycleService().disconnectFromSSE();

// When token is refreshed
await AppLifecycleService().updateToken(newToken);
```

## Connection Flow

### 1. App Start
```
App Starts → AppLifecycleService.initialize() → PersistentSSEService.initialize()
```

### 2. User Login
```
User Login → AppLifecycleService.connectToSSE(token) → 
PersistentSSEService.connect(token) → CurrentOrdersSSEService.connect(token)
```

### 3. Connection Loss
```
Connection Lost → PersistentSSEService._scheduleReconnection() → 
Timer(5 seconds) → PersistentSSEService._connectToSSE() → 
Retry up to 5 times
```

### 4. App Resume
```
App Resumed → AppLifecycleService._handleAppResumed() → 
_checkAndReconnectSSE() → Reconnect if needed
```

### 5. App Termination
```
App Detached → AppLifecycleService._handleAppDetached() → 
PersistentSSEService.disconnect() → Clean shutdown
```

## Benefits

### 1. **Persistent Connection**
- SSE connection stays alive throughout the app lifecycle
- Real-time updates even when app is in background
- No need to reconnect on every screen navigation

### 2. **Automatic Recovery**
- Automatic reconnection on network issues
- Graceful handling of connection errors
- Configurable retry attempts and delays

### 3. **App Lifecycle Awareness**
- Maintains connection during app state transitions
- Proper cleanup on app termination
- Efficient resource management

### 4. **Centralized Management**
- Single point of control for SSE connections
- Consistent behavior across the app
- Easy to debug and monitor

## Error Handling

### 1. **Connection Errors**
- Automatic retry with exponential backoff
- Maximum retry attempts to prevent infinite loops
- Graceful degradation when connection fails

### 2. **Network Issues**
- Handles network timeouts and disconnections
- Reconnects when network becomes available
- Maintains connection during network switches

### 3. **Data Parsing Errors**
- Logs parsing errors for debugging
- Continues listening for valid messages
- Doesn't break the connection on malformed data

## Testing

### 1. **Unit Tests**
- `test/test_persistent_sse_service.dart`: Tests the persistent SSE service
- Covers initialization, connection, token management, and error handling
- Verifies singleton pattern and lifecycle management

### 2. **Integration Tests**
- Tests the complete flow from app start to SSE connection
- Verifies automatic reconnection behavior
- Tests app lifecycle event handling

### 3. **Mock Data**
- Provides realistic mock data for testing
- Simulates various SSE response scenarios
- Allows testing without actual server connection

## Configuration

### 1. **Reconnection Settings**
```dart
static const int _maxReconnectionAttempts = 5;
static const Duration _reconnectionDelay = Duration(seconds: 5);
```

### 2. **SSE Endpoint**
```dart
final url = '$_baseUrl/user/orders/current/stream';
```

### 3. **Headers**
```dart
final headers = {
  'Authorization': 'Bearer $token',
  'Accept': 'text/event-stream',
  'Cache-Control': 'no-cache',
  'Connection': 'keep-alive',
};
```

## Monitoring and Debugging

### 1. **Debug Logs**
- Comprehensive logging for connection events
- Error tracking and debugging information
- Performance monitoring and connection status

### 2. **Connection Status**
```dart
bool get isConnected => _currentOrdersService.isConnected;
bool get hasValidToken => _currentToken != null && _currentToken!.isNotEmpty;
```

### 3. **Stream Access**
```dart
Stream<CurrentOrdersUpdate> get currentOrdersStream => _currentOrdersService.ordersStream;
```

## Future Enhancements

### 1. **Connection Quality Monitoring**
- Monitor connection latency and reliability
- Adaptive reconnection strategies based on network quality
- Connection health metrics

### 2. **Background Processing**
- Enhanced background processing capabilities
- Push notification integration
- Battery optimization

### 3. **Multi-Endpoint Support**
- Support for multiple SSE endpoints
- Load balancing and failover
- Endpoint health monitoring

## Files Modified

- `lib/main.dart` - Added app lifecycle service initialization
- `lib/service/app_lifecycle_service.dart` - New app lifecycle management service
- `lib/service/persistent_sse_service.dart` - New persistent SSE service
- `lib/widgets/current_orders_floating_button.dart` - Updated to use persistent service
- `test/test_persistent_sse_service.dart` - Comprehensive test suite

## Testing Commands

```bash
# Run persistent SSE service tests
flutter test test/test_persistent_sse_service.dart

# Run all SSE-related tests
flutter test test/test_current_orders_sse.dart test/test_persistent_sse_service.dart
```

This implementation ensures that the SSE connection remains persistent throughout the app lifecycle, providing real-time updates and automatic recovery from connection issues. 
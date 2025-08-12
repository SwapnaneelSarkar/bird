import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart';

import '../../models/chat_models.dart';
import '../../models/order_details_model.dart';
import '../../service/chat_service.dart';
import '../../service/socket_service.dart';
import '../../service/token_service.dart';
import '../../service/order_history_service.dart';
import '../../service/menu_item_service.dart';
import '../../utils/timezone_utils.dart';
import '../../utils/performance_monitor.dart';
import 'event.dart';
import 'state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatService _chatService;
  final SocketService _socketService;
  String? _currentRoomId;
  String? _currentUserId;
  String? _currentPartnerId;
  StreamSubscription<Map<String, dynamic>>? _messageSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  StreamSubscription? _readReceiptSubscription;
  StreamSubscription? _typingSubscription;
  bool _isSocketConnected = false;
  Timer? _typingTimer;
  Timer? _refreshTimer;
  
  // Add global message tracking to prevent duplicates
  final Set<String> _processedMessageHashes = <String>{};
  static const int _maxProcessedHashes = 200;
  
  // Add message ID mapping for read receipt tracking
  final Map<String, String> _tempToRealMessageIds = <String, String>{};
  final Map<String, String> _contentToMessageId = <String, String>{};
  
  // Add caching for order details and menu items
  static final Map<String, OrderDetails> _orderDetailsCache = {};
  static final Map<String, Map<String, dynamic>> _menuItemCache = {};
  static const Duration _cacheDuration = Duration(minutes: 5);
  static final Map<String, DateTime> _cacheTimestamps = {};
  
  ChatBloc({required ChatService chatService, required SocketService socketService})
      : _chatService = chatService,
        _socketService = socketService,
        super(ChatInitial()) {
    _setupSocketListeners();
    _setupConnectionListener();
    on<LoadChatData>(_onLoadChatData);
    on<SendMessage>(_onSendMessage);
    on<ConnectSocket>(_onConnectSocket);
    on<DisconnectSocket>(_onDisconnectSocket);
    on<ReceiveMessage>(_onReceiveMessage);
    on<MarkAsRead>(_onMarkAsRead);
    on<StartTyping>(_onStartTyping);
    on<StopTyping>(_onStopTyping);
    on<UpdateMessageReadStatus>(_onUpdateMessageReadStatus);
    on<ChatPageOpened>(_onChatPageOpened);
    on<ChatPageClosed>(_onChatPageClosed);
    on<MessageReceivedOnActivePage>(_onMessageReceivedOnActivePage);
    on<UpdateBlueTicksForPreviousMessages>(_onUpdateBlueTicksForPreviousMessages);
  }
  
  @override
  Future<void> close() {
    _typingTimer?.cancel();
    _refreshTimer?.cancel();
    _messageSubscription?.cancel();
    _connectionSubscription?.cancel();
    _readReceiptSubscription?.cancel();
    _typingSubscription?.cancel();
    _socketService.disconnect();
    return super.close();
  }
  
  void _setupSocketListeners() {
    // Listen for socket connection status
    _connectionSubscription = _socketService.connectionStream.listen((connected) {
      debugPrint('ChatBloc: Received socket connection status: $connected');
      
      if (connected && _currentRoomId != null) {
        _socketService.joinRoom(_currentRoomId!);
        debugPrint('ChatBloc: Socket joined room on reconnection');
      }
    });
    
    // Listen for incoming socket messages
    _messageSubscription = _socketService.messageStream.listen((messageData) {
      try {
        debugPrint('ChatBloc: Received socket message: $messageData');
        
        // Handle different message data formats
        String messageId = '';
        String roomId = '';
        String senderId = '';
        String senderType = '';
        String content = '';
        String messageType = 'text';
        DateTime createdAt = TimezoneUtils.getCurrentTime();
        List<ReadByEntry> readBy = [];
        
        // Parse message data safely
        if (messageData['_id'] != null) {
          messageId = messageData['_id'].toString();
        } else if (messageData['id'] != null) {
          messageId = messageData['id'].toString();
        } else {
          messageId = 'socket_${DateTime.now().millisecondsSinceEpoch}';
        }
        
        if (messageData['roomId'] != null) {
          roomId = messageData['roomId'].toString();
        }
        
        if (messageData['senderId'] != null) {
          senderId = messageData['senderId'].toString();
        }
        
        if (messageData['senderType'] != null) {
          senderType = messageData['senderType'].toString();
        }
        
        if (messageData['content'] != null) {
          content = messageData['content'].toString();
        }
        
        if (messageData['messageType'] != null) {
          messageType = messageData['messageType'].toString();
        }
        
        // Parse createdAt safely
        if (messageData['createdAt'] != null) {
          try {
            createdAt = TimezoneUtils.parseToIST(messageData['createdAt'].toString());
          } catch (e) {
            debugPrint('Error parsing createdAt: $e');
            createdAt = TimezoneUtils.getCurrentTime();
          }
        } else {
          createdAt = TimezoneUtils.getCurrentTime();
          debugPrint('No createdAt in socket message, using current IST time: $createdAt');
        }
        
        // Parse readBy safely
        if (messageData['readBy'] != null && messageData['readBy'] is List) {
          try {
            readBy = (messageData['readBy'] as List)
                .map((entry) => ReadByEntry.fromJson(entry as Map<String, dynamic>))
                .toList();
          } catch (e) {
            debugPrint('Error parsing readBy: $e');
            readBy = [];
          }
        }
        
        final chatMessage = ChatMessage(
          id: messageId,
          roomId: roomId,
          senderId: senderId,
          senderType: senderType,
          content: content,
          messageType: messageType,
          readBy: readBy,
          createdAt: createdAt,
        );
        
        debugPrint('ChatBloc: Parsed socket message: ${chatMessage.content}');
        
        // Process messages from other users and own messages for delivery confirmation
        if (senderId != _currentUserId) {
          debugPrint('ChatBloc: Adding message from other user to UI');
          add(ReceiveMessage(chatMessage));
        } else {
          debugPrint('ChatBloc: Processing own message from socket for delivery confirmation');
          add(ReceiveMessage(chatMessage));
          debugPrint('ChatBloc: ✅ Own message delivered via socket: ${chatMessage.content}');
        }
      } catch (e) {
        debugPrint('ChatBloc: Error parsing socket message: $e');
        debugPrint('ChatBloc: Raw message data: $messageData');
      }
    });
    
    // Listen for read receipt updates
    _readReceiptSubscription = _socketService.readReceiptStream.listen((readData) {
      debugPrint('ChatBloc: Received read receipt: $readData');
      add(UpdateMessageReadStatus(readData));
    });
    
    // Listen for typing indicators
    _typingSubscription = _socketService.typingStream.listen((typingData) {
      debugPrint('ChatBloc: 📨 RECEIVED typing event from socket service: $typingData');
      
      // Handle typing indicators in UI if needed
      if (typingData['isTyping'] == true && typingData['userId'] != _currentUserId) {
        debugPrint('ChatBloc: 👥 Partner is typing - can show typing indicator in UI');
        debugPrint('ChatBloc: 🔵 Updating blue ticks for previous messages due to partner typing');
        _updateBlueTicksForPreviousMessages();
      } else if (typingData['isTyping'] == false && typingData['userId'] != _currentUserId) {
        debugPrint('ChatBloc: 🛑 Partner stopped typing');
        debugPrint('ChatBloc: 🔵 Updating blue ticks for previous messages due to partner stopping typing');
        _updateBlueTicksForPreviousMessages();
      }
    });
  }
  
  void _setupConnectionListener() {
    debugPrint('ChatBloc: 🔧 Setting up connection listener...');
    // Listen for socket connection status
    _connectionSubscription = _socketService.connectionStream.listen((connected) {
      debugPrint('ChatBloc: 🔌 Connection stream event received: $connected');
      debugPrint('ChatBloc: 🔌 Previous _isSocketConnected: $_isSocketConnected');
      _isSocketConnected = connected;
      debugPrint('ChatBloc: 🔌 Updated _isSocketConnected to: $_isSocketConnected');
      
      if (connected && _currentRoomId != null) {
        debugPrint('ChatBloc: 🔌 Socket connected, joining room: $_currentRoomId');
        _socketService.joinRoom(_currentRoomId!);
        debugPrint('ChatBloc: Socket joined room on reconnection');
      } else if (!connected) {
        debugPrint('ChatBloc: 🔌 Socket disconnected');
      }
    });
    debugPrint('ChatBloc: ✅ Connection listener set up successfully');
  }
  
  Future<void> _onLoadChatData(LoadChatData event, Emitter<ChatState> emit) async {
    PerformanceMonitor.startTimer('ChatDataLoading');
    debugPrint('ChatBloc: 🚩 _onLoadChatData called for event.orderId: ${event.orderId}');
    
    if (event.orderId.isEmpty) {
      debugPrint('ChatBloc: ❌ ERROR - orderId is empty!');
      emit(const ChatError('Invalid order ID'));
      return;
    }
    
    try {
      emit(ChatLoading());
      
      // Get current user ID first
      _currentUserId = await TokenService.getUserId();
      if (_currentUserId == null) {
        debugPrint('ChatBloc: No user ID found');
        emit(const ChatError('Please login to access chat.'));
        return;
      }
      
      debugPrint('ChatBloc: Loading chat data for order: ${event.orderId}');
      debugPrint('ChatBloc: Current user ID: $_currentUserId');
      
      // OPTIMIZATION 1: Load chat room and chat history in parallel
      debugPrint('ChatBloc: 🚀 OPTIMIZATION 1: Loading chat room and history in parallel...');
      
      final chatRoomFuture = ChatService.createOrGetChatRoom(event.orderId);
      final orderDetailsFuture = _getOrderDetailsWithCache(event.orderId);
      
      // Wait for chat room first (required for history)
      final roomResult = await chatRoomFuture;
      
      if (roomResult['success'] != true) {
        debugPrint('ChatBloc: Failed to create/get chat room: ${roomResult['message']}');
        emit(ChatError(roomResult['message'] ?? 'Failed to load chat room'));
        return;
      }
      
      final chatRoom = ChatRoom.fromJson(roomResult['data']);
      _currentRoomId = chatRoom.roomId;
      
      // Clear processed messages when joining a new room
      _clearProcessedMessages();
      
      debugPrint('ChatBloc: Chat room loaded: ${chatRoom.roomId}');
      
      // OPTIMIZATION 2: Load chat history and order details in parallel
      debugPrint('ChatBloc: 🚀 OPTIMIZATION 2: Loading chat history and order details in parallel...');
      
      final historyFuture = _loadChatHistoryWithTimeout(chatRoom.roomId);
      final orderDetailsFuture2 = orderDetailsFuture; // Reuse the future
      
      // Wait for both with timeout
      final results = await Future.wait([
        historyFuture,
        orderDetailsFuture2,
      ]).timeout(const Duration(seconds: 10)); // 10 second total timeout
      
      final messages = results[0] as List<ChatMessage>;
      final orderDetails = results[1] as OrderDetails?;
      
      debugPrint('ChatBloc: 📨 Loaded ${messages.length} messages');
      debugPrint('ChatBloc: 📋 Order details loaded: ${orderDetails != null}');
      
      // OPTIMIZATION 3: Emit state immediately with available data
      debugPrint('ChatBloc: 📤 Emitting ChatLoaded state immediately');
      emit(ChatLoaded(
        chatRoom: chatRoom,
        messages: messages,
        currentUserId: _currentUserId!,
        orderDetails: orderDetails,
        menuItemDetails: {},
      ));
      
      // OPTIMIZATION 4: Load menu items in background (non-blocking)
      if (orderDetails != null && orderDetails.items.isNotEmpty) {
        // Load menu items synchronously for immediate display
        await _loadMenuItemDetailsSynchronously(orderDetails, emit);
      }
      
      // OPTIMIZATION 5: Setup socket connection in background
      debugPrint('ChatBloc: 🔌 Setting up socket connection in background...');
      _setupSocketListeners();
      
      _socketService.connect().then((connected) {
        if (connected && _currentRoomId != null) {
          _socketService.joinRoom(_currentRoomId!);
          debugPrint('ChatBloc: 🔌 Socket connected and joined room: $_currentRoomId');
        } else {
          debugPrint('ChatBloc: ⚠️ Socket connection failed or room ID is null');
        }
      }).catchError((error) {
        debugPrint('ChatBloc: ❌ Socket connection error: $error');
      });
      
      // Emit page opened event immediately
      debugPrint('ChatBloc: 🚀 TRIGGERING ChatPageOpened event from _onLoadChatData');
      add(const ChatPageOpened());
      
      // Start periodic refresh for real-time updates
      _startPeriodicRefresh();
      
      debugPrint('ChatBloc: Chat data loaded with optimizations');
      
      // Log performance statistics
      PerformanceMonitor.endTimer('ChatDataLoading');
      PerformanceMonitor.logAllStatistics();
      
    } catch (e, stackTrace) {
      debugPrint('ChatBloc: 🚩 Exception in _onLoadChatData: $e');
      debugPrint('ChatBloc: 🚩 Stack trace: $stackTrace');
      PerformanceMonitor.endTimer('ChatDataLoading');
      emit(const ChatError('Failed to load chat. Please try again.'));
    }
  }

  // OPTIMIZATION: Load chat history with timeout
  Future<List<ChatMessage>> _loadChatHistoryWithTimeout(String roomId) async {
    try {
      final historyResult = await ChatService.getChatHistory(roomId)
          .timeout(const Duration(seconds: 5)); // 5 second timeout for chat history
      
      if (historyResult['success'] == true) {
        final historyData = historyResult['data'] as List<dynamic>;
        final messages = historyData
            .map((messageData) => ChatMessage.fromJson(messageData))
            .toList();
        
        // Sort messages by creation time
        messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        
        debugPrint('ChatBloc: 📨 Loaded ${messages.length} messages');
        return messages;
      }
    } catch (e) {
      debugPrint('ChatBloc: ⚠️ Chat history loading failed or timed out: $e');
    }
    return [];
  }

  // OPTIMIZATION: Get order details with caching
  Future<OrderDetails?> _getOrderDetailsWithCache(String orderId) async {
    // Check cache first
    if (_orderDetailsCache.containsKey(orderId)) {
      final timestamp = _cacheTimestamps[orderId];
      if (timestamp != null && DateTime.now().difference(timestamp) < _cacheDuration) {
        debugPrint('ChatBloc: ✅ Returning cached order details for: $orderId');
        return _orderDetailsCache[orderId];
      } else {
        _orderDetailsCache.remove(orderId);
        _cacheTimestamps.remove(orderId);
        debugPrint('ChatBloc: 🗑️ Removed expired cache for: $orderId');
      }
    }
    
    try {
      final orderResult = await OrderHistoryService.getOrderDetails(orderId)
          .timeout(const Duration(seconds: 8)); // 8 second timeout for order details
      
      debugPrint('ChatBloc: 🔍 Order details API called for orderId: $orderId');
      
      if ((orderResult['success'] == 'SUCCESS' || orderResult['success'] == true) && orderResult['data'] != null) {
        try {
          final orderDetails = OrderDetails.fromJson(orderResult['data']);
          debugPrint('ChatBloc: ✅ Order details loaded successfully');
          
          // Cache the result
          _orderDetailsCache[orderId] = orderDetails;
          _cacheTimestamps[orderId] = DateTime.now();
          debugPrint('ChatBloc: 💾 Cached order details for: $orderId');
          
          return orderDetails;
        } catch (e) {
          debugPrint('ChatBloc: ❌ Error parsing order details: $e');
        }
      } else {
        debugPrint('ChatBloc: ⚠️ Order details not available initially');
      }
    } catch (e) {
      debugPrint('ChatBloc: ⚠️ Order details loading failed or timed out: $e');
    }
    return null;
  }

  // Load menu item details synchronously for immediate display
  Future<void> _loadMenuItemDetailsSynchronously(OrderDetails orderDetails, Emitter<ChatState> emit) async {
    try {
      debugPrint('ChatBloc: 🚀 Loading menu item details synchronously...');
      
      // Get unique menu IDs to avoid duplicate API calls
      final uniqueMenuIds = orderDetails.items
          .where((item) => item.menuId != null && item.menuId!.isNotEmpty)
          .map((item) => item.menuId!)
          .toSet()
          .toList();
      
      debugPrint('ChatBloc: 🔍 Fetching menu details for ${uniqueMenuIds.length} unique items');
      
      // Load all menu items synchronously
      final Map<String, Map<String, dynamic>> menuItemDetails = {};
      
      for (final menuId in uniqueMenuIds) {
        try {
          // Check cache first
          if (_menuItemCache.containsKey(menuId)) {
            final timestamp = _cacheTimestamps[menuId];
            if (timestamp != null && DateTime.now().difference(timestamp) < _cacheDuration) {
              debugPrint('ChatBloc: ✅ Returning cached menu item: $menuId');
              menuItemDetails[menuId] = _menuItemCache[menuId]!;
              continue;
            } else {
              _menuItemCache.remove(menuId);
              _cacheTimestamps.remove(menuId);
            }
          }
          
          final menuResult = await MenuItemService.getMenuItemDetails(menuId)
              .timeout(const Duration(seconds: 8)); // 8 second timeout per item
          
          if (menuResult['success'] == true && menuResult['data'] != null) {
            // Cache the result
            _menuItemCache[menuId] = menuResult['data'] as Map<String, dynamic>;
            _cacheTimestamps[menuId] = DateTime.now();
            menuItemDetails[menuId] = menuResult['data'] as Map<String, dynamic>;
            debugPrint('ChatBloc: ✅ Loaded menu item: $menuId');
          }
        } catch (e) {
          debugPrint('ChatBloc: ❌ Error fetching menu item details for $menuId: $e');
        }
      }
      
      // Update state with all menu item details
      if (state is ChatLoaded && !isClosed && !emit.isDone) {
        final currentState = state as ChatLoaded;
        emit(currentState.copyWith(menuItemDetails: menuItemDetails));
        debugPrint('ChatBloc: 📤 Updated state with ${menuItemDetails.length} menu items');
      }
      
      debugPrint('ChatBloc: ✅ Menu item details loading completed synchronously');
      
    } catch (e) {
      debugPrint('ChatBloc: ❌ Error in menu item details synchronous loading: $e');
    }
  }

  // OPTIMIZATION: Load menu item details in background with better caching
  Future<void> _loadMenuItemDetailsInBackground(OrderDetails orderDetails, Emitter<ChatState> emit) async {
    try {
      debugPrint('ChatBloc: 🚀 Loading menu item details in background...');
      
      // Get unique menu IDs to avoid duplicate API calls
      final uniqueMenuIds = orderDetails.items
          .where((item) => item.menuId != null && item.menuId!.isNotEmpty)
          .map((item) => item.menuId!)
          .toSet()
          .toList();
      
      debugPrint('ChatBloc: 🔍 Fetching menu details for ${uniqueMenuIds.length} unique items');
      
      // Process menu items in batches to avoid overwhelming the API
      const batchSize = 3;
      for (int i = 0; i < uniqueMenuIds.length; i += batchSize) {
        final batch = uniqueMenuIds.skip(i).take(batchSize).toList();
        
        try {
          await Future.wait(
            batch.map((menuId) async {
              // Check cache first
              if (_menuItemCache.containsKey(menuId)) {
                final timestamp = _cacheTimestamps[menuId];
                if (timestamp != null && DateTime.now().difference(timestamp) < _cacheDuration) {
                  debugPrint('ChatBloc: ✅ Returning cached menu item: $menuId');
                  return;
                } else {
                  _menuItemCache.remove(menuId);
                  _cacheTimestamps.remove(menuId);
                }
              }
              
              try {
                final menuResult = await MenuItemService.getMenuItemDetails(menuId)
                    .timeout(const Duration(seconds: 3)); // 3 second timeout per item
                
                if (menuResult['success'] == true && menuResult['data'] != null) {
                  // Cache the result
                  _menuItemCache[menuId] = menuResult['data'] as Map<String, dynamic>;
                  _cacheTimestamps[menuId] = DateTime.now();
                  
                  // Update state immediately for each successful menu item
                  if (state is ChatLoaded && !isClosed && !emit.isDone) {
                    final currentState = state as ChatLoaded;
                    final updatedMenuDetails = Map<String, Map<String, dynamic>>.from(currentState.menuItemDetails);
                    updatedMenuDetails[menuId] = menuResult['data'] as Map<String, dynamic>;
                    
                    emit(currentState.copyWith(menuItemDetails: updatedMenuDetails));
                    debugPrint('ChatBloc: 📤 Updated state with menu item: $menuId');
                  }
                }
              } catch (e) {
                debugPrint('ChatBloc: ❌ Error fetching menu item details for $menuId: $e');
              }
            }),
            eagerError: false, // Don't fail all if one fails
          ).timeout(const Duration(seconds: 5)); // 5 second timeout per batch
          
          // Small delay between batches to avoid overwhelming the server
          if (i + batchSize < uniqueMenuIds.length) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
          
        } catch (e) {
          debugPrint('ChatBloc: ⚠️ Batch processing failed: $e');
        }
      }
      
      debugPrint('ChatBloc: ✅ Menu item details loading completed');
      
    } catch (e) {
      debugPrint('ChatBloc: ❌ Error in menu item details background loading: $e');
    }
  }
  
  Future<void> _onSendMessage(SendMessage event, Emitter<ChatState> emit) async {
    if (state is ChatLoaded && _currentRoomId != null && _currentUserId != null) {
      final currentState = state as ChatLoaded;
      
      debugPrint('ChatBloc: Sending message: "${event.content}"');
      
      // OPTIMISTIC UPDATE: Add message immediately to UI
      final optimisticMessage = ChatMessage(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
        roomId: _currentRoomId!,
        senderId: _currentUserId!,
        senderType: 'user',
        content: event.content,
        messageType: 'text',
        readBy: [],
        createdAt: TimezoneUtils.getCurrentTime(),
      );
      
      // Add the optimistic message to the UI immediately
      final updatedMessages = [...currentState.messages, optimisticMessage];
      updatedMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      emit(currentState.copyWith(
        messages: updatedMessages,
        isSendingMessage: true,
      ));
      
      try {
        // Send message via HTTP API first
        final httpResult = await ChatService.sendMessage(
          roomId: _currentRoomId!,
          content: event.content,
        );
        
        debugPrint('ChatBloc: HTTP send result: $httpResult');
        
        if (httpResult['success'] == true) {
          debugPrint('ChatBloc: Message sent successfully via HTTP');
          
          // Get the real message ID from the response
          final realMessageId = httpResult['data']['_id'] as String?;
          if (realMessageId != null) {
            debugPrint('ChatBloc: Replaced optimistic message with real message ID: $realMessageId');
            _tempToRealMessageIds[optimisticMessage.id] = realMessageId;
            _contentToMessageId[event.content] = realMessageId;
          }
          
          // Also send via socket for real-time delivery
          debugPrint('ChatBloc: Also sending via socket (real-time)');
          debugPrint('ChatBloc: 📤 Socket service connected: ${_socketService.isConnected}');
          debugPrint('ChatBloc: 📤 Current room ID: $_currentRoomId');
          debugPrint('ChatBloc: 📤 Message content: ${event.content}');
          
          if (_socketService.isConnected && _currentRoomId != null) {
            final socketResult = _socketService.sendMessage(
              roomId: _currentRoomId!,
              content: event.content,
            );
            debugPrint('ChatBloc: 📤 Socket send result: $socketResult');
            if (socketResult) {
              debugPrint('ChatBloc: ✅ Message sent via socket successfully');
              debugPrint('ChatBloc: 🔄 Waiting for socket delivery confirmation...');
            } else {
              debugPrint('ChatBloc: ❌ Failed to send message via socket');
            }
          } else {
            debugPrint('ChatBloc: ⚠️ Cannot send via socket - not connected or room ID is null');
            debugPrint('ChatBloc: ⚠️ Socket connected: ${_socketService.isConnected}, Room ID: $_currentRoomId');
          }
          
          // Mark messages as read immediately after sending (only if bloc is not closed)
          debugPrint('ChatBloc: Auto marking as read after sending message');
          if (!isClosed) {
            add(MarkAsRead(_currentRoomId!));
          } else {
            debugPrint('ChatBloc: ⚠️ Cannot add MarkAsRead event - bloc is closed');
          }
        } else {
          debugPrint('ChatBloc: Failed to send message via HTTP: ${httpResult['message']}');
          // Remove optimistic message on failure
          final currentState = state;
          if (currentState is ChatLoaded) {
            final updatedMessages = currentState.messages
                .where((msg) => msg.id != optimisticMessage.id)
                .toList();
            
            emit(ChatLoaded(
              chatRoom: currentState.chatRoom,
              messages: updatedMessages,
              currentUserId: currentState.currentUserId,
              orderDetails: currentState.orderDetails,
              menuItemDetails: currentState.menuItemDetails,
            ));
          }
        }
        
      } catch (e) {
        debugPrint('ChatBloc: Error sending message: $e');
        
        // Remove the optimistic message since sending failed
        final messagesWithoutOptimistic = currentState.messages
            .where((msg) => msg.id != optimisticMessage.id)
            .toList();
        
        emit(currentState.copyWith(
          messages: messagesWithoutOptimistic,
          isSendingMessage: false,
        ));
      }
    } else {
      debugPrint('ChatBloc: Cannot send message - invalid state or missing room/user ID');
    }
  }
  
  Future<void> _onConnectSocket(ConnectSocket event, Emitter<ChatState> emit) async {
    debugPrint('ChatBloc: 🔌 _onConnectSocket called');
    debugPrint('ChatBloc: 🔌 Current _isSocketConnected: $_isSocketConnected');
    debugPrint('ChatBloc: 🔌 Socket service connected: ${_socketService.isConnected}');
    
    try {
      final connected = await _socketService.connect();
      debugPrint('ChatBloc: 🔌 Socket connect result: $connected');
      
      if (connected) {
        debugPrint('ChatBloc: ✅ Socket connection initiated successfully');
        
        // Join room after connection
        if (_currentRoomId != null) {
          debugPrint('ChatBloc: 🏠 Joining room after connection: $_currentRoomId');
          _socketService.joinRoom(_currentRoomId!);
        } else {
          debugPrint('ChatBloc: ⚠️ Cannot join room - _currentRoomId is null');
        }
      } else {
        debugPrint('ChatBloc: ❌ Socket connection failed');
      }
    } catch (e) {
      debugPrint('ChatBloc: ❌ Error connecting socket: $e');
    }
  }
  
  Future<void> _onDisconnectSocket(DisconnectSocket event, Emitter<ChatState> emit) async {
    debugPrint('ChatBloc: Disconnecting from socket...');
    _socketService.disconnect();
  }
  
  Future<void> _onReceiveMessage(ReceiveMessage event, Emitter<ChatState> emit) async {
    debugPrint('ChatBloc: _onReceiveMessage called with message: ${event.message.content}');
    
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      
      debugPrint('ChatBloc: Processing received message: ${event.message.content}');
      debugPrint('ChatBloc: Message from: ${event.message.senderType} (ID: ${event.message.senderId})');
      debugPrint('ChatBloc: Message timestamp: ${event.message.createdAt}');
      debugPrint('ChatBloc: Current messages count: ${currentState.messages.length}');
      
      // Check if message has been processed recently using global tracking
      if (_isMessageProcessed(event.message)) {
        debugPrint('ChatBloc: Message already processed recently, ignoring duplicate');
        debugPrint('ChatBloc: Duplicate message content: "${event.message.content}"');
        return;
      }
      
      // Mark message as processed immediately to prevent future duplicates
      _markMessageAsProcessed(event.message);
      
      // Additional check for existing messages in the current list
      final existingMessageIndex = currentState.messages
          .indexWhere((msg) => 
              // Exact ID match
              msg.id == event.message.id ||
              // Same content, sender, and very recent timestamp (within 2 seconds)
              (msg.content == event.message.content && 
               msg.senderId == event.message.senderId &&
               msg.senderType == event.message.senderType &&
               msg.createdAt.difference(event.message.createdAt).abs().inSeconds < 2));
      
      debugPrint('ChatBloc: Existing message index: $existingMessageIndex');
      debugPrint('ChatBloc: Checking for duplicates - Content: "${event.message.content}", Sender: ${event.message.senderId}');
      
      // Check if the existing message is an optimistic message that should be replaced
      bool shouldReplaceOptimistic = false;
      if (existingMessageIndex != -1) {
        final existingMessage = currentState.messages[existingMessageIndex];
        shouldReplaceOptimistic = existingMessage.id.startsWith('temp_') && 
                                 existingMessage.content == event.message.content &&
                                 existingMessage.senderId == event.message.senderId;
        debugPrint('ChatBloc: Found existing message at index $existingMessageIndex');
        debugPrint('ChatBloc: Existing message ID: ${existingMessage.id}');
        debugPrint('ChatBloc: Existing message is optimistic: ${existingMessage.id.startsWith('temp_')}');
        debugPrint('ChatBloc: Should replace optimistic message: $shouldReplaceOptimistic');
      }
      
      if (existingMessageIndex == -1 || shouldReplaceOptimistic) {
        debugPrint('ChatBloc: Message is new, adding to UI');
        
        // Remove any temporary optimistic messages that might match this content
        final messagesWithoutOptimistic = currentState.messages
            .where((msg) => !(msg.id.startsWith('temp_') && 
                            msg.content == event.message.content &&
                            msg.senderId == event.message.senderId))
            .toList();
        
        debugPrint('ChatBloc: Messages without optimistic: ${messagesWithoutOptimistic.length}');
        debugPrint('ChatBloc: Original messages count: ${currentState.messages.length}');
        debugPrint('ChatBloc: Removed ${currentState.messages.length - messagesWithoutOptimistic.length} optimistic messages');
        
        // Create a new message with adjusted timestamp if needed
        var newMessage = event.message;
        
        // If the incoming message timestamp is older than the last message,
        // adjust it to ensure it appears at the bottom
        if (messagesWithoutOptimistic.isNotEmpty) {
          final lastMessage = messagesWithoutOptimistic.last;
          if (newMessage.createdAt.isBefore(lastMessage.createdAt) || 
              newMessage.createdAt.isAtSameMomentAs(lastMessage.createdAt)) {
            // Adjust timestamp to be 1 second after the last message
            final adjustedTime = lastMessage.createdAt.add(const Duration(seconds: 1));
            newMessage = ChatMessage(
              id: newMessage.id,
              roomId: newMessage.roomId,
              senderId: newMessage.senderId,
              senderType: newMessage.senderType,
              content: newMessage.content,
              messageType: newMessage.messageType,
              readBy: newMessage.readBy,
              createdAt: adjustedTime,
            );
            debugPrint('ChatBloc: Adjusted message timestamp from ${event.message.createdAt} to $adjustedTime');
          }
        }
        
        // Add new message to the list
        final updatedMessages = [...messagesWithoutOptimistic, newMessage];
        
        // Sort by creation time to ensure proper order
        updatedMessages.sort((a, b) {
          final comparison = a.createdAt.compareTo(b.createdAt);
          // If timestamps are equal, prioritize real messages over temp ones
          if (comparison == 0) {
            if (a.id.startsWith('temp_') && !b.id.startsWith('temp_')) {
              return -1; // temp message comes first
            } else if (!a.id.startsWith('temp_') && b.id.startsWith('temp_')) {
              return 1; // real message comes after
            }
          }
          return comparison;
        });
        
        debugPrint('ChatBloc: Added new message from ${newMessage.senderType}: ${newMessage.content}');
        debugPrint('ChatBloc: Total messages now: ${updatedMessages.length}');
        
        // Log the last few messages for debugging
        if (updatedMessages.length > 1) {
          final lastTwo = updatedMessages.length >= 2 
              ? updatedMessages.sublist(updatedMessages.length - 2)
              : updatedMessages;
          debugPrint('ChatBloc: Last two messages:');
          for (int i = 0; i < lastTwo.length; i++) {
            debugPrint('  ${i + 1}. ${lastTwo[i].content} (${lastTwo[i].createdAt}) from ${lastTwo[i].senderId}');
          }
        }
        
        // Emit the updated state first
        debugPrint('ChatBloc: Emitting updated state with ${updatedMessages.length} messages');
        emit(currentState.copyWith(
          messages: updatedMessages,
          isSendingMessage: false,
        ));
        
        // Auto mark as read for incoming messages (not from current user)
        if (_currentRoomId != null && newMessage.senderId != _currentUserId) {
          debugPrint('ChatBloc: 📨 Auto marking as read for incoming message from ${newMessage.senderType}');
          debugPrint('ChatBloc: 📨 Message content: "${newMessage.content}"');
          // Use the new typing event strategy for message receipt on active page
          debugPrint('ChatBloc: 📨 TRIGGERING MessageReceivedOnActivePage event');
          add(MessageReceivedOnActivePage(newMessage));
          
          // Note: message_seen events are not being broadcasted by the server
          // We rely on mark_as_read events for real-time blue tick updates
          debugPrint('ChatBloc: Using typing events for real-time blue tick updates');
        } else {
          debugPrint('ChatBloc: ⚠️ Skipping MessageReceivedOnActivePage - Room ID: $_currentRoomId, Message sender: ${newMessage.senderId}, Current user: $_currentUserId');
        }
        
      } else {
        debugPrint('ChatBloc: Message already exists in current list, ignoring duplicate');
        debugPrint('ChatBloc: Duplicate message content: "${event.message.content}"');
      }
    } else {
      debugPrint('ChatBloc: Cannot process message - state is not ChatLoaded');
    }
  }
  
  Future<void> _onMarkAsRead(MarkAsRead event, Emitter<ChatState> emit) async {
    try {
      debugPrint('ChatBloc: Marking messages as read for room: ${event.roomId}');
      
      // Mark as read via socket first (real-time)
      _socketService.markAsReadViaSocket(event.roomId);
      debugPrint('ChatBloc: Marked as read via socket - SUCCESS');
      
      // Also mark as read via HTTP API for persistence
      debugPrint('ChatBloc: Calling mark as read API...');
      final apiResult = await ChatService.markMessagesAsRead(roomId: event.roomId);
      final apiSuccess = apiResult['success'] == true;
      debugPrint('ChatBloc: Marked as read via API - ${apiSuccess ? 'SUCCESS' : 'FAILED'}');
      
      debugPrint('ChatBloc: Mark as read completed - Socket: true, API: $apiSuccess');
      
      // Simulate mark_as_read event locally since server doesn't broadcast it
      debugPrint('ChatBloc: Simulating mark_as_read event locally since server doesn\'t broadcast');
      
      if (state is ChatLoaded) {
        final currentState = state as ChatLoaded;
        final updatedMessages = currentState.messages.map((message) {
          // Mark all messages as read by current user
          if (!message.isReadByOthers(_currentUserId!)) {
            final updatedReadBy = List<ReadByEntry>.from(message.readBy);
            final existingEntry = updatedReadBy.firstWhereOrNull(
              (entry) => entry.userId == _currentUserId,
            );
            
            if (existingEntry == null) {
              updatedReadBy.add(ReadByEntry(
                userId: _currentUserId!,
                readAt: TimezoneUtils.getCurrentTime(),
                id: DateTime.now().millisecondsSinceEpoch.toString(),
              ));
            }
            
            debugPrint('ChatBloc: Locally marking message as read: ${message.content}');
            
            return ChatMessage(
              id: message.id,
              roomId: message.roomId,
              senderId: message.senderId,
              senderType: message.senderType,
              content: message.content,
              messageType: message.messageType,
              readBy: updatedReadBy,
              createdAt: message.createdAt,
            );
          }
          return message;
        }).toList();
        
        emit(ChatLoaded(
          chatRoom: currentState.chatRoom,
          messages: updatedMessages,
          currentUserId: currentState.currentUserId,
          orderDetails: currentState.orderDetails,
          menuItemDetails: currentState.menuItemDetails,
        ));
        
        debugPrint('ChatBloc: Updated messages with local read status');
      }
    } catch (e) {
      debugPrint('ChatBloc: Error marking as read: $e');
    }
  }
  
  Future<void> _onStartTyping(StartTyping event, Emitter<ChatState> emit) async {
    debugPrint('ChatBloc: 📤 _onStartTyping called');
    debugPrint('ChatBloc: 📤 Current room ID: $_currentRoomId');
    debugPrint('ChatBloc: 📤 Current user ID: $_currentUserId');
    debugPrint('ChatBloc: 📤 Socket connected: ${_socketService.isConnected}');
    
    if (_isSocketConnected && _currentRoomId != null) {
      debugPrint('ChatBloc: 📤 SENDING typing event to socket service');
      debugPrint('ChatBloc: Room ID: $_currentRoomId, User ID: $_currentUserId');
      _socketService.sendTyping(_currentRoomId!);
      debugPrint('ChatBloc: Started typing indicator');
    } else {
      debugPrint('ChatBloc: ⚠️ Cannot send typing - Socket connected: $_isSocketConnected, Room ID: $_currentRoomId');
      debugPrint('ChatBloc: ⚠️ Socket service connected: ${_socketService.isConnected}');
    }
  }
  
  Future<void> _onStopTyping(StopTyping event, Emitter<ChatState> emit) async {
    debugPrint('ChatBloc: 📤 _onStopTyping called');
    debugPrint('ChatBloc: 📤 Current room ID: $_currentRoomId');
    debugPrint('ChatBloc: 📤 Current user ID: $_currentUserId');
    debugPrint('ChatBloc: 📤 Socket connected: ${_socketService.isConnected}');
    
    if (_isSocketConnected && _currentRoomId != null) {
      debugPrint('ChatBloc: 📤 SENDING stop typing event to socket service');
      debugPrint('ChatBloc: Room ID: $_currentRoomId, User ID: $_currentUserId');
      _socketService.sendStopTyping(_currentRoomId!);
      debugPrint('ChatBloc: Stopped typing indicator');
    } else {
      debugPrint('ChatBloc: ⚠️ Cannot send stop typing - Socket connected: $_isSocketConnected, Room ID: $_currentRoomId');
      debugPrint('ChatBloc: ⚠️ Socket service connected: ${_socketService.isConnected}');
    }
  }
  
  Future<void> _onUpdateMessageReadStatus(UpdateMessageReadStatus event, Emitter<ChatState> emit) async {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      final readData = event.readData;
      
      debugPrint('ChatBloc: Processing read status update: ${readData['type']}');
      debugPrint('ChatBloc: Current messages count: ${currentState.messages.length}');
      debugPrint('ChatBloc: Current user ID: $_currentUserId');
      
      try {
        bool hasUpdates = false;
        final updatedMessages = currentState.messages.map((message) {
          // Update read status for matching messages
          if (readData['type'] == 'single_message_read') {
            final messageId = readData['data']['messageId'];
            debugPrint('ChatBloc: Checking message_read for message: $messageId, current message: ${message.id}');
            if (message.id == messageId) {
              final updatedReadBy = List<ReadByEntry>.from(message.readBy);
              final userId = readData['data']['readBy'];
              
              if (!updatedReadBy.any((entry) => entry.userId == userId)) {
                updatedReadBy.add(ReadByEntry(
                  userId: userId,
                  readAt: TimezoneUtils.parseToIST(readData['data']['readAt']),
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                ));
                hasUpdates = true;
                debugPrint('ChatBloc: Updated message_read for message: $messageId by user: $userId');
                
                return ChatMessage(
                  id: message.id,
                  roomId: message.roomId,
                  senderId: message.senderId,
                  senderType: message.senderType,
                  content: message.content,
                  messageType: message.messageType,
                  readBy: updatedReadBy,
                  createdAt: message.createdAt,
                );
              }
            }
          } else if (readData['type'] == 'single_message_seen') {
            // Handle individual message seen events
            final messageId = readData['data']['messageId'];
            final seenBy = readData['data']['seenBy'];
            
            debugPrint('ChatBloc: Checking message_seen for message: $messageId, current message: ${message.id}');
            debugPrint('ChatBloc: Message seen by: $seenBy, Message sender: ${message.senderId}');
            
            // Check if this is a real message ID or if we need to map it
            String targetMessageId = messageId;
            if (messageId.startsWith('socket_')) {
              // This is a temporary socket ID, try to find the real message ID
              final realMessageId = _tempToRealMessageIds[messageId];
              if (realMessageId != null) {
                targetMessageId = realMessageId;
                debugPrint('ChatBloc: Mapped socket ID $messageId to real ID $realMessageId');
              }
            }
            
            // Check if this message matches (either by ID or content)
            bool messageMatches = false;
            
            // First try exact ID match
            if (message.id == targetMessageId) {
              messageMatches = true;
              debugPrint('ChatBloc: Exact ID match found for message: ${message.content}');
            }
            
            // If no exact match, try content-based matching for recent messages
            if (!messageMatches && message.content == readData['data']['content'] && 
                message.senderId == readData['data']['senderId']) {
              messageMatches = true;
              debugPrint('ChatBloc: Content-based match found for message: ${message.content}');
            }
            
            if (messageMatches) {
              final updatedReadBy = List<ReadByEntry>.from(message.readBy);
              
              debugPrint('ChatBloc: Current readBy entries: ${message.readBy.map((e) => '${e.userId} at ${e.readAt}').toList()}');
              debugPrint('ChatBloc: Adding seenBy user: $seenBy');
              
              if (!updatedReadBy.any((entry) => entry.userId == seenBy)) {
                updatedReadBy.add(ReadByEntry(
                  userId: seenBy,
                  readAt: TimezoneUtils.parseToIST(readData['data']['seenAt']),
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                ));
                hasUpdates = true;
                
                debugPrint('ChatBloc: Updated message seen status for message: ${message.content} by user: $seenBy');
                debugPrint('ChatBloc: New readBy entries: ${updatedReadBy.map((e) => '${e.userId} at ${e.readAt}').toList()}');
                
                return ChatMessage(
                  id: message.id,
                  roomId: message.roomId,
                  senderId: message.senderId,
                  senderType: message.senderType,
                  content: message.content,
                  messageType: message.messageType,
                  readBy: updatedReadBy,
                  createdAt: message.createdAt,
                );
              } else {
                debugPrint('ChatBloc: User $seenBy already marked as read for message: ${message.content}');
              }
            } else {
              debugPrint('ChatBloc: No match found for message_seen event');
              debugPrint('ChatBloc: Looking for: $targetMessageId, Available: ${message.id}');
            }
          } else if (readData['type'] == 'bulk_messages_read') {
            final roomId = readData['data']['roomId'];
            final userId = readData['data']['userId'];
            
            debugPrint('ChatBloc: Processing bulk messages read for room: $roomId by user: $userId');
            
            if (message.roomId == roomId && !message.readBy.any((entry) => entry.userId == userId)) {
              final updatedReadBy = List<ReadByEntry>.from(message.readBy);
              updatedReadBy.add(ReadByEntry(
                userId: userId,
                readAt: TimezoneUtils.parseToIST(readData['data']['readAt'] ?? readData['data']['timestamp']),
                id: DateTime.now().millisecondsSinceEpoch.toString(),
              ));
              hasUpdates = true;
              debugPrint('ChatBloc: Updated bulk read for message: ${message.content} by user: $userId');
              
              return ChatMessage(
                id: message.id,
                roomId: message.roomId,
                senderId: message.senderId,
                senderType: message.senderType,
                content: message.content,
                messageType: message.messageType,
                readBy: updatedReadBy,
                createdAt: message.createdAt,
              );
            }
          } else if (readData['type'] == 'partner_typing') {
            // Handle partner typing event - mark all unread messages as read
            final typingUserId = readData['data']['userId'];
            
            // Only mark as read if this is a partner (not current user) and message is from current user
            if (typingUserId != _currentUserId && message.senderId == _currentUserId && 
                !message.readBy.any((entry) => entry.userId == typingUserId)) {
              
              final updatedReadBy = List<ReadByEntry>.from(message.readBy);
              updatedReadBy.add(ReadByEntry(
                userId: typingUserId,
                readAt: DateTime.now(),
                id: DateTime.now().millisecondsSinceEpoch.toString(),
              ));
              hasUpdates = true;
              debugPrint('ChatBloc: Marked message as read due to partner typing: ${message.content} by user: $typingUserId');
              
              return ChatMessage(
                id: message.id,
                roomId: message.roomId,
                senderId: message.senderId,
                senderType: message.senderType,
                content: message.content,
                messageType: message.messageType,
                readBy: updatedReadBy,
                createdAt: message.createdAt,
              );
            }
          }
          
          return message;
        }).toList();
        
        if (hasUpdates) {
          emit(currentState.copyWith(messages: updatedMessages));
          debugPrint('ChatBloc: Updated message read status via socket - SUCCESS');
          
          // Force UI rebuild to show blue tick updates
          debugPrint('ChatBloc: Forcing UI rebuild for blue tick updates');
        } else {
          debugPrint('ChatBloc: No message read status updates found');
          debugPrint('ChatBloc: This might be because messages are already marked as read');
        }
      } catch (e) {
        debugPrint('ChatBloc: Error updating message read status: $e');
        debugPrint('ChatBloc: Read data that caused error: $readData');
      }
    } else {
      debugPrint('ChatBloc: Cannot update read status - state is not ChatLoaded');
    }
  }
  
  // Helper method to create a unique hash for a message
  String _createMessageHash(ChatMessage message) {
    // Create a more unique hash using content, sender, and a time window
    final timeWindow = (message.createdAt.millisecondsSinceEpoch / 1000).round(); // Round to nearest second
    return '${message.content}_${message.senderId}_${message.senderType}_$timeWindow';
  }
  
  // Helper method to check if message has been processed recently
  bool _isMessageProcessed(ChatMessage message) {
    final hash = _createMessageHash(message);
    final isProcessed = _processedMessageHashes.contains(hash);
    debugPrint('ChatBloc: Checking message hash: $hash - Processed: $isProcessed');
    return isProcessed;
  }
  
  // Helper method to mark message as processed
  void _markMessageAsProcessed(ChatMessage message) {
    final hash = _createMessageHash(message);
    _processedMessageHashes.add(hash);
    debugPrint('ChatBloc: Marked message as processed: $hash');
    
    // Maintain size limit
    if (_processedMessageHashes.length > _maxProcessedHashes) {
      final removed = _processedMessageHashes.first;
      _processedMessageHashes.remove(removed);
      debugPrint('ChatBloc: Removed old message hash: $removed');
    }
  }
  
  // Helper method to clear processed messages when joining new room
  void _clearProcessedMessages() {
    _processedMessageHashes.clear();
    _tempToRealMessageIds.clear();
    _contentToMessageId.clear();
    debugPrint('ChatBloc: Cleared processed message hashes and ID mappings for new room');
  }
  
  // OPTIMIZATION: Start periodic refresh for real-time updates
  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (state is ChatLoaded) {
        final currentState = state as ChatLoaded;
        // Only refresh if order details are not available
        if (currentState.orderDetails == null && _currentRoomId != null) {
          debugPrint('ChatBloc: 🔄 Periodic refresh - checking for order details...');
          _refreshOrderDetails();
        }
      }
    });
    debugPrint('ChatBloc: ✅ Periodic refresh started for order details');
  }
  
  // OPTIMIZATION: Refresh order details with caching
  Future<void> _refreshOrderDetails() async {
    if (state is ChatLoaded && _currentRoomId != null) {
      final currentState = state as ChatLoaded;
      final orderId = currentState.chatRoom.orderId.isNotEmpty 
          ? currentState.chatRoom.orderId 
          : currentState.chatRoom.roomId;
      
      if (orderId.isNotEmpty) {
        try {
          debugPrint('ChatBloc: 🔄 Refreshing order details for: $orderId');
          final orderDetails = await _getOrderDetailsWithCache(orderId);
          
          if (orderDetails != null) {
            debugPrint('ChatBloc: ✅ Order details refreshed successfully');
            
            // Emit updated state with order details only
            emit(currentState.copyWith(
              orderDetails: orderDetails,
            ));
            
            debugPrint('ChatBloc: ✅ Chat state updated with refreshed order details');
          } else {
            debugPrint('ChatBloc: ⚠️ Order details still not available in refresh');
          }
        } catch (e) {
          debugPrint('ChatBloc: ❌ Error refreshing order details: $e');
        }
      }
    }
  }
  
  Future<void> _onChatPageOpened(ChatPageOpened event, Emitter<ChatState> emit) async {
    debugPrint('ChatBloc: 🚀 CHAT PAGE OPENED event received');
    if (_isSocketConnected && _currentRoomId != null) {
      debugPrint('ChatBloc: 📤 SENDING typing event for page open');
      debugPrint('ChatBloc: Room ID: $_currentRoomId, User ID: $_currentUserId');
      _socketService.sendTyping(_currentRoomId!);
      
      // Auto mark as read when page opens to handle previous unread messages
      add(MarkAsRead(_currentRoomId!));
      
      // NEW: Also update blue ticks for previous messages when page opens
      debugPrint('ChatBloc: 🔵 Updating blue ticks for previous messages due to page open');
      _updateBlueTicksForPreviousMessages();
      
    } else {
      debugPrint('ChatBloc: ⚠️ Cannot emit typing for page open - Socket connected: $_isSocketConnected, Room ID: $_currentRoomId');
    }
  }
  
  Future<void> _onChatPageClosed(ChatPageClosed event, Emitter<ChatState> emit) async {
    debugPrint('ChatBloc: 🚪 CHAT PAGE CLOSED event received');
    if (_isSocketConnected && _currentRoomId != null) {
      debugPrint('ChatBloc: 📤 SENDING stop typing event for page close');
      debugPrint('ChatBloc: Room ID: $_currentRoomId, User ID: $_currentUserId');
      _socketService.sendStopTyping(_currentRoomId!);
    } else {
      debugPrint('ChatBloc: ⚠️ Cannot emit stop typing for page close - Socket connected: $_isSocketConnected, Room ID: $_currentRoomId');
    }
  }
  
  Future<void> _onMessageReceivedOnActivePage(MessageReceivedOnActivePage event, Emitter<ChatState> emit) async {
    debugPrint('ChatBloc: 📨 MESSAGE RECEIVED ON ACTIVE PAGE event received');
    debugPrint('ChatBloc: 📨 Message content: "${event.message.content}"');
    debugPrint('ChatBloc: 📨 Message sender: ${event.message.senderId}');
    
    if (_isSocketConnected && _currentRoomId != null) {
      debugPrint('ChatBloc: 📤 SENDING typing event for message receipt on active page');
      debugPrint('ChatBloc: Room ID: $_currentRoomId, User ID: $_currentUserId');
      _socketService.sendTyping(_currentRoomId!);
      
      // Auto mark as read when new message is received on active page
      add(MarkAsRead(_currentRoomId!));
      
      // NEW: Also update blue ticks for previous messages when new message is received
      debugPrint('ChatBloc: 🔵 Updating blue ticks for previous messages due to message receipt on active page');
      _updateBlueTicksForPreviousMessages();
      
    } else {
      debugPrint('ChatBloc: ⚠️ Cannot emit typing for message receipt - Socket connected: $_isSocketConnected, Room ID: $_currentRoomId');
    }
  }
  
  // NEW: Update blue ticks for previous messages when partner starts typing
  void _updateBlueTicksForPreviousMessages() {
    debugPrint('ChatBloc: 🔵 Triggering blue tick update event');
    add(const UpdateBlueTicksForPreviousMessages());
  }

  Future<void> _onUpdateBlueTicksForPreviousMessages(UpdateBlueTicksForPreviousMessages event, Emitter<ChatState> emit) async {
    if (state is ChatLoaded && _currentUserId != null) {
      final currentState = state as ChatLoaded;
      debugPrint('ChatBloc: 🔵 Starting blue tick update for previous messages');
      debugPrint('ChatBloc: 🔵 Current messages count: ${currentState.messages.length}');
      
      // Get the partner ID from the current state or from the partner IDs
      String? partnerId;
      if (currentState.chatRoom != null && currentState.chatRoom!.participants.isNotEmpty) {
        // Find the first participant that is not the current user (i.e., the partner)
        final partner = currentState.chatRoom!.participants.firstWhere(
          (p) => p.userId != _currentUserId,
          orElse: () => Participant(userId: '', userType: ''),
        );
        if (partner.userId.isNotEmpty) {
          partnerId = partner.userId;
        }
      }
      
      // Fallback: use the current partner ID if available
      if (partnerId == null && _currentPartnerId != null) {
        partnerId = _currentPartnerId;
        debugPrint('ChatBloc: 🔵 Using fallback partner ID: $partnerId');
      }
      
      if (partnerId == null) {
        debugPrint('ChatBloc: ⚠️ Cannot update blue ticks - no partner ID found');
        return;
      }
      
      debugPrint('ChatBloc: 🔵 Using partner ID for blue tick update: $partnerId');
      
      bool hasUpdates = false;
      final updatedMessages = currentState.messages.map((message) {
        // Only update messages sent by current user that don't have blue ticks from partner yet
        if (message.isFromCurrentUser(_currentUserId) && !message.isReadByUser(partnerId!)) {
          debugPrint('ChatBloc: 🔵 Updating message "${message.content}" for blue tick');
          debugPrint('ChatBloc: 🔵 Message readBy entries: ${message.readBy.map((r) => '${r.userId} at ${r.readAt}').join(', ')}');
          
          // Create updated message with blue tick by adding a read entry with REAL partner ID
          final updatedReadBy = List<ReadByEntry>.from(message.readBy);
          updatedReadBy.add(ReadByEntry(
            userId: partnerId!, // Use REAL partner ID instead of dummy
            readAt: DateTime.now(),
            id: DateTime.now().millisecondsSinceEpoch.toString(),
          ));
          
          final updatedMessage = ChatMessage(
            id: message.id,
            roomId: message.roomId,
            senderId: message.senderId,
            senderType: message.senderType,
            content: message.content,
            messageType: message.messageType,
            readBy: updatedReadBy,
            createdAt: message.createdAt,
          );
          
          hasUpdates = true;
          return updatedMessage;
        }
        return message;
      }).toList();
      
      if (hasUpdates) {
        debugPrint('ChatBloc: 🔵 Emitting updated state with blue ticks');
        emit(currentState.copyWith(messages: updatedMessages));
        debugPrint('ChatBloc: ✅ Blue tick update completed');
      } else {
        debugPrint('ChatBloc: 🔄 No messages needed blue tick update');
        // Debug: Let's see what messages we have and their read status
        for (final message in currentState.messages.take(5)) {
          if (message.isFromCurrentUser(_currentUserId)) {
            debugPrint('ChatBloc: 🔍 Message "${message.content}": isReadByUser($partnerId) = ${message.isReadByUser(partnerId!)}');
            debugPrint('ChatBloc: 🔍 Message readBy entries: ${message.readBy.map((r) => '${r.userId}').join(', ')}');
          }
        }
      }
    } else {
      debugPrint('ChatBloc: ⚠️ Cannot update blue ticks - not in ChatLoaded state or missing user ID');
    }
  }
}
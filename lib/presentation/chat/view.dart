import 'package:bird/service/order_service.dart';
import 'package:bird/service/chat_service.dart';
import 'package:bird/service/socket_service.dart';
import 'package:bird/utils/snackbar_utils.dart';
import 'package:bird/widgets/cancel_order_bottom_sheet.dart';

import 'package:bird/widgets/chat_order_details_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../constants/color/colorConstant.dart';
import '../../constants/font/fontManager.dart';
import '../../models/chat_models.dart';
import '../../models/order_details_model.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';
import 'dart:async';
import 'package:bird/service/restaurant_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:collection/collection.dart';
import 'package:flutter/services.dart';


class ChatView extends StatefulWidget {
  final String? orderId;
  final bool isNewlyPlacedOrder; // Flag to indicate if this is a newly placed order
  
  ChatView({
    Key? key,
    this.orderId,
    this.isNewlyPlacedOrder = false, // Default to false
  }) : super(key: key) {
    debugPrint('🚨🚨🚨 CHAT VIEW CONSTRUCTOR CALLED with orderId: $orderId, isNewlyPlacedOrder: $isNewlyPlacedOrder 🚨🚨🚨');
    print('🚨🚨🚨 CHAT VIEW CONSTRUCTOR PRINT with orderId: $orderId, isNewlyPlacedOrder: $isNewlyPlacedOrder 🚨🚨🚨');
  }

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  Timer? _typingTimer;
  bool _isTyping = false;
  ChatBloc? _chatBloc; // Store reference to avoid provider issues
  
  // Message input state is now computed dynamically
  
  // Add flag to track if page opened event has been emitted
  bool _pageOpenedEventEmitted = false;
  String? _partnerPhoneNumber;
  bool _isFetchingPhone = false;
  
  // Flag to toggle order details sender type (for testing) - moved to state management

  @override
  void initState() {
    super.initState();
    debugPrint('🚨🚨🚨 CHAT VIEW INIT STATE CALLED with orderId: ${widget.orderId} 🚨🚨🚨');
    print('🚨🚨🚨 CHAT VIEW INIT STATE PRINT with orderId: ${widget.orderId} 🚨🚨🚨');
    // Listen to text changes to update send button state and typing indicators
    _messageController.addListener(_onTextChanged);
    
    // Listen to focus changes to handle keyboard
    _focusNode.addListener(_onFocusChanged);
    // Optionally, prefetch partner phone number if orderId is available
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();
    
    // Emit page closed event when disposing
    if (_chatBloc != null) {
      debugPrint('ChatView: 🚪 EMITTING ChatPageClosed event from dispose');
      _chatBloc!.add(const ChatPageClosed());
      debugPrint('ChatView: ✅ ChatPageClosed event emitted successfully from dispose');
    } else {
      debugPrint('ChatView: ⚠️ Cannot emit ChatPageClosed from dispose - chatBloc is null');
    }
    
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    
    // Add debug prints to see if typing events are being triggered
    debugPrint('ChatView: ⌨️ Text changed - hasText: $hasText, isTyping: $_isTyping');
    
    // Note: Typing indicators are now used for blue tick updates via page lifecycle events
    // Actual typing indicators are handled by the typing event strategy
    
    // BUT: Let's also trigger typing events during actual typing for better UX
    if (_chatBloc != null) {
      if (hasText && !_isTyping) {
        _isTyping = true;
        debugPrint('ChatView: ⌨️ Starting typing indicator for actual typing');
        _chatBloc!.add(const StartTyping());
      } else if (!hasText && _isTyping) {
        _isTyping = false;
        debugPrint('ChatView: ⌨️ Stopping typing indicator for actual typing');
        _chatBloc!.add(const StopTyping());
      }
      
      // Reset typing timer for actual typing
      _typingTimer?.cancel();
      if (hasText) {
        _typingTimer = Timer(const Duration(seconds: 2), () {
          if (_isTyping && _chatBloc != null) {
            _isTyping = false;
            debugPrint('ChatView: ⌨️ Auto-stopping typing indicator after 2 seconds');
            _chatBloc!.add(const StopTyping());
          }
        });
      }
    }
  }

  void _onFocusChanged() {
    // Scroll to bottom when keyboard appears/disappears
    if (_focusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Handle cancel order
  Future<void> _handleCancelOrder(String orderId) async {
    try {
      debugPrint('ChatView: Attempting to cancel order: $orderId');
      
      final result = await OrderService.cancelOrder(orderId);
      
      if (mounted) {
        Navigator.pop(context); // Close bottom sheet
        
        if (result['success'] == true) {
          // Show success message using SnackBarUtils
          SnackBarUtils.showSuccess(
            context: context,
            message: result['message'] ?? 'Order cancelled successfully',
          );
          
          // Pop back to previous screen after short delay
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.pop(context);
          }
        } else {
          // Show error message using SnackBarUtils
          SnackBarUtils.showError(
            context: context,
            message: result['message'] ?? 'Failed to cancel order',
          );
        }
      }
    } catch (e) {
      debugPrint('ChatView: Error cancelling order: $e');
      
      if (mounted) {
        Navigator.pop(context); // Close bottom sheet
        
        SnackBarUtils.showError(
          context: context,
          message: 'Something went wrong. Please try again.',
        );
      }
    }
  }

  Future<void> _fetchPartnerPhone(ChatRoom chatRoom) async {
    debugPrint('ChatView: 📞 Starting to fetch partner phone for chat room: ${chatRoom.id}');
    
    setState(() {
      _isFetchingPhone = true;
    });
    
    try {
      debugPrint('ChatView: 📞 Looking for partner in participants: ${chatRoom.participants.length} participants');
      
      final partner = chatRoom.participants.firstWhereOrNull((p) => p.userType == 'partner');
      
      if (partner != null) {
        debugPrint('ChatView: 📞 Found partner with ID: ${partner.userId}');
        
        final data = await RestaurantService.fetchRestaurantByPartnerId(partner.userId);
        debugPrint('ChatView: 📞 Restaurant service response: $data');
        
        if (data != null) {
          debugPrint('ChatView: 📞 Available data keys: ${data.keys.toList()}');
          
          // Try different possible phone number fields
          String? phoneNumber;
          if (data['mobile'] != null) {
            phoneNumber = data['mobile'].toString();
            debugPrint('ChatView: 📞 Found phone in "mobile" field: $phoneNumber');
          } else if (data['phone'] != null) {
            phoneNumber = data['phone'].toString();
            debugPrint('ChatView: 📞 Found phone in "phone" field: $phoneNumber');
          } else if (data['contact'] != null) {
            phoneNumber = data['contact'].toString();
            debugPrint('ChatView: 📞 Found phone in "contact" field: $phoneNumber');
          } else if (data['phoneNumber'] != null) {
            phoneNumber = data['phoneNumber'].toString();
            debugPrint('ChatView: 📞 Found phone in "phoneNumber" field: $phoneNumber');
          }
          
          if (phoneNumber != null && phoneNumber.isNotEmpty) {
            debugPrint('ChatView: 📞 Retrieved phone number: $phoneNumber');
            
            setState(() {
              _partnerPhoneNumber = phoneNumber;
            });
            
            debugPrint('ChatView: 📞 Phone number stored in state: $_partnerPhoneNumber');
          } else {
            debugPrint('ChatView: 📞 No valid phone number found in restaurant data');
          }
        } else {
          debugPrint('ChatView: 📞 No restaurant data received');
        }
      } else {
        debugPrint('ChatView: 📞 No partner found in participants');
        debugPrint('ChatView: 📞 Available participants: ${chatRoom.participants.map((p) => '${p.userId} (${p.userType})').toList()}');
      }
    } catch (e) {
      debugPrint('ChatView: 📞 Error fetching partner phone: $e');
      debugPrint('ChatView: 📞 Error stack trace: ${StackTrace.current}');
    } finally {
      setState(() {
        _isFetchingPhone = false;
      });
      debugPrint('ChatView: 📞 Finished fetching phone number. Result: $_partnerPhoneNumber');
    }
  }

  Future<void> _callPartner(ChatRoom chatRoom) async {
    debugPrint('ChatView: 📞 Call button pressed for chat room: ${chatRoom.id}');
    
    try {
      // For debugging purposes, you can uncomment the next line to test with a hardcoded number
      // await _testCallWithHardcodedNumber();
      
      // Check if we already have the phone number
      if (_partnerPhoneNumber == null) {
        debugPrint('ChatView: 📞 Phone number not cached, fetching from API...');
        await _fetchPartnerPhone(chatRoom);
      } else {
        debugPrint('ChatView: 📞 Using cached phone number: $_partnerPhoneNumber');
      }
      
      if (_partnerPhoneNumber != null && _partnerPhoneNumber!.isNotEmpty) {
        // Sanitize and ensure country code
        String phone = _partnerPhoneNumber!.replaceAll(RegExp(r'[^0-9+]'), '');
        debugPrint('ChatView: 📞 Sanitized phone number: $phone');
        
        if (!phone.startsWith('+')) {
          phone = '+91$phone'; // Default to India, change as needed
          debugPrint('ChatView: 📞 Added country code: $phone');
        }
        
        debugPrint('ChatView: 📞 Attempting to launch dialer with number: $phone');
        
        // Try multiple approaches to launch the dialer
        debugPrint('ChatView: 📞 Trying to launch dialer...');
        
        bool launched = false;
        
        // Method 1: Try with tel: scheme
        final telUri = Uri(scheme: 'tel', path: phone);
        debugPrint('ChatView: 📞 Trying tel URI: $telUri');
        
        final canLaunchTel = await canLaunchUrl(telUri);
        debugPrint('ChatView: 📞 Can launch tel URL: $canLaunchTel');
        
        if (canLaunchTel) {
          launched = await launchUrl(
            telUri,
            mode: LaunchMode.externalApplication,
          );
          debugPrint('ChatView: 📞 Tel URL launch result: $launched');
        }
        
        // Method 2: If tel: fails, try with tel:// scheme
        if (!launched) {
          debugPrint('ChatView: 📞 Trying tel:// URI...');
          final telSlashUri = Uri.parse('tel://$phone');
          debugPrint('ChatView: 📞 Tel slash URI: $telSlashUri');
          
          final canLaunchTelSlash = await canLaunchUrl(telSlashUri);
          debugPrint('ChatView: 📞 Can launch tel:// URL: $canLaunchTelSlash');
          
          if (canLaunchTelSlash) {
            launched = await launchUrl(
              telSlashUri,
              mode: LaunchMode.externalApplication,
            );
            debugPrint('ChatView: 📞 Tel slash URL launch result: $launched');
          }
        }
        
        // Method 3: Try with intent URL for Android
        if (!launched) {
          debugPrint('ChatView: 📞 Trying Android intent...');
          final intentUri = Uri.parse('intent://dial/$phone#Intent;scheme=tel;package=com.android.dialer;end');
          debugPrint('ChatView: 📞 Intent URI: $intentUri');
          
          final canLaunchIntent = await canLaunchUrl(intentUri);
          debugPrint('ChatView: 📞 Can launch intent URL: $canLaunchIntent');
          
          if (canLaunchIntent) {
            launched = await launchUrl(
              intentUri,
              mode: LaunchMode.externalApplication,
            );
            debugPrint('ChatView: 📞 Intent URL launch result: $launched');
          }
        }
        
        // Method 4: Try with just the phone number (some devices handle this)
        if (!launched) {
          debugPrint('ChatView: 📞 Trying direct phone number...');
          final directUri = Uri.parse('tel:$phone');
          debugPrint('ChatView: 📞 Direct URI: $directUri');
          
          final canLaunchDirect = await canLaunchUrl(directUri);
          debugPrint('ChatView: 📞 Can launch direct URL: $canLaunchDirect');
          
          if (canLaunchDirect) {
            launched = await launchUrl(
              directUri,
              mode: LaunchMode.externalApplication,
            );
            debugPrint('ChatView: 📞 Direct URL launch result: $launched');
          }
        }
        
        // Method 5: Try with different launch modes
        if (!launched) {
          debugPrint('ChatView: 📞 Trying with different launch modes...');
          
          // Try with platformDefault mode
          try {
            launched = await launchUrl(
              telUri,
              mode: LaunchMode.platformDefault,
            );
            debugPrint('ChatView: 📞 Platform default mode result: $launched');
          } catch (e) {
            debugPrint('ChatView: 📞 Platform default mode error: $e');
          }
          
          // Try with inAppWebView mode if platform default fails
          if (!launched) {
            try {
              launched = await launchUrl(
                telUri,
                mode: LaunchMode.inAppWebView,
              );
              debugPrint('ChatView: 📞 InAppWebView mode result: $launched');
            } catch (e) {
              debugPrint('ChatView: 📞 InAppWebView mode error: $e');
            }
          }
        }
        
        if (launched) {
          debugPrint('ChatView: 📞 Dialer launched successfully!');
        } else {
          debugPrint('ChatView: 📞 All methods failed to launch dialer');
          
          // Check if we're on an emulator
          final isEmulator = await _isEmulator();
          debugPrint('ChatView: 📞 Is emulator: $isEmulator');
          
          if (mounted) {
            String errorMessage;
            if (isEmulator) {
              errorMessage = 'Phone calls are not supported on emulators. Please test on a real device.';
            } else {
              errorMessage = 'No phone app found. Please install a dialer app or use a device with phone capabilities.';
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'Copy Number',
                  textColor: Colors.white,
                  onPressed: () {
                    // Copy phone number to clipboard
                    Clipboard.setData(ClipboardData(text: phone));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Phone number copied to clipboard: $phone'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ),
            );
          }
        }
      } else {
        debugPrint('ChatView: 📞 Phone number is null or empty');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Phone number not available for this restaurant'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('ChatView: 📞 Error in _callPartner: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error making call: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the orderId from widget or route arguments
    final String orderId = widget.orderId ??
        (ModalRoute.of(context)?.settings.arguments as String?) ??
        'default_order';

    // Get responsive dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return BlocProvider(
      create: (context) {
        debugPrint('ChatView: 🔧 Creating ChatBloc with orderId: $orderId');
        debugPrint('ChatView: 🔧 Widget orderId: ${widget.orderId}');
        debugPrint('ChatView: 🔧 Widget isNewlyPlacedOrder: ${widget.isNewlyPlacedOrder}');
        _chatBloc = ChatBloc(
          chatService: ChatService(),
          socketService: SocketService(),
        );
        debugPrint('ChatView: 🔧 ChatBloc created, adding LoadChatData event');
        _chatBloc!.add(LoadChatData(orderId));
        debugPrint('ChatView: 🔧 LoadChatData event added with orderId: $orderId');
        return _chatBloc!;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        body: BlocConsumer<ChatBloc, ChatState>(
          listener: (context, state) {
            if (state is ChatLoaded) {
              debugPrint('ChatView: 📡 Received ChatLoaded state with orderDetails: ${state.orderDetails != null}');
              if (state.orderDetails != null) {
                debugPrint('ChatView: 📡 Order details orderId: ${state.orderDetails!.orderId}');
                debugPrint('ChatView: 📡 Order details status: ${state.orderDetails!.orderStatus}');
              }
              
              // Order details are now loaded immediately, no need for forced rebuild
              
              // Scroll to bottom when new messages arrive
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
              });
              
              // Emit page opened event when chat is loaded (only once)
              if (_chatBloc != null && !_pageOpenedEventEmitted) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _chatBloc!.add(const ChatPageOpened());
                    _pageOpenedEventEmitted = true;
                  }
                });
              }
            }
          },
          builder: (context, state) {
            debugPrint('ChatView: 🎨 Building UI for state: ${state.runtimeType}');
            if (state is ChatLoading) {
              return _buildLoadingState(screenWidth, screenHeight);
            } else if (state is ChatLoaded) {
              debugPrint('ChatView: 🎨 Building ChatLoaded state with orderDetails: ${state.orderDetails != null}');
              if (state.orderDetails != null) {
                debugPrint('ChatView: 🎨 Order details available in builder - orderId: ${state.orderDetails!.orderId}');
              }
              return _buildChatContent(context, state, screenWidth, screenHeight, orderId);
            } else if (state is ChatError) {
              return _buildErrorState(context, state, screenWidth, screenHeight);
            }
            
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState(double screenWidth, double screenHeight) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(ColorManager.primary),
              strokeWidth: 3,
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              'Loading chat...',
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeightManager.medium,
                color: Colors.grey[600],
                fontFamily: FontFamily.Montserrat,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatContent(BuildContext context, ChatLoaded state, double screenWidth, double screenHeight, String orderId) {
    debugPrint('ChatView: 🏗️ _buildChatContent called');
    debugPrint('ChatView: 🏗️ Order details in _buildChatContent: ${state.orderDetails != null}');
    if (state.orderDetails != null) {
      debugPrint('ChatView: 🏗️ Order details orderId: ${state.orderDetails!.orderId}');
      debugPrint('ChatView: 🏗️ Order details restaurant: ${state.orderDetails!.restaurantName}');
    }
    return SafeArea(
      child: Column(
        children: [
          _buildAppBar(context, state.chatRoom, screenWidth, screenHeight),
          SizedBox(height: screenHeight * 0.012), // Add space between topbar and order details
          Expanded(
            child: _buildMessagesList(state.messages, state.currentUserId, state.isSendingMessage, screenWidth, screenHeight, state.orderDetails, state.menuItemDetails, orderId),
          ),
          _buildMessageInput(context, state.isSendingMessage, screenWidth, screenHeight),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ChatRoom chatRoom, double screenWidth, double screenHeight) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.012,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              // Unfocus text field before navigating back
              _focusNode.unfocus();
              // Stop typing indicator and emit page closed event
              if (_chatBloc != null) {
                debugPrint('ChatView: 🚪 EMITTING ChatPageClosed event from back button');
                _chatBloc!.add(const StopTyping());
                _chatBloc!.add(const ChatPageClosed());
                debugPrint('ChatView: ✅ ChatPageClosed event emitted successfully from back button');
              } else {
                debugPrint('ChatView: ⚠️ Cannot emit ChatPageClosed from back button - chatBloc is null');
              }
              Navigator.of(context).pop();
            },
            child: Container(
              padding: EdgeInsets.all(screenWidth * 0.018),
              child: Icon(
                Icons.arrow_back,
                size: screenWidth * 0.055,
                color: ColorManager.black,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Chat',
                style: TextStyle(
                  fontSize: screenWidth * 0.047,
                  fontWeight: FontWeightManager.semiBold,
                  color: ColorManager.black,
                  fontFamily: FontFamily.Montserrat,
                ),
              ),
            ),
          ),
          Row(
            children: [
              // Refresh button for testing
              IconButton(
                icon: Icon(Icons.refresh, color: ColorManager.primary, size: screenWidth * 0.06),
                tooltip: 'Refresh Order Details',
                onPressed: () {
                  debugPrint('ChatView: 🔄 Refresh button pressed!');
                  if (_chatBloc != null) {
                    final orderId = widget.orderId ??
                        (ModalRoute.of(context)?.settings.arguments as String?) ??
                        'default_order';
                    _chatBloc!.add(LoadChatData(orderId));
                  }
                },
              ),
              // Call icon
              _isFetchingPhone
                  ? SizedBox(
                      width: screenWidth * 0.06,
                      height: screenWidth * 0.06,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      icon: Icon(Icons.call, color: ColorManager.primary, size: screenWidth * 0.06),
                      tooltip: 'Call Restaurant',
                      onPressed: () {
                        debugPrint('ChatView: 📞 Call button pressed!');
                        _callPartner(chatRoom);
                      },
                    ),
            ],
          ),
        ],
      ),
    );
  }



  Widget _buildMessagesList(List<ChatMessage> messages, String currentUserId, bool isSending, double screenWidth, double screenHeight, OrderDetails? orderDetails, Map<String, Map<String, dynamic>> menuItemDetails, String orderId) {
    debugPrint('ChatView: 📋 Building messages list - Messages:  [33m${messages.length} [0m, Order details:  [33m${orderDetails != null} [0m');
    
    // If there are no messages and not sending, but order details exist, show only the order details bubble
    if (messages.isEmpty && !isSending) {
      if (orderDetails != null) {
        debugPrint('ChatView: 📋 No messages, but order details available - showing only order details bubble');
        return ListView(
          controller: _scrollController,
          padding: EdgeInsets.all(screenWidth * 0.035),
          children: [
            ChatOrderDetailsBubble(
              orderDetails: orderDetails,
              menuItemDetails: menuItemDetails,
              isFromCurrentUser: true, // Order details are always shown as from user
              currentUserId: currentUserId,
              onCancelOrder: () {
                showCancelOrderBottomSheet(
                  context: context,
                  orderId: orderId,
                  onCancel: _handleCancelOrder,
                );
              },
            ),
          ],
        );
      } else {
        debugPrint('ChatView: 📋 No messages and no order details - showing empty state');
        return _buildEmptyState(screenWidth, screenHeight);
      }
    }

    debugPrint('ChatView: 📋 Building ListView with orderDetails: ${orderDetails != null}, messages: ${messages.length}');
    debugPrint('ChatView: 📋 ItemCount: ${(orderDetails != null ? 1 : 0) + messages.length}');
    
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(screenWidth * 0.035),
      itemCount: (orderDetails != null ? 1 : 0) + messages.length,
      itemBuilder: (context, index) {
        debugPrint('ChatView: 📋 Building item at index: $index');
        // Show order details as first item if available
        if (orderDetails != null && index == 0) {
          debugPrint('ChatView: 📋 Rendering order details bubble for order: ${orderDetails.orderId}');
          return ChatOrderDetailsBubble(
            orderDetails: orderDetails,
            menuItemDetails: menuItemDetails,
            isFromCurrentUser: true, // Order details are always shown as from user
            currentUserId: currentUserId,
            onCancelOrder: () {
              showCancelOrderBottomSheet(
                context: context,
                orderId: orderId,
                onCancel: _handleCancelOrder,
              );
            },
          );
        }
        
        // Show regular messages
        final messageIndex = orderDetails != null ? index - 1 : index;
        final message = messages[messageIndex];
        final isFromCurrentUser = message.isFromCurrentUser(currentUserId);
        final isOptimistic = message.id.startsWith('temp_');
        
        return _buildMessageBubble(
          message, 
          isFromCurrentUser, 
          isOptimistic,
          currentUserId,
          screenWidth, 
          screenHeight
        );
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isFromCurrentUser, bool isOptimistic, String currentUserId, double screenWidth, double screenHeight) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: screenHeight * 0.012),
      child: Row(
        mainAxisAlignment: isFromCurrentUser 
            ? MainAxisAlignment.end     // User messages on RIGHT
            : MainAxisAlignment.start,  // Partner messages on LEFT
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isFromCurrentUser) const Spacer(),
          Flexible(
            flex: 7,
            child: Column(
              crossAxisAlignment: isFromCurrentUser 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                // Sender type indicator for non-current user messages
                if (!isFromCurrentUser) ...[
                  Padding(
                    padding: EdgeInsets.only(bottom: screenHeight * 0.004),
                    child: Text(
                      message.senderType == 'partner' ? 'Restaurant' : 'Support',
                      style: TextStyle(
                        fontSize: screenWidth * 0.028,
                        fontWeight: FontWeightManager.medium,
                        color: ColorManager.primary,
                        fontFamily: FontFamily.Montserrat,
                      ),
                    ),
                  ),
                ],
                
                // Message bubble
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.038,
                    vertical: screenHeight * 0.012,
                  ),
                  decoration: BoxDecoration(
                    color: isFromCurrentUser 
                        ? ColorManager.primary
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(screenWidth * 0.035),
                      topRight: Radius.circular(screenWidth * 0.035),
                      bottomLeft: Radius.circular(
                        isFromCurrentUser ? screenWidth * 0.035 : screenWidth * 0.01
                      ),
                      bottomRight: Radius.circular(
                        isFromCurrentUser ? screenWidth * 0.01 : screenWidth * 0.035
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      fontSize: screenWidth * 0.035,
                      fontWeight: FontWeightManager.regular,
                      color: isFromCurrentUser 
                          ? Colors.white 
                          : ColorManager.black,
                      fontFamily: FontFamily.Montserrat,
                      height: 1.35,
                    ),
                  ),
                ),
                
                // Time and status
                SizedBox(height: screenHeight * 0.004),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.formattedTime,
                      style: TextStyle(
                        fontSize: screenWidth * 0.028,
                        fontWeight: FontWeightManager.regular,
                        color: isOptimistic ? Colors.grey.shade400 : Colors.grey.shade500,
                        fontFamily: FontFamily.Montserrat,
                      ),
                    ),
                    // Show read ticks only for USER messages (sent by current user)
                    if (isFromCurrentUser && !isOptimistic) ...[
                      SizedBox(width: screenWidth * 0.01),
                      Builder(
                        builder: (context) {
                          final shouldShowBlue = _shouldShowBlueTick(message, currentUserId);
                          debugPrint('ChatView: 🎨 Building blue tick for message: ${message.content} - Should show blue: $shouldShowBlue');
                          return Icon(
                            Icons.done_all,
                            size: screenWidth * 0.03,
                            // BLUE tick if read by both users, GREY tick if not read yet
                            color: shouldShowBlue
                                ? Colors.blue               // BLUE = Read by both users
                                : Colors.grey.shade500,    // GREY = Not read by both yet
                          );
                        },
                      ),
                    ],
                    // Show subtle indicator for optimistic messages
                    if (isOptimistic && isFromCurrentUser) ...[
                      SizedBox(width: screenWidth * 0.01),
                      Icon(
                        Icons.schedule,
                        size: screenWidth * 0.025,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (!isFromCurrentUser) const Spacer(),
        ],
      ),
    );
  }

  // Helper method to determine if we should show blue tick
  bool _shouldShowBlueTick(ChatMessage message, String currentUserId) {
    // Get partner user IDs from the chat room
    if (_chatBloc != null && _chatBloc!.state is ChatLoaded) {
      final chatState = _chatBloc!.state as ChatLoaded;
      final partnerUserIds = chatState.chatRoom.participants
          .where((participant) => participant.userId != currentUserId)
          .map((participant) => participant.userId)
          .toList();
      
      debugPrint('ChatView: Checking blue tick for message: ${message.content}');
      debugPrint('ChatView: Message sender: ${message.senderId}');
      debugPrint('ChatView: Current user: $currentUserId');
      debugPrint('ChatView: Partner IDs: $partnerUserIds');
      debugPrint('ChatView: ReadBy entries: ${message.readBy.map((e) => '${e.userId} at ${e.readAt}').toList()}');
      
      // Filter out test users and auto-marked entries from readBy entries
      final currentTime = DateTime.now();
      final cutoffTime = currentTime.subtract(const Duration(seconds: 5));
      debugPrint('ChatView: Current time: $currentTime');
      debugPrint('ChatView: Cutoff time (5 seconds ago): $cutoffTime');
      
      final realReadByEntries = message.readBy
          .where((entry) => 
            !entry.userId.startsWith('test_user_') &&
            // Only count entries that are not auto-marked (check if readAt is not the current time)
            entry.readAt.isBefore(cutoffTime)
          )
          .toList();
      
      debugPrint('ChatView: Real ReadBy entries (excluding auto-marked): ${realReadByEntries.map((e) => '${e.userId} at ${e.readAt}').toList()}');
      
      // Check if message is read by both current user and at least one real partner
      bool shouldShowBlue = false;
      
      if (message.senderId == currentUserId) {
        // For messages sent by current user: check if at least one real partner has read it
        shouldShowBlue = partnerUserIds.any((partnerId) => 
            realReadByEntries.any((entry) => entry.userId == partnerId));
      } else {
        // For messages from partners: check if current user has read it
        shouldShowBlue = realReadByEntries.any((entry) => entry.userId == currentUserId);
      }
      
      debugPrint('ChatView: Should show blue tick: $shouldShowBlue');
      
      return shouldShowBlue;
    }
    
    // Fallback to the old method if we can't get partner IDs
    final fallbackResult = message.isReadByOthers(currentUserId);
    debugPrint('ChatView: Using fallback method, should show blue tick: $fallbackResult');
    return fallbackResult;
  }

  Widget _buildMessageInput(BuildContext context, bool isSending, double screenWidth, double screenHeight) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.all(screenWidth * 0.035),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.038,
              ),
              decoration: BoxDecoration(
                color: _focusNode.hasFocus ? Colors.grey.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(screenWidth * 0.055),
                border: Border.all(
                  color: _focusNode.hasFocus ? ColorManager.primary.withOpacity(0.3) : Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeightManager.regular,
                  color: ColorManager.black,
                  fontFamily: FontFamily.Montserrat,
                ),
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeightManager.regular,
                    color: Colors.grey.shade500,
                    fontFamily: FontFamily.Montserrat,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.012,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(context),
                enabled: !isSending,
                onTap: () {
                  // Scroll to bottom when user taps the text field
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });
                },
              ),
            ),
          ),
          SizedBox(width: screenWidth * 0.028),
          // Send button with improved responsiveness
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: screenWidth * 0.11,
            height: screenWidth * 0.11,
            decoration: BoxDecoration(
              color: isSending
                  ? Colors.grey.shade300 
                  : ColorManager.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: isSending
                      ? Colors.transparent
                      : ColorManager.primary.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(screenWidth * 0.055),
                onTap: isSending
                    ? null 
                    : () {
                        _sendMessage(context);
                        // Add haptic feedback for better UX
                        HapticFeedback.lightImpact();
                      },
                child: Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: isSending ? 0.6 : 1.0,
                    child: Icon(
                      Icons.send,
                      color: Colors.white,
                      size: screenWidth * 0.045,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, ChatError state, double screenWidth, double screenHeight) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(screenWidth * 0.04),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth * 0.08),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: screenWidth * 0.12,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
              Text(
                'Something went wrong',
                style: TextStyle(
                  fontSize: screenWidth * 0.045,
                  fontWeight: FontWeightManager.semiBold,
                  color: Colors.grey.shade700,
                  fontFamily: FontFamily.Montserrat,
                ),
              ),
              SizedBox(height: screenHeight * 0.01),
              Text(
                state.message,
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeightManager.regular,
                  color: Colors.grey.shade600,
                  fontFamily: FontFamily.Montserrat,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: screenHeight * 0.03),
              ElevatedButton(
                onPressed: () {
                  final orderId = widget.orderId ?? 
                      (ModalRoute.of(context)?.settings.arguments as String?) ?? 
                      'default_order';
                  if (_chatBloc != null) {
                    _chatBloc!.add(LoadChatData(orderId));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.08,
                    vertical: screenHeight * 0.015,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  ),
                ),
                child: Text(
                  'Try Again',
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeightManager.semiBold,
                    fontFamily: FontFamily.Montserrat,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendMessage(BuildContext context) {
    final message = _messageController.text.trim();
    if (message.isNotEmpty && _chatBloc != null) {
      // Clear the text field immediately for better responsiveness
      _messageController.clear();
      
      // Send the message
      _chatBloc!.add(SendMessage(message));
      
      // Stop typing indicator when message is sent
      _typingTimer?.cancel();
      if (_isTyping) {
        _isTyping = false;
        _chatBloc!.add(const StopTyping());
      }
      
      // Scroll to bottom after sending
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  // Check if running on emulator (simplified version)
  Future<bool> _isEmulator() async {
    try {
      // Simple check based on the fact that emulators often can't handle tel: URLs
      final testUri = Uri(scheme: 'tel', path: '1234567890');
      final canLaunch = await canLaunchUrl(testUri);
      debugPrint('ChatView: 📞 Emulator check - can launch test tel URL: $canLaunch');
      
      // If we can't launch a simple tel URL, we're likely on an emulator
      return !canLaunch;
    } catch (e) {
      debugPrint('ChatView: 📞 Error checking if emulator: $e');
      return false;
    }
  }

  Widget _buildEmptyState(double screenWidth, double screenHeight) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: screenWidth * 0.12,
            color: ColorManager.primary,
          ),
          SizedBox(height: screenHeight * 0.02),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeightManager.semiBold,
              color: Colors.grey.shade700,
              fontFamily: FontFamily.Montserrat,
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            'Send a message to get help with your order',
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              fontWeight: FontWeightManager.regular,
              color: Colors.grey.shade500,
              fontFamily: FontFamily.Montserrat,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


}
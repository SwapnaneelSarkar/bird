import 'package:bird/service/order_service.dart';
import 'package:bird/service/chat_service.dart';
import 'package:bird/service/socket_service.dart';
import 'package:bird/utils/snackbar_utils.dart';
import 'package:bird/widgets/cancel_order_bottom_sheet.dart';
import 'package:bird/widgets/chat_order_details_widget.dart';
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
import 'dart:io';

class ChatView extends StatefulWidget {
  final String? orderId;
  
  const ChatView({
    Key? key,
    this.orderId,
  }) : super(key: key);

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
  
  // Add this to track message input state
  bool _hasText = false;
  
  // Add flag to track if page opened event has been emitted
  bool _pageOpenedEventEmitted = false;
  String? _partnerPhoneNumber;
  bool _isFetchingPhone = false;

  @override
  void initState() {
    super.initState();
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
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
    
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
    // Get responsive dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Get orderId from route arguments if not provided directly
    final String orderId = widget.orderId ?? 
        (ModalRoute.of(context)?.settings.arguments as String?) ?? 
        'default_order';
        
    debugPrint('ChatView: 🏗️ Building with order ID: $orderId');
    debugPrint('ChatView: 🏗️ Widget orderId: ${widget.orderId}');
    debugPrint('ChatView: 🏗️ Route arguments: ${ModalRoute.of(context)?.settings.arguments}');
    
    return BlocProvider(
      create: (context) {
        _chatBloc = ChatBloc(
          chatService: ChatService(),
          socketService: SocketService(),
        )..add(LoadChatData(orderId));
        return _chatBloc!;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true, // This is important for keyboard handling
        body: BlocConsumer<ChatBloc, ChatState>(
          listener: (context, state) {
            if (state is ChatLoaded) {
              // Scroll to bottom when new messages arrive
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
              });
              
              // Emit page opened event when chat is loaded (only once)
              if (_chatBloc != null && !_pageOpenedEventEmitted) {
                // Use a post frame callback to ensure this runs after the initial build
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    debugPrint('ChatView: 🚀 EMITTING ChatPageOpened event');
                    _chatBloc!.add(const ChatPageOpened());
                    _pageOpenedEventEmitted = true;
                    debugPrint('ChatView: ✅ ChatPageOpened event emitted successfully');
                  } else {
                    debugPrint('ChatView: ⚠️ Widget not mounted, skipping ChatPageOpened event');
                  }
                });
              } else {
                debugPrint('ChatView: ⚠️ Cannot emit ChatPageOpened - chatBloc: ${_chatBloc != null}, already emitted: $_pageOpenedEventEmitted');
              }
            }
          },
          builder: (context, state) {
            if (state is ChatLoading) {
              return _buildLoadingState(screenWidth, screenHeight);
            } else if (state is ChatLoaded) {
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
    return SafeArea(
      child: Column(
        children: [
          _buildAppBar(context, state.chatRoom, screenWidth, screenHeight),
          // Show order details if available
          Builder(
            builder: (context) {
              debugPrint('ChatView: 🔍 Order details in state: ${state.orderDetails != null ? 'Available' : 'Not available'}');
              if (state.orderDetails != null) {
                debugPrint('ChatView: 📋 Order ID: ${state.orderDetails!.orderId}');
                debugPrint('ChatView: 📋 Restaurant: ${state.orderDetails!.restaurantName}');
                debugPrint('ChatView: 📋 Items count: ${state.orderDetails!.items.length}');
                                 return ChatOrderDetailsWidget(
                   orderDetails: state.orderDetails!,
                   menuItemDetails: state.menuItemDetails,
                   onCancelOrder: () {
                     showCancelOrderBottomSheet(
                       context: context,
                       orderId: orderId,
                       onCancel: _handleCancelOrder,
                     );
                   },
                 );
              } else {
                debugPrint('ChatView: ❌ No order details available to display');
                // Show a simple placeholder for testing
                return Container(
                  margin: EdgeInsets.all(screenWidth * 0.035),
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order Details Not Available',
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          fontWeight: FontWeightManager.bold,
                          color: Colors.orange[700],
                          fontFamily: FontFamily.Montserrat,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.01),
                      Text(
                        'Order ID: $orderId',
                        style: TextStyle(
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeightManager.medium,
                          color: Colors.grey[600],
                          fontFamily: FontFamily.Montserrat,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.005),
                      Text(
                        'Debug: Order details could not be loaded',
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          fontWeight: FontWeightManager.regular,
                          color: Colors.grey[500],
                          fontFamily: FontFamily.Montserrat,
                        ),
                      ),
                    ],
                  ),
                );
              }
            },
          ),
          Expanded(
            child: _buildMessagesList(state.messages, state.currentUserId, state.isSendingMessage, screenWidth, screenHeight, state.orderDetails),
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
              Container(
                width: screenWidth * 0.025,
                height: screenWidth * 0.025,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
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



  Widget _buildMessagesList(List<ChatMessage> messages, String currentUserId, bool isSending, double screenWidth, double screenHeight, OrderDetails? orderDetails) {
    if (messages.isEmpty && !isSending) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(screenWidth * 0.08),
              decoration: BoxDecoration(
                color: ColorManager.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: screenWidth * 0.12,
                color: ColorManager.primary,
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              orderDetails != null ? 'Order Details Available' : 'Start a conversation',
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeightManager.semiBold,
                color: Colors.grey.shade700,
                fontFamily: FontFamily.Montserrat,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              orderDetails != null 
                ? 'Your order details are shown above. Send a message to get help with your order.'
                : 'Send a message to get help with your order',
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

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(screenWidth * 0.035),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
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
                      Icon(
                        Icons.done_all,
                        size: screenWidth * 0.03,
                        // BLUE tick if read by both users, GREY tick if not read yet
                        color: _shouldShowBlueTick(message, currentUserId)
                            ? Colors.blue               // BLUE = Read by both users
                            : Colors.grey.shade500,    // GREY = Not read by both yet
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
      
      // Filter out test users from readBy entries
      final realReadByEntries = message.readBy
          .where((entry) => !entry.userId.startsWith('test_user_'))
          .toList();
      
      debugPrint('ChatView: Real ReadBy entries (excluding test users): ${realReadByEntries.map((e) => '${e.userId} at ${e.readAt}').toList()}');
      
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
              color: (isSending || !_hasText)
                  ? Colors.grey.shade300 
                  : ColorManager.primary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isSending || !_hasText) 
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
                onTap: (isSending || !_hasText) 
                    ? null 
                    : () {
                        _sendMessage(context);
                        // Add haptic feedback for better UX
                        HapticFeedback.lightImpact();
                      },
                child: Center(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: (isSending || !_hasText) ? 0.6 : 1.0,
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

  // Test method for debugging call functionality
  Future<void> _testCallWithHardcodedNumber() async {
    debugPrint('ChatView: 📞 Testing call with hardcoded number');
    
    try {
      const testPhoneNumber = '+1234567890'; // Replace with a test number
      debugPrint('ChatView: 📞 Test phone number: $testPhoneNumber');
      
      final uri = Uri(scheme: 'tel', path: testPhoneNumber);
      debugPrint('ChatView: 📞 Test URI: $uri');
      
      final canLaunchResult = await canLaunchUrl(uri);
      debugPrint('ChatView: 📞 Can launch test URL: $canLaunchResult');
      
      if (canLaunchResult) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        debugPrint('ChatView: 📞 Test call launched: $launched');
      } else {
        debugPrint('ChatView: 📞 Cannot launch test URL');
      }
    } catch (e) {
      debugPrint('ChatView: 📞 Error in test call: $e');
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
}
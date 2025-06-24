import 'package:bird/service/order_service.dart';
import 'package:bird/utils/snackbar_utils.dart';
import 'package:bird/widgets/cancel_order_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../constants/color/colorConstant.dart';
import '../../constants/font/fontManager.dart';
import '../../models/chat_models.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';
import 'dart:async';

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

  @override
  void initState() {
    super.initState();
    // Listen to text changes to update send button state and typing indicators
    _messageController.addListener(_onTextChanged);
    
    // Listen to focus changes to handle keyboard
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
    
    // Handle typing indicators - check if chatBloc is available
    if (_chatBloc != null) {
      if (hasText && !_isTyping) {
        _isTyping = true;
        _chatBloc!.add(const StartTyping());
      }
      
      // Reset typing timer
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), () {
        if (_isTyping && _chatBloc != null) {
          _isTyping = false;
          _chatBloc!.add(const StopTyping());
        }
      });
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

  @override
  Widget build(BuildContext context) {
    // Get responsive dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Get orderId from route arguments if not provided directly
    final String orderId = widget.orderId ?? 
        (ModalRoute.of(context)?.settings.arguments as String?) ?? 
        'default_order';
        
    debugPrint('ChatView: Building with order ID: $orderId');
    
    return BlocProvider(
      create: (context) {
        _chatBloc = ChatBloc()..add(LoadChatData(orderId));
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
          _buildOrderHeader(state.chatRoom, screenWidth, screenHeight, orderId),
          Expanded(
            child: _buildMessagesList(state.messages, state.currentUserId, state.isSendingMessage, screenWidth, screenHeight),
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
              // Stop typing indicator
              if (_chatBloc != null) {
                _chatBloc!.add(const StopTyping());
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
                'Chat Support',
                style: TextStyle(
                  fontSize: screenWidth * 0.047,
                  fontWeight: FontWeightManager.semiBold,
                  color: ColorManager.black,
                  fontFamily: FontFamily.Montserrat,
                ),
              ),
            ),
          ),
          // Connection status and refresh button
          Row(
            children: [
              // Connection indicator
              Container(
                width: screenWidth * 0.025,
                height: screenWidth * 0.025,
                decoration: BoxDecoration(
                  color: Colors.green, // You can make this dynamic based on socket connection
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              // Refresh button - removed to avoid manual refresh in socket mode
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderHeader(ChatRoom chatRoom, double screenWidth, double screenHeight, String orderId) {
    return GestureDetector(
      onTap: () {
        // Show cancel order bottom sheet
        showCancelOrderBottomSheet(
          context: context,
          orderId: orderId,
          onCancel: _handleCancelOrder,
        );
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: ColorManager.primary.withOpacity(0.05),
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Order #${chatRoom.orderId.length > 8 ? chatRoom.orderId.substring(0, 8) + '...' : chatRoom.orderId}',
                          style: TextStyle(
                            fontSize: screenWidth * 0.042,
                            fontWeight: FontWeightManager.bold,
                            color: ColorManager.black,
                            fontFamily: FontFamily.Montserrat,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.02),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: screenWidth * 0.05,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: screenWidth * 0.02),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.028,
                    vertical: screenHeight * 0.006,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(screenWidth * 0.035),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: screenWidth * 0.018,
                        height: screenWidth * 0.018,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: screenWidth * 0.018),
                      Text(
                        'Active',
                        style: TextStyle(
                          fontSize: screenWidth * 0.03,
                          fontWeight: FontWeightManager.medium,
                          color: Colors.green,
                          fontFamily: FontFamily.Montserrat,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: screenHeight * 0.008),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chat with restaurant support',
                  style: TextStyle(
                    fontSize: screenWidth * 0.033,
                    fontWeight: FontWeightManager.regular,
                    color: Colors.grey.shade600,
                    fontFamily: FontFamily.Montserrat,
                  ),
                ),
                Text(
                  'Tap to cancel order',
                  style: TextStyle(
                    fontSize: screenWidth * 0.028,
                    fontWeight: FontWeightManager.medium,
                    color: Colors.red.shade600,
                    fontFamily: FontFamily.Montserrat,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList(List<ChatMessage> messages, String currentUserId, bool isSending, double screenWidth, double screenHeight) {
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
              'Start a conversation',
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
    return Padding(
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
                        ? (isOptimistic 
                            ? ColorManager.primary.withOpacity(0.7)
                            : ColorManager.primary)
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isOptimistic && isFromCurrentUser) ...[
                        SizedBox(
                          width: screenWidth * 0.03,
                          height: screenWidth * 0.03,
                          child: const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.02),
                      ],
                      Flexible(
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
                    ],
                  ),
                ),
                
                // Time and status
                SizedBox(height: screenHeight * 0.004),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isOptimistic ? 'Sending...' : message.formattedTime,
                      style: TextStyle(
                        fontSize: screenWidth * 0.028,
                        fontWeight: FontWeightManager.regular,
                        color: Colors.grey.shade500,
                        fontFamily: FontFamily.Montserrat,
                      ),
                    ),
                    // Show read ticks only for USER messages (sent by current user)
                    if (isFromCurrentUser && !isOptimistic) ...[
                      SizedBox(width: screenWidth * 0.01),
                      Icon(
                        Icons.done_all,
                        size: screenWidth * 0.03,
                        // BLUE tick if read by others, GREY tick if not read yet
                        color: message.isReadByOthers(currentUserId)
                            ? Colors.blue               // BLUE = Read by partner
                            : Colors.grey.shade500,    // GREY = Not read yet
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

  Widget _buildMessageInput(BuildContext context, bool isSending, double screenWidth, double screenHeight) {
    return Container(
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
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.038,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(screenWidth * 0.055),
                border: Border.all(
                  color: Colors.grey.shade200,
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
              ),
            ),
          ),
          SizedBox(width: screenWidth * 0.028),
          // FIXED: Use _hasText instead of checking controller directly
          GestureDetector(
            onTap: (isSending || !_hasText) 
                ? null 
                : () => _sendMessage(context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: screenWidth * 0.11,
              height: screenWidth * 0.11,
              decoration: BoxDecoration(
                color: (isSending || !_hasText)
                    ? Colors.grey.shade400 
                    : ColorManager.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: ColorManager.primary.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.send,
                  color: Colors.white,
                  size: screenWidth * 0.045,
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
      _chatBloc!.add(SendMessage(message));
      _messageController.clear();
      // Stop typing indicator when message is sent
      _typingTimer?.cancel();
      if (_isTyping) {
        _isTyping = false;
        _chatBloc!.add(const StopTyping());
      }
    }
  }
}
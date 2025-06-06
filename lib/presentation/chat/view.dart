import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../constants/color/colorConstant.dart';
import '../../constants/font/fontManager.dart';
import '../../models/chat_models.dart';
import 'bloc.dart';
import 'event.dart';
import 'state.dart';

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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    // Get orderId from route arguments if not provided directly
    final String orderId = widget.orderId ?? 
        (ModalRoute.of(context)?.settings.arguments as String?) ?? 
        'default_order';
        
    debugPrint('ChatView: Building with order ID: $orderId');
    
    return BlocProvider(
      create: (context) => ChatBloc()..add(LoadChatData(orderId)),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocConsumer<ChatBloc, ChatState>(
          listener: (context, state) {
            if (state is ChatLoaded && !state.isSendingMessage) {
              // Scroll to bottom when new messages arrive
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollToBottom();
              });
            }
          },
          builder: (context, state) {
            if (state is ChatLoading) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (state is ChatLoaded) {
              return _buildChatContent(context, state);
            } else if (state is ChatError) {
              return _buildErrorState(context, state);
            }
            
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildChatContent(BuildContext context, ChatLoaded state) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return SafeArea(
      child: Column(
        children: [
          _buildAppBar(context, state.chatRoom, screenWidth, screenHeight),
          _buildOrderHeader(state.chatRoom, screenWidth, screenHeight),
          Expanded(
            child: _buildMessagesList(state.messages, state.currentUserId, screenWidth, screenHeight),
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
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
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
          // Refresh button
          GestureDetector(
            onTap: () => context.read<ChatBloc>().add(const RefreshMessages()),
            child: Container(
              padding: EdgeInsets.all(screenWidth * 0.018),
              child: Icon(
                Icons.refresh,
                size: screenWidth * 0.055,
                color: ColorManager.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderHeader(ChatRoom chatRoom, double screenWidth, double screenHeight) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
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
                child: Text(
                  'Order ${chatRoom.orderId.length > 8 ? chatRoom.orderId.substring(0, 8) + '...' : chatRoom.orderId}',
                  style: TextStyle(
                    fontSize: screenWidth * 0.048,
                    fontWeight: FontWeightManager.bold,
                    color: ColorManager.black,
                    fontFamily: FontFamily.Montserrat,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.028,
                  vertical: screenHeight * 0.004,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    screenWidth * 0.035,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: screenWidth * 0.018,
                      height: screenWidth * 0.018,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.018),
                    Text(
                      'Active',
                      style: TextStyle(
                        fontSize: screenWidth * 0.033,
                        fontWeight: FontWeightManager.medium,
                        color: Colors.orange,
                        fontFamily: FontFamily.Montserrat,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.004),
          Text(
            'Room: ${chatRoom.roomId.length > 20 ? chatRoom.roomId.substring(0, 20) + '...' : chatRoom.roomId}',
            style: TextStyle(
              fontSize: screenWidth * 0.033,
              fontWeight: FontWeightManager.regular,
              color: Colors.grey.shade600,
              fontFamily: FontFamily.Montserrat,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  } BoxDecoration(
        color: Colors.white,
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
              Text(
                'Order ${chatRoom.orderId}',
                style: TextStyle(
                  fontSize: screenWidth * 0.048,
                  fontWeight: FontWeightManager.bold,
                  color: ColorManager.black,
                  fontFamily: FontFamily.Montserrat,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.028,
                  vertical: screenHeight * 0.004,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    screenWidth * 0.035,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: screenWidth * 0.018,
                      height: screenWidth * 0.018,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: screenWidth * 0.018),
                    Text(
                      'Active',
                      style: TextStyle(
                        fontSize: screenWidth * 0.033,
                        fontWeight: FontWeightManager.medium,
                        color: Colors.orange,
                        fontFamily: FontFamily.Montserrat,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.004),
          Text(
            'Room ID: ${chatRoom.roomId}',
            style: TextStyle(
              fontSize: screenWidth * 0.033,
              fontWeight: FontWeightManager.regular,
              color: Colors.grey.shade600,
              fontFamily: FontFamily.Montserrat,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(List<ChatMessage> messages, String currentUserId, double screenWidth, double screenHeight) {
    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: screenWidth * 0.12,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              'No messages yet',
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeightManager.medium,
                color: Colors.grey.shade600,
                fontFamily: FontFamily.Montserrat,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              'Start the conversation!',
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeightManager.regular,
                color: Colors.grey.shade500,
                fontFamily: FontFamily.Montserrat,
              ),
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
        return _buildMessageBubble(message, isFromCurrentUser, screenWidth, screenHeight);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isFromCurrentUser, double screenWidth, double screenHeight) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: screenHeight * 0.012,
      ),
      child: Row(
        mainAxisAlignment: isFromCurrentUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
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
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.038,
                    vertical: screenHeight * 0.012,
                  ),
                  decoration: BoxDecoration(
                    color: isFromCurrentUser 
                        ? const Color(0xFFE17A47)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(
                      screenWidth * 0.038,
                    ),
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
                SizedBox(height: screenHeight * 0.004),
                Text(
                  message.formattedTime,
                  style: TextStyle(
                    fontSize: screenWidth * 0.028,
                    fontWeight: FontWeightManager.regular,
                    color: Colors.grey.shade500,
                    fontFamily: FontFamily.Montserrat,
                  ),
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
                borderRadius: BorderRadius.circular(
                  screenWidth * 0.055,
                ),
              ),
              child: TextField(
                controller: _messageController,
                style: TextStyle(
                  fontSize: screenWidth * 0.035,
                  fontWeight: FontWeightManager.regular,
                  color: ColorManager.black,
                  fontFamily: FontFamily.Montserrat,
                ),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
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
              ),
            ),
          ),
          SizedBox(width: screenWidth * 0.028),
          GestureDetector(
            onTap: isSending ? null : _sendMessage,
            child: Container(
              width: screenWidth * 0.11,
              height: screenWidth * 0.11,
              decoration: BoxDecoration(
                color: isSending 
                    ? Colors.grey.shade400 
                    : const Color(0xFFE17A47),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isSending
                    ? SizedBox(
                        width: screenWidth * 0.035,
                        height: screenWidth * 0.035,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
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

  Widget _buildErrorState(BuildContext context, ChatError state) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: screenWidth * 0.12,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: screenHeight * 0.015),
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
            SizedBox(height: screenHeight * 0.02),
            ElevatedButton(
              onPressed: () {
                final orderId = widget.orderId ?? 
                    (ModalRoute.of(context)?.settings.arguments as String?) ?? 
                    'default_order';
                context.read<ChatBloc>().add(LoadChatData(orderId));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE17A47),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.06,
                  vertical: screenHeight * 0.01,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    screenWidth * 0.015,
                  ),
                ),
              ),
              child: Text(
                'Retry',
                style: TextStyle(
                  fontSize: screenWidth * 0.032,
                  fontWeight: FontWeightManager.medium,
                  fontFamily: FontFamily.Montserrat,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      context.read<ChatBloc>().add(SendMessage(message));
      _messageController.clear();
    }
  }
}
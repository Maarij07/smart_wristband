import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/colors.dart';
import '../services/messaging_provider.dart';
import '../models/message_model.dart';

class ChatScreen extends StatefulWidget {
  final String contactId;
  final String contactName;
  final String contactAvatar;

  const ChatScreen({
    super.key,
    required this.contactId,
    required this.contactName,
    required this.contactAvatar,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    // Load messages for this contact
    Future.microtask(() {
      context.read<MessagingProvider>().loadMessagesForContact(widget.contactId);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_textController.text.trim().isNotEmpty) {
      context.read<MessagingProvider>().sendMessage(
        contactId: widget.contactId,
        text: _textController.text.trim(),
      );
      _textController.clear();
      
      // Scroll to bottom after a short delay
      Future.delayed(const Duration(milliseconds: 100), () {
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

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.black,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  widget.contactAvatar,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.contactName,
                  style: TextStyle(
                    color: AppColors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Consumer<MessagingProvider>(
                  builder: (context, messagingProvider, _) {
                    final statusText = messagingProvider.isConnected ? 'Online' : 'Offline';
                    final statusColor = messagingProvider.isConnected ? Colors.green : AppColors.textSecondary;
                    return Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        centerTitle: false,
      ),
      body: Consumer<MessagingProvider>(
        builder: (context, messagingProvider, _) {
          final messages = messagingProvider.currentMessages;
          
          // Auto-scroll when new messages arrive
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
          
          return Column(
            children: [
              // Messages list
              Expanded(
                child: messages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet. Start the conversation!',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: messages.length,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          return _buildMessageBubble(message);
                        },
                      ),
              ),
              
              // Message input
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.divider, width: 1),
                        ),
                        child: TextField(
                          controller: _textController,
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                          enabled: messagingProvider.isConnected,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: messagingProvider.isConnected ? AppColors.black : AppColors.lightGray,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.send, color: AppColors.white, size: 20),
                        onPressed: messagingProvider.isConnected ? _sendMessage : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isMe = message.senderId == context.read<MessagingProvider>().currentUserId;
    
    return Container(
      margin: EdgeInsets.only(
        bottom: 8,
        left: isMe ? 60 : 12,
        right: isMe ? 12 : 60,
      ),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe)
            Container(
              width: 32,
              height: 32,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: AppColors.black,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  widget.contactAvatar,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe ? AppColors.black : AppColors.surfaceVariant,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isMe ? 20 : 4),
                  topRight: Radius.circular(isMe ? 4 : 20),
                  bottomLeft: const Radius.circular(20),
                  bottomRight: const Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isMe ? AppColors.white : AppColors.textPrimary,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: isMe ? AppColors.white.withValues(alpha: 0.7) : AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.status == 'read' ? Icons.done_all : Icons.done,
                          size: 12,
                          color: isMe ? AppColors.white.withValues(alpha: 0.7) : AppColors.textSecondary,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
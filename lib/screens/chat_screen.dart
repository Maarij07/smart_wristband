import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../utils/colors.dart';

class ChatScreen extends StatefulWidget {
  final int chatId;
  final String chatName;
  final bool isOnline;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.chatName,
    required this.isOnline,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, dynamic>> _messages = [
    {
      'id': 1,
      'text': 'Hey there! How are you doing?',
      'sender': 'other',
      'timestamp': '10:30 AM',
      'isRead': true,
    },
    {
      'id': 2,
      'text': 'I\'m doing great! Just finished the project.',
      'sender': 'me',
      'timestamp': '10:32 AM',
      'isRead': true,
    },
    {
      'id': 3,
      'text': 'That\'s awesome! Can you share the details?',
      'sender': 'other',
      'timestamp': '10:33 AM',
      'isRead': true,
    },
    {
      'id': 4,
      'text': 'Sure, I\'ll send you the document later today.',
      'sender': 'me',
      'timestamp': '10:35 AM',
      'isRead': false,
    },
  ];

  final TextEditingController _messageController = TextEditingController();
  
  // WebSocket channel for real-time communication
  late WebSocketChannel _channel;

  @override
  void initState() {
    super.initState();
    // Initialize WebSocket connection for real-time messaging
    _initializeWebSocket();
  }

  void _initializeWebSocket() {
    // In a real app, this would connect to your WebSocket server
    // For demo purposes, we'll simulate the connection
    // _channel = IOWebSocketChannel.connect('ws://your-websocket-server.com/chat/${widget.chatId}');
  }

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      // Add message to local list
      setState(() {
        _messages.add({
          'id': _messages.length + 1,
          'text': _messageController.text,
          'sender': 'me',
          'timestamp': _formatTime(DateTime.now()),
          'isRead': false,
        });
      });

      // Send message via WebSocket or WebRTC
      _sendViaWebSocket(_messageController.text);

      // Clear the input field
      _messageController.clear();
    }
  }

  void _sendViaWebSocket(String message) {
    // In a real app, this would send the message through the WebSocket
    // _channel.sink.add(jsonEncode({'message': message, 'sender': 'me'}));
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _channel.sink.close();
    super.dispose();
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
            Stack(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.surface,
                  child: Icon(Icons.person, color: AppColors.black, size: 16),
                ),
                if (widget.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.surface, width: 1),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.chatName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  widget.isOnline ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isOnline ? Colors.green : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (String result) {
              // Handle menu options
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'view_profile',
                child: Text('View Profile'),
              ),
              const PopupMenuItem<String>(
                value: 'clear_chat',
                child: Text('Clear Chat'),
              ),
              const PopupMenuItem<String>(
                value: 'block_user',
                child: Text('Block User'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                final isMe = message['sender'] == 'me';
                
                return Container(
                  margin: EdgeInsets.only(
                    left: isMe ? 50 : 16,
                    right: isMe ? 16 : 50,
                    top: 8,
                  ),
                  child: Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isMe ? AppColors.black : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: !isMe ? const Radius.circular(4) : const Radius.circular(18),
                          bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message['text'],
                            style: TextStyle(
                              color: isMe ? AppColors.white : AppColors.textPrimary,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                message['timestamp'],
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isMe ? AppColors.white.withOpacity(0.7) : AppColors.textSecondary,
                                ),
                              ),
                              if (isMe && message['isRead'])
                                const SizedBox(width: 4),
                              if (isMe && message['isRead'])
                                Icon(
                                  Icons.done_all,
                                  size: 12,
                                  color: AppColors.white.withOpacity(0.7),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
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
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        IconButton(
                          icon: Icon(Icons.emoji_emotions_outlined, color: AppColors.textSecondary),
                          onPressed: () {},
                          iconSize: 20,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                              hintText: 'Type a message...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 16),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.attach_file, color: AppColors.textSecondary),
                          onPressed: () {},
                          iconSize: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send, color: AppColors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
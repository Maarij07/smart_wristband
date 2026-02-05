import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:async';

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String recipientId;
  final String text;
  final DateTime timestamp;
  final bool isMe;
  final MessageStatus status; // pending, sent, delivered, read

  Message({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.recipientId,
    required this.text,
    required this.timestamp,
    required this.isMe,
    this.status = MessageStatus.sent,
  });

  factory Message.fromJson(Map<String, dynamic> json, {required String currentUserId}) {
    final senderId = json['senderId'] as String;
    final isMe = senderId == currentUserId;

    return Message(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: senderId,
      senderName: json['senderName'] as String? ?? 'Unknown',
      senderAvatar: json['senderAvatar'] as String? ?? '?',
      recipientId: json['recipientId'] as String? ?? '',
      text: json['text'] as String? ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      isMe: isMe,
      status: MessageStatus.values.firstWhere(
        (e) => e.toString() == 'MessageStatus.${json['status'] ?? 'sent'}',
        orElse: () => MessageStatus.sent,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'recipientId': recipientId,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'status': status.toString().split('.').last,
    };
  }
}

enum MessageStatus { pending, sent, delivered, read }

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  WebSocketChannel? _channel;
  StreamController<Message> messageStream = StreamController.broadcast();
  StreamController<String> connectionStatusStream = StreamController.broadcast();
  
  bool _isConnected = false;
  String? _currentUserId;
  String? _currentUserName;
  String? _currentUserAvatar;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;
  static const Duration _reconnectDelay = Duration(seconds: 3);

  bool get isConnected => _isConnected;
  String? get currentUserId => _currentUserId;

  /// Connect to WebSocket server
  Future<bool> connect({
    required String userId,
    required String userName,
    required String userAvatar,
    String wsUrl = 'ws://localhost:8080',
  }) async {
    try {
      _currentUserId = userId;
      _currentUserName = userName;
      _currentUserAvatar = userAvatar;

      // Create WebSocket connection
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));

      // Send authentication message
      _sendAuthMessage();

      // Listen to incoming messages
      _channel!.stream.listen(
        _handleIncomingMessage,
        onError: _handleError,
        onDone: _handleConnectionClosed,
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      connectionStatusStream.add('connected');
      print('✅ WebSocket connected: $userId');
      
      return true;
    } catch (e) {
      print('❌ WebSocket connection error: $e');
      _isConnected = false;
      connectionStatusStream.add('disconnected');
      _scheduleReconnect();
      return false;
    }
  }

  /// Send authentication message on connection
  void _sendAuthMessage() {
    if (_channel == null) return;

    final authMessage = {
      'type': 'auth',
      'userId': _currentUserId,
      'userName': _currentUserName,
      'userAvatar': _currentUserAvatar,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      _channel!.sink.add(jsonEncode(authMessage));
      print('📤 Auth message sent');
    } catch (e) {
      print('❌ Error sending auth message: $e');
    }
  }

  /// Send a message
  Future<void> sendMessage({
    required String recipientId,
    required String text,
  }) async {
    if (!_isConnected || _channel == null) {
      print('❌ WebSocket not connected');
      return;
    }

    try {
      final message = {
        'type': 'message',
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'senderId': _currentUserId,
        'senderName': _currentUserName,
        'senderAvatar': _currentUserAvatar,
        'recipientId': recipientId,
        'text': text,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'pending',
      };

      // Add to local stream immediately (optimistic update)
      messageStream.add(
        Message.fromJson(message, currentUserId: _currentUserId!),
      );

      // Send over WebSocket
      _channel!.sink.add(jsonEncode(message));
      print('📤 Message sent to $recipientId: $text');
    } catch (e) {
      print('❌ Error sending message: $e');
    }
  }

  /// Handle incoming messages
  void _handleIncomingMessage(dynamic data) {
    try {
      final decodedData = jsonDecode(data as String) as Map<String, dynamic>;
      final messageType = decodedData['type'] as String?;

      switch (messageType) {
        case 'message':
          final message = Message.fromJson(decodedData, currentUserId: _currentUserId!);
          messageStream.add(message);
          print('📥 Message received from ${message.senderId}: ${message.text}');
          break;

        case 'status':
          print('📊 Status update: ${decodedData['status']}');
          connectionStatusStream.add(decodedData['status'] as String);
          break;

        case 'error':
          print('⚠️ Server error: ${decodedData['message']}');
          connectionStatusStream.add('error: ${decodedData['message']}');
          break;

        default:
          print('❓ Unknown message type: $messageType');
      }
    } catch (e) {
      print('❌ Error handling incoming message: $e');
    }
  }

  /// Handle connection errors
  void _handleError(error) {
    print('❌ WebSocket error: $error');
    _isConnected = false;
    connectionStatusStream.add('error');
    _scheduleReconnect();
  }

  /// Handle connection closed
  void _handleConnectionClosed() {
    print('⛔ WebSocket connection closed');
    _isConnected = false;
    connectionStatusStream.add('disconnected');
    _scheduleReconnect();
  }

  /// Schedule automatic reconnection
  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      print('❌ Max reconnection attempts reached');
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () {
      _reconnectAttempts++;
      print('🔄 Reconnecting... Attempt $_reconnectAttempts/$_maxReconnectAttempts');
      connect(
        userId: _currentUserId!,
        userName: _currentUserName!,
        userAvatar: _currentUserAvatar!,
      );
    });
  }

  /// Disconnect from WebSocket
  Future<void> disconnect() async {
    try {
      _reconnectTimer?.cancel();
      _channel?.sink.close();
      _isConnected = false;
      connectionStatusStream.add('disconnected');
      print('⛔ WebSocket disconnected');
    } catch (e) {
      print('❌ Error disconnecting: $e');
    }
  }

  /// Get message stream for a specific recipient
  Stream<Message> getMessageStream({required String recipientId}) {
    return messageStream.stream.where(
      (message) =>
          (message.senderId == recipientId && message.isMe == false) ||
          (message.recipientId == recipientId && message.isMe == true),
    );
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    messageStream.close();
    connectionStatusStream.close();
    _reconnectTimer?.cancel();
  }
}

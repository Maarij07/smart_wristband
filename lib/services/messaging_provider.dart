import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'firestore_messaging_service.dart';
import '../models/message_model.dart';

class MessagingProvider extends ChangeNotifier {
  final FirestoreMessagingService _firestoreService =
      FirestoreMessagingService();

  static const String _conversationsCacheKey = 'cached_conversations_';
  static const String _messagesCacheKey = 'cached_messages_';

  List<Map<String, dynamic>> _conversations = [];
  Map<String, List<Message>> _messagesByContact = {};
  String? _currentContactId;

  List<Map<String, dynamic>> get conversations => _conversations;
  List<Message> get currentMessages =>
      _currentContactId != null
          ? (_messagesByContact[_currentContactId] ?? [])
          : [];
  bool get isConnected => FirebaseAuth.instance.currentUser != null;
  String get connectionStatus =>
      isConnected ? 'connected' : 'disconnected';
  String get currentUserId => _firestoreService.currentUserId;

  /// Initialize messaging (Firestore auto-connects)
  Future<void> initialize() async {
    // Update user online status
    await _firestoreService.updateUserOnlineStatus(true);

    await _loadCachedConversations();

    // Listen to conversations
    _firestoreService.getConversationsStream().listen((conversations) {
      _conversations = conversations;
      _cacheConversations();
      notifyListeners();
    });

    notifyListeners();
  }

  /// Load messages for a specific contact
  void loadMessagesForContact(String contactId) {
    _currentContactId = contactId;

    _loadCachedMessages(contactId);

    // Mark messages as read
    _firestoreService.markMessagesAsRead(contactId);

    // Listen to message stream
    _firestoreService.getMessagesStream(contactId).listen((messages) {
      _messagesByContact[contactId] = messages;
      _cacheMessages(contactId);
      notifyListeners();
    });

    notifyListeners();
  }

  /// Send a message
  Future<void> sendMessage({
    required String contactId,
    required String text,
  }) async {
    try {
      await _firestoreService.sendMessage(contactId, text);
      notifyListeners();
    } catch (e) {
      print('❌ Error sending message: $e');
      rethrow;
    }
  }

  /// Create or start a conversation
  Future<void> startConversation({
    required String contactId,
    required String contactName,
    String contactAvatar = '',
  }) async {
    try {
      await _firestoreService.createOrStartConversation(
        contactId,
        contactName,
        contactAvatar,
      );
      _currentContactId = contactId;
      notifyListeners();
    } catch (e) {
      print('❌ Error starting conversation: $e');
      rethrow;
    }
  }

  /// Delete a conversation
  Future<void> deleteConversation(String contactId) async {
    try {
      await _firestoreService.deleteConversation(contactId);
      _conversations.removeWhere((conv) => conv['contactId'] == contactId);
      _messagesByContact.remove(contactId);
      notifyListeners();
    } catch (e) {
      print('❌ Error deleting conversation: $e');
      rethrow;
    }
  }

  /// Mark messages as read
  Future<void> markAsRead(String contactId) async {
    try {
      await _firestoreService.markMessagesAsRead(contactId);
      notifyListeners();
    } catch (e) {
      print('❌ Error marking messages as read: $e');
    }
  }

  Future<void> clearNewMatchFlag(String contactId) async {
    try {
      await _firestoreService.setNewMatchFlag(contactId, false);
      notifyListeners();
    } catch (e) {
      print('❌ Error clearing new match flag: $e');
    }
  }

  /// Get unread count stream
  Stream<int> getUnreadCountStream() {
    return _firestoreService.getUnreadCountStream();
  }

  /// Update online status
  Future<void> setOnlineStatus(bool isOnline) async {
    try {
      await _firestoreService.updateUserOnlineStatus(isOnline);
      notifyListeners();
    } catch (e) {
      print('❌ Error updating online status: $e');
    }
  }

  /// Get contact online status stream
  Stream<bool> getContactOnlineStatusStream(String contactId) {
    return _firestoreService.getUserOnlineStatusStream(contactId);
  }

  /// Get last message for a conversation
  Message? getLastMessage(String contactId) {
    final messages = _messagesByContact[contactId];
    return messages?.isNotEmpty == true ? messages!.first : null;
  }

  Future<void> _loadCachedConversations() async {
    final userId = currentUserId;
    if (userId.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('$_conversationsCacheKey$userId');
    if (cached == null || cached.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(cached) as List<dynamic>;
      _conversations = decoded
          .whereType<Map<String, dynamic>>()
          .map((item) {
            final millis = item['lastMessageTimeMs'] as int?;
            return {
              'contactId': item['contactId'],
              'contactName': item['contactName'],
              'contactAvatar': item['contactAvatar'],
              'contactProfilePicture': item['contactProfilePicture'],
              'lastMessage': item['lastMessage'],
              'lastMessageTime': millis != null
                  ? Timestamp.fromMillisecondsSinceEpoch(millis)
                  : Timestamp.now(),
              'unreadCount': item['unreadCount'] ?? 0,
              'isOnline': item['isOnline'] ?? false,
              'isNewMatch': item['isNewMatch'] ?? false,
            };
          })
          .toList();
      notifyListeners();
    } catch (e) {
      // Ignore cache parsing errors.
    }
  }

  Future<void> _cacheConversations() async {
    final userId = currentUserId;
    if (userId.isEmpty) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = _conversations.map((conversation) {
        final lastMessageTime = conversation['lastMessageTime'];
        final millis = lastMessageTime is Timestamp
            ? lastMessageTime.millisecondsSinceEpoch
            : DateTime.now().millisecondsSinceEpoch;
        return {
          'contactId': conversation['contactId'],
          'contactName': conversation['contactName'],
          'contactAvatar': conversation['contactAvatar'],
          'contactProfilePicture': conversation['contactProfilePicture'],
          'lastMessage': conversation['lastMessage'],
          'lastMessageTimeMs': millis,
          'unreadCount': conversation['unreadCount'] ?? 0,
          'isOnline': conversation['isOnline'] ?? false,
          'isNewMatch': conversation['isNewMatch'] ?? false,
        };
      }).toList();
      await prefs.setString(
        '$_conversationsCacheKey$userId',
        jsonEncode(payload),
      );
    } catch (e) {
      // Ignore cache write errors.
    }
  }

  Future<void> _loadCachedMessages(String contactId) async {
    final userId = currentUserId;
    if (userId.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('$_messagesCacheKey$userId-$contactId');
    if (cached == null || cached.isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(cached) as List<dynamic>;
      final messages = decoded
          .whereType<Map<String, dynamic>>()
          .map((item) => Message.fromJson(item))
          .toList();
      _messagesByContact[contactId] = messages;
      notifyListeners();
    } catch (e) {
      // Ignore cache parsing errors.
    }
  }

  Future<void> _cacheMessages(String contactId) async {
    final userId = currentUserId;
    if (userId.isEmpty) {
      return;
    }

    final messages = _messagesByContact[contactId];
    if (messages == null) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = messages.map((message) => message.toJson()).toList();
      await prefs.setString(
        '$_messagesCacheKey$userId-$contactId',
        jsonEncode(payload),
      );
    } catch (e) {
      // Ignore cache write errors.
    }
  }

  /// Cleanup on dispose
  @override
  void dispose() {
    _firestoreService.updateUserOnlineStatus(false);
    super.dispose();
  }}
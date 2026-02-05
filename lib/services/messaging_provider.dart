import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firestore_messaging_service.dart';
import '../models/message_model.dart';

class MessagingProvider extends ChangeNotifier {
  final FirestoreMessagingService _firestoreService =
      FirestoreMessagingService();

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

    // Listen to conversations
    _firestoreService.getConversationsStream().listen((conversations) {
      _conversations = conversations;
      notifyListeners();
    });

    notifyListeners();
  }

  /// Load messages for a specific contact
  void loadMessagesForContact(String contactId) {
    _currentContactId = contactId;

    // Mark messages as read
    _firestoreService.markMessagesAsRead(contactId);

    // Listen to message stream
    _firestoreService.getMessagesStream(contactId).listen((messages) {
      _messagesByContact[contactId] = messages;
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

  /// Cleanup on dispose
  @override
  void dispose() {
    _firestoreService.updateUserOnlineStatus(false);
    super.dispose();
  }}
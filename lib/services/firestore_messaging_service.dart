import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/message_model.dart';

class FirestoreMessagingService {
  static final FirestoreMessagingService _instance =
      FirestoreMessagingService._internal();

  factory FirestoreMessagingService() {
    return _instance;
  }

  FirestoreMessagingService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  /// Get all conversations for the current user
  Stream<List<Map<String, dynamic>>> getConversationsStream() {
    if (currentUserId.isEmpty) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('conversations')
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<Map<String, dynamic>> conversations = [];

      for (var doc in snapshot.docs) {
        final contactId = doc.id;
        final conversationData = doc.data();

        // Get contact details
        final contactDoc =
            await _firestore.collection('users').doc(contactId).get();
        final contactData = contactDoc.data() ?? {};

        conversations.add({
          'contactId': contactId,
          'contactName': contactData['name'] ?? 'Unknown',
          'contactAvatar': contactData['avatar'] ?? '',
          'lastMessage': conversationData['lastMessage'] ?? '',
          'lastMessageTime': conversationData['lastMessageTime'] ?? Timestamp.now(),
          'unreadCount': conversationData['unreadCount'] ?? 0,
          'isOnline': contactData['isOnline'] ?? false,
        });
      }

      return conversations;
    });
  }

  /// Get messages for a specific conversation
  Stream<List<Message>> getMessagesStream(String contactId) {
    if (currentUserId.isEmpty) {
      return Stream.value([]);
    }

    // Create a conversation ID that's consistent regardless of user order
    final conversationId = _getConversationId(currentUserId, contactId);

    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Message.fromFirestore(doc))
          .toList();
    });
  }

  /// Send a message
  Future<void> sendMessage(String contactId, String messageText) async {
    if (currentUserId.isEmpty || messageText.trim().isEmpty) {
      throw Exception('Invalid user or message');
    }

    final conversationId = _getConversationId(currentUserId, contactId);
    final timestamp = Timestamp.now();

    try {
      // Add message to conversation
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .add({
        'senderId': currentUserId,
        'recipientId': contactId,
        'text': messageText.trim(),
        'timestamp': timestamp,
        'status': 'sent', // sent, delivered, read
      });

      // Update last message for sender
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('conversations')
          .doc(contactId)
          .set({
        'lastMessage': messageText.trim(),
        'lastMessageTime': timestamp,
      }, SetOptions(merge: true));

      // Update last message for recipient
      await _firestore
          .collection('users')
          .doc(contactId)
          .collection('conversations')
          .doc(currentUserId)
          .set({
        'lastMessage': messageText.trim(),
        'lastMessageTime': timestamp,
        'unreadCount': FieldValue.increment(1),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String contactId) async {
    if (currentUserId.isEmpty) return;

    final conversationId = _getConversationId(currentUserId, contactId);

    try {
      final unreadMessages = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .where('recipientId', isEqualTo: currentUserId)
          .where('status', isNotEqualTo: 'read')
          .get();

      for (var doc in unreadMessages.docs) {
        await doc.reference.update({'status': 'read'});
      }

      // Reset unread count
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('conversations')
          .doc(contactId)
          .set({'unreadCount': 0}, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  /// Delete a conversation
  Future<void> deleteConversation(String contactId) async {
    if (currentUserId.isEmpty) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('conversations')
          .doc(contactId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete conversation: $e');
    }
  }

  /// Create a new conversation (initialize if doesn't exist)
  Future<void> createOrStartConversation(
    String contactId,
    String contactName,
    String contactAvatar,
  ) async {
    if (currentUserId.isEmpty) return;

    try {
      // Initialize conversation for current user
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('conversations')
          .doc(contactId)
          .set({
        'lastMessage': '',
        'lastMessageTime': Timestamp.now(),
        'unreadCount': 0,
      }, SetOptions(merge: true));

      // Initialize conversation for contact user
      await _firestore
          .collection('users')
          .doc(contactId)
          .collection('conversations')
          .doc(currentUserId)
          .set({
        'lastMessage': '',
        'lastMessageTime': Timestamp.now(),
        'unreadCount': 0,
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to create conversation: $e');
    }
  }

  /// Get unread message count
  Stream<int> getUnreadCountStream() {
    if (currentUserId.isEmpty) {
      return Stream.value(0);
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('conversations')
        .snapshots()
        .map((snapshot) {
      int totalUnread = 0;
      for (var doc in snapshot.docs) {
        final unreadCount = doc.data()['unreadCount'] ?? 0;
        totalUnread += unreadCount as int;
      }
      return totalUnread;
    });
  }

  /// Helper method to generate consistent conversation ID
  String _getConversationId(String userId1, String userId2) {
    final ids = [userId1, userId2];
    ids.sort();
    return '${ids[0]}_${ids[1]}';
  }

  /// Update user online status
  Future<void> updateUserOnlineStatus(bool isOnline) async {
    if (currentUserId.isEmpty) return;

    try {
      await _firestore.collection('users').doc(currentUserId).set({
        'isOnline': isOnline,
        'lastSeen': Timestamp.now(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update online status: $e');
    }
  }

  /// Get user online status stream
  Stream<bool> getUserOnlineStatusStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data()?['isOnline'] ?? false);
  }
}

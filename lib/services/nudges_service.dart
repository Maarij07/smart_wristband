import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NudgeItem {
  final String userId;
  final String name;
  final String? profilePicture;
  final String status;
  final DateTime? updatedAt;

  NudgeItem({
    required this.userId,
    required this.name,
    required this.status,
    this.profilePicture,
    this.updatedAt,
  });

  factory NudgeItem.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return NudgeItem(
      userId: data['userId']?.toString() ?? doc.id,
      name: data['name']?.toString() ?? 'User',
      profilePicture: data['profilePicture']?.toString(),
      status: data['status']?.toString() ?? 'sent',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}

class NudgesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  Stream<List<NudgeItem>> getReceivedNudgesStream() {
    if (currentUserId.isEmpty) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('nudges_received')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => NudgeItem.fromDoc(doc)).toList());
  }

  Stream<List<NudgeItem>> getSentNudgesStream() {
    if (currentUserId.isEmpty) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('nudges_sent')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => NudgeItem.fromDoc(doc)).toList());
  }

  Future<void> sendNudge({
    required String receiverId,
    required String receiverName,
    required String senderName,
    String? receiverProfilePicture,
    String? senderProfilePicture,
  }) async {
    if (currentUserId.isEmpty) {
      throw Exception('Not authenticated');
    }

    final senderId = currentUserId;
    final timestamp = FieldValue.serverTimestamp();

    await _firestore
        .collection('users')
        .doc(senderId)
        .collection('nudges_sent')
        .doc(receiverId)
        .set({
      'userId': receiverId,
      'name': receiverName,
      'profilePicture': receiverProfilePicture,
      'status': 'sent',
      'updatedAt': timestamp,
    }, SetOptions(merge: true));

    await _firestore
        .collection('users')
        .doc(receiverId)
        .collection('nudges_received')
        .doc(senderId)
        .set({
      'userId': senderId,
      'name': senderName,
      'profilePicture': senderProfilePicture,
      'status': 'received',
      'updatedAt': timestamp,
    }, SetOptions(merge: true));
  }

  Future<void> markMatched({
    required String otherUserId,
    required String otherUserName,
    String? otherUserProfilePicture,
    required String currentUserName,
    String? currentUserProfilePicture,
  }) async {
    if (currentUserId.isEmpty) {
      throw Exception('Not authenticated');
    }

    final currentId = currentUserId;
    final timestamp = FieldValue.serverTimestamp();

    await _firestore
        .collection('users')
        .doc(currentId)
        .collection('nudges_received')
        .doc(otherUserId)
        .set({
      'userId': otherUserId,
      'name': otherUserName,
      'profilePicture': otherUserProfilePicture,
      'status': 'matched',
      'updatedAt': timestamp,
    }, SetOptions(merge: true));

    await _firestore
        .collection('users')
        .doc(otherUserId)
        .collection('nudges_sent')
        .doc(currentId)
        .set({
      'userId': currentId,
      'name': currentUserName,
      'profilePicture': currentUserProfilePicture,
      'status': 'matched',
      'updatedAt': timestamp,
    }, SetOptions(merge: true));
  }
}

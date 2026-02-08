import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class ChatAttachment {
  final String id;
  final String mediaUrl;
  final String mediaType;
  final String? fileName;
  final int? sizeBytes;
  final DateTime? createdAt;

  ChatAttachment({
    required this.id,
    required this.mediaUrl,
    required this.mediaType,
    this.fileName,
    this.sizeBytes,
    this.createdAt,
  });

  factory ChatAttachment.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ChatAttachment(
      id: doc.id,
      mediaUrl: data['mediaUrl']?.toString() ?? '',
      mediaType: data['mediaType']?.toString() ?? 'image',
      fileName: data['fileName']?.toString(),
      sizeBytes: data['sizeBytes'] as int?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class ChatAttachmentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String get currentUserId => _auth.currentUser?.uid ?? '';

  String _getConversationId(String userId1, String userId2) {
    final ids = [userId1, userId2];
    ids.sort();
    return '${ids[0]}_${ids[1]}';
  }

  Future<String> uploadAttachment({
    required String contactId,
    required File file,
    required String mediaType,
  }) async {
    final userId = currentUserId;
    if (userId.isEmpty) {
      throw Exception('Not authenticated');
    }

    final conversationId = _getConversationId(userId, contactId);
    final extension = path.extension(file.path);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final attachmentId = '${userId}_$timestamp';

    final storageRef = _storage
        .ref()
        .child('chat_attachments/$conversationId/$attachmentId$extension');

    final metadata = SettableMetadata(
      contentType: _contentTypeForMedia(mediaType, extension),
    );

    await storageRef.putFile(file, metadata);
    final mediaUrl = await storageRef.getDownloadURL();

    final attachmentDoc = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('attachments')
        .doc(attachmentId);

    await attachmentDoc.set({
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'fileName': path.basename(file.path),
      'sizeBytes': await file.length(),
      'createdAt': FieldValue.serverTimestamp(),
      'uploaderId': userId,
    });

    return attachmentId;
  }

  Stream<ChatAttachment?> watchAttachment({
    required String contactId,
    required String attachmentId,
  }) {
    final userId = currentUserId;
    if (userId.isEmpty) {
      return const Stream.empty();
    }

    final conversationId = _getConversationId(userId, contactId);
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('attachments')
        .doc(attachmentId)
        .snapshots()
        .map((doc) => doc.exists ? ChatAttachment.fromDoc(doc) : null);
  }

  String _contentTypeForMedia(String mediaType, String extension) {
    switch (mediaType) {
      case 'video':
        return 'video/${extension.replaceFirst('.', '')}';
      case 'audio':
        return 'audio/${extension.replaceFirst('.', '')}';
      default:
        return 'image/${extension.replaceFirst('.', '')}';
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String recipientId;
  final String text;
  final DateTime timestamp;
  final String status; // sent, delivered, read
  final String type; // text, attachment
  final String? attachmentId;
  final String? mediaType; // image, video, audio

  Message({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.text,
    required this.timestamp,
    required this.status,
    this.type = 'text',
    this.attachmentId,
    this.mediaType,
  });

  factory Message.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      recipientId: data['recipientId'] ?? '',
      text: data['text'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'sent',
      type: data['type'] ?? 'text',
      attachmentId: data['attachmentId'],
      mediaType: data['mediaType'],
    );
  }

  factory Message.fromJson(Map<String, dynamic> data) {
    final timestampMs = data['timestampMs'] as int?;
    return Message(
      id: data['id']?.toString() ?? '',
      senderId: data['senderId']?.toString() ?? '',
      recipientId: data['recipientId']?.toString() ?? '',
      text: data['text']?.toString() ?? '',
      timestamp: timestampMs != null
          ? DateTime.fromMillisecondsSinceEpoch(timestampMs)
          : DateTime.now(),
      status: data['status']?.toString() ?? 'sent',
      type: data['type']?.toString() ?? 'text',
      attachmentId: data['attachmentId']?.toString(),
      mediaType: data['mediaType']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'recipientId': recipientId,
      'text': text,
      'timestamp': timestamp,
      'status': status,
      'type': type,
      'attachmentId': attachmentId,
      'mediaType': mediaType,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'recipientId': recipientId,
      'text': text,
      'timestampMs': timestamp.millisecondsSinceEpoch,
      'status': status,
      'type': type,
      'attachmentId': attachmentId,
      'mediaType': mediaType,
    };
  }

  // Create a copy with modifications
  Message copyWith({
    String? id,
    String? senderId,
    String? recipientId,
    String? text,
    DateTime? timestamp,
    String? status,
    String? type,
    String? attachmentId,
    String? mediaType,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      type: type ?? this.type,
      attachmentId: attachmentId ?? this.attachmentId,
      mediaType: mediaType ?? this.mediaType,
    );
  }
}

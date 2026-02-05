import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String recipientId;
  final String text;
  final DateTime timestamp;
  final String status; // sent, delivered, read

  Message({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.text,
    required this.timestamp,
    required this.status,
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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'recipientId': recipientId,
      'text': text,
      'timestamp': timestamp,
      'status': status,
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
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      recipientId: recipientId ?? this.recipientId,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }
}

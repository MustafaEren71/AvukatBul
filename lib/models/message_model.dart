import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final List<String> participants;
  final DateTime timestamp;
  final bool isRead;
  
  MessageModel({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.participants,
    required this.timestamp,
    this.isRead = false,
  });
  
  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      content: map['content'] ?? '',
      participants: List<String>.from(map['participants'] ?? []),
      timestamp: map['timestamp'] != null 
        ? (map['timestamp'] as Timestamp).toDate() 
        : DateTime.now(),
      isRead: map['isRead'] ?? false,
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'participants': participants,
      'timestamp': timestamp,
      'isRead': isRead,
    };
  }
}

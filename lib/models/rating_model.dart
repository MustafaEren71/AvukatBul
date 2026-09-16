import 'package:cloud_firestore/cloud_firestore.dart';

class RatingModel {
  final String id;
  final String userId;
  final String lawyerId;
  final String userName;
  final double rating;
  final String? comment;
  final DateTime createdAt;
  
  RatingModel({
    required this.id,
    required this.userId,
    required this.lawyerId,
    required this.userName,
    required this.rating,
    this.comment,
    required this.createdAt,
  });
  
  factory RatingModel.fromMap(Map<String, dynamic> map, String id) {
    return RatingModel(
      id: id,
      userId: map['userId'] ?? '',
      lawyerId: map['lawyerId'] ?? '',
      userName: map['userName'] ?? '',
      rating: (map['rating'] ?? 0).toDouble(),
      comment: map['comment'],
      createdAt: map['createdAt'] != null 
        ? (map['createdAt'] as Timestamp).toDate() 
        : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'lawyerId': lawyerId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt,
    };
  }
}

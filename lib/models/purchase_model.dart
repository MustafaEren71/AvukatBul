import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseModel {
  final String id;
  final String userId;
  final String lawyerId;
  final String packageId;
  final String packageTitle;
  final double amount;
  final String status; // 'pending', 'completed', 'cancelled'
  final DateTime createdAt;
  
  PurchaseModel({
    required this.id,
    required this.userId,
    required this.lawyerId,
    required this.packageId,
    required this.packageTitle,
    required this.amount,
    required this.status,
    required this.createdAt,
  });
  
  factory PurchaseModel.fromMap(Map<String, dynamic> map, String id) {
    return PurchaseModel(
      id: id,
      userId: map['userId'] ?? '',
      lawyerId: map['lawyerId'] ?? '',
      packageId: map['packageId'] ?? '',
      packageTitle: map['packageTitle'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt'] != null 
        ? (map['createdAt'] as Timestamp).toDate() 
        : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'lawyerId': lawyerId,
      'packageId': packageId,
      'packageTitle': packageTitle,
      'amount': amount,
      'status': status,
      'createdAt': createdAt,
    };
  }
  
  PurchaseModel copyWith({
    String? id,
    String? userId,
    String? lawyerId,
    String? packageId,
    String? packageTitle,
    double? amount,
    String? status,
    DateTime? createdAt,
  }) {
    return PurchaseModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      lawyerId: lawyerId ?? this.lawyerId,
      packageId: packageId ?? this.packageId,
      packageTitle: packageTitle ?? this.packageTitle,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

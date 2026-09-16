import 'package:cloud_firestore/cloud_firestore.dart';

class PackageModel {
  final String id;
  final String lawyerId;
  final String title;
  final String description;
  final double price;
  final bool isActive;
  final DateTime createdAt;
  
  PackageModel({
    required this.id,
    required this.lawyerId,
    required this.title,
    required this.description,
    required this.price,
    required this.isActive,
    required this.createdAt,
  });
  
  factory PackageModel.fromMap(Map<String, dynamic> map, String id) {
    return PackageModel(
      id: id,
      lawyerId: map['lawyerId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      isActive: map['isActive'] ?? false,
      createdAt: map['createdAt'] != null 
        ? (map['createdAt'] as Timestamp).toDate() 
        : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'lawyerId': lawyerId,
      'title': title,
      'description': description,
      'price': price,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }
  
  PackageModel copyWith({
    String? id,
    String? lawyerId,
    String? title,
    String? description,
    double? price,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return PackageModel(
      id: id ?? this.id,
      lawyerId: lawyerId ?? this.lawyerId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

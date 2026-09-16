import 'package:cloud_firestore/cloud_firestore.dart';

class CaseModel {
  final String id;
  final String lawyerId;
  final String title;
  final String description;
  final String status; // 'ongoing', 'won', 'lost'
  final DateTime startDate;
  final DateTime? endDate;

  CaseModel({
    required this.id,
    required this.lawyerId,
    required this.title,
    required this.description,
    required this.status,
    required this.startDate,
    this.endDate,
  });

  factory CaseModel.fromMap(Map<String, dynamic> map, String id) {
    return CaseModel(
      id: id,
      lawyerId: map['lawyerId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'ongoing',
      startDate: map['startDate'] != null 
        ? (map['startDate'] as Timestamp).toDate() 
        : DateTime.now(),
      endDate: map['endDate'] != null 
        ? (map['endDate'] as Timestamp).toDate() 
        : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lawyerId': lawyerId,
      'title': title,
      'description': description,
      'status': status,
      'startDate': startDate,
      'endDate': endDate,
    };
  }

  CaseModel copyWith({
    String? id,
    String? lawyerId,
    String? title,
    String? description,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return CaseModel(
      id: id ?? this.id,
      lawyerId: lawyerId ?? this.lawyerId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class LawyerModel {
  final String id;
  final String userId;
  final String name;
  final String city;
  final String district; // İlçe bilgisi eklendi
  final String bio;
  final double averageRating;
  final int casesCount;
  final int successfulCasesCount;
  final double successRate;
  final String? profileImageUrl;
  final DateTime createdAt;
  
  LawyerModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.city,
    required this.district, // İlçe bilgisi eklendi
    required this.bio,
    required this.averageRating,
    required this.casesCount,
    required this.successfulCasesCount,
    required this.successRate,
    this.profileImageUrl,
    required this.createdAt,
  });
  
  factory LawyerModel.fromMap(Map<String, dynamic> map, String id) {
    int casesCount = map['casesCount'] ?? 0;
    int successfulCasesCount = map['successfulCasesCount'] ?? 0;
    
    // Başarı oranını hesapla
    double successRate = casesCount > 0 ? successfulCasesCount / casesCount : 0.0;
    
    return LawyerModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      city: map['city'] ?? '',
      district: map['district'] ?? '', // İlçe bilgisi eklendi
      bio: map['bio'] ?? '',
      averageRating: (map['averageRating'] ?? 0).toDouble(),
      casesCount: casesCount,
      successfulCasesCount: successfulCasesCount,
      successRate: successRate,
      profileImageUrl: map['profileImageUrl'],
      createdAt: map['createdAt'] != null 
        ? (map['createdAt'] as Timestamp).toDate() 
        : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'city': city,
      'district': district, // İlçe bilgisi eklendi
      'bio': bio,
      'averageRating': averageRating,
      'casesCount': casesCount,
      'successfulCasesCount': successfulCasesCount,
      'successRate': successRate,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt,
    };
  }
  
  LawyerModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? city,
    String? district, // İlçe bilgisi eklendi
    String? bio,
    double? averageRating,
    int? casesCount,
    int? successfulCasesCount,
    double? successRate,
    String? profileImageUrl,
    DateTime? createdAt,
  }) {
    return LawyerModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      city: city ?? this.city,
      district: district ?? this.district, // İlçe bilgisi eklendi
      bio: bio ?? this.bio,
      averageRating: averageRating ?? this.averageRating,
      casesCount: casesCount ?? this.casesCount,
      successfulCasesCount: successfulCasesCount ?? this.successfulCasesCount,
      successRate: successRate ?? this.successRate,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

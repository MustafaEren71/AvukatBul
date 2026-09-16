import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final String userType; // 'client' veya 'lawyer'
  final String city;
  final String? fcmToken;
  final String? profileImageUrl; // Profil fotoğrafı URL'i eklendi
  final DateTime createdAt;
  
  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.userType,
    required this.city,
    this.fcmToken,
    this.profileImageUrl,
    required this.createdAt,
  });
  
  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      userType: map['userType'] ?? '',
      city: map['city'] ?? '',
      fcmToken: map['fcmToken'],
      profileImageUrl: map['profileImageUrl'],
      createdAt: map['createdAt'] != null 
        ? (map['createdAt'] as Timestamp).toDate() 
        : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'userType': userType,
      'city': city,
      'fcmToken': fcmToken,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt,
    };
  }
  
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? userType,
    String? city,
    String? fcmToken,
    String? profileImageUrl,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      userType: userType ?? this.userType,
      city: city ?? this.city,
      fcmToken: fcmToken ?? this.fcmToken,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

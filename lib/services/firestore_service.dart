// Firestore servisine ilçe filtreleme ekleyelim
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:avukatbul/models/lawyer_model.dart';
import 'package:avukatbul/models/package_model.dart';
import 'package:avukatbul/models/message_model.dart';
import 'package:avukatbul/models/rating_model.dart';
import 'package:avukatbul/models/user_model.dart';
import 'package:avukatbul/models/purchase_model.dart';
import 'package:avukatbul/models/case_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Kullanıcı işlemleri
  Future<UserModel?> getUserById(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Kullanıcı getirme hatası: $e');
      rethrow;
    }
  }
  
  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
    } catch (e) {
      print('Kullanıcı güncelleme hatası: $e');
      rethrow;
    }
  }
  
  // Profil fotoğrafı güncelleme
  Future<void> updateProfileImage(String userId, String imageUrl) async {
    try {
      // Kullanıcı belgesini güncelle
      await _firestore.collection('users').doc(userId).update({
        'profileImageUrl': imageUrl,
      });
      
      // Eğer avukatsa, avukat belgesini de güncelle
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        if (userData['userType'] == 'lawyer') {
          await _firestore.collection('lawyers').doc(userId).update({
            'profileImageUrl': imageUrl,
          });
        }
      }
    } catch (e) {
      print('Profil fotoğrafı güncelleme hatası: $e');
      rethrow;
    }
  }
  
  // Avukat işlemleri
  Future<List<LawyerModel>> getLawyersByCity(String city) async {
    try {
      QuerySnapshot snapshot = await _firestore
        .collection('lawyers')
        .where('city', isEqualTo: city)
        .get();
      
      return snapshot.docs.map((doc) => 
        LawyerModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)
      ).toList();
    } catch (e) {
      print('Avukat listesi getirme hatası: $e');
      rethrow;
    }
  }
  
  // Şehir ve ilçeye göre avukat getirme
  Future<List<LawyerModel>> getLawyersByCityAndDistrict(String city, String district) async {
    try {
      QuerySnapshot snapshot;
      
      if (district.isEmpty) {
        // Sadece şehre göre filtrele
        snapshot = await _firestore
          .collection('lawyers')
          .where('city', isEqualTo: city)
          .get();
      } else {
        // Şehir ve ilçeye göre filtrele
        snapshot = await _firestore
          .collection('lawyers')
          .where('city', isEqualTo: city)
          .where('district', isEqualTo: district)
          .get();
      }
      
      return snapshot.docs.map((doc) => 
        LawyerModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)
      ).toList();
    } catch (e) {
      print('Avukat listesi getirme hatası: $e');
      rethrow;
    }
  }
  
  // İsme göre avukat arama
  Future<List<LawyerModel>> searchLawyersByName(String name) async {
    try {
      // Firestore'da tam metin araması olmadığı için, tüm avukatları çekip isim filtrelemesi yapıyoruz
      QuerySnapshot snapshot = await _firestore
        .collection('lawyers')
        .get();
      
      List<LawyerModel> lawyers = snapshot.docs.map((doc) => 
        LawyerModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)
      ).toList();
      
      // İsme göre filtreleme
      if (name.isNotEmpty) {
        name = name.toLowerCase();
        lawyers = lawyers.where((lawyer) => 
          lawyer.name.toLowerCase().contains(name)
        ).toList();
      }
      
      return lawyers;
    } catch (e) {
      print('Avukat arama hatası: $e');
      rethrow;
    }
  }
  
  Future<LawyerModel?> getLawyerById(String lawyerId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('lawyers').doc(lawyerId).get();
      if (doc.exists) {
        return LawyerModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Avukat getirme hatası: $e');
      rethrow;
    }
  }
  
  Future<void> updateLawyerData(String lawyerId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('lawyers').doc(lawyerId).update(data);
    } catch (e) {
      print('Avukat güncelleme hatası: $e');
      rethrow;
    }
  }
  
  // Avukat dava istatistiklerini güncelleme
  Future<void> updateLawyerCases(String lawyerId, int casesCount, int successfulCasesCount) async {
    try {
      // Başarı oranını hesapla
      double successRate = casesCount > 0 ? successfulCasesCount / casesCount : 0.0;
      
      await updateLawyerData(lawyerId, {
        'casesCount': casesCount,
        'successfulCasesCount': successfulCasesCount,
        'successRate': successRate,
      });
    } catch (e) {
      print('Avukat dava istatistikleri güncelleme hatası: $e');
      rethrow;
    }
  }
  
  // Diğer metotlar...
  
  // Puanlama işlemleri
  Future<List<RatingModel>> getRatingsByLawyerId(String lawyerId) async {
    try {
      QuerySnapshot snapshot = await _firestore
        .collection('ratings')
        .where('lawyerId', isEqualTo: lawyerId)
        .orderBy('createdAt', descending: true)
        .get();
      
      return snapshot.docs.map((doc) => 
        RatingModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)
      ).toList();
    } catch (e) {
      print('Puanlama listesi getirme hatası: $e');
      rethrow;
    }
  }
  
  Future<RatingModel?> getRatingByUserAndLawyer(String userId, String lawyerId) async {
    try {
      QuerySnapshot snapshot = await _firestore
        .collection('ratings')
        .where('userId', isEqualTo: userId)
        .where('lawyerId', isEqualTo: lawyerId)
        .get();
      
      if (snapshot.docs.isNotEmpty) {
        return RatingModel.fromMap(
          snapshot.docs.first.data() as Map<String, dynamic>, 
          snapshot.docs.first.id
        );
      }
      return null;
    } catch (e) {
      print('Puanlama getirme hatası: $e');
      rethrow;
    }
  }
  
  Future<String> addRating(RatingModel rating) async {
    try {
      // Önce mevcut puanlamayı kontrol et
      RatingModel? existingRating = await getRatingByUserAndLawyer(
        rating.userId, 
        rating.lawyerId
      );
      
      if (existingRating != null) {
        // Mevcut puanlamayı güncelle
        await _firestore.collection('ratings').doc(existingRating.id).update({
          'rating': rating.rating,
          'comment': rating.comment,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        // Avukatın ortalama puanını güncelle
        await updateLawyerAverageRating(rating.lawyerId);
        
        return existingRating.id;
      } else {
        // Yeni puanlama ekle
        DocumentReference docRef = await _firestore.collection('ratings').add({
          ...rating.toMap(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // Avukatın ortalama puanını güncelle
        await updateLawyerAverageRating(rating.lawyerId);
        
        return docRef.id;
      }
    } catch (e) {
      print('Puanlama ekleme hatası: $e');
      rethrow;
    }
  }
  
  Future<void> updateLawyerAverageRating(String lawyerId) async {
    try {
      List<RatingModel> ratings = await getRatingsByLawyerId(lawyerId);
      
      if (ratings.isEmpty) return;
      
      double totalRating = 0;
      ratings.forEach((rating) {
        totalRating += rating.rating;
      });
      
      double averageRating = totalRating / ratings.length;
      
      await updateLawyerData(lawyerId, {'averageRating': averageRating});
    } catch (e) {
      print('Ortalama puan güncelleme hatası: $e');
      rethrow;
    }
  }
  
  // Diğer metotlar...
}

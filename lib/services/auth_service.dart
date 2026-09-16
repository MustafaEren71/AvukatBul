import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:avukatbul/models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Kayıt olma
  Future<UserCredential?> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required bool isLawyer,
    required String city,
  }) async {
    try {
      // Firebase Auth ile kullanıcı oluştur
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Email doğrulama gönder
      await userCredential.user!.sendEmailVerification();
      
      // Firestore'a kullanıcı bilgilerini kaydet
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'name': name,
        'userType': isLawyer ? 'lawyer' : 'client',
        'city': city,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // Eğer avukatsa, avukat koleksiyonuna da ekle
      if (isLawyer) {
        await _firestore.collection('lawyers').doc(userCredential.user!.uid).set({
          'userId': userCredential.user!.uid,
          'name': name,
          'bio': '',
          'city': city,
          'successRate': 0,
          'casesCount': 0,
          'averageRating': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      notifyListeners();
      return userCredential;
    } catch (e) {
      print('Kayıt hatası: $e');
      rethrow; // Hatayı yukarı fırlat
    }
  }
  
  // Giriş yapma
  Future<UserCredential?> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      notifyListeners();
      return userCredential;
    } catch (e) {
      print('Giriş hatası: $e');
      rethrow; // Hatayı yukarı fırlat
    }
  }
  
  // Çıkış yapma
  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }
  
  // Kullanıcı tipini kontrol et
  Future<String> getUserType() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        return userDoc.get('userType') ?? '';
      }
    }
    return '';
  }
  
  // Email doğrulama durumunu kontrol et
  bool isEmailVerified() {
    User? user = _auth.currentUser;
    return user != null && user.emailVerified;
  }
  
  // Email doğrulama durumunu yenile
  Future<bool> checkEmailVerified() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.reload();
      user = _auth.currentUser; // Güncellenmiş kullanıcı bilgisini al
      notifyListeners();
      return user?.emailVerified ?? false;
    }
    return false;
  }
  
  // Email doğrulama gönder
  Future<void> sendEmailVerification() async {
    User? user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }
  
  // Şifre sıfırlama
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
  
  // Kullanıcı bilgilerini getir
  Future<UserModel?> getUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        return UserModel.fromMap(userDoc.data() as Map<String, dynamic>, user.uid);
      }
    }
    return null;
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:avukatbul/services/firestore_service.dart';
import 'package:avukatbul/models/rating_model.dart';
import 'package:avukatbul/widgets/rating_bar.dart';
import 'package:avukatbul/widgets/custom_button.dart';

class RatingScreen extends StatefulWidget {
  final String lawyerId;
  final String lawyerName;
  
  const RatingScreen({
    Key? key,
    required this.lawyerId,
    required this.lawyerName,
  }) : super(key: key);
  
  @override
  _RatingScreenState createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  
  double _rating = 0;
  final _commentController = TextEditingController();
  RatingModel? _existingRating;
  
  @override
  void initState() {
    super.initState();
    _loadExistingRating();
  }
  
  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
  
  Future<void> _loadExistingRating() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      String userId = _auth.currentUser!.uid;
      
      // Mevcut değerlendirmeyi kontrol et
      RatingModel? rating = await _firestoreService.getRatingByUserAndLawyer(
        userId, 
        widget.lawyerId
      );
      
      if (rating != null) {
        setState(() {
          _existingRating = rating;
          _rating = rating.rating;
          _commentController.text = rating.comment ?? '';
        });
      }
    } catch (e) {
      print('Değerlendirme yükleme hatası: $e');
      setState(() {
        _errorMessage = 'Değerlendirme yüklenirken bir hata oluştu: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Avukat Değerlendir'),
      ),
      body: _isLoading
        ? Center(child: CircularProgressIndicator())
        : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Hata: $_errorMessage',
                    style: TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadExistingRating,
                    child: Text('Tekrar Dene'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avukat bilgisi
                  Card(
                    elevation: 2,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: Text(
                              widget.lawyerName.isNotEmpty ? widget.lawyerName.substring(0, 1).toUpperCase() : '?',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bol

Şimdi Firestore güvenlik kurallarını da ekleyelim. Bu kurallar, veritabanınızı güvende tutmak için önemlidir:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Kullanıcı kimlik doğrulaması yapılmış mı kontrol et
    function isAuthenticated() {
      return request.auth != null;
    }
    
    // Kullanıcı kendi belgesine erişiyor mu kontrol et
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    // Kullanıcı avukat mı kontrol et
    function isLawyer() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType == 'lawyer';
    }
    
    // Kullanıcı müşteri mi kontrol et
    function isClient() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType == 'client';
    }
    
    // Kullanıcılar koleksiyonu kuralları
    match /users/{userId} {
      // Herkes okuyabilir, sadece kendisi yazabilir
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update, delete: if isOwner(userId);
    }
    
    // Avukatlar koleksiyonu kuralları
    match /lawyers/{lawyerId} {
      // Herkes okuyabilir, sadece kendisi yazabilir
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && isLawyer() && isOwner(lawyerId);
      allow update: if isOwner(lawyerId);
      allow delete: if isOwner(lawyerId);
    }
    
    // Paketler koleksiyonu kuralları
    match /packages/{packageId} {
      // Herkes okuyabilir, sadece avukat yazabilir
      allow read: if isAuthenticated();
      allow create, update, delete: if isAuthenticated() && isLawyer() && 
        resource.data.lawyerId == request.auth.uid;
    }
    
    // Davalar koleksiyonu kuralları
    match /cases/{caseId} {
      // Sadece ilgili avukat okuyabilir ve yazabilir
      allow read, write: if isAuthenticated() && isLawyer() && 
        resource.data.lawyerId == request.auth.uid;
    }
    
    // Mesajlar koleksiyonu kuralları
    match /messages/{messageId} {
      // Sadece mesajın katılımcıları okuyabilir ve yazabilir
      allow read, create: if isAuthenticated() && 
        (request.resource.data.participants.hasAny([request.auth.uid]) || 
         resource.data.participants.hasAny([request.auth.uid]));
      allow update, delete: if isAuthenticated() && 
        resource.data.senderId == request.auth.uid;
    }
    
    // Değerlendirmeler koleksiyonu kuralları
    match /ratings/{ratingId} {
      // Herkes okuyabilir, sadece değerlendirmeyi yapan kişi yazabilir
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && isClient() && 
        request.resource.data.userId == request.auth.uid;
      allow update, delete: if isAuthenticated() && 
        resource.data.userId == request.auth.uid;
    }
    
    // Satın almalar koleksiyonu kuralları
    match /purchases/{purchaseId} {
      // Sadece ilgili müşteri ve avukat okuyabilir, sadece müşteri yazabilir
      allow read: if isAuthenticated() && 
        (resource.data.userId == request.auth.uid || 
         resource.data.lawyerId == request.auth.uid);
      allow create: if isAuthenticated() && isClient() && 
        request.resource.data.userId == request.auth.uid;
      allow update: if isAuthenticated() && 
        (resource.data.userId == request.auth.uid || 
         resource.data.lawyerId == request.auth.uid);
      allow delete: if false; // Satın alma kayıtları silinemez
    }
  }
}

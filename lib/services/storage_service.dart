import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  
  // Galeriden resim seçme
  Future<File?> pickImageFromGallery() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    
    return null;
  }
  
  // Kameradan resim çekme
  Future<File?> pickImageFromCamera() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    
    return null;
  }
  
  // Profil fotoğrafını yükleme
  Future<String?> uploadProfileImage(String userId, File imageFile) async {
    try {
      String fileName = 'profile_$userId.${path.extension(imageFile.path)}';
      Reference storageRef = _storage.ref().child('profile_images/$fileName');
      
      // Dosyayı yükle
      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      
      // Dosya URL'ini al
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Profil fotoğrafı yükleme hatası: $e');
      return null;
    }
  }
  
  // Profil fotoğrafını silme
  Future<bool> deleteProfileImage(String userId) async {
    try {
      String fileName = 'profile_$userId';
      Reference storageRef = _storage.ref().child('profile_images/$fileName');
      await storageRef.delete();
      return true;
    } catch (e) {
      print('Profil fotoğrafı silme hatası: $e');
      return false;
    }
  }
}

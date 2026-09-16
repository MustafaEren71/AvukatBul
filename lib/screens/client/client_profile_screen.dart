import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:avukatbul/services/auth_service.dart';
import 'package:avukatbul/services/firestore_service.dart';
import 'package:avukatbul/services/storage_service.dart';
import 'package:avukatbul/models/user_model.dart';
import 'package:avukatbul/models/purchase_model.dart';
import 'package:avukatbul/widgets/custom_button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class ClientProfileScreen extends StatefulWidget {
  @override
  _ClientProfileScreenState createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  late TabController _tabController;
  
  bool _isLoading = true;
  bool _isUploading = false;
  String? _errorMessage;
  UserModel? _user;
  List<PurchaseModel> _purchases = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      String userId = _auth.currentUser!.uid;
      
      // Kullanıcı bilgilerini getir
      UserModel? user = await _firestoreService.getUserById(userId);
      
      if (user == null) {
        setState(() {
          _errorMessage = 'Profil bilgileri bulunamadı';
          _isLoading = false;
        });
        return;
      }
      
      // Satın alma geçmişini getir
      List<PurchaseModel> purchases = await _firestoreService.getPurchasesByUserId(userId);
      
      setState(() {
        _user = user;
        _purchases = purchases;
        _isLoading = false;
      });
    } catch (e) {
      print('Profil yükleme hatası: $e');
      setState(() {
        _errorMessage = 'Profil yüklenirken bir hata oluştu: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _changeProfileImage() async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Galeriden Seç'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Kamera ile Çek'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              if (_user?.profileImageUrl != null && _user!.profileImageUrl!.isNotEmpty)
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Profil Fotoğrafını Kaldır', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    _removeProfileImage();
                  },
                ),
            ],
          ),
        );
      },
    );
  }
  
  Future<void> _pickImageFromGallery() async {
    try {
      File? imageFile = await _storageService.pickImageFromGallery();
      if (imageFile != null) {
        _uploadProfileImage(imageFile);
      }
    } catch (e) {
      print('Galeri resim seçme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Resim seçilirken bir hata oluştu: ${e.toString()}')),
      );
    }
  }
  
  Future<void> _pickImageFromCamera() async {
    try {
      File? imageFile = await _storageService.pickImageFromCamera();
      if (imageFile != null) {
        _uploadProfileImage(imageFile);
      }
    } catch (e) {
      print('Kamera resim çekme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Resim çekilirken bir hata oluştu: ${e.toString()}')),
      );
    }
  }
  
  Future<void> _uploadProfileImage(File imageFile) async {
    if (_user == null) return;
    
    setState(() {
      _isUploading = true;
    });
    
    try {
      String? imageUrl = await _storageService.uploadProfileImage(_user!.id, imageFile);
      
      if (imageUrl != null) {
        await _firestoreService.updateProfileImage(_user!.id, imageUrl);
        
        // Kullanıcı modelini güncelle
        setState(() {
          _user = _user!.copyWith(profileImageUrl: imageUrl);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil fotoğrafı güncellendi')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profil fotoğrafı yüklenemedi')),
        );
      }
    } catch (e) {
      print('Profil fotoğrafı yükleme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }
  
  Future<void> _removeProfileImage() async {
    if (_user == null || _user!.profileImageUrl == null || _user!.profileImageUrl!.isEmpty) return;
    
    setState(() {
      _isUploading = true;
    });
    
    try {
      await _storageService.deleteProfileImage(_user!.id);
      await _firestoreService.updateProfileImage(_user!.id, '');
      
      // Kullanıcı modelini güncelle
      setState(() {
        _user = _user!.copyWith(profileImageUrl: '');
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profil fotoğrafı kaldırıldı')),
      );
    } catch (e) {
      print('Profil fotoğrafı kaldırma hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return _isLoading
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
                  onPressed: _loadProfile,
                  child: Text('Tekrar Dene'),
                ),
              ],
            ),
          )
        : Column(
            children: [
              // Profil başlığı
              Container(
                padding: EdgeInsets.all(16),
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        _isUploading
                          ? CircularProgressIndicator()
                          : GestureDetector(
                              onTap: _changeProfileImage,
                              child: _buildProfileImage(),
                            ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      _user!.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _user!.email,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 4),
                        Text(
                          _user!.city,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Tab bar
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: 'Profil Bilgileri'),
                  Tab(text: 'Satın Alma Geçmişi'),
                ],
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Theme.of(context).primaryColor,
              ),
              
              // Tab içerikleri
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Profil bilgileri tab
                    _buildProfileInfoTab(),
                    
                    // Satın alma geçmişi tab
                    _buildPurchaseHistoryTab(),
                  ],
                ),
              ),
            ],
          );
  }
  
  Widget _buildProfileImage() {
    if (_user!.profileImageUrl != null && _user!.profileImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: CachedNetworkImage(
          imageUrl: _user!.profileImageUrl!,
          width: 100,
          height: 100,
          fit: BoxFit.cover,
          placeholder: (context, url) => CircularProgressIndicator(),
          errorWidget: (context, url, error) => _buildDefaultAvatar(),
        ),
      );
    } else {
      return _buildDefaultAvatar();
    }
  }
  
  Widget _buildDefaultAvatar() {
    return CircleAvatar(
      radius: 50,
      backgroundColor: Theme.of(context).primaryColor,
      child: Text(
        _user!.name.isNotEmpty ? _user!.name.substring(0, 1).toUpperCase() : '?',
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
  
  Widget _buildProfileInfoTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kişisel Bilgiler',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  ListTile(
                    title: Text('Ad Soyad'),
                    subtitle: Text(_user!.name),
                    leading: Icon(Icons.person),
                    trailing: IconButton(
                      icon: Icon(Icons.edit, color: Theme.of(context).primaryColor),
                      onPressed: () {
                        _showEditNameDialog();
                      },
                    ),
                  ),
                  Divider(),
                  ListTile(
                    title: Text('E-posta'),
                    subtitle: Text(_user!.email),
                    leading: Icon(Icons.email),
                  ),
                  Divider(),
                  ListTile(
                    title: Text('Şehir'),
                    subtitle: Text(_user!.city),
                    leading: Icon(Icons.location_city),
                    trailing: IconButton(
                      icon: Icon(Icons.edit, color: Theme.of(context).primaryColor),
                      onPressed: () {
                        _showEditCityDialog();
                      },
                    ),
                  ),
                  Divider(),
                  ListTile(
                    title: Text('Hesap Türü'),
                    subtitle: Text(_user!.userType == 'client' ? 'Müşteri' : 'Avukat'),
                    leading: Icon(Icons.badge),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
          Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hesap Ayarları',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  CustomButton(
                    text: 'Şifre Değiştir',
                    onPressed: _showChangePasswordDialog,
                    icon: Icons.lock,
                    isOutlined: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPurchaseHistoryTab() {
    if (_purchases.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'Henüz satın alma işlemi yapmadınız',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _purchases.length,
      itemBuilder: (context, index) {
        PurchaseModel purchase = _purchases[index];
        
        return Card(
          elevation: 2,
          margin: EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        purchase.packageTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(purchase.status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(purchase.status),
                        style: TextStyle(
                          color: _getStatusColor(purchase.status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${purchase.amount.toStringAsFixed(2)} ₺',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    Text(
                      DateFormat('dd.MM.yyyy HH:mm').format(purchase.createdAt),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'Tamamlandı';
      case 'pending':
        return 'Beklemede';
      case 'cancelled':
        return 'İptal Edildi';
      default:
        return 'Bilinmiyor';
    }
  }
  
  Future<void> _showEditNameDialog() async {
    final nameController = TextEditingController(text: _user!.name);
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Ad Soyad Düzenle'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Ad Soyad',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isNotEmpty) {
                  Navigator.pop(context);
                  await _updateUserName(nameController.text.trim());
                }
              },
              child: Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _showEditCityDialog() async {
    final cityController = TextEditingController(text: _user!.city);
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Şehir Düzenle'),
          content: TextField(
            controller: cityController,
            decoration: InputDecoration(
              labelText: 'Şehir',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (cityController.text.trim().isNotEmpty) {
                  Navigator.pop(context);
                  await _updateUserCity(cityController.text.trim());
                }
              },
              child: Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _updateUserName(String name) async {
    try {
      await _firestoreService.updateUserData(_user!.id, {'name': name});
      
      // Kullanıcı modelini güncelle
      setState(() {
        _user = _user!.copyWith(name: name);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ad Soyad güncellendi')),
      );
    } catch (e) {
      print('Ad Soyad güncelleme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: ${e.toString()}')),
      );
    }
  }
  
  Future<void> _updateUserCity(String city) async {
    try {
      await _firestoreService.updateUserData(_user!.id, {'city': city});
      
      // Kullanıcı modelini güncelle
      setState(() {
        _user = _user!.copyWith(city: city);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Şehir güncellendi')),
      );
    } catch (e) {
      print('Şehir güncelleme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: ${e.toString()}')),
      );
    }
  }
  
  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Şifre Değiştir'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Mevcut Şifre',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Mevcut şifrenizi girin';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: newPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Yeni Şifre',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Yeni şifrenizi girin';
                    }
                    if (value.length < 6) {
                      return 'Şifre en az 6 karakter olmalıdır';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Yeni Şifre (Tekrar)',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Yeni şifrenizi tekrar girin';
                    }
                    if (value != newPasswordController.text) {
                      return 'Şifreler eşleşmiyor';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context);
                  await _changePassword(
                    currentPasswordController.text,
                    newPasswordController.text,
                  );
                }
              },
              child: Text('Değiştir'),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _changePassword(String currentPassword, String newPassword) async {
    try {
      // Kullanıcının email adresini al
      final user = _auth.currentUser;
      final email = user?.email;
      
      if (email == null) {
        throw Exception('Kullanıcı email adresi bulunamadı');
      }
      
      // Mevcut şifre ile yeniden kimlik doğrulama
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );
      
      await user?.reauthenticateWithCredential(credential);
      
      // Şifreyi güncelle
      await user?.updatePassword(newPassword);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Şifreniz başarıyla değiştirildi')),
      );
    } catch (e) {
      print('Şifre değiştirme hatası: $e');
      String errorMessage = 'Şifre değiştirilemedi';
      
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'wrong-password':
            errorMessage = 'Mevcut şifreniz yanlış';
            break;
          case 'weak-password':
            errorMessage = 'Yeni şifre çok zayıf';
            break;
          case 'requires-recent-login':
            errorMessage = 'Lütfen tekrar giriş yapın ve yeniden deneyin';
            break;
        }
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $errorMessage')),
      );
    }
  }
}

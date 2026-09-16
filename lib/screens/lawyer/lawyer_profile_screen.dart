import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:avukatbul/services/auth_service.dart';
import 'package:avukatbul/services/firestore_service.dart';
import 'package:avukatbul/services/storage_service.dart';
import 'package:avukatbul/models/lawyer_model.dart';
import 'package:avukatbul/models/user_model.dart';
import 'package:avukatbul/screens/lawyer/package_management_screen.dart';
import 'package:avukatbul/screens/lawyer/case_management_screen.dart';
import 'package:avukatbul/widgets/custom_button.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LawyerProfileScreen extends StatefulWidget {
  @override
  _LawyerProfileScreenState createState() => _LawyerProfileScreenState();
}

class _LawyerProfileScreenState extends State<LawyerProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = true;
  bool _isUploading = false;
  String? _errorMessage;
  LawyerModel? _lawyer;
  UserModel? _user;
  
  final _bioController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;
  
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }
  
  @override
  void dispose() {
    _bioController.dispose();
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
      
      // Avukat bilgilerini getir
      LawyerModel? lawyer = await _firestoreService.getLawyerById(userId);
      
      if (user == null || lawyer == null) {
        setState(() {
          _errorMessage = 'Profil bilgileri bulunamadı';
          _isLoading = false;
        });
        return;
      }
      
      setState(() {
        _user = user;
        _lawyer = lawyer;
        _bioController.text = lawyer.bio;
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
              if (_lawyer?.profileImageUrl != null && _lawyer!.profileImageUrl!.isNotEmpty)
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
    if (_lawyer == null) return;
    
    setState(() {
      _isUploading = true;
    });
    
    try {
      String? imageUrl = await _storageService.uploadProfileImage(_lawyer!.id, imageFile);
      
      if (imageUrl != null) {
        await _firestoreService.updateProfileImage(_lawyer!.id, imageUrl);
        
        // Avukat modelini güncelle
        setState(() {
          _lawyer = _lawyer!.copyWith(profileImageUrl: imageUrl);
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
    if (_lawyer == null || _lawyer!.profileImageUrl == null || _lawyer!.profileImageUrl!.isEmpty) return;
    
    setState(() {
      _isUploading = true;
    });
    
    try {
      await _storageService.deleteProfileImage(_lawyer!.id);
      await _firestoreService.updateProfileImage(_lawyer!.id, '');
      
      // Avukat modelini güncelle
      setState(() {
        _lawyer = _lawyer!.copyWith(profileImageUrl: '');
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
        : _buildProfileContent();
  }
  
  Widget _buildProfileContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profil başlığı
          Center(
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
                      _lawyer!.city,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatCard(
                      icon: Icons.star,
                      value: _lawyer!.averageRating.toStringAsFixed(1),
                      label: 'Puan',
                      color: Colors.amber,
                    ),
                    SizedBox(width: 16),
                    _buildStatCard(
                      icon: Icons.gavel,
                      value: _lawyer!.casesCount.toString(),
                      label: 'Dava',
                      color: Colors.blue,
                    ),
                    SizedBox(width: 16),
                    _buildStatCard(
                      icon: Icons.trending_up,
                      value: '${(_lawyer!.successRate * 100).toStringAsFixed(0)}%',
                      label: 'Başarı',
                      color: Colors.green,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24),
          
          // Kişisel Bilgiler
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
                    subtitle: Text(_lawyer!.city),
                    leading: Icon(Icons.location_city),
                    trailing: IconButton(
                      icon: Icon(Icons.edit, color: Theme.of(context).primaryColor),
                      onPressed: () {
                        _showEditCityDialog();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
          // Dava İstatistikleri
          Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Dava İstatistikleri',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.edit,
                          color: Theme.of(context).primaryColor,
                        ),
                        onPressed: () {
                          _showEditCasesDialog();
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  ListTile(
                    title: Text('Toplam Dava Sayısı'),
                    subtitle: Text(_lawyer!.casesCount.toString()),
                    leading: Icon(Icons.gavel, color: Colors.blue),
                  ),
                  Divider(),
                  ListTile(
                    title: Text('Başarılı Dava Sayısı'),
                    subtitle: Text(_lawyer!.successfulCasesCount.toString()),
                    leading: Icon(Icons.check_circle, color: Colors.green),
                  ),
                  Divider(),
                  ListTile(
                    title: Text('Başarı Oranı'),
                    subtitle: Text('${(_lawyer!.successRate * 100).toStringAsFixed(1)}%'),
                    leading: Icon(Icons.trending_up, color: Colors.orange),
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.gavel),
                      label: Text('Dava Yönetimi'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CaseManagementScreen(),
                          ),
                        ).then((_) => _loadProfile());
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
          // Biyografi
          Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hakkımda',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isEditing ? Icons.save : Icons.edit,
                          color: Theme.of(context).primaryColor,
                        ),
                        onPressed: () {
                          if (_isEditing) {
                            // Kaydet
                            if (_formKey.currentState!.validate()) {
                              _saveBio();
                            }
                          } else {
                            // Düzenleme moduna geç
                            setState(() {
                              _isEditing = true;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  _isEditing
                    ? Form(
                        key: _formKey,
                        child: TextFormField(
                          controller: _bioController,
                          decoration: InputDecoration(
                            hintText: 'Kendinizi tanıtın...',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 5,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Lütfen kendinizi tanıtın';
                            }
                            return null;
                          },
                        ),
                      )
                    : Text(
                        _lawyer!.bio.isEmpty
                          ? 'Henüz bir biyografi eklenmemiş. Düzenle butonuna tıklayarak kendinizi tanıtabilirsiniz.'
                          : _lawyer!.bio,
                        style: TextStyle(fontSize: 16),
                      ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 24),
          
          // Hesap Ayarları
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
          
          SizedBox(height: 24),
          
          // Hizmet paketleri yönetimi
          Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hizmet Paketleri',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Müşterilerinize sunduğunuz hizmet paketlerini yönetin.',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.inventory_2),
                    label: Text('Paketleri Yönet'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PackageManagementScreen(),
                        ),
                      ).then((_) => _loadProfile());
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProfileImage() {
    if (_lawyer!.profileImageUrl != null && _lawyer!.profileImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: CachedNetworkImage(
          imageUrl: _lawyer!.profileImageUrl!,
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
  
  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      width: 80,
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _saveBio() async {
    try {
      await _firestoreService.updateLawyerData(
        _lawyer!.id,
        {'bio': _bioController.text},
      );
      
      // Lawyer modelini güncelle
      if (_lawyer != null) {
        setState(() {
          _lawyer = _lawyer!.copyWith(bio: _bioController.text);
          _isEditing = false;
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Biyografi güncellendi')),
      );
    } catch (e) {
      print('Biyografi güncelleme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: ${e.toString()}')),
      );
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
    final cityController = TextEditingController(text: _lawyer!.city);
    
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
                  await _updateLawyerCity(cityController.text.trim());
                }
              },
              child: Text('Kaydet'),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _showEditCasesDialog() async {
    final casesController = TextEditingController(text: _lawyer!.casesCount.toString());
    final successfulCasesController = TextEditingController(text: _lawyer!.successfulCasesCount.toString());
    final formKey = GlobalKey<FormState>();
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Dava İstatistiklerini Düzenle'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: casesController,
                  decoration: InputDecoration(
                    labelText: 'Toplam Dava Sayısı',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen dava sayısını girin';
                    }
                    try {
                      int cases = int.parse(value);
                      if (cases < 0) {
                        return 'Dava sayısı negatif olamaz';
                      }
                    } catch (e) {
                      return 'Geçerli bir sayı girin';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: successfulCasesController,
                  decoration: InputDecoration(
                    labelText: 'Başarılı Dava Sayısı',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen başarılı dava sayısını girin';
                    }
                    try {
                      int successfulCases = int.parse(value);
                      int totalCases = int.parse(casesController.text);
                      if (successfulCases < 0) {
                        return 'Başarılı dava sayısı negatif olamaz';
                      }
                      if (successfulCases > totalCases) {
                        return 'Başarılı dava sayısı toplam dava sayısından büyük olamaz';
                      }
                    } catch (e) {
                      return 'Geçerli bir sayı girin';
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
                  int casesCount = int.parse(casesController.text);
                  int successfulCasesCount = int.parse(successfulCasesController.text);
                  await _updateLawyerCases(casesCount, successfulCasesCount);
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
      await _firestoreService.updateLawyerData(_lawyer!.id, {'name': name});
      
      // Modelleri güncelle
      setState(() {
        _user = _user!.copyWith(name: name);
        _lawyer = _lawyer!.copyWith(name: name);
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
  
  Future<void> _updateLawyerCity(String city) async {
    try {
      await _firestoreService.updateUserData(_user!.id, {'city': city});
      await _firestoreService.updateLawyerData(_lawyer!.id, {'city': city});
      
      // Modelleri güncelle
      setState(() {
        _user = _user!.copyWith(city: city);
        _lawyer = _lawyer!.copyWith(city: city);
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
  
  Future<void> _updateLawyerCases(int casesCount, int successfulCasesCount) async {
    try {
      await _firestoreService.updateLawyerCases(_lawyer!.id, casesCount, successfulCasesCount);
      
      // Başarı oranını hesapla
      double successRate = casesCount > 0 ? successfulCasesCount / casesCount : 0.0;
      
      // Lawyer modelini güncelle
      setState(() {
        _lawyer = _lawyer!.copyWith(
          casesCount: casesCount,
          successfulCasesCount: successfulCasesCount,
          successRate: successRate,
        );
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dava istatistikleri güncellendi')),
      );
    } catch (e) {
      print('Dava istatistikleri güncelleme hatası: $e');
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

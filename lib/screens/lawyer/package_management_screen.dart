import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:avukatbul/services/firestore_service.dart';
import 'package:avukatbul/models/package_model.dart';
import 'package:avukatbul/widgets/custom_button.dart';

class PackageManagementScreen extends StatefulWidget {
  @override
  _PackageManagementScreenState createState() => _PackageManagementScreenState();
}

class _PackageManagementScreenState extends State<PackageManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = true;
  String? _errorMessage;
  List<PackageModel> _packages = [];
  
  @override
  void initState() {
    super.initState();
    _loadPackages();
  }
  
  Future<void> _loadPackages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      String lawyerId = _auth.currentUser!.uid;
      List<PackageModel> packages = await _firestoreService.getPackagesByLawyerId(lawyerId);
      
      setState(() {
        _packages = packages;
        _isLoading = false;
      });
    } catch (e) {
      print('Paket listesi yükleme hatası: $e');
      setState(() {
        _errorMessage = 'Paketler yüklenirken bir hata oluştu: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hizmet Paketleri'),
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
                    onPressed: _loadPackages,
                    child: Text('Tekrar Dene'),
                  ),
                ],
              ),
            )
          : _buildPackagesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPackageDialog(),
        child: Icon(Icons.add),
        tooltip: 'Yeni Paket Ekle',
      ),
    );
  }
  
  Widget _buildPackagesList() {
    if (_packages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'Henüz paket eklenmemiş',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Müşterilerinize sunmak istediğiniz hizmet paketlerini ekleyin',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _loadPackages,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _packages.length,
        itemBuilder: (context, index) {
          PackageModel package = _packages[index];
          
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
                          package.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showPackageDialog(package: package),
                            tooltip: 'Düzenle',
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDeletePackage(package),
                            tooltip: 'Sil',
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    package.description,
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${package.price.toStringAsFixed(2)} ₺',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: package.isActive 
                            ? Colors.green.withOpacity(0.2) 
                            : Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          package.isActive ? 'Aktif' : 'Pasif',
                          style: TextStyle(
                            color: package.isActive ? Colors.green[700] : Colors.red[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  
  Future<void> _showPackageDialog({PackageModel? package}) async {
    // Düzenleme modunda mı yoksa ekleme modunda mı?
    bool isEditing = package != null;
    
    // Form controller'ları
    final titleController = TextEditingController(text: isEditing ? package.title : '');
    final descriptionController = TextEditingController(text: isEditing ? package.description : '');
    final priceController = TextEditingController(text: isEditing ? package.price.toString() : '');
    
    // Aktif/pasif durumu
    bool isActive = isEditing ? package.isActive : true;
    
    // Form anahtarı (validasyon için)
    final formKey = GlobalKey<FormState>();
    
    // Dialog içeriği
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(isEditing ? 'Paketi Düzenle' : 'Yeni Paket Ekle'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Paket Adı',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen paket adını girin';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Açıklama',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen açıklama girin';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: priceController,
                        decoration: InputDecoration(
                          labelText: 'Fiyat (₺)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen fiyat girin';
                          }
                          
                          // Sayı formatı kontrolü
                          try {
                            double price = double.parse(value.replaceAll(',', '.'));
                            if (price <= 0) {
                              return 'Fiyat 0\'dan büyük olmalıdır';
                            }
                          } catch (e) {
                            return 'Geçerli bir fiyat girin';
                          }
                          
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      SwitchListTile(
                        title: Text('Aktif'),
                        subtitle: Text('Paket müşterilere gösterilsin mi?'),
                        value: isActive,
                        onChanged: (value) {
                          setState(() {
                            isActive = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Form validasyonu
                    if (formKey.currentState!.validate()) {
                      try {
                        // Fiyatı double'a çevir
                        double price = double.parse(priceController.text.replaceAll(',', '.'));
                        
                        if (isEditing) {
                          // Paketi güncelle
                          await _firestoreService.updatePackage(
                            package.id,
                            {
                              'title': titleController.text,
                              'description': descriptionController.text,
                              'price': price,
                              'isActive': isActive,
                            },
                          );
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Paket güncellendi')),
                          );
                        } else {
                          // Yeni paket ekle
                          String lawyerId = _auth.currentUser!.uid;
                          
                          PackageModel newPackage = PackageModel(
                            id: '',
                            lawyerId: lawyerId,
                            title: titleController.text,
                            description: descriptionController.text,
                            price: price,
                            isActive: isActive,
                            createdAt: DateTime.now(),
                          );
                          
                          await _firestoreService.addPackage(newPackage);
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Paket eklendi')),
                          );
                        }
                        
                        // Dialog'u kapat
                        Navigator.pop(context);
                        
                        // Paketleri yeniden yükle
                        _loadPackages();
                      } catch (e) {
                        print('Paket kaydetme hatası: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Hata: ${e.toString()}')),
                        );
                      }
                    }
                  },
                  child: Text(isEditing ? 'Güncelle' : 'Ekle'),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  Future<void> _confirmDeletePackage(PackageModel package) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Paketi Sil'),
          content: Text('${package.title} paketini silmek istediğinize emin misiniz?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text('Sil'),
            ),
          ],
        );
      },
    ) ?? false;
    
    if (confirm) {
      try {
        await _firestoreService.deletePackage(package.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Paket silindi')),
        );
        
        _loadPackages();
      } catch (e) {
        print('Paket silme hatası: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${e.toString()}')),
        );
      }
    }
  }
}

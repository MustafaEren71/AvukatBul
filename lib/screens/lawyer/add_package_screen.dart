import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:avukatbul/services/firestore_service.dart';
import 'package:avukatbul/models/package_model.dart';
import 'package:avukatbul/widgets/custom_button.dart';

class AddPackageScreen extends StatefulWidget {
  @override
  _AddPackageScreenState createState() => _AddPackageScreenState();
}

class _AddPackageScreenState extends State<AddPackageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isActive = true; // Varsayılan olarak aktif
  
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Yeni Paket Ekle'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Paket Bilgileri',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Paket Adı',
                    prefixIcon: Icon(Icons.title),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Paket Açıklaması',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen paket açıklamasını girin';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: InputDecoration(
                    labelText: 'Fiyat (TL)',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen fiyat girin';
                    }
                    try {
                      double price = double.parse(value);
                      if (price <= 0) {
                        return 'Fiyat sıfırdan büyük olmalıdır';
                      }
                    } catch (e) {
                      return 'Geçerli bir sayı girin';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),
                SwitchListTile(
                  title: Text('Aktif'),
                  subtitle: Text('Paket müşterilere gösterilsin mi?'),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                ),
                SizedBox(height: 32),
                _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : CustomButton(
                      text: 'Paketi Ekle',
                      onPressed: _addPackage,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Future<void> _addPackage() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        String lawyerId = _auth.currentUser!.uid;
        
        PackageModel package = PackageModel(
          id: '',
          lawyerId: lawyerId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          price: double.parse(_priceController.text),
          isActive: _isActive, // isActive parametresi eklendi
          createdAt: DateTime.now(),
        );
        
        String packageId = await _firestoreService.addPackage(package);
        
        if (packageId.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Paket başarıyla eklendi')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Paket eklenirken bir hata oluştu')),
          );
        }
      } catch (e) {
        print('Paket ekleme hatası: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

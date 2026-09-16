import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:avukatbul/services/firestore_service.dart';
import 'package:avukatbul/models/package_model.dart';
import 'package:avukatbul/models/purchase_model.dart';
import 'package:avukatbul/widgets/custom_button.dart';

class PackagePurchaseScreen extends StatefulWidget {
  final PackageModel package;
  final String lawyerName;
  
  const PackagePurchaseScreen({
    Key? key,
    required this.package,
    required this.lawyerName,
  }) : super(key: key);
  
  @override
  _PackagePurchaseScreenState createState() => _PackagePurchaseScreenState();
}

class _PackagePurchaseScreenState extends State<PackagePurchaseScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Paket Satın Al'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Paket bilgileri
            Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paket Bilgileri',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    ListTile(
                      title: Text('Paket Adı'),
                      subtitle: Text(widget.package.title),
                      leading: Icon(Icons.inventory_2),
                    ),
                    Divider(),
                    ListTile(
                      title: Text('Avukat'),
                      subtitle: Text(widget.lawyerName),
                      leading: Icon(Icons.person),
                    ),
                    Divider(),
                    ListTile(
                      title: Text('Fiyat'),
                      subtitle: Text('${widget.package.price.toStringAsFixed(2)} ₺'),
                      leading: Icon(Icons.attach_money),
                    ),
                    Divider(),
                    ListTile(
                      title: Text('Açıklama'),
                      subtitle: Text(widget.package.description),
                      leading: Icon(Icons.description),
                    ),
                    SizedBox(height: 24),
                    _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.payment),
                            label: Text('Ödeme Yap - ${widget.package.price.toStringAsFixed(2)} ₺'),
                            onPressed: _processPayment,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _processPayment() async {
    // BURAYA ÖDEME SAYFASINA GİTMESİ İÇİN KOD GİRİLECEK
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Satın alma kaydı oluştur
      String userId = _auth.currentUser!.uid;
      
      PurchaseModel purchase = PurchaseModel(
        id: '',
        userId: userId,
        lawyerId: widget.package.lawyerId,
        packageId: widget.package.id,
        packageTitle: widget.package.title,
        amount: widget.package.price,
        status: 'pending', // Ödeme tamamlanmadığı için pending olarak işaretliyoruz
        createdAt: DateTime.now(),
      );
      
      await _firestoreService.addPurchase(purchase);
      
      // Başarılı ödeme sonrası
      _showSuccessDialog();
    } catch (e) {
      print('Ödeme hatası: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bir hata oluştu: ${e.toString()}')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _showSuccessDialog() {
    setState(() {
      _isLoading = false;
    });
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text('İşlem Başarılı'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
              SizedBox(height: 16),
              Text(
                'Paket satın alma talebiniz alındı.',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Ödeme işlemi tamamlandıktan sonra avukat ile iletişime geçebilirsiniz.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Dialog'u kapat
                Navigator.pop(context); // Satın alma sayfasını kapat
              },
              child: Text('Tamam'),
            ),
          ],
        );
      },
    );
  }
}

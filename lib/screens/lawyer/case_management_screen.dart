import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:avukatbul/services/firestore_service.dart';
import 'package:avukatbul/models/case_model.dart';
import 'package:avukatbul/widgets/custom_button.dart';
import 'package:intl/intl.dart';

class CaseManagementScreen extends StatefulWidget {
  @override
  _CaseManagementScreenState createState() => _CaseManagementScreenState();
}

class _CaseManagementScreenState extends State<CaseManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = true;
  String? _errorMessage;
  List<CaseModel> _cases = [];
  
  @override
  void initState() {
    super.initState();
    _loadCases();
  }
  
  Future<void> _loadCases() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      String lawyerId = _auth.currentUser!.uid;
      List<CaseModel> cases = await _firestoreService.getCasesByLawyerId(lawyerId);
      
      setState(() {
        _cases = cases;
        _isLoading = false;
      });
    } catch (e) {
      print('Dava listesi yükleme hatası: $e');
      setState(() {
        _errorMessage = 'Davalar yüklenirken bir hata oluştu: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dava Yönetimi'),
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
                    onPressed: _loadCases,
                    child: Text('Tekrar Dene'),
                  ),
                ],
              ),
            )
          : _buildCasesList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCaseDialog(),
        child: Icon(Icons.add),
        tooltip: 'Yeni Dava Ekle',
      ),
    );
  }
  
  Widget _buildCasesList() {
    if (_cases.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.gavel,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'Henüz dava eklenmemiş',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Davalarınızı ekleyerek istatistiklerinizi güncelleyin',
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
      onRefresh: _loadCases,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _cases.length,
        itemBuilder: (context, index) {
          CaseModel caseItem = _cases[index];
          
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
                          caseItem.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(caseItem.status).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getStatusText(caseItem.status),
                          style: TextStyle(
                            color: _getStatusColor(caseItem.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    caseItem.description,
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Başlangıç: ${DateFormat('dd.MM.yyyy').format(caseItem.startDate)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (caseItem.endDate != null)
                        Text(
                          'Bitiş: ${DateFormat('dd.MM.yyyy').format(caseItem.endDate!)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showCaseDialog(caseItem: caseItem),
                        tooltip: 'Düzenle',
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDeleteCase(caseItem),
                        tooltip: 'Sil',
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
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'ongoing':
        return Colors.blue;
      case 'won':
        return Colors.green;
      case 'lost':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  
  String _getStatusText(String status) {
    switch (status) {
      case 'ongoing':
        return 'Devam Ediyor';
      case 'won':
        return 'Kazanıldı';
      case 'lost':
        return 'Kaybedildi';
      default:
        return 'Bilinmiyor';
    }
  }
  
  Future<void> _showCaseDialog({CaseModel? caseItem}) async {
    // Düzenleme modunda mı yoksa ekleme modunda mı?
    bool isEditing = caseItem != null;
    
    // Form controller'ları
    final titleController = TextEditingController(text: isEditing ? caseItem.title : '');
    final descriptionController = TextEditingController(text: isEditing ? caseItem.description : '');
    
    // Tarih seçimleri
    DateTime startDate = isEditing ? caseItem.startDate : DateTime.now();
    DateTime? endDate = isEditing ? caseItem.endDate : null;
    
    // Durum seçimi
    String status = isEditing ? caseItem.status : 'ongoing';
    
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
              title: Text(isEditing ? 'Davayı Düzenle' : 'Yeni Dava Ekle'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Dava Başlığı',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen dava başlığını girin';
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
                      ListTile(
                        title: Text('Başlangıç Tarihi'),
                        subtitle: Text(DateFormat('dd.MM.yyyy').format(startDate)),
                        trailing: Icon(Icons.calendar_today),
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null && picked != startDate) {
                            setState(() {
                              startDate = picked;
                            });
                          }
                        },
                      ),
                      SizedBox(height: 8),
                      ListTile(
                        title: Text('Bitiş Tarihi'),
                        subtitle: Text(endDate != null 
                          ? DateFormat('dd.MM.yyyy').format(endDate) 
                          : 'Seçilmedi'),
                        trailing: Icon(Icons.calendar_today),
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: endDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              endDate = picked;
                            });
                          }
                        },
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Durum',
                          border: OutlineInputBorder(),
                        ),
                        value: status,
                        items: [
                          DropdownMenuItem(
                            value: 'ongoing',
                            child: Text('Devam Ediyor'),
                          ),
                          DropdownMenuItem(
                            value: 'won',
                            child: Text('Kazanıldı'),
                          ),
                          DropdownMenuItem(
                            value: 'lost',
                            child: Text('Kaybedildi'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              status = value;
                              
                              // Eğer durum "devam ediyor" değilse ve bitiş tarihi yoksa, bugünü ekle
                              if (value != 'ongoing' && endDate == null) {
                                endDate = DateTime.now();
                              }
                              
                              // Eğer durum "devam ediyor" ise, bitiş tarihini temizle
                              if (value == 'ongoing') {
                                endDate = null;
                              }
                            });
                          }
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
                        String lawyerId = _auth.currentUser!.uid;
                        
                        if (isEditing) {
                          // Davayı güncelle
                          await _firestoreService.updateCase(
                            caseItem.id,
                            {
                              'title': titleController.text,
                              'description': descriptionController.text,
                              'status': status,
                              'startDate': startDate,
                              'endDate': endDate,
                            },
                          );
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Dava güncellendi')),
                          );
                        } else {
                          // Yeni dava ekle
                          CaseModel newCase = CaseModel(
                            id: '',
                            lawyerId: lawyerId,
                            title: titleController.text,
                            description: descriptionController.text,
                            status: status,
                            startDate: startDate,
                            endDate: endDate,
                          );
                          
                          await _firestoreService.addCase(newCase);
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Dava eklendi')),
                          );
                        }
                        
                        // Dialog'u kapat
                        Navigator.pop(context);
                        
                        // Davaları yeniden yükle
                        _loadCases();
                      } catch (e) {
                        print('Dava kaydetme hatası: $e');
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
  
  Future<void> _confirmDeleteCase(CaseModel caseItem) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Davayı Sil'),
          content: Text('${caseItem.title} davasını silmek istediğinize emin misiniz?'),
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
        await _firestoreService.deleteCase(caseItem.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dava silindi')),
        );
        
        _loadCases();
      } catch (e) {
        print('Dava silme hatası: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: ${e.toString()}')),
        );
      }
    }
  }
}

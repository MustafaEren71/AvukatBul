import 'package:flutter/material.dart';
import 'package:avukatbul/services/firestore_service.dart';
import 'package:avukatbul/models/lawyer_model.dart';
import 'package:avukatbul/screens/client/lawyer_detail_screen.dart';
import 'package:avukatbul/widgets/lawyer_card.dart';
import 'package:avukatbul/screens/common/error_screen.dart';
import 'package:avukatbul/data/cities_data.dart';

class LawyerSearchScreen extends StatefulWidget {
  @override
  _LawyerSearchScreenState createState() => _LawyerSearchScreenState();
}

class _LawyerSearchScreenState extends State<LawyerSearchScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  
  String _selectedCity = '';
  String _selectedDistrict = '';
  List<LawyerModel> _lawyers = [];
  List<LawyerModel> _filteredLawyers = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  List<String> _cities = CityData.getAllCities();
  List<String> _districts = [];
  
  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterLawyers);
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_filterLawyers);
    _searchController.dispose();
    super.dispose();
  }
  
  void _filterLawyers() {
    if (_searchController.text.isEmpty && _selectedDistrict.isEmpty) {
      setState(() {
        _filteredLawyers = List.from(_lawyers);
      });
      return;
    }
    
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredLawyers = _lawyers.where((lawyer) {
        bool matchesName = lawyer.name.toLowerCase().contains(query);
        bool matchesDistrict = _selectedDistrict.isEmpty || lawyer.district == _selectedDistrict;
        
        return matchesName && matchesDistrict;
      }).toList();
    });
  }
  
  void _updateDistricts(String city) {
    setState(() {
      _districts = CityData.getDistrictsOfCity(city);
      _selectedDistrict = '';
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Avukat Ara',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Şehir Seçin',
              prefixIcon: Icon(Icons.location_city),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            value: _selectedCity.isNotEmpty ? _selectedCity : null,
            hint: Text('Şehir seçin'),
            items: _cities.map((city) {
              return DropdownMenuItem(
                value: city,
                child: Text(city),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCity = value!;
                _updateDistricts(value);
                _loadLawyers();
              });
            },
          ),
          SizedBox(height: 16),
          if (_selectedCity.isNotEmpty)
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'İlçe Seçin (Opsiyonel)',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              value: _selectedDistrict.isNotEmpty ? _selectedDistrict : null,
              hint: Text('İlçe seçin (opsiyonel)'),
              items: _districts.map((district) {
                return DropdownMenuItem(
                  value: district,
                  child: Text(district),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDistrict = value ?? '';
                  _filterLawyers();
                });
              },
            ),
          SizedBox(height: 16),
          if (_lawyers.isNotEmpty)
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Avukat Ara',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : null,
              ),
            ),
          SizedBox(height: 16),
          Expanded(
            child: _buildLawyersList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLawyersList() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage != null) {
      return Center(
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
              onPressed: _loadLawyers,
              child: Text('Tekrar Dene'),
            ),
          ],
        ),
      );
    }
    
    if (_selectedCity.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_city,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'Lütfen bir şehir seçin',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }
    
    if (_filteredLawyers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty || _selectedDistrict.isNotEmpty
                ? 'Arama kriterlerine uygun avukat bulunamadı'
                : 'Seçilen şehirde avukat bulunamadı',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () => _loadLawyers(),
      child: ListView.builder(
        itemCount: _filteredLawyers.length,
        itemBuilder: (context, index) {
          return LawyerCard(
            lawyer: _filteredLawyers[index],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LawyerDetailScreen(
                    lawyerId: _filteredLawyers[index].id,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
  
  Future<void> _loadLawyers() async {
    if (_selectedCity.isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      List<LawyerModel> lawyers = await _firestoreService.getLawyersByCity(_selectedCity);
      setState(() {
        _lawyers = lawyers;
        _filteredLawyers = List.from(lawyers);
        _isLoading = false;
      });
    } catch (e) {
      print('Avukat listesi yükleme hatası: $e');
      setState(() {
        _errorMessage = 'Avukatlar yüklenirken bir hata oluştu: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:avukatbul/services/firestore_service.dart';
import 'package:avukatbul/models/lawyer_model.dart';
import 'package:avukatbul/models/user_model.dart';
import 'package:avukatbul/models/package_model.dart';
import 'package:avukatbul/models/rating_model.dart';
import 'package:avukatbul/screens/common/chat_screen.dart';
import 'package:avukatbul/screens/client/package_purchase_screen.dart';
import 'package:avukatbul/screens/client/rating_screen.dart';
import 'package:avukatbul/widgets/rating_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class LawyerDetailScreen extends StatefulWidget {
  final String lawyerId;
  
  const LawyerDetailScreen({
    Key? key,
    required this.lawyerId,
  }) : super(key: key);
  
  @override
  _LawyerDetailScreenState createState() => _LawyerDetailScreenState();
}

class _LawyerDetailScreenState extends State<LawyerDetailScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  late TabController _tabController;
  
  bool _isLoading = true;
  String? _errorMessage;
  LawyerModel? _lawyer;
  UserModel? _lawyerUser;
  List<PackageModel> _packages = [];
  List<RatingModel> _ratings = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadLawyerDetails();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadLawyerDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Avukat bilgilerini getir
      LawyerModel? lawyer = await _firestoreService.getLawyerById(widget.lawyerId);
      
      if (lawyer == null) {
        setState(() {
          _errorMessage = 'Avukat bilgileri bulunamadı';
          _isLoading = false;
        });
        return;
      }
      
      // Avukatın kullanıcı bilgilerini getir
      UserModel? lawyerUser = await _firestoreService.getUserById(widget.lawyerId);
      
      if (lawyerUser == null) {
        setState(() {
          _errorMessage = 'Avukat kullanıcı bilgileri bulunamadı';
          _isLoading = false;
        });
        return;
      }
      
      // Avukatın paketlerini getir
      List<PackageModel> packages = await _firestoreService.getPackagesByLawyerId(widget.lawyerId);
      
      // Sadece aktif paketleri göster
      packages = packages.where((package) => package.isActive).toList();
      
      // Avukatın değerlendirmelerini getir
      List<RatingModel> ratings = await _firestoreService.getRatingsByLawyerId(widget.lawyerId);
      
      setState(() {
        _lawyer = lawyer;
        _lawyerUser = lawyerUser;
        _packages = packages;
        _ratings = ratings;
        _isLoading = false;
      });
    } catch (e) {
      print('Avukat detayları yükleme hatası: $e');
      setState(() {
        _errorMessage = 'Avukat bilgileri yüklenirken bir hata oluştu: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Avukat Detayları'),
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
                    onPressed: _loadLawyerDetails,
                    child: Text('Tekrar Dene'),
                  ),
                ],
              ),
            )
          : _buildLawyerDetails(),
    );
  }
  
  Widget _buildLawyerDetails() {
    return Column(
      children: [
        // Avukat profil başlığı
        Container(
          padding: EdgeInsets.all(16),
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Column(
            children: [
              _buildProfileImage(),
              SizedBox(height: 16),
              Text(
                _lawyer!.name.isNotEmpty ? _lawyer!.name : 'İsimsiz Avukat',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
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
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.message),
                      label: Text('Mesaj Gönder'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              receiverId: widget.lawyerId,
                              receiverName: _lawyer!.name,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.star),
                      label: Text('Değerlendir'),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RatingScreen(
                              lawyerId: widget.lawyerId,
                              lawyerName: _lawyer!.name,
                            ),
                          ),
                        ).then((_) => _loadLawyerDetails());
                      },
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
            Tab(text: 'Hakkında'),
            Tab(text: 'Hizmetler'),
            Tab(text: 'Değerlendirmeler'),
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
              // Hakkında tab
              _buildAboutTab(),
              
              // Hizmetler tab
              _buildServicesTab(),
              
              // Değerlendirmeler tab
              _buildRatingsTab(),
            ],
          ),
        ),
      ],
    );
  }
  
  // Diğer metotlar...
  
  Widget _buildProfileImage() {
    if (_lawyer!.profileImageUrl != null && _lawyer!.profileImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: CachedNetworkImage(
          imageUrl: _lawyer!.profileImageUrl!,
          width: 80,
          height: 80,
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
      radius: 40,
      backgroundColor: Theme.of(context).primaryColor,
      child: Text(
        _lawyer!.name.isNotEmpty ? _lawyer!.name.substring(0, 1).toUpperCase() : '?',
        style: TextStyle(
          fontSize: 30,
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
  
  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hakkında',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Text(
            _lawyer!.bio.isEmpty
              ? 'Avukat henüz bir biyografi eklememiş.'
              : _lawyer!.bio,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
  
  Widget _buildServicesTab() {
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
              'Henüz hizmet paketi eklenmemiş',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
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
                Text(
                  package.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
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
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PackagePurchaseScreen(
                              package: package,
                              lawyerName: _lawyer!.name,
                            ),
                          ),
                        );
                      },
                      child: Text('Satın Al'),
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
  
  Widget _buildRatingsTab() {
    if (_ratings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_border,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'Henüz değerlendirme yapılmamış',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _ratings.length,
      itemBuilder: (context, index) {
        RatingModel rating = _ratings[index];
        
        return Card(
          elevation: 2,
          margin: EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor,
                      radius: 16,
                      child: Text(
                        rating.userName.isNotEmpty ? rating.userName.substring(0, 1).toUpperCase() : '?',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      rating.userName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    Text(
                      DateFormat('dd.MM.yyyy').format(rating.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                RatingBar(
                  rating: rating.rating,
                  size: 20,
                ),
                SizedBox(height: 8),
                if (rating.comment != null && rating.comment!.isNotEmpty)
                  Text(
                    rating.comment!,
                    style: TextStyle(fontSize: 14),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:avukatbul/services/auth_service.dart';
import 'package:avukatbul/screens/lawyer/lawyer_profile_screen.dart';
import 'package:avukatbul/screens/common/chats_list_screen.dart';
import 'package:avukatbul/screens/lawyer/package_management_screen.dart';
import 'package:avukatbul/screens/lawyer/case_management_screen.dart';
import 'package:avukatbul/screens/auth/login_screen.dart';

class LawyerHomeScreen extends StatefulWidget {
  @override
  _LawyerHomeScreenState createState() => _LawyerHomeScreenState();
}

class _LawyerHomeScreenState extends State<LawyerHomeScreen> {
  int _currentIndex = 0;
  
  late List<Widget> _screens;
  
  final List<String> _titles = [
    'Profil',
    'Mesajlar',
    'Hizmet Paketleri',
    'Davalarım',
  ];
  
  @override
  void initState() {
    super.initState();
    _screens = [
      LawyerProfileScreen(),
      ChatsListScreen(),
      PackageManagementScreen(),
      CaseManagementScreen(),
    ];
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AvukatBul - ${_titles[_currentIndex]}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _signOut,
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Mesajlar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Paketler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.gavel),
            label: 'Davalar',
          ),
        ],
      ),
    );
  }
  
  Future<void> _signOut() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: ${e.toString()}')),
      );
    }
  }
}

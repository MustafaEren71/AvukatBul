import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:avukatbul/services/auth_service.dart';
import 'package:avukatbul/screens/client/lawyer_search_screen.dart';
import 'package:avukatbul/screens/client/client_profile_screen.dart';
import 'package:avukatbul/screens/common/chats_list_screen.dart';
import 'package:avukatbul/screens/auth/login_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  @override
  _ClientHomeScreenState createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  int _currentIndex = 0;
  
  late List<Widget> _screens;
  
  final List<String> _titles = [
    'Avukat Ara',
    'Mesajlar',
    'Profil',
  ];
  
  @override
  void initState() {
    super.initState();
    _screens = [
      LawyerSearchScreen(),
      ChatsListScreen(),
      ClientProfileScreen(),
    ];
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Avukat Ara',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Mesajlar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
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

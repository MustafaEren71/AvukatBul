import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:avukatbul/services/auth_service.dart';
import 'package:avukatbul/services/notification_service.dart';
import 'package:avukatbul/screens/auth/login_screen.dart';
import 'package:avukatbul/screens/auth/verify_email_screen.dart';
import 'package:avukatbul/screens/client/client_home_screen.dart';
import 'package:avukatbul/screens/lawyer/lawyer_home_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    
    // Logo animasyonu için
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    );
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    _animationController.forward();
    
    // Bildirim servisini başlat
    final notificationService = NotificationService();
    notificationService.initialize();
    
    // Kullanıcı durumunu kontrol et
    _checkUserStatus();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  Future<void> _checkUserStatus() async {
    await Future.delayed(Duration(seconds: 3));
    
    if (!mounted) return;
    
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Kullanıcı oturum açmış mı kontrol et
    if (authService.currentUser == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
      return;
    }
    
    // Email doğrulanmış mı kontrol et
    bool isVerified = await authService.checkEmailVerified();
    if (!isVerified) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => VerifyEmailScreen()),
      );
      return;
    }
    
    // Kullanıcı tipini kontrol et
    String userType = await authService.getUserType();
    
    if (userType == 'lawyer') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LawyerHomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ClientHomeScreen()),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _animation,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.gavel,
                      size: 60,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),
              FadeTransition(
                opacity: _animation,
                child: Text(
                  'AvukatBul',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 16),
              FadeTransition(
                opacity: _animation,
                child: Text(
                  'Hukuki Çözüm Ortağınız',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
              SizedBox(height: 48),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

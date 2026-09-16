import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:avukatbul/services/auth_service.dart';
import 'package:avukatbul/screens/client/client_home_screen.dart';
import 'package:avukatbul/screens/lawyer/lawyer_home_screen.dart';
import 'package:avukatbul/screens/auth/login_screen.dart';
import 'package:avukatbul/widgets/custom_button.dart';

class VerifyEmailScreen extends StatefulWidget {
  @override
  _VerifyEmailScreenState createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _isLoading = false;
  Timer? _timer;
  Timer? _countdownTimer;
  int _countDown = 60;
  bool _canResend = false;
  
  @override
  void initState() {
    super.initState();
    _startVerificationCheck();
    _startCountDown();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }
  
  void _startVerificationCheck() {
    _timer = Timer.periodic(Duration(seconds: 3), (timer) async {
      if (!mounted) return;
      
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Kullanıcının email doğrulama durumunu kontrol et
      bool isVerified = await authService.checkEmailVerified();
      
      if (isVerified) {
        _timer?.cancel();
        _countdownTimer?.cancel();
        
        if (!mounted) return;
        
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
    });
  }
  
  void _startCountDown() {
    _countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!mounted) return;
      
      setState(() {
        if (_countDown > 0) {
          _countDown--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Email Doğrulama'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.mark_email_read,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              SizedBox(height: 24),
              Text(
                'Email Adresinizi Doğrulayın',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Kayıt olduğunuz email adresine bir doğrulama bağlantısı gönderdik. Lütfen email adresinizi kontrol edin ve bağlantıya tıklayarak hesabınızı doğrulayın.',
                style: TextStyle(
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Email gelmedi mi? Spam klasörünü kontrol edin.',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              _isLoading
                ? Center(child: CircularProgressIndicator())
                : CustomButton(
                    text: _canResend 
                      ? 'Doğrulama Emailini Tekrar Gönder' 
                      : 'Tekrar Gönder ($_countDown)',
                    onPressed: _canResend ? () => _resendVerificationEmail() : null,
                  ),
              SizedBox(height: 16),
              CustomButton(
                text: 'Doğrulama Durumunu Kontrol Et',
                onPressed: _checkVerificationStatus,
                isOutlined: true,
              ),
              SizedBox(height: 16),
              TextButton(
                onPressed: _signOut,
                child: Text('Çıkış Yap'),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _resendVerificationEmail() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.sendEmailVerification();
      
      if (!mounted) return;
      
      setState(() {
        _countDown = 60;
        _canResend = false;
      });
      
      _startCountDown();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Doğrulama emaili tekrar gönderildi')),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _checkVerificationStatus() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      bool isVerified = await authService.checkEmailVerified();
      
      if (!mounted) return;
      
      if (isVerified) {
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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Email henüz doğrulanmamış. Lütfen email adresinizi kontrol edin.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _signOut() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();
      
      if (!mounted) return;
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: ${e.toString()}')),
      );
    }
  }
}

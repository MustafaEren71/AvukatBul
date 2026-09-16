import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:avukatbul/services/auth_service.dart';
import 'package:avukatbul/widgets/custom_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  
  bool _isLoading = false;
  bool _isEmailSent = false;
  String? _errorMessage;
  
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Şifremi Unuttum'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.lock_reset,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(height: 24),
                Text(
                  'Şifrenizi mi Unuttunuz?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  _isEmailSent
                    ? 'Şifre sıfırlama bağlantısı e-posta adresinize gönderildi. Lütfen e-postanızı kontrol edin.'
                    : 'Kayıt olduğunuz e-posta adresinizi girin. Size şifre sıfırlama bağlantısı göndereceğiz.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                
                // Hata mesajı
                if (_errorMessage != null && !_isEmailSent)
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (_errorMessage != null && !_isEmailSent) SizedBox(height: 24),
                
                // Form
                if (!_isEmailSent)
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'E-posta',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Lütfen e-posta adresinizi girin';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'Geçerli bir e-posta adresi girin';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 24),
                        _isLoading
                          ? CircularProgressIndicator()
                          : CustomButton(
                              text: 'Şifre Sıfırlama Bağlantısı Gönder',
                              onPressed: _resetPassword,
                            ),
                      ],
                    ),
                  ),
                
                // Başarılı mesaj
                if (_isEmailSent)
                  Column(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 64,
                        color: Colors.green,
                      ),
                      SizedBox(height: 24),
                      CustomButton(
                        text: 'Giriş Sayfasına Dön',
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Future<void> _resetPassword() async {
    // Form validasyonu
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Şifre sıfırlama e-postası gönder
      await authService.resetPassword(_emailController.text.trim());
      
      setState(() {
        _isEmailSent = true;
      });
    } catch (e) {
      print('Şifre sıfırlama hatası: $e');
      
      String errorMessage = 'Şifre sıfırlama bağlantısı gönderilirken bir hata oluştu';
      
      if (e is Exception) {
        if (e.toString().contains('user-not-found')) {
          errorMessage = 'Bu e-posta adresiyle kayıtlı bir kullanıcı bulunamadı';
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = 'Geçersiz e-posta adresi';
        }
      }
      
      setState(() {
        _errorMessage = errorMessage;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

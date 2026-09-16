import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:avukatbul/services/auth_service.dart';
import 'package:avukatbul/screens/auth/verify_email_screen.dart';
import 'package:avukatbul/widgets/custom_button.dart';

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _cityController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLawyer = false;
  String? _errorMessage;
  
  List<String> _cities = [
    'İstanbul', 'Ankara', 'İzmir', 'Bursa', 'Antalya', 'Adana', 'Konya',
    'Gaziantep', 'Şanlıurfa', 'Kocaeli', 'Mersin', 'Diyarbakır', 'Hatay',
    'Manisa', 'Kayseri', 'Samsun', 'Balıkesir', 'Kahramanmaraş', 'Van',
    'Aydın', 'Denizli', 'Sakarya', 'Tekirdağ', 'Muğla', 'Eskişehir',
    'Mardin', 'Malatya', 'Trabzon', 'Erzurum', 'Ordu'
  ];
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _cityController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kayıt Ol'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                Icon(
                  Icons.gavel,
                  size: 64,
                  color: Theme.of(context).primaryColor,
                ),
                SizedBox(height: 16),
                Text(
                  'AvukatBul\'a Hoş Geldiniz',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Hesabınızı oluşturun',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                
                // Hata mesajı
                if (_errorMessage != null)
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
                if (_errorMessage != null) SizedBox(height: 24),
                
                // Kayıt formu
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Ad Soyad',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen adınızı ve soyadınızı girin';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
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
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Şifre',
                          prefixIcon: Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen şifre girin';
                          }
                          if (value.length < 6) {
                            return 'Şifre en az 6 karakter olmalıdır';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Şifre (Tekrar)',
                          prefixIcon: Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        obscureText: _obscureConfirmPassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen şifrenizi tekrar girin';
                          }
                          if (value != _passwordController.text) {
                            return 'Şifreler eşleşmiyor';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Şehir',
                          prefixIcon: Icon(Icons.location_city),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        value: _cityController.text.isNotEmpty ? _cityController.text : null,
                        hint: Text('Şehir seçin'),
                        items: _cities.map((city) {
                          return DropdownMenuItem(
                            value: city,
                            child: Text(city),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _cityController.text = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Lütfen şehir seçin';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      SwitchListTile(
                        title: Text('Avukat olarak kaydol'),
                        subtitle: Text('Avukat iseniz bu seçeneği işaretleyin'),
                        value: _isLawyer,
                        onChanged: (value) {
                          setState(() {
                            _isLawyer = value;
                          });
                        },
                        activeColor: Theme.of(context).primaryColor,
                      ),
                      SizedBox(height: 24),
                      _isLoading
                        ? CircularProgressIndicator()
                        : CustomButton(
                            text: 'Kayıt Ol',
                            onPressed: _register,
                          ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Zaten hesabınız var mı?'),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('Giriş Yap'),
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
  
  Future<void> _register() async {
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
      
      // Kayıt ol
      await authService.registerWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        isLawyer: _isLawyer,
        city: _cityController.text,
      );
      
      // Email doğrulama ekranına yönlendir
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => VerifyEmailScreen()),
      );
    } catch (e) {
      print('Kayıt hatası: $e');
      
      String errorMessage = 'Kayıt olurken bir hata oluştu';
      
      if (e is Exception) {
        if (e.toString().contains('email-already-in-use')) {
          errorMessage = 'Bu e-posta adresi zaten kullanılıyor';
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = 'Geçersiz e-posta adresi';
        } else if (e.toString().contains('weak-password')) {
          errorMessage = 'Şifre çok zayıf';
        } else if (e.toString().contains('operation-not-allowed')) {
          errorMessage = 'Bu işlem şu anda kullanılamıyor';
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

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'package:avukatbul/screens/common/splash_screen.dart';
import 'package:avukatbul/services/auth_service.dart';
import 'package:avukatbul/utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase'i başlat
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Tarih formatlaması için Türkçe desteği
  await initializeDateFormatting('tr_TR', null);
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: MaterialApp(
        title: 'AvukatBul',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: SplashScreen(),
      ),
    );
  }
}

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  
  factory NotificationService() {
    return _instance;
  }
  
  NotificationService._internal();
  
  Future<void> initialize() async {
    // İzinleri iste
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Bildirim izinleri alındı');
      
      // FCM token al
      String? token = await _messaging.getToken();
      print('FCM Token: $token');
      
      // Token'ı Firestore'a kaydet
      await _saveTokenToFirestore(token);
      
      // Yerel bildirimler için başlatma
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
          // Bildirime tıklandığında yapılacak işlemler
          print('Bildirime tıklandı: ${response.payload}');
          // Burada yönlendirme yapılabilir
        },
      );
      
      // Android için bildirim kanalı oluştur
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        importance: Importance.high,
        playSound: true,
      );
      
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      
      // Ön planda bildirim gösterme
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showLocalNotification(message);
      });
      
      // Arka planda bildirime tıklandığında
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('Arka planda bildirime tıklandı: ${message.data}');
        // Burada yönlendirme yapılabilir
      });
      
      // Token yenilendiğinde
      _messaging.onTokenRefresh.listen((newToken) {
        _saveTokenToFirestore(newToken);
      });
    }
  }
  
  Future<void> _saveTokenToFirestore(String? token) async {
    if (token == null) return;
    
    User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    }
  }
  
  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;
    
    if (notification != null && android != null) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data['route'],
      );
    }
  }
  
  // Belirli bir kullanıcıya bildirim gönderme (Cloud Functions ile kullanılacak)
  Future<void> sendNotificationToUser(String userId, String title, String body, Map<String, dynamic> data) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists) {
        String? fcmToken = userDoc.get('fcmToken');
        if (fcmToken != null && fcmToken.isNotEmpty) {
          // Cloud Functions ile bildirim gönderme işlemi yapılacak
          print('FCM Token: $fcmToken, Title: $title, Body: $body, Data: $data');
        }
      }
    } catch (e) {
      print('Bildirim gönderme hatası: $e');
    }
  }
}

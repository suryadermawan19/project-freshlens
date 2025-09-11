// lib/service/notification_service.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Inisialisasi untuk iOS
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Konfigurasi Notifikasi Lokal untuk Android (agar notifikasi muncul saat app di foreground)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Listener untuk notifikasi yang masuk saat aplikasi di foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Menerima notifikasi saat aplikasi di foreground: ${message.notification?.title}');
      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });
  }
  
  void _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
        'high_importance_channel', // ID Channel
        'High Importance Notifications', // Nama Channel
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false,
      );
    const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await _flutterLocalNotificationsPlugin.show(
      0, // ID Notifikasi
      message.notification!.title,
      message.notification!.body,
      platformChannelSpecifics,
      payload: 'item x',
    );
}


  Future<void> requestPermissions() async {
    await _firebaseMessaging.requestPermission();
  }
  
  // Method untuk mendapatkan FCM token
  Future<String?> getToken() async {
    final token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');
    return token;
  }
}
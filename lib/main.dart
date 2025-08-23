// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // <-- Import Firebase Core
import 'firebase_options.dart'; // <-- Import file yang digenerate FlutterFire
import 'login_screen.dart';


// Ubah 'main' menjadi async
Future<void> main() async {
  // Pastikan semua plugin terinisialisasi sebelum menjalankan aplikasi
  WidgetsFlutterBinding.ensureInitialized();
  // Inisialisasi Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const FreshLensApp());
}

class FreshLensApp extends StatelessWidget {
  const FreshLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FreshLens AI',
      theme: ThemeData(primarySwatch: Colors.green, fontFamily: 'Poppins'),
      home: const LoginScreen(),
    );
  }
}

// lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:freshlens_ai_app/theme_provider.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // Bungkus aplikasi dengan ThemeProvider
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const FreshLensApp(),
    ),
  );
}

class FreshLensApp extends StatelessWidget {
  const FreshLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Gunakan Consumer untuk mendapatkan state tema saat ini
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'FreshLens AI',
          // Tentukan tema terang dan gelap
          theme: ThemeData(
            primarySwatch: Colors.green,
            fontFamily: 'Poppins',
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFFAF8F1),
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.green,
            fontFamily: 'Poppins',
            brightness: Brightness.dark,
            // Anda bisa menyesuaikan warna dark mode di sini
          ),
          // Atur themeMode dari provider
          themeMode: themeProvider.themeMode,
          home: const LoginScreen(),
        );
      },
    );
  }
}
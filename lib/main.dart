// lib/main.dart (REVISI FINAL DENGAN FIX)

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:freshlens_ai_app/providers/loading_provider.dart';
import 'package:freshlens_ai_app/service/notification_service.dart';
import 'package:freshlens_ai_app/theme_provider.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'login_screen.dart';

// Definisikan palet warna utama di sini agar mudah diakses
class AppColors {
  static const Color primaryGreen = Color(0xFF5D8A41);
  static const Color backgroundCream = Color(0xFFFAF8F1);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1E1E1E);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  await NotificationService().requestPermissions();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => LoadingProvider()),
      ],
      child: const FreshLensApp(),
    ),
  );
}

class FreshLensApp extends StatelessWidget {
  const FreshLensApp({super.key});

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    
    final baseTheme = ThemeData(
      brightness: brightness,
      fontFamily: 'Poppins',
      primaryColor: AppColors.primaryGreen,
      // PERBAIKAN 2: Hapus properti 'background' yang sudah usang dari ColorScheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryGreen,
        brightness: brightness,
      ),
      scaffoldBackgroundColor: isDark ? AppColors.darkBackground : AppColors.backgroundCream,
    );

    return baseTheme.copyWith(
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      // PERBAIKAN 1: Gunakan CardThemeData, bukan CardTheme
      cardTheme: CardThemeData(
        elevation: 1,
        margin: EdgeInsets.zero,
        color: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          side: isDark ? BorderSide(color: Colors.grey.shade800) : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkCard : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      textTheme: baseTheme.textTheme.copyWith(
        headlineMedium: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        titleLarge: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        titleMedium: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        bodyLarge: const TextStyle(fontSize: 16),
        bodyMedium: const TextStyle(fontSize: 14),
      ).apply(
        bodyColor: isDark ? Colors.white : Colors.black87,
        displayColor: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'FreshLens AI',
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          themeMode: themeProvider.themeMode,
          home: const LoginScreen(),
        );
      },
    );
  }
}
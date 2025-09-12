
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:freshlens_ai_app/onboarding_screen.dart';
import 'package:freshlens_ai_app/providers/loading_provider.dart';
import 'package:freshlens_ai_app/service/notification_service.dart'; 
import 'package:freshlens_ai_app/theme_provider.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freshlens_ai_app/service/firestore_service.dart';

class AppColors {
  static const Color primaryGreen = Color(0xFF5D8A41);
  static const Color backgroundCream = Color(0xFFFAF8F1);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1E1E1E);
  static const Color darkText = Color(0xFFEFEFEF);
  static const Color lightText = Color(0xFF333333);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.requestPermissions();
  FirebaseAuth.instance.authStateChanges().listen((user) {
    if (user != null) {
      notificationService.getToken().then((token) {
        FirestoreService().saveUserToken(token);
      });
    }
  });

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

  // [LANGKAH 1.2] Buat fungsi untuk membangun tema (light & dark).
  ThemeData _buildTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final Color textColor = isDark ? AppColors.darkText : AppColors.lightText;

    final baseTheme = ThemeData(
      brightness: brightness,
      fontFamily: 'Montserrat', // Set font default
      primaryColor: AppColors.primaryGreen,
      scaffoldBackgroundColor:
          isDark ? AppColors.darkBackground : AppColors.backgroundCream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryGreen,
        brightness: brightness,
        primary: AppColors.primaryGreen, // Pastikan warna utama tetap
      ),
      // [LANGKAH 1.3] Atur TEXT THEME secara global.
      textTheme: TextTheme(
        displayLarge: TextStyle(fontFamily: 'Montserrat', color: textColor, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(fontFamily: 'Montserrat', color: textColor, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(fontFamily: 'Montserrat', color: textColor, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(fontFamily: 'Montserrat', color: textColor, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontFamily: 'Montserrat', color: textColor, fontWeight: FontWeight.bold, fontSize: 24),
        headlineSmall: TextStyle(fontFamily: 'Montserrat', color: textColor, fontWeight: FontWeight.w600, fontSize: 20),
        titleLarge: TextStyle(fontFamily: 'Montserrat', color: textColor, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontFamily: 'Montserrat', color: textColor, fontSize: 16),
        bodyMedium: TextStyle(fontFamily: 'Montserrat', color: textColor, fontSize: 14),
        labelLarge: const TextStyle(fontFamily: 'Montserrat', fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
    
    // [LANGKAH 1.4] Atur tema spesifik untuk widget.
    return baseTheme.copyWith(
      // Tema untuk Tombol
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // Tema untuk Kartu
      cardTheme: CardThemeData(
        elevation: 2,
        margin: EdgeInsets.zero,
        color: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      // Tema untuk AppBar
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Montserrat',
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      // Tema untuk Input Field (TextFormField)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.darkCard : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryGreen, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Consumer digunakan untuk mendengarkan perubahan tema (light/dark)
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'FreshLens AI',
          theme: _buildTheme(Brightness.light),      // Tema terang
          darkTheme: _buildTheme(Brightness.dark),   // Tema gelap
          themeMode: themeProvider.themeMode,        // Mode tema saat ini
          home: const OnboardingScreen(),            // Memulai aplikasi dari OnboardingScreen
        );
      },
    );
  }
}
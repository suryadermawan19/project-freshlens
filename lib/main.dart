// lib/main.dart (REVISI FINAL FIX)

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:freshlens_ai_app/theme_provider.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

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
    final elevatedButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF5D8A41),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        fontFamily: 'Poppins',
      ),
    );

    // --- PERBAIKAN: gunakan CardThemeData, bukan CardTheme ---
    const cardThemeData = CardThemeData(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      clipBehavior: Clip.antiAlias,
    );

    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'FreshLens AI',
          theme: ThemeData(
            primarySwatch: Colors.green,
            fontFamily: 'Poppins',
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFFAF8F1),
            elevatedButtonTheme:
                ElevatedButtonThemeData(style: elevatedButtonStyle),
            cardTheme: cardThemeData, // <-- FIXED
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.green,
            fontFamily: 'Poppins',
            brightness: Brightness.dark,
            elevatedButtonTheme:
                ElevatedButtonThemeData(style: elevatedButtonStyle),
            cardTheme: cardThemeData, // <-- FIXED
          ),
          themeMode: themeProvider.themeMode,
          home: const LoginScreen(),
        );
      },
    );
  }
}

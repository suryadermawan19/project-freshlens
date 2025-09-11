// lib/onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:freshlens_ai_app/login_screen.dart';
import 'package:freshlens_ai_app/register_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Pastikan status bar terlihat di atas
    return Scaffold(
      body: Stack(
        children: [
          // Latar belakang dengan gradient atau warna dasar
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF7F7F7), // Warna agak krem di atas
                  Color(0xFFD4EDBF), // Warna hijau muda di bawah
                ],
              ),
            ),
          ),
          
          // [BARU] Gambar latar belakang gelombang di bagian bawah
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/onboarding_illustration.png', // Ganti dengan path ilustrasi gelombang Anda
              fit: BoxFit.cover, // Menutupi lebar
              alignment: Alignment.bottomCenter,
            ),
          ),

          // Konten utama (Logo, Teks, Tombol)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Pusatkan vertikal
                children: [
                  const Spacer(flex: 2), // Dorong ke bawah dari atas
                  
                  // [BARU] Logo Aplikasi (pastikan logo FreshLens ada di assets/images/logo.png)
                  Image.asset(
                    'assets/images/logo.png', // Sesuaikan dengan path logo aplikasi Anda
                    width: 150, // Ukuran logo yang lebih besar
                    height: 150,
                  ),
                  const SizedBox(height: 16),
                  
                  // [BARU] Nama Aplikasi
                  Text(
                    'FreshLens',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF333333), // Warna teks agar terlihat jelas
                        ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Slogan atau Deskripsi Singkat
                  Text(
                    'Jaga kesegaran, kurangi limbah.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[700],
                        ),
                  ),
                  
                  const Spacer(flex: 3), // Dorong ke atas dari bawah
                  
                  // Tombol Masuk
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).primaryColor, // Menggunakan warna utama tema
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('MASUK'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Tombol Daftar
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Theme.of(context).primaryColor, width: 2), // Warna border sesuai tema
                        foregroundColor: Theme.of(context).primaryColor,
                      ),
                      child: const Text('DAFTAR'),
                    ),
                  ),
                  const Spacer(), // Sedikit ruang di bawah tombol
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
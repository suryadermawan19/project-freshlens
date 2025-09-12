// lib/welcome_screen.dart

import 'package:flutter/material.dart';
import 'package:freshlens_ai_app/login_screen.dart'; // Navigasi ke layar Login
import 'package:freshlens_ai_app/register_screen.dart'; // Navigasi ke layar Register
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // [LANGKAH 3.1] Gunakan Stack untuk menumpuk background dan konten
      body: Stack(
        fit: StackFit.expand, // Membuat Stack mengisi seluruh layar
        children: [
          // Lapisan Bawah: Gambar Latar Belakang
          Image.asset(
            'assets/images/welcome_background.png',
            fit: BoxFit.cover, // Memastikan gambar menutupi seluruh area
          ),

          // Lapisan Atas: Konten Utama
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // [LANGKAH 3.2] Bagian Atas: Logo dan Judul
                  Column(
                    children: [
                      Image.asset(
                        'assets/images/logo.png', // Pastikan nama file logo sesuai
                        height: 60,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'FreshLens',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  // [LANGKAH 3.3] Bagian Bawah: Tombol Aksi
                  Column(
                    children: [
                      // Tombol Masuk
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        },
                        // Style tombol sudah diatur di main.dart, kita hanya perlu override
                        // jika ada yang berbeda, seperti warna.
                        child: const Text('MASUK'),
                      ),
                      const SizedBox(height: 16),
                      // Tombol Daftar
                      OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegisterScreen()),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white, // Warna teks
                          side: const BorderSide(color: Colors.white, width: 2), // Garis tepi
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontFamily: 'Montserrat',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          )
                        ),
                        child: const Text('DAFTAR'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
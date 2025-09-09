// lib/register_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_profile_screen.dart'; // <-- 1. IMPORT SCREEN BARU

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signUp() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password dan konfirmasi password tidak cocok.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        // 2. UBAH NAVIGASI KE CreateProfileScreen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const CreateProfileScreen()), // <-- PERUBAHAN DI SINI
          (Route<dynamic> route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Terjadi kesalahan, silakan coba lagi.';
      if (e.code == 'weak-password') {
        errorMessage = 'Password yang dimasukkan terlalu lemah.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Alamat email ini sudah terdaftar.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Format email tidak valid.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ... (Sisa kode build UI di bawah ini tidak ada yang berubah)
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F1),
      body: Stack(
        children: [
          Positioned(
            top: -size.height * 0.15,
            left: -size.width * 0.4,
            child: Container(
              width: size.width * 0.9,
              height: size.height * 0.5,
              decoration: BoxDecoration(
                color: const Color(0xFF5D8A41).withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: size.height * 0.1),
                    const Icon(Icons.eco_outlined, size: 80, color: Color(0xFF5D8A41)),
                    const SizedBox(height: 8),
                    const Text('FreshLens', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF4E5D49))),
                    const SizedBox(height: 40),
                    const Text('Buat Akun Baru', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _buildInputDecoration('Email', Icons.email_outlined),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: _buildInputDecoration('Password', Icons.lock_outline),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: _buildInputDecoration('Konfirmasi Password', Icons.lock_outline_rounded),
                    ),
                    const SizedBox(height: 32),

                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _signUp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5D8A41),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: const Text('DAFTAR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Sudah punya akun?"),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Masuk'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey.shade300)),
    );
  }
}
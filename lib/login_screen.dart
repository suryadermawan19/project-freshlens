// lib/login_screen.dart (REVISI LENGKAP DENGAN PROVIDER)

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freshlens_ai_app/providers/loading_provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart'; // <-- 1. IMPORT PROVIDER
import 'dashboard_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  // bool _isLoading = false; // <-- 2. HAPUS STATE LOKAL

  // Login Email & Password
  Future<void> _signInWithEmail() async {
    // 3. PANGGIL LOADINGPROVIDER
    final loadingProvider = Provider.of<LoadingProvider>(context, listen: false);
    loadingProvider.startLoading();
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Terjadi kesalahan, silakan coba lagi.';
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        errorMessage = 'Email atau password yang dimasukkan salah.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Format email tidak valid.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } finally {
      loadingProvider.stopLoading(); // Hentikan loading, apapun hasilnya
    }
  }

  // Login Google
  Future<void> _signInWithGoogle() async {
    final loadingProvider = Provider.of<LoadingProvider>(context, listen: false);
    loadingProvider.startLoading();
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: [
          'email',
          'https://www.googleapis.com/auth/userinfo.profile',
        ],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        loadingProvider.stopLoading(); // Hentikan jika pengguna membatalkan
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal login dengan Google. Silakan coba lagi.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      loadingProvider.stopLoading();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // 4. GUNAKAN CONSUMER UNTUK MENDENGARKAN PERUBAHAN
    return Consumer<LoadingProvider>(
      builder: (context, loadingProvider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFFAF8F1),
          body: Stack(
            children: [
              Positioned(
                top: -size.height * 0.15,
                right: -size.width * 0.4,
                child: Container(
                  width: size.width * 0.9,
                  height: size.height * 0.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5D8A41).withAlpha(77),
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
                        const Icon(Icons.eco_outlined,
                            size: 80, color: Color(0xFF5D8A41)),
                        const SizedBox(height: 8),
                        const Text(
                          'FreshLens',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4E5D49)),
                        ),
                        const SizedBox(height: 40),
                        const Text(
                          'Selamat Datang!',
                          style:
                              TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration:
                              _buildInputDecoration('Email', Icons.person_outline),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration:
                              _buildInputDecoration('Password', Icons.lock_outline),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                              onPressed: () {}, child: const Text('Lupa Password?')),
                        ),
                        const SizedBox(height: 24),
                        // 5. TAMPILKAN LOADING BERDASARKAN PROVIDER
                        loadingProvider.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                                onPressed: _signInWithEmail,
                                child: const Text('MASUK'),
                              ),
                        const SizedBox(height: 32),
                        const Row(
                          children: [
                            Expanded(child: Divider()),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text('Atau Masuk dengan'),
                            ),
                            Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildSocialButton(FontAwesomeIcons.facebook, () {}),
                            const SizedBox(width: 16),
                            _buildSocialButton(
                                FontAwesomeIcons.google, _signInWithGoogle),
                            const SizedBox(width: 16),
                            _buildSocialButton(FontAwesomeIcons.apple, () {}),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Belum punya akun?"),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const RegisterScreen()),
                                );
                              },
                              child: const Text('Daftar'),
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
      },
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: FaIcon(icon, size: 20),
    );
  }
}
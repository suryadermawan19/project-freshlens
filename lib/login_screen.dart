// lib/login_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freshlens_ai_app/providers/loading_provider.dart';
import 'package:provider/provider.dart';
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
  bool _obscureText = true;

  // --- LOGIKA AUTENTIKASI ---
  Future<void> _signInWithEmail() async {
    final loadingProvider = Provider.of<LoadingProvider>(context, listen: false);
    loadingProvider.startLoading();
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;
      navigator.pushReplacement(
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Terjadi kesalahan, silakan coba lagi.';
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        errorMessage = 'Email atau password yang dimasukkan salah.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Format email tidak valid.';
      }
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } finally {
      loadingProvider.stopLoading();
    }
  }

  // --- Fungsi untuk dialog Lupa Password ---
  Future<void> _showForgotPasswordDialog() async {
    final TextEditingController emailController = TextEditingController();
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('Masukkan alamat email Anda untuk menerima tautan reset password.'),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'Email'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Kirim'),
              onPressed: () async {
                final String email = emailController.text.trim();
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                if (email.isNotEmpty) {
                  try {
                    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                    if (!mounted) return;
                    navigator.pop();
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Tautan reset password telah dikirim. Silakan periksa email Anda.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } on FirebaseAuthException catch (e) {
                    if (!mounted) return;
                    navigator.pop();
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Gagal mengirim: ${e.message}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LoadingProvider>(
      builder: (context, loadingProvider, child) {
        // Tambah gradient background
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.green.shade50,
                Colors.green.shade200,
              ],
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    BackButton(onPressed: () => Navigator.pop(context)),
                    const SizedBox(height: 32),
                    Text('Selamat Datang!', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 8),
                    Text(
                      'Silakan masuk untuk melanjutkan',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscureText,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          ),
                          onPressed: () => setState(() {
                            _obscureText = !_obscureText;
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        child: const Text('Lupa Password?'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: loadingProvider.isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              onPressed: _signInWithEmail,
                              child: const Text('MASUK'),
                            ),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Belum punya akun?"),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterScreen()),
                            );
                          },
                          child: const Text('Daftar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// lib/login_screen.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:freshlens_ai_app/providers/loading_provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
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
    // Amankan context sebelum await
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

  Future<void> _signInWithGoogle() async {
    final loadingProvider = Provider.of<LoadingProvider>(context, listen: false);
    loadingProvider.startLoading();
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        loadingProvider.stopLoading();
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;
      navigator.pushReplacement(
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Gagal login dengan Google. Silakan coba lagi.'),
          backgroundColor: Colors.red,
        ),
      );
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

  // Fungsi untuk dialog Lupa Password
  Future<void> _showForgotPasswordDialog() async {
    final TextEditingController emailController = TextEditingController();
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
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
                  decoration: const InputDecoration(
                    hintText: 'Email',
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Kirim'),
              onPressed: () async {
                final String email = emailController.text.trim();
                // Amankan context sebelum await
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                if (email.isNotEmpty) {
                  try {
                    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
                    if (!mounted) return;
                    navigator.pop(); // Tutup dialog
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
  Widget build(BuildContext context) {
    return Consumer<LoadingProvider>(
      builder: (context, loadingProvider, child) {
        return Scaffold(
          body: Stack(
            children: [
              Positioned(
                top: -100,
                right: -120,
                child: Container(
                  width: 300,
                  height: 400,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withAlpha(38),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      BackButton(
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Selamat Datang!',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Silakan masuk untuk melanjutkan',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
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
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
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
                      const SizedBox(height: 32),
                      _buildDivider(),
                      const SizedBox(height: 24),
                      Center(
                        child: OutlinedButton.icon(
                          onPressed: _signInWithGoogle,
                          icon: const FaIcon(FontAwesomeIcons.google, size: 18),
                          label: const Text('Masuk dengan Google'),
                          style: OutlinedButton.styleFrom(
                             padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                             side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                             foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Atau masuk dengan',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
// lib/create_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:freshlens_ai_app/service/firestore_service.dart';
import 'dashboard_screen.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _occupationController = TextEditingController();
  
  final _firestoreService = FirestoreService();
  bool _isLoading = false;

  Future<void> _submitProfile() async {
    // Validasi form terlebih dahulu
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Panggil service untuk membuat profil di Firestore
      await _firestoreService.createUserProfile(
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        occupation: _occupationController.text.trim(),
      );

      if (mounted) {
        // Arahkan ke dasbor dan hapus semua rute sebelumnya (login/register/create profile)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan profil: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _occupationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F1),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: size.height * 0.1),
                  const Icon(Icons.person_add_alt_1_outlined, size: 80, color: Color(0xFF5D8A41)),
                  const SizedBox(height: 16),
                  const Text(
                    'Satu Langkah Lagi!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF4E5D49)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Lengkapi profil Anda untuk memulai.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 40),
                  
                  // Form Input Nama
                  TextFormField(
                    controller: _nameController,
                    decoration: _buildInputDecoration('Nama Lengkap', Icons.person_outline),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Form Input Umur
                  TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: _buildInputDecoration('Umur', Icons.cake_outlined),
                     validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Umur tidak boleh kosong';
                      }
                      if (int.tryParse(value) == null) {
                        return 'Masukkan angka yang valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Form Input Pekerjaan
                  TextFormField(
                    controller: _occupationController,
                    decoration: _buildInputDecoration('Pekerjaan', Icons.work_outline),
                     validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Pekerjaan tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),

                  // Tombol Submit
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _submitProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5D8A41),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('SIMPAN & MULAI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                ],
              ),
            ),
          ),
        ),
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
// lib/edit_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:freshlens_ai_app/service/firestore_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _occupationController = TextEditingController();
  
  final _firestoreService = FirestoreService();
  bool _isLoading = false;

  // Variabel untuk menampung data awal
  Map<String, dynamic>? _initialData;

  @override
  void initState() {
    super.initState();
    // Ambil data profil saat ini untuk ditampilkan di form
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final userDoc = await _firestoreService.getUserProfile().first;
    if (userDoc.exists) {
      _initialData = userDoc.data() as Map<String, dynamic>;
      // Isi controller dengan data yang sudah ada
      _nameController.text = _initialData?['name'] ?? '';
      _ageController.text = _initialData?['age']?.toString() ?? '';
      _occupationController.text = _initialData?['occupation'] ?? '';
    }
  }

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Siapkan data yang akan di-update
      final Map<String, dynamic> updatedData = {
        'name': _nameController.text.trim(),
        'age': int.parse(_ageController.text.trim()),
        'occupation': _occupationController.text.trim(),
      };

      // Panggil service untuk update profil
      await _firestoreService.updateUserProfile(updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui!'), backgroundColor: Colors.green),
        );
        // Kembali ke halaman profil setelah berhasil
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui profil: $e'), backgroundColor: Colors.red),
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
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F1),
      appBar: AppBar(
        title: const Text('Edit Profil'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                        onPressed: _submitUpdate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5D8A41),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text('SIMPAN PERUBAHAN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
              ],
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
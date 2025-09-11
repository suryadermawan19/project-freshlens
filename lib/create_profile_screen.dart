// lib/create_profile_screen.dart

import 'package:flutter/material.dart';
import 'package:freshlens_ai_app/dashboard_screen.dart';
import 'package:freshlens_ai_app/providers/loading_provider.dart';
import 'package:freshlens_ai_app/service/firestore_service.dart';
import 'package:provider/provider.dart';

class CreateProfileScreen extends StatefulWidget {
  final String name;

  const CreateProfileScreen({super.key, required this.name});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  late final TextEditingController _nameController;
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    // Isi otomatis nama dari halaman registrasi
    _nameController = TextEditingController(text: widget.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _occupationController.dispose();
    super.dispose();
  }

  Future<void> _saveProfileAndContinue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final loadingProvider = Provider.of<LoadingProvider>(context, listen: false);
    loadingProvider.startLoading();

    try {
      await _firestoreService.createUserProfile(
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text.trim()),
        occupation: _occupationController.text.trim(),
      );

      if (mounted) {
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
      loadingProvider.stopLoading();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lengkapi Profil Anda'),
        automaticallyImplyLeading: false, // Sembunyikan tombol kembali
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Satu langkah lagi!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Bantu kami mengenal Anda lebih baik untuk memberikan pengalaman yang lebih personal.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 40),

              // Form Nama
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Form Usia
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Usia'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Usia tidak boleh kosong';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Masukkan angka yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Form Pekerjaan
              TextFormField(
                controller: _occupationController,
                decoration: const InputDecoration(labelText: 'Pekerjaan'),
                 validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Pekerjaan tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 40),

              // Tombol Simpan
              Consumer<LoadingProvider>(
                builder: (context, loadingProvider, child) {
                  return loadingProvider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _saveProfileAndContinue,
                          child: const Text('SIMPAN & MULAI'),
                        );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
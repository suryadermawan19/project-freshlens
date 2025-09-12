// lib/edit_profile_screen.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:freshlens_ai_app/providers/loading_provider.dart';
import 'package:freshlens_ai_app/service/firestore_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();

  String? _currentImageUrl;
  File? _selectedImageFile;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _occupationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        _selectedImageFile = File(pickedFile.path);
      });
    }
  }
  
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                _pickImage(ImageSource.gallery);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Ambil Foto'),
              onTap: () {
                _pickImage(ImageSource.camera);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
     if (!_formKey.currentState!.validate()) {
      return;
    }

    final loadingProvider = Provider.of<LoadingProvider>(context, listen: false);
    loadingProvider.startLoading();

    try {
      if (_selectedImageFile != null) {
        await _firestoreService.uploadProfileImage(_selectedImageFile!.path);
      }

      final Map<String, dynamic> updatedData = {
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()) ?? 0,
        'occupation': _occupationController.text.trim(),
      };

      await _firestoreService.updateUserProfile(updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil diperbarui!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }

    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui profil: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      loadingProvider.stopLoading();
    }
  }

  @override
  Widget build(BuildContext context) {
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
        appBar: AppBar(
          title: const Text('Edit Profil'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          // [DIHAPUS] Tombol simpan di AppBar dihapus dari sini
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: _firestoreService.getUserProfile(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>;
            if (_nameController.text.isEmpty) {
              _nameController.text = userData['name'] ?? '';
              _ageController.text = (userData['age'] ?? 0).toString();
              _occupationController.text = userData['occupation'] ?? '';
              _currentImageUrl = userData['profileImageUrl'];
            }
            
            return _buildForm(context);
          },
        ),
      ),
    );
  }
  
  Widget _buildForm(BuildContext context) {
    return Consumer<LoadingProvider>(
      builder: (context, loadingProvider, child) {
        return AbsorbPointer(
          absorbing: loadingProvider.isLoading,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildProfileImage(),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: _showImageSourceDialog,
                    icon: const Icon(Icons.camera_alt_outlined, size: 20),
                    label: const Text('Ubah Foto Profil'),
                  ),
                  const SizedBox(height: 40),

                  TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Nama Lengkap'), validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
                  const SizedBox(height: 20),
                  TextFormField(controller: _ageController, decoration: const InputDecoration(labelText: 'Usia'), keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
                  const SizedBox(height: 20),
                  TextFormField(controller: _occupationController, decoration: const InputDecoration(labelText: 'Pekerjaan'), validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
                  
                  // [BARU] Tombol simpan dipindahkan ke bawah
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: loadingProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _saveProfile,
                            child: const Text('SIMPAN PERUBAHAN'),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileImage() {
    ImageProvider? backgroundImage;
    if (_selectedImageFile != null) {
      backgroundImage = FileImage(_selectedImageFile!);
    } else if (_currentImageUrl != null) {
      backgroundImage = NetworkImage(_currentImageUrl!);
    }

    return CircleAvatar(
      radius: 60,
      backgroundColor: Colors.grey.shade300,
      backgroundImage: backgroundImage,
      child: backgroundImage == null
          ? const Icon(Icons.person, size: 60, color: Colors.grey)
          : null,
    );
  }
}
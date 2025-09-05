// lib/profile_screen.dart (REVISI)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:freshlens_ai_app/edit_profile_screen.dart';
import 'package:freshlens_ai_app/login_screen.dart';
import 'package:freshlens_ai_app/service/firestore_service.dart';
import 'package:freshlens_ai_app/settings_screen.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isUploading = false;

  Future<void> _signOut() async {
    // <-- PERBAIKAN 1: Simpan referensi Navigator sebelum 'await'
    final navigator = Navigator.of(context);
    
    await _auth.signOut();
    
    // Gunakan navigator yang sudah disimpan, ini lebih aman
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 50);

    if (pickedFile != null) {
      // <-- PERBAIKAN 2: Simpan referensi ScaffoldMessenger sebelum 'await'
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      setState(() => _isUploading = true);
      try {
        await _firestoreService.uploadProfileImage(pickedFile.path);

        // Cek 'mounted' tetap penting
        if (!mounted) return;
        scaffoldMessenger.showSnackBar( // Gunakan messenger yang sudah disimpan
          const SnackBar(content: Text('Foto profil berhasil diperbarui!'), backgroundColor: Colors.green),
        );
      } catch (e) {
        if (!mounted) return;
        scaffoldMessenger.showSnackBar( // Gunakan messenger yang sudah disimpan
          SnackBar(content: Text('Gagal mengunggah foto: $e'), backgroundColor: Colors.red),
        );
      } finally {
        if (mounted) {
          setState(() => _isUploading = false);
        }
      }
    }
  }

  // --- (Sisa kode tidak ada yang berubah) ---
  
  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.of(context).pop();
                _pickAndUploadImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Ambil Foto dari Kamera'),
              onTap: () {
                Navigator.of(context).pop();
                _pickAndUploadImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F1),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestoreService.getUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Tidak dapat memuat profil."));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;

          return Stack(
            children: [
              Positioned(
                top: -size.height * 0.2,
                left: -size.width * 0.1,
                child: Container(
                  width: size.width * 1.2,
                  height: size.height * 0.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F0D3),
                    borderRadius: BorderRadius.circular(size.width),
                  ),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      const Text("Profil", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundImage: userData['profileImageUrl'] != null
                                ? NetworkImage(userData['profileImageUrl'])
                                : null,
                            child: userData['profileImageUrl'] == null
                                ? Text(
                                    userData['name']?.substring(0, 1).toUpperCase() ?? 'A',
                                    style: const TextStyle(fontSize: 40),
                                  )
                                : null,
                          ),
                          if (_isUploading)
                            const Positioned.fill(
                              child: CircularProgressIndicator(color: Colors.white),
                            ),
                          Positioned.fill(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _isUploading ? null : _showImageSourceActionSheet,
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(userData['name'] ?? 'Nama Pengguna', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(userData['email'] ?? 'email@pengguna.com', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                      const SizedBox(height: 40),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Statistik Saya", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(child: _buildStatCard("Makanan Diselamatkan", userData['savedFoodCount'].toString(), "item")),
                                const SizedBox(width: 16),
                                Expanded(child: _buildStatCard("Estimasi Uang Hemat", "Rp ${userData['moneySaved'].toStringAsFixed(0)}", "")),
                              ],
                            ),
                            const SizedBox(height: 24),
                            const Text("Pengaturan Akun", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            _buildMenuButton(
                              icon: Icons.person_outline, 
                              text: "Edit Profil",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                                );
                              }
                            ),
                            _buildMenuButton(
                              icon: Icons.settings_outlined, 
                              text: "Pengaturan", 
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                                );
                              }
                            ),
                            _buildMenuButton(icon: Icons.devices_other_outlined, text: "Kelola Perangkat Box", onTap: () {}),
                            _buildMenuButton(icon: Icons.workspace_premium_outlined, text: "Langganan", onTap: () {}),
                            const SizedBox(height: 24),
                            const Text("Bantuan dan Dukungan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            _buildMenuButton(icon: Icons.help_outline, text: "Pusat Bantuan (FAQ)", onTap: () {}),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _signOut,
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.red,
                                backgroundColor: Colors.white,
                                elevation: 1,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.logout),
                                  SizedBox(width: 16),
                                  Text("Keluar", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String unit) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            const SizedBox(height: 8),
            Text('$value $unit', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton({required IconData icon, required String text, required VoidCallback onTap}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black87,
        backgroundColor: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[700]),
          const SizedBox(width: 16),
          Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const Spacer(),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
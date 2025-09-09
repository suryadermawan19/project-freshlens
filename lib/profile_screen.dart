// lib/profile_screen.dart

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
    // Simpan reference sebelum await
    final navigator = Navigator.of(context);

    await _auth.signOut();

    // Guard agar aman dari use_build_context_synchronously
    if (!mounted) return;

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 50);

    if (pickedFile != null) {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      setState(() => _isUploading = true);
      try {
        await _firestoreService.uploadProfileImage(pickedFile.path);
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diperbarui!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Gagal mengunggah foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

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
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F1),
      appBar: AppBar(
        title: const Text('Profil Saya'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
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

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            children: [
              _buildProfileHeader(context, userData),
              const SizedBox(height: 24),
              _buildStatsSection(context, userData),
              const SizedBox(height: 24),
              _buildSectionTitle(context, 'Pengaturan Akun'),
              _buildSettingsCard(
                context,
                [
                  _buildMenuTile(
                    icon: Icons.person_outline,
                    text: "Edit Profil",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                    ),
                  ),
                  _buildMenuTile(
                    icon: Icons.settings_outlined,
                    text: "Pengaturan Lanjutan",
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    ),
                  ),
                  _buildMenuTile(icon: Icons.devices_other_outlined, text: "Kelola Perangkat Box", onTap: () {}),
                  _buildMenuTile(icon: Icons.workspace_premium_outlined, text: "Langganan", onTap: () {}),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(context, 'Dukungan'),
              _buildSettingsCard(
                context,
                [
                  _buildMenuTile(icon: Icons.description_outlined, text: "Syarat & Ketentuan", onTap: () {}),
                ],
              ),
              const SizedBox(height: 24),
              _buildLogoutButton(context),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, Map<String, dynamic> userData) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: userData['profileImageUrl'] != null
                  ? NetworkImage(userData['profileImageUrl'])
                  : null,
              child: userData['profileImageUrl'] == null
                  ? Text(
                      (userData['name']?.toString().isNotEmpty == true
                              ? userData['name'][0]
                              : 'A')
                          .toUpperCase(),
                      style: const TextStyle(fontSize: 40, color: Colors.black54),
                    )
                  : null,
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                clipBehavior: Clip.hardEdge,
                shape: const CircleBorder(),
                child: InkWell(onTap: _isUploading ? null : _showImageSourceActionSheet),
              ),
            ),
            if (_isUploading)
              const Positioned.fill(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF5D8A41)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          userData['name'] ?? 'Nama Pengguna',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          userData['email'] ?? 'email@pengguna.com',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context, Map<String, dynamic> userData) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            "Makanan Diselamatkan",
            (userData['savedFoodCount'] ?? 0).toString(),
            "item",
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            "Estimasi Uang Hemat",
            "Rp ${(userData['moneySaved'] ?? 0).toString()}",
            "",
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String unit) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor.withAlpha(128)),
      ),
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, List<Widget> children) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).dividerColor.withAlpha(128)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuTile({required IconData icon, required String text, VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _signOut,
      icon: const Icon(Icons.logout),
      label: const Text("Keluar"),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.red.shade700,
        backgroundColor: Colors.red.withAlpha(40),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

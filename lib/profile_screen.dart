// lib/profile_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:freshlens_ai_app/login_screen.dart';
import 'package:freshlens_ai_app/service/firestore_service.dart';
import 'package:freshlens_ai_app/edit_profile_screen.dart';
import 'package:freshlens_ai_app/settings_screen.dart';
import 'package:freshlens_ai_app/help_screen.dart';
import 'package:freshlens_ai_app/about_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      // Kembali ke halaman login dan hapus semua halaman sebelumnya dari stack
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestoreService.getUserProfile(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Gagal memuat data profil.'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final name = userData['name'] as String? ?? 'Pengguna';
          final email = userData['email'] as String? ?? 'email@anda.com';
          final imageUrl = userData['profileImageUrl'] as String?;
          final savedFoodCount = userData['savedFoodCount'] as int? ?? 0;
          final moneySaved = (userData['moneySaved'] as num? ?? 0.0).toDouble();

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            children: [
              _buildUserInfoSection(context, name, email, imageUrl),
              const SizedBox(height: 24),
              _buildStatsSection(context, savedFoodCount, moneySaved),
              const SizedBox(height: 24),
              _buildMenuList(context),
              const SizedBox(height: 32),
              _buildLogoutButton(context),
            ],
          );
        },
      ),
    );
  }

  // Widget helper untuk bagian info pengguna
  Widget _buildUserInfoSection(
      BuildContext context, String name, String email, String? imageUrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
            child: imageUrl == null
                ? Text(
                    name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'A',
                    style: const TextStyle(fontSize: 32))
                : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const EditProfileScreen()),
              );
            },
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
    );
  }

  // Widget helper untuk bagian statistik
  Widget _buildStatsSection(
      BuildContext context, int savedFoodCount, double moneySaved) {
    // Estimasi Poin Eco: 10 poin per makanan, 1 poin per Rp1000
    final ecoPoints = (savedFoodCount * 10) + (moneySaved / 1000).floor();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Card(
        elevation: 0,
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(context,
                  value: savedFoodCount.toString(),
                  label: 'Makanan Terselamatkan'),
              _buildStatItem(context,
                  value: 'Rp ${moneySaved.toStringAsFixed(0)}',
                  label: 'Uang Dihemat'),
              _buildStatItem(context,
                  value: ecoPoints.toString(), label: 'Poin Eco'),
            ],
          ),
        ),
      ),
    );
  }

  // Widget kecil untuk setiap item statistik
  Widget _buildStatItem(BuildContext context,
      {required String value, required String label}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  // Widget helper untuk daftar menu
  Widget _buildMenuList(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          _buildMenuTile(context, icon: Icons.person_outline, title: 'Pengaturan Akun', onTap: () {
  Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
}),
          const Divider(height: 0),
          _buildMenuTile(context, icon: Icons.help_outline, title: 'Bantuan & FAQ', onTap: () {
  Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpScreen()));
}),
const Divider(height: 0),
_buildMenuTile(context, icon: Icons.info_outline, title: 'Tentang Kami', onTap: () {
  Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutScreen()));
}),
        ],
      ),
    );
  }

  // Widget kecil untuk setiap baris menu
  Widget _buildMenuTile(BuildContext context,
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title, style: Theme.of(context).textTheme.bodyLarge),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  // Widget helper untuk tombol logout
  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: OutlinedButton.icon(
        onPressed: _signOut,
        icon: const Icon(Icons.logout),
        label: const Text('Keluar Akun'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

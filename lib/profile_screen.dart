// lib/profile_screen.dart

import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F1),
      body: Stack(
        children: [
          // Latar belakang melengkung berwarna hijau
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

          // Konten Utama
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // --- Bagian Header ---
                  const SizedBox(height: 16),
                  const Text("Profil", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage('assets/images/profile.png'),
                  ),
                  const SizedBox(height: 16),
                  const Text("Azizah", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text("azizahn@gmail.com", style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                  const SizedBox(height: 40),

                  // --- Bagian Konten di Bawah Header ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- Statistik Saya ---
                        const Text("Statistik Saya", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildStatCard("Makanan Diselamatkan", "25", "")),
                            const SizedBox(width: 16),
                            Expanded(child: _buildStatCard("Estimasi Uang Hemat", "Rp 50.000", "")),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // --- Pengaturan Akun ---
                        const Text("Pengaturan Akun", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildMenuButton(icon: Icons.person_outline, text: "Edit Profil"),
                        const SizedBox(height: 12),
                        _buildMenuButton(icon: Icons.settings_outlined, text: "Pengaturan"),
                        const SizedBox(height: 12),
                        _buildMenuButton(icon: Icons.devices_other_outlined, text: "Kelola Perangkat Box"),
                        const SizedBox(height: 12),
                        _buildMenuButton(icon: Icons.workspace_premium_outlined, text: "Langganan"),
                        const SizedBox(height: 24),

                        // --- Bantuan dan Dukungan ---
                        const Text("Bantuan dan Dukungan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        _buildMenuButton(icon: Icons.help_outline, text: "Pusat Bantuan (FAQ)"),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget helper untuk kartu statistik
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
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // Widget helper untuk tombol menu
  Widget _buildMenuButton({required IconData icon, required String text}) {
    return ElevatedButton(
      onPressed: () {},
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
        ],
      ),
    );
  }
}
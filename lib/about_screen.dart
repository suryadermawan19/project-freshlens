// lib/about_screen.dart

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  // Fungsi untuk mendapatkan versi aplikasi
  Future<String> _getAppVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentang Kami'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.eco_outlined, size: 80, color: Color(0xFF5D8A41)),
            const SizedBox(height: 16),
            const Text(
              'FreshLens AI',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text(
              'Misi kami adalah memberdayakan setiap rumah tangga untuk mengurangi limbah makanan melalui teknologi yang mudah digunakan dan cerdas.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
            const Spacer(),
            // Widget untuk menampilkan versi secara dinamis
            FutureBuilder<String>(
              future: _getAppVersion(),
              builder: (context, snapshot) {
                final version = snapshot.hasData ? snapshot.data : '...';
                return Text(
                  'Versi Aplikasi $version',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              '© 2025 FreshLens Project',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
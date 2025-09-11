// lib/settings_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:freshlens_ai_app/qr_scanner_screen.dart';
import 'package:freshlens_ai_app/service/firestore_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  void _showChangePasswordDialog() {
    // ... (kode di dalam fungsi ini tidak berubah)
  }
  void _showDeleteAccountDialog() {
    // ... (kode di dalam fungsi ini tidak berubah)
  }
  
  // [DIUBAH] Fungsi unregisterDevice diperbarui untuk keamanan
  Future<void> _unregisterDevice() async {
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Putuskan Perangkat'),
        content: const Text('Apakah Anda yakin ingin memutuskan hubungan dengan perangkat ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Putuskan', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      // Amankan context sebelum await
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      try {
        final functions = FirebaseFunctions.instanceFor(region: 'asia-southeast2');
        final callable = functions.httpsCallable('unregisterDevice');
        await callable.call();
        
        // Cek `mounted` sebelum menggunakan context
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(const SnackBar(
          content: Text('Perangkat berhasil diputuskan.'),
          backgroundColor: Colors.green,
        ));
      } on FirebaseFunctionsException catch (e) {
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(SnackBar(
          content: Text('Gagal: ${e.message}'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle(context, 'Perangkat IoT'),
          _buildDeviceSection(),
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Keamanan'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Ubah Password'),
              onTap: _showChangePasswordDialog,
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle(context, 'Zona Berbahaya'),
          Card(
            color: Colors.red.withAlpha(20),
            child: ListTile(
              leading: const Icon(Icons.delete_forever_outlined, color: Colors.red),
              title: const Text('Hapus Akun', style: TextStyle(color: Colors.red)),
              onTap: _showDeleteAccountDialog,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDeviceSection() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestoreService.getUserProfile(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(child: ListTile(title: Text('Memuat...')));
        }
        
        final deviceId = (snapshot.data!.data() as Map<String, dynamic>)['linkedDeviceId'];

        if (deviceId != null) {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.sensors, color: Colors.green),
              title: const Text('Perangkat Terhubung'),
              subtitle: Text('ID: $deviceId'),
              trailing: TextButton(
                onPressed: _unregisterDevice,
                child: const Text('Putuskan', style: TextStyle(color: Colors.red)),
              ),
            ),
          );
        } else {
          return Card(
            child: ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: const Text('Hubungkan Perangkat'),
              subtitle: const Text('Pindai QR code pada box buah Anda'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const QRScannerScreen()));
              },
            ),
          );
        }
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
     return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.grey[600],
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
// lib/help_screen.dart

import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // [BARU] Bungkus dengan Container untuk gradient
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
        // [PENTING] Jadikan Scaffold transparan
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Bantuan & FAQ'),
          // [PENTING] Jadikan AppBar transparan
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: const [
            ExpansionTile(
              title: Text('Apa itu FreshLens AI?', style: TextStyle(fontWeight: FontWeight.bold)),
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('FreshLens AI adalah aplikasi cerdas yang membantu Anda mengelola inventaris dapur, memprediksi masa simpan makanan, dan mengurangi limbah makanan menggunakan teknologi AI.'),
                ),
              ],
            ),
            ExpansionTile(
              title: Text('Bagaimana cara kerja prediksi usia simpan?', style: TextStyle(fontWeight: FontWeight.bold)),
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('AI kami menggunakan data dari gambar yang Anda unggah, kondisi awal yang Anda masukkan, serta data suhu dan kelembapan dari sensor untuk memberikan estimasi masa simpan yang lebih akurat.'),
                ),
              ],
            ),
             ExpansionTile(
              title: Text('Apakah data saya aman?', style: TextStyle(fontWeight: FontWeight.bold)),
              children: [
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Tentu saja. Semua data Anda disimpan dengan aman di server Firebase dan hanya dapat diakses oleh Anda. Kami sangat menjaga privasi pengguna.'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
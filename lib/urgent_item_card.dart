// lib/urgent_item_card.dart (REVISI LENGKAP)

import 'package:flutter/material.dart';

class UrgentItemCard extends StatelessWidget {
  final String itemName;
  final int daysLeft;
  final String imageUrl; // Tambahkan imageUrl untuk menampilkan gambar

  const UrgentItemCard({
    super.key,
    required this.itemName,
    required this.daysLeft,
    required this.imageUrl,
  });

  // Helper untuk menentukan warna berdasarkan sisa hari
  Color _getDaysColor() {
    if (daysLeft <= 2) {
      return Colors.red.shade700;
    } else if (daysLeft <= 4) {
      return Colors.orange.shade800;
    }
    return Colors.green.shade800;
  }

  // Helper untuk mendapatkan gambar
  ImageProvider _getImageProvider(String path) {
    if (path.startsWith('http')) {
      return NetworkImage(path);
    } else {
      // Fallback jika path bukan URL
      return const AssetImage('assets/images/placeholder.png');
    }
  }


  @override
  Widget build(BuildContext context) {
    final color = _getDaysColor();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias, // Penting untuk melengkungkan gambar
      child: Container(
        width: 160, // Lebar kartu tetap untuk carousel
        decoration: BoxDecoration(
          image: DecorationImage(
            image: _getImageProvider(imageUrl),
            fit: BoxFit.cover,
            // Buat gambar sedikit gelap agar teks mudah dibaca
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.4),
              BlendMode.darken,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end, // Posisikan konten di bawah
            children: [
              Text(
                itemName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 2.0, color: Colors.black54)],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Sisa $daysLeft hari',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// lib/inventory_group_item.dart

import 'package:flutter/material.dart';
import 'models/inventory_item_model.dart';

class InventoryGroupItem extends StatelessWidget {
  final InventoryItemGroup itemGroup;
  final VoidCallback onTap;

  const InventoryGroupItem({
    super.key,
    required this.itemGroup,
    required this.onTap,
  });

  String _getStatusForDays(int days) {
    if (days <= 2) return 'Kritis';
    if (days <= 4) return 'Segera Olah';
    return 'Segar';
  }

  // FUNGSI BARU UNTUK MENENTUKAN TIPE GAMBAR
  ImageProvider _getImageProvider(String path) {
    // Jika path adalah URL dari internet, gunakan NetworkImage
    if (path.startsWith('http')) {
      return NetworkImage(path);
    }
    // Jika tidak, anggap itu adalah aset lokal
    else {
      return AssetImage(path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final criticalBatch = itemGroup.batches.reduce((a, b) => a.predictedShelfLife < b.predictedShelfLife ? a : b);
    final shortestDaysLeft = criticalBatch.predictedShelfLife;
    final groupStatus = _getStatusForDays(shortestDaysLeft);
    final statusColor = groupStatus == 'Kritis' ? Colors.red.shade700 : (groupStatus == 'Segera Olah' ? Colors.orange.shade800 : Colors.green.shade800);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            // Gambar di Kiri
            CircleAvatar(
              radius: 28,
              // GUNAKAN FUNGSI _getImageProvider DI SINI
              backgroundImage: _getImageProvider(itemGroup.imagePath),
              // Tambahkan child untuk fallback jika gambar gagal dimuat
              child: ClipOval(
                child: Image(
                  image: _getImageProvider(itemGroup.imagePath),
                  fit: BoxFit.cover,
                  width: 56,
                  height: 56,
                  errorBuilder: (context, error, stackTrace) {
                    // Tampilkan inisial nama jika gambar gagal
                    return Center(
                      child: Text(
                        itemGroup.itemName.isNotEmpty ? itemGroup.itemName[0] : '?',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Teks di Tengah
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itemGroup.itemName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      children: [
                        TextSpan(text: 'Total: ${itemGroup.totalQuantity} buah • '),
                        TextSpan(
                          text: groupStatus,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Sisa Hari di Kanan
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$shortestDaysLeft',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black87),
                ),
                const Text('hari lagi', style: TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
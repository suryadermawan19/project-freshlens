// lib/widgets/inventory_grid_item.dart

import 'package:flutter/material.dart';
import 'package:freshlens_ai_app/models/inventory_item_model.dart';

class InventoryGridItem extends StatelessWidget {
  final InventoryItemGroup itemGroup;
  final VoidCallback onTap;

  const InventoryGridItem({
    super.key,
    required this.itemGroup,
    required this.onTap,
  });

  // Helper untuk menentukan status berdasarkan hari terpendek
  String getStatusForDays(int days) {
    if (days <= 2) return 'Kritis';
    if (days <= 4) return 'Segera Olah';
    return 'Segar';
  }

  // Helper untuk menentukan warna chip status
  Color getColorForStatus(String status) {
    switch (status) {
      case 'Kritis':
        return Colors.red.shade400;
      case 'Segera Olah':
        return Colors.orange.shade400;
      case 'Segar':
      default:
        return Colors.green.shade400;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hitung sisa hari terpendek dan total kuantitas dari semua batch
    final shortestDays = itemGroup.batches
        .map((b) => b.predictedShelfLife)
        .reduce((a, b) => a < b ? a : b);
    final totalQuantity = itemGroup.batches
        .map((b) => b.quantity)
        .reduce((a, b) => a + b);
    
    final status = getStatusForDays(shortestDays);
    final statusColor = getColorForStatus(status);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Gambar Item
            Expanded(
              child: Image.network( // Menggunakan Image.network untuk URL dari Firebase
                itemGroup.imagePath,
                fit: BoxFit.cover,
                // Tampilkan loading indicator saat gambar dimuat
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                },
                // Tampilkan ikon error jika gambar gagal dimuat
                errorBuilder: (context, error, stackTrace) {
                  return const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey));
                },
              ),
            ),

            // Informasi Item
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itemGroup.itemName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Total Kuantitas
                      Text(
                        'Jumlah: $totalQuantity',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      ),
                      // Chip Status Kesegaran
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
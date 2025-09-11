// lib/widgets/urgent_item_card.dart

import 'package:flutter/material.dart';

class UrgentItemCard extends StatelessWidget {
  final String imageUrl;
  final String itemName;
  final int daysLeft;

  const UrgentItemCard({
    super.key,
    required this.imageUrl,
    required this.itemName,
    required this.daysLeft,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Card(
        clipBehavior: Clip.antiAlias, // Untuk memastikan gambar mengikuti border radius
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: imageUrl.isEmpty
                  // Jika URL kosong, tampilkan placeholder
                  ? const Center(child: Icon(Icons.image_not_supported_outlined, color: Colors.grey))
                  // [DIUBAH] Menggunakan Image.network untuk URL dari Firebase
                  : Image.network(
                      imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      // [DITAMBAH] Tampilkan loading indicator saat gambar dimuat
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                      },
                      // [DITAMBAH] Tampilkan ikon error jika gambar gagal dimuat
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey));
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itemName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$daysLeft hari lagi',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: daysLeft <= 2 ? Colors.red.shade700 : Colors.orange.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
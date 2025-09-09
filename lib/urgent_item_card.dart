// lib/urgent_item_card.dart

import 'package:flutter/material.dart';

class UrgentItemCard extends StatelessWidget {
  final String itemName;
  final int daysLeft;
  final String imageUrl;

  const UrgentItemCard({
    super.key,
    required this.itemName,
    required this.daysLeft,
    required this.imageUrl,
  });

  Color _getDaysColor() {
    if (daysLeft <= 2) {
      return Colors.red.shade600;
    } else if (daysLeft <= 4) {
      return Colors.orange.shade600;
    }
    return Colors.green.shade600;
  }

  ImageProvider _getImageProvider(String path) {
    if (path.startsWith('http')) {
      return NetworkImage(path);
    } else {
      return const AssetImage('assets/images/placeholder.png');
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getDaysColor();

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 3,
      // PERBAIKAN WARNING: Menggunakan withAlpha()
      shadowColor: Colors.black.withAlpha(77),
      child: Container(
        width: 160,
        height: 180,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: _getImageProvider(imageUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      // PERBAIKAN WARNING: Menggunakan withAlpha()
                      Colors.black.withAlpha(26),
                      Colors.black.withAlpha(204),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.5, 0.7, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itemName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                      shadows: [
                        Shadow(blurRadius: 2.0, color: Colors.black54)
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
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
          ],
        ),
      ),
    );
  }
}
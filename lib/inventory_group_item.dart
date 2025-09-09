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

  // Helper untuk menentukan status dan warna
  (String, Color) _getStatusInfo() {
    final shortestDaysLeft = itemGroup.batches
        .map((b) => b.predictedShelfLife)
        .reduce((a, b) => a < b ? a : b);

    if (shortestDaysLeft <= 2) {
      return ('Kritis', Colors.red.shade600);
    } else if (shortestDaysLeft <= 4) {
      return ('Segera Olah', Colors.orange.shade700);
    } else {
      return ('Segar', Colors.green.shade600);
    }
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
    final (statusText, statusColor) = _getStatusInfo();

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        // PERBAIKAN WARNING: Menggunakan withAlpha()
        side: BorderSide(color: Theme.of(context).dividerColor.withAlpha(128)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: Colors.grey.shade100,
                // PERBAIKAN ERROR: Widget Image dibungkus dengan Padding
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Image(
                    image: _getImageProvider(itemGroup.imagePath),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.inventory_2_outlined,
                          color: Colors.grey, size: 40);
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itemGroup.itemName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total: ${itemGroup.totalQuantity} buah',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      // PERBAIKAN WARNING: Menggunakan withAlpha()
                      color: statusColor.withAlpha(38),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
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
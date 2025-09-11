// lib/widgets/inventory_preview_card.dart

import 'package:flutter/material.dart';
import 'package:freshlens_ai_app/models/inventory_item_model.dart';

class InventoryPreviewCard extends StatelessWidget {
  final InventoryItemGroup itemGroup;
  final VoidCallback onTap;

  const InventoryPreviewCard({
    super.key,
    required this.itemGroup,
    required this.onTap,
  });
  
  // Helper untuk status dan warna (bisa dipindahkan ke file terpisah nanti)
  String getStatusForDays(int days) {
    if (days <= 2) return 'Kritis';
    if (days <= 4) return 'Segera Olah';
    return 'Segar';
  }

  Color getColorForStatus(String status) {
    switch (status) {
      case 'Kritis': return Colors.red;
      case 'Segera Olah': return Colors.orange;
      default: return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final shortestDays = itemGroup.batches.map((b) => b.predictedShelfLife).reduce((a, b) => a < b ? a : b);
    final totalQuantity = itemGroup.batches.map((b) => b.quantity).reduce((a, b) => a + b);
    final status = getStatusForDays(shortestDays);
    final statusColor = getColorForStatus(status);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Ikon status
              Icon(Icons.circle, color: statusColor, size: 12),
              const SizedBox(width: 16),
              // Nama item
              Expanded(
                child: Text(
                  itemGroup.itemName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              // Jumlah
              Text(
                '$totalQuantity Pcs',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
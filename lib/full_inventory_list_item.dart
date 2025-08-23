// lib/full_inventory_list_item.dart

import 'package:flutter/material.dart';

class FullInventoryListItem extends StatelessWidget {
  final String imagePath;
  final String itemName;
  final String daysLeft;
  final String status;
  final VoidCallback onTap;

  const FullInventoryListItem({
    super.key,
    required this.imagePath,
    required this.itemName,
    required this.daysLeft,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Kita gunakan ListTile, widget yang didesain khusus untuk baris daftar
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 25,
        backgroundImage: AssetImage(imagePath),
      ),
      title: Text(
        itemName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text('$daysLeft • $status'),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
    );
  }
}
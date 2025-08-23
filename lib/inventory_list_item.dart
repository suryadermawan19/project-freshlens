// lib/inventory_list_item.dart

import 'package:flutter/material.dart';

class InventoryListItem extends StatelessWidget {
  final String itemName;
  final VoidCallback onTap; // Untuk handle saat item di-klik

  const InventoryListItem({
    super.key,
    required this.itemName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Kita gunakan Column agar bisa menambahkan Divider (garis) di bawah ListTile
    return Column(
      children: [
        // ListTile adalah widget Flutter yang sempurna untuk baris daftar seperti ini
        ListTile(
          contentPadding: EdgeInsets.zero, // Menghapus padding default
          title: Text(
            itemName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: const Text('Lihat selengkapnya'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap, // Menjalankan fungsi saat di-klik
        ),
        const Divider(height: 1, color: Colors.black12), // Garis pemisah tipis
      ],
    );
  }
}
// lib/urgent_item_card.dart

import 'package:flutter/material.dart';

class UrgentItemCard extends StatelessWidget {
  // Widget ini menerima data ikon, nama item, dan sisa hari
  final IconData itemIcon;
  final String itemName;
  final String daysLeft;

  const UrgentItemCard({
    super.key,
    required this.itemIcon,
    required this.itemName,
    required this.daysLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F0D3), // Warna latar kartu
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Row(
        children: [
          // Wadah untuk menampilkan Ikon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: Colors.white.withOpacity(0.7),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Icon(
              itemIcon,
              color: const Color(0xFF4E5D49),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),

          // Nama item, akan mengambil sisa ruang
          Expanded(
            child: Text(
              itemName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF37474F),
              ),
            ),
          ),

          // Teks untuk sisa hari
          Text(
            daysLeft,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF4E5D49),
            ),
          ),
        ],
      ),
    );
  }
}
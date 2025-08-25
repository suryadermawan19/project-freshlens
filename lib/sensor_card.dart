// lib/sensor_card.dart

import 'package:flutter/material.dart';

class SensorCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String unit;
  final String status;

  const SensorCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.unit,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF6B8E9A),
        borderRadius: BorderRadius.circular(25.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 30),
              const SizedBox(width: 5), // Sedikit mengurangi jarak
              // --- PERBAIKAN DI SINI ---
              // Gunakan Flexible agar teks bisa menyesuaikan diri
              Flexible(
                child: Text(
                  value + unit,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                  // Mencegah teks turun baris dan menampilkan '...' jika terlalu panjang
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          Text(
            status,
            style: TextStyle(
              color: Colors.white.withAlpha(230),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
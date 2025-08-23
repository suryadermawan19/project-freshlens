// lib/sensor_card.dart (Versi Perbaikan Layout)

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
    // Kita beri tinggi yang pasti pada kartu kita agar tidak terjadi konflik
    return Container(
      height: 140, // <-- KUNCI PERBAIKAN: Memberi tinggi yang pasti
      padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF6B8E9A),
        borderRadius: BorderRadius.circular(25.5),
      ), 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // <-- Menggantikan fungsi Spacer
        children: [
          // Bagian atas: Judul
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Bagian tengah: Ikon dan Nilai
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 40),
              const SizedBox(width: 12),
              Text(
                value + unit,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

       
           // Bagian bawah: Status
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
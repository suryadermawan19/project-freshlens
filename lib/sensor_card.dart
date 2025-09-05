// lib/sensor_card.dart (REVISI FINAL - LOGIKA SUHU FLEKSIBEL)

import 'package:flutter/material.dart';

class SensorCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String unit;
  final Color color;
  final double sensorValue;

  const SensorCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.unit,
    required this.color,
    required this.sensorValue,
  });

  // --- LOGIKA BARU YANG LEBIH FLEKSIBEL ---
  // Helper untuk menentukan status suhu (bisa kulkas atau ruang)
  (String, Color) _getTemperatureStatus(double temp) {
    // Kulkas (Optimal: 2-8°C)
    if (temp >= 2 && temp <= 8) {
      return ('Suhu Kulkas Optimal', Colors.green);
    }
    // Suhu Ruang Sejuk (Optimal: 18-24°C)
    else if (temp >= 18 && temp <= 24) {
      return ('Suhu Ruang Optimal', Colors.green);
    }
    // Kondisi Peringatan (sedikit di luar rentang ideal)
    else if ((temp > 8 && temp < 18) || (temp > 24 && temp <= 28)) {
      return ('Perlu Perhatian', Colors.orange.shade700);
    }
    // Kondisi Anomali (berbahaya untuk makanan)
    else {
      return ('Anomali!', Colors.red.shade800);
    }
  }

  // Helper untuk menentukan status kelembaban (logika tetap sama)
  (String, Color) _getHumidityStatus(double humidity) {
    if (humidity >= 60 && humidity <= 80) {
      return ('Normal', Colors.green);
    } else if (humidity < 60 && humidity >= 40) {
      return ('Agak Kering', Colors.orange.shade700);
    } else if (humidity < 40) {
      return ('Kering!', Colors.red.shade800);
    } else if (humidity > 80 && humidity <= 90) {
      return ('Agak Basah', Colors.blue.shade700);
    } else {
      return ('Basah!', Colors.red.shade800);
    }
  }

  @override
  Widget build(BuildContext context) {
    String statusText;
    Color statusColor;

    // Tentukan status berdasarkan jenis sensor
    if (title.toLowerCase().contains('suhu')) { // Deteksi berdasarkan judul
      final (text, color) = _getTemperatureStatus(sensorValue);
      statusText = text;
      statusColor = color;
    } else if (title.toLowerCase().contains('kelembapan')) {
      final (text, color) = _getHumidityStatus(sensorValue);
      statusText = text;
      statusColor = color;
    } else {
      statusText = 'N/A';
      statusColor = Colors.grey;
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 24, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                children: <TextSpan>[
                  TextSpan(text: value),
                  TextSpan(
                    text: ' $unit',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: statusColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
// lib/sensor_card.dart

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

  // Logika untuk menentukan status suhu
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

  // Logika untuk menentukan status kelembaban
  (String, Color) _getHumidityStatus(double humidity) {
    if (humidity >= 60 && humidity <= 80) {
      return ('Normal', Colors.green);
    } else if (humidity < 60 && humidity >= 40) {
      return ('Agak Kering', Colors.orange.shade700);
    } else if (humidity < 40) {
      return ('Kering!', Colors.red.shade800);
    } else if (humidity > 80 && humidity <= 90) {
      return ('Agak Lembab', Colors.blue.shade700);
    } else {
      return ('Terlalu Lembab!', Colors.red.shade800);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (statusText, statusColor) = title.toLowerCase().contains('suhu')
        ? _getTemperatureStatus(sensorValue)
        : _getHumidityStatus(sensorValue);

    return Card(
      // Menggunakan warna dari CardTheme yang sudah kita atur di main.dart
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris Atas: Ikon dan Judul
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, size: 28, color: color),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Spacer(),
            // Baris Tengah: Nilai Sensor
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                children: <TextSpan>[
                  TextSpan(text: value),
                  TextSpan(
                    text: ' $unit',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.normal,
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Baris Bawah: Status
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 14,
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
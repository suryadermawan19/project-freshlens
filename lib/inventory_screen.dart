// lib/inventory_screen.dart (Dengan Sorting)

import 'package:flutter/material.dart';
import 'models/inventory_item_model.dart';
import 'item_detail_screen.dart';
import 'inventory_group_item.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});
  
  // Helper function untuk menentukan status berdasarkan sisa hari
  String _getStatusForDays(int days) {
    if (days <= 2) return 'Kritis';
    if (days <= 4) return 'Segera Olah';
    return 'Segar';
  }
  
  // Helper function untuk mendapatkan nilai prioritas dari status
  int _getPriorityForStatus(String status) {
    switch (status) {
      case 'Kritis':
        return 1;
      case 'Segera Olah':
        return 2;
      case 'Segar':
        return 3;
      default:
        return 4;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<InventoryItemGroup> allItemGroups = [
      InventoryItemGroup(itemName: 'Tomat', imagePath: 'assets/images/tomato.png', batches: [Batch(id: 'tomat1', entryDate: DateTime(2025, 8, 8), quantity: 3, predictedShelfLife: 3), Batch(id: 'tomat2', entryDate: DateTime(2025, 8, 9), quantity: 2, predictedShelfLife: 4)]),
      InventoryItemGroup(itemName: 'Selada', imagePath: 'assets/images/lettuce.png', batches: [Batch(id: 'selada1', entryDate: DateTime(2025, 8, 7), quantity: 1, predictedShelfLife: 5)]),
      InventoryItemGroup(itemName: 'Pisang', imagePath: 'assets/images/banana.png', batches: [Batch(id: 'pisang1', entryDate: DateTime(2025, 8, 11), quantity: 5, predictedShelfLife: 2)]),
      InventoryItemGroup(itemName: 'Wortel', imagePath: 'assets/images/carrot.png', batches: [Batch(id: 'wortel1', entryDate: DateTime(2025, 8, 10), quantity: 4, predictedShelfLife: 8)]),
    ];

    // ==========================================================
    // ## LOGIKA SORTING DITERAPKAN DI SINI ##
    // ==========================================================
    allItemGroups.sort((a, b) {
      // Cari sisa hari terpendek untuk item A
      final shortestDaysA = a.batches.map((batch) => batch.predictedShelfLife).reduce((val, el) => val < el ? val : el);
      // Cari sisa hari terpendek untuk item B
      final shortestDaysB = b.batches.map((batch) => batch.predictedShelfLife).reduce((val, el) => val < el ? val : el);
      
      // Dapatkan status & prioritas untuk masing-masing
      final priorityA = _getPriorityForStatus(_getStatusForDays(shortestDaysA));
      final priorityB = _getPriorityForStatus(_getStatusForDays(shortestDaysB));
      
      // Bandingkan berdasarkan prioritas
      return priorityA.compareTo(priorityB);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F1),
      appBar: AppBar(
        title: const Text('Inventaris'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFFFAF8F1),
        foregroundColor: Colors.black,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: allItemGroups.length,
        itemBuilder: (context, index) {
          final itemGroup = allItemGroups[index];
          return InventoryGroupItem(
            itemGroup: itemGroup,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ItemDetailScreen(itemGroup: itemGroup))),
          );
        },
        separatorBuilder: (context, index) => const Divider(indent: 20, endIndent: 20),
      ),
    );
  }
}
// lib/inventory_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:freshlens_ai_app/item_detail_screen.dart';
import 'package:freshlens_ai_app/models/inventory_item_model.dart';
import 'package:freshlens_ai_app/service/firestore_service.dart';
import 'package:freshlens_ai_app/widgets/inventory_grid_item.dart';
import 'package:freshlens_ai_app/widgets/inventory_grid_shimmer.dart'; // <-- 1. IMPORT SHIMMER WIDGET

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  // Logika untuk sorting
  String _getStatusForDays(int days) {
    if (days <= 2) return 'Kritis';
    if (days <= 4) return 'Segera Olah';
    return 'Segar';
  }
  
  int _getPriorityForStatus(String status) {
    switch (status) {
      case 'Kritis': return 1;
      case 'Segera Olah': return 2;
      case 'Segar': return 3;
      default: return 4;
    }
  }

  // Logika untuk grouping
  List<InventoryItemGroup> _groupItems(List<DocumentSnapshot> allItems) {
    final Map<String, List<DocumentSnapshot>> groupedData = {};
    for (var doc in allItems) {
      final data = doc.data() as Map<String, dynamic>;
      final itemName = data['itemName'] as String;
      if (groupedData[itemName] == null) groupedData[itemName] = [];
      groupedData[itemName]!.add(doc);
    }
    return groupedData.entries.map((entry) {
      final batchesData = entry.value;
      final firstItemData = batchesData.first.data() as Map<String, dynamic>;
      return InventoryItemGroup(
        itemName: entry.key,
        imagePath: firstItemData['imageUrl'] ?? '',
        batches: batchesData.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Batch(
            id: doc.id,
            entryDate: (data['entryDate'] as Timestamp? ?? Timestamp.now()).toDate(),
            quantity: data['quantity'] ?? 0,
            predictedShelfLife: data['predictedShelfLife'] ?? 7,
            initialCondition: data['initialCondition'] ?? 'Tidak diketahui',
          );
        }).toList(),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventaris Saya'),
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getInventoryItems(),
        builder: (context, snapshot) {
          // [DIUBAH] Tampilkan shimmer saat data sedang dimuat
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const InventoryGridShimmer();
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final itemDocs = snapshot.data!.docs;
          final allItemGroups = _groupItems(itemDocs);

          allItemGroups.sort((a, b) {
            final shortestDaysA = a.batches.map((b) => b.predictedShelfLife).reduce((v, e) => v < e ? v : e);
            final shortestDaysB = b.batches.map((b) => b.predictedShelfLife).reduce((v, e) => v < e ? v : e);
            final priorityA = _getPriorityForStatus(_getStatusForDays(shortestDaysA));
            final priorityB = _getPriorityForStatus(_getStatusForDays(shortestDaysB));
            if (priorityA != priorityB) {
              return priorityA.compareTo(priorityB);
            }
            return shortestDaysA.compareTo(shortestDaysB);
          });
          
          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: allItemGroups.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 0.8,
            ),
            itemBuilder: (context, index) {
              final itemGroup = allItemGroups[index];
              return InventoryGridItem(
                itemGroup: itemGroup,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemDetailScreen(itemGroup: itemGroup),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'Inventaris Anda Kosong',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Tekan tombol kamera di bawah untuk menambahkan item pertama Anda!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}